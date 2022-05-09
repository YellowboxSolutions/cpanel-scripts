#!/bin/bash

do_checks () {
	echo "Checking cPanel contact email"
	cat /home/$duser/.contactemail
	echo "."
	echo ""

	echo "Listing Wordpress Files"
	echo "* www"
	ls -la /home/$duser/public_html
	echo "."
	echo ""

	echo "* www/wp-content/plugins"
	ls -la /home/$duser/public_html/wp-content/plugins
	echo "."
	echo ""

	echo "* www/wp-content/themes"
	ls -la /home/$duser/public_html/wp-content/themes
	echo "."
	echo ""

	echo "Checking for files modified in the last $mmin  minutes"
	find /home/$duser/public_html/wp-content -mmin $mmin -ls
	find /home/$duser/public_html/wp-includes -mmin $mmin -ls
	echo "."
	echo ""

	echo "Checking ~/etc"
	ls -R /home/$duser/etc
	echo "."
	echo ""

	echo "Printing ~/etc shadow files recursively"
	find /home/$duser/etc -name shadow -type f |xargs cat
	echo "."
	echo ""

	echo "Checking for suspicious named files"
	find /home/$duser \( -iname *anonymousFox* -o -iname *smtpfox* -o -iname *lock360* \) -ls
	echo "."
	echo ""

	echo "Checking for suspicious processes"
	ps -aux|grep [l]ock360
	echo "."
	echo ""

	echo "Showing cronjobs"
	crontab -l
	echo "."
	echo ""
} 2>&1

do_wpval () {
	echo "Checking wordpress user"
	eval "$WP_COMMAND user list"
	echo "."
	echo "Listing wordpress themes"
	eval "$WP_COMMAND theme list"
	echo "."
	echo ""

	echo "Checking wordpress checksums"
	echo "* core"
	eval "$WP_COMMAND core verify-checksums"
	echo "* plugins"
	eval "$WP_COMMAND plugin verify-checksums --all"
	echo "."
	echo ""

} 2>&1

do_files () {
	echo "Getting access-logs"
	mkdir -p $PWD/access-log-copies >/dev/null 2>&1
	cp /home/$duser/logs/*.gz $PWD/access-log-copies/
	cp /home/$duser/access-logs/* $PWD/access-log-copies/
	echo "."
	echo ""
} 2>&1

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }
no_tests() { checks=false;files=false;wpval=false; }
all_tests() { checks=true;files=true;wpval=true; }

# Fail if running as root
if [ "$(id -u)" -eq 0 ]; then
	die "Cannot be ran as root"
fi
all_tests


while getopts cfwm:u:-: OPT; do
	# support long options: https://stackoverflow.com/a/28466267/519360
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		c | checks )    no_tests;checks=true ;;
		f | files )     no_tests;files=true ;;
		nochecks )      checks=false ;;
		nofiles )       files=false ;;
		nowpval )       wpval=false ;;
		w | wpval )     no_tests;wpval=true ;;
		m | mmin )      needs_arg; mmin="$OPTARG" ;; # number of minutes to look for modified files
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


if [[ -z $mmin ]]; then
	mmin="-60"
fi

WP_COMMAND='/usr/local/bin/php /usr/bin/wp --path="/home/$duser/public_html"'

echo "*********************************"
echo "* Checking $duser"
echo "*********************************"

echo "  * Doing checks"
echo "*********************************"
if $checks; then
	do_checks
else
	echo "skipping"
fi

echo "  * Doing wp validations"
echo "*********************************"
if $wpval; then

	do_wpval
else
	echo "skipping"
fi

echo "  * Doing log copy"
echo "*********************************"
if $files; then
	do_files
else
	echo "skipping"
fi

