#!/bin/bash +x


die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

# Fail if running as root
if [ "$(id -u)" -eq 0 ]; then
	die "Cannot be ran as root"
fi

while getopts u:-: OPT; do
	# support long options: https://stackoverflow.com/a/28466267/519360
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		u | user )      needs_arg; duser="$OPTARG" ;; # number of minutes to look for modified files
		??* )           die "Illegal option --$OPT" ;;  # bad long option
		? )             exit 2 ;;  # bad short option (error reported via getopts)
	esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list


if [[ -z $duser ]]; then
	duser=$USER
	if [ "$DUSER" = "root" ]; then
		die "Cannot be ran as root"
	fi
fi

echo "*********************************"
echo "* hacksearch"
echo "*********************************"

duserdir=/home/$duser
WP_COMMAND='/usr/local/bin/php /usr/bin/wp --path="$duserdir/public_html"'

echo "Remove suspicious directories in ~/etc"
find $duserdir/etc -type d \( -iname *anonymousFox* -o -iname *smtpfox* -o -iname *pwcache* \) | xargs rm -rf
echo "."
echo ""

echo "Remove suspicious files in ~/mail"
find $duserdir/mail \( -iname *anonymousFox* -o -iname *smtpfox* -o -iname *pwcache* \) | xargs rm -rf

echo "Remove bad entries from ~/etc/shadow"
if [ -f "$duserdir/etc/shadow" ]; then
	mv -f $duserdir/etc/shadow $duserdir/etc/shadow.old
	egrep -iv "fox|anonymous|smtp" $duserdir/etc/shadow.old > $duserdir/etc/shadow
	rm $duserdir/etc/shadow.old
fi
echo "."
echo ""

echo "Fixing user_login (will set user_id to ybs_support)"
eval "$WP_COMMAND db query \"UPDATE wp_users SET user_login = 'ybs_support', display_name = 'ybs_support' where user_email = 'webmaster@yellowboxsolutions.com'\""
echo "."
echo ""

echo "Generating new password for wordpress user"
new_wp_pass=$(openssl rand -base64 15)
echo "***new wp password"
echo "$new_wp_pass"
echo "."
echo ""

echo "Setting new password for wordpress user"
eval "$WP_COMMAND user update ybs_support --user_pass=$new_wp_pass"
echo "."
echo ""

echo "**************************************"
echo "* Changing DB Password                "
echo "**************************************"

echo "Getting current DB info"
db_user=$(eval "$WP_COMMAND config get \"DB_USER\"")
echo "***DB_USER"
echo $db_user
db_password=$(eval "$WP_COMMAND config get \"DB_PASSWORD\"")
echo "***DB_PASSWORD"
echo $db_password

echo "Generating new password for wordpress database"
new_db_pass=$(openssl rand -base64 15)

echo "Changing db password in mysql"
echo "***mysql> $sql"
sql="SET PASSWORD = PASSWORD('$new_db_pass');"
mysql -u $db_user -p"$db_password" <<< $sql
echo "***new db password"
echo "$new_db_pass"
if [ $? -eq 0 ]
then
	echo "Changing db password in wp-config.php"
	eval "$WP_COMMAND config set DB_PASSWORD '$new_db_pass'"
else
	echo "Changing db password in mysql failed. Skipping wp-config"
fi
echo "."
echo ""

echo "Checking db connection"
eval "$WP_COMMAND db check"

echo "Shuffling salts in wp-config.php"
eval "$WP_COMMAND config shuffle-salts"
echo "."
echo ""

echo "Reinstalling wp-admin and wp-includes"
WPVER=$(eval "$WP_COMMAND core version")
rm -rf $duserdir/public_html/wp-admin
rm -rf $duserdir/public_html/wp-includes
eval "$WP_COMMAND core download --force --skip-content --version=$WPVER"

echo "Reinstalling active plugins"
WP_ACTIVE_PLUGINS=$(EVAL "$WP_COMMAND plugin list --status=active")
echo "Archiving plugin directory"
tar -cf $duserdir/public_html/wp-content/plugins.bad $duserdir/public_html/wp-content/plugins
eval "$WP_COMMAND plugin delete --all"
mkdir $duserdir/public_html/wp-content/plugins
eval "$WP_COMMAND plugin install $WP_ACTIVE_PLUGINS"


echo "Now please ensure you change this user's password with root privileges"
echo "$> passwd $USER"
echo "."

echo "done"
