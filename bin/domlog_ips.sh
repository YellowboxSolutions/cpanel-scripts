# Show the quantity of logs for each ip address in the 
# domlog file unique by date and IP.
#
# user@host #> sudo domlog_ips.sh
#
# 1129 12/APR/2020 example1.com
# 1066 13/APR/2020 example1.com
# 198 12/APR/2020 example2.com

do_filter () {
        awk '{print $1, $4}' $1|
        cut -d: -f1|
	awk '{print $2, $1}'|
	cut -d[ -f2 |
	sort|
        uniq -c|
        sort -n|
        awk '{print $1, $2, $3 " '`echo $1|cut -d/ -f6`'"}'
}

file=${1// }
if [[ -z $file ]]
then
	for i in `find /etc/apache2/logs/domlogs -maxdepth 1 -type f|egrep -v 'offset|_log$|proxy'`
	do
		do_filter $i
	done|sort -nr
else
	do_filter $file|sort -nr

fi


