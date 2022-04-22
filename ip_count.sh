# print ip addresses along with the number of connections shown by
# netstat
#
# user@host #>./ip_count.sh
# 1 207.171.238.242
# 1 68.235.48.75
# 2 76.105.102.172
# 2 99.194.140.239

netstat -ntu |grep ESTABLISHED| awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -n
