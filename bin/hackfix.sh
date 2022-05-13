#!/bin/bash +x

fix_login () {
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
}

fix_db_password () {
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
	echo "."
	echo ""
}

fix_salts () {
	echo "Shuffling salts in wp-config.php"
	eval "$WP_COMMAND config shuffle-salts"
	echo "."
	echo ""
}

reinstall_wpadmin_wpincludes () {
	echo "Reinstalling wp-admin and wp-includes"
	WPVER=$(eval "$WP_COMMAND core version")
	rm -rf $duserdir/public_html/wp-admin
	rm -rf $duserdir/public_html/wp-includes
	eval "$WP_COMMAND core download --force --skip-content --version=$WPVER"
}

set_wp_file_dir_permissions () {
	echo "Setting Wordpress file permissions"
	chmod 600 $duserdir/public_html/wp-config.php
	chmod 644 $duserdir/public_html/.htaccess
	chmod 755 $duserdir/public_html/wp-admin
	chmod 755 $duserdir/public_html/wp-content
	chmod 755 $duserdir/public_html/wp-content/themes
	chmod 755 $duserdir/public_html/wp-content/plugins
	chmod 755 $duserdir/public_html/wp-content/uploads
} 

do_file_removal () {
	echo "Remove suspicious directories in ~/etc"
	find $duserdir/etc -type d \( -iname *anonymousFox* -o -iname *smtpfox* -o -iname *pwcache* \) | xargs rm -rf
	echo "."
	echo ""
	
	echo "Remove suspicious files in ~/mail"
	find $duserdir/mail \( -iname *anonymousFox* -o -iname *smtpfox* -o -iname *pwcache* \) | xargs rm -rf
	echo "."
	echo ""

	echo "Remove bad entries from ~/etc/shadow and ~/etc/<domain>/shadow"
	if [ -f "$duserdir/etc/shadow" ]; then
		mv -f $duserdir/etc/shadow $duserdir/etc/shadow.old
		egrep -iv "fox|anonymous|smtp" $duserdir/etc/shadow.old > $duserdir/etc/shadow
		rm $duserdir/etc/shadow.old
	fi
	echo "."
	echo ""
}

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error

needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

no_tests() { do_fix_login=false;do_fix_db_password=false;do_fix_salts=false;do_reinstall_wpadmin_wpincludes=false;do_set_wp_file_dir_permissions=false;do_file_removal=false; }

all_tests() { do_fix_login=true;do_fix_db_password=true;do_fix_salts=true;do_set_wp_file_dir_permissions=true;do_file_removal=true; }

# Fail if running as root
if [ "$(id -u)" -eq 0 ]; then
	die "Cannot be ran as root"
fi

all_tests

while getopts ldsipfru:-: OPT; do
	# support long options: https://stackoverflow.com/a/28466267/519360
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		l | login )		no_tests;do_fix_login=true ;;
		d | dbpass )		no_tests;do_fix_db_password=true ;;
		s | salts )		no_tests;do_fix_salts=true ;;
		i | adminincludes )	no_tests;do_reinstall_wpadmin_wpincludes=true ;;
		p | plugins )		no_tests;do_reinstall_plugins=true ;;
		f | file )		no_tests;do_set_wp_file_dir_permissions=true ;;
		r | removal )		no_tests;do_file_removal=true ;;
		nologin )		do_fix_login=false ;;
		nodbpass )		do_fix_db_password=false ;;
		nosalts )		do_fix_salts=false ;;
		noadminincludes )	do_reinstall_wpadmin_wpincludes=false ;;
		noplugins )		do_reinstall_plugins=false ;;
		nofile )		do_set_wp_file_dir_permissions=false ;;
		noremoval )		do_file_removal=false ;;
		u | user )      	needs_arg; duser="$OPTARG" ;; # number of minutes to look for modified files
		??* )           	die "Illegal option --$OPT" ;;  # bad long option
		? )             	exit 2 ;;  # bad short option (error reported via getopts)
	esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list


if [[ -z $duser ]]; then
	duser=$USER
	if [ "$DUSER" = "root" ]; then
		die "Cannot be ran as root"
	fi
fi

duserdir=/home/$duser
WP_COMMAND='/usr/local/bin/php /usr/bin/wp --path="$duserdir/public_html"'

echo "*********************************"
echo "* hacksearch"
echo "*********************************"

if $do_fix_login; then
	fix_login
else
	echo "skipping"
fi

if $do_fix_db_password; then
	fix_db_password
else
	echo "skipping"
fi

if $do_fix_salts; then
	fix_salts
else
	echo "skipping"
fi

if $do_reinstall_wpadmin_wpincludes; then
	reinstall_wpadmin_wpincludes
else
	echo "skipping"
fi

if $do_reinstall_plugins; then
	reinstall_plugins
else
	echo "skipping"
fi

if $do_set_wp_file_dir_permissions; then
	set_wp_file_dir_permissions
else
	echo "skipping"
fi

if $do_file_removal; then
	do_file_removal
else
	echo "skipping"
fi

echo "Now please ensure you change this user's password with root privileges"
echo "$> passwd $dUSER"
echo "."
echo "done"
