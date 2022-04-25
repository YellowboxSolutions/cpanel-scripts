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

	echo "Printing ~/etc/shadow"
	cat /home/$duser/etc/shadow
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
	crontab -u $duser -l
	echo "."
	echo ""
} 2>&1

do_wpval () {

	echo "Checking wordpress user"
	sudo -u $duser -- /usr/local/bin/php /usr/bin/wp --path=/home/$duser/public_html user list
	echo "."
	echo ""

	echo "Checking wordpress checksums"
	echo "* core"
	sudo -u $duser -- /usr/local/bin/php /usr/bin/wp --path=/home/$duser/public_html core verify-checksums 
	echo "* plugins"
	sudo -u $duser -- /usr/local/bin/php /usr/bin/wp --path=/home/$duser/public_html plugin verify-checksums --all 
	echo "."
	echo ""
} 2>&1

do_files () {
	echo "Getting access-logs"
	mkdir -p $PWD/access-logs >/dev/null 2>&1
	sudo cp /home/$duser/logs/*.gz $PWD/access-logs 
	sudo cp /home/$duser/access-logs/* $PWD/access-logs
	sudo chmod -R +r $PWD
	echo "."
	echo ""
} 2>&1

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

while getopts c:u:-: OPT; do
	# support long options: https://stackoverflow.com/a/28466267/519360
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		a | alpha )    alpha=true ;;
		m | min )      mmin="$OPTARG" ;; # number of minutes to look for modified files
		u | user )    needs_arg; duser="$OPTARG" ;; # number of minutes to look for modified files
		??* )          die "Illegal option --$OPT" ;;  # bad long option
		? )            exit 2 ;;  # bad short option (error reported via getopts)
	esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

if [[ -z $duser ]]; then
	die "--user is required"
fi

if [[ -z $mmin ]]; then
	mmin="-60"
fi

echo "*********************************"
echo "* Checking $duser"
echo "*********************************"

echo "  * Doing checks"
echo "*********************************"
do_checks

echo "  * Doing wp validations"
echo "*********************************"
do_wpval

echo "  * Doing log copy"
echo "*********************************"
do_files

