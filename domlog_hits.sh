# Show the quantity of logs for each domlog file
#
# user@host #> sudo domlog_hits.sh
#
# 1129 example1.com
# 1123 example2.com
# 123 example3.com

for i in `find /etc/apache2/logs/domlogs -maxdepth 1 -type f|egrep -v 'offset|_log$|proxy'`
do
        awk '{print $4}' $i|
        cut -d: -f1|
	cut -d[ -f2|
        uniq -c|
        sort -n|
        awk '{print $1, $2 " '`echo $i|cut -d/ -f6`'"}'
done|sort -nr
