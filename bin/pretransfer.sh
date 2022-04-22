source=${1// }
if [[ -z $source ]]; then
  echo "wrong params"
  echo "pretransfer.sh color domain.com"
  exit 0
fi

domain=${2// }
if [[ -z $domain ]]; then
  echo "wrong params"
  echo "pretransfer.sh color domain.com"
  exit 0
fi

echo "*********************************"
echo "* Checking $domain A record"
echo "*********************************"
dig +short $domain soa
rec="$(dig +short $domain)"
rev="$(dig +short -x "$rec")"
echo "Record: $rec"
echo "Reverse: $rev"

echo ""

echo "*********************************"
echo "* Checking $domain NS record"
echo "*********************************"
dig +short $domain ns
echo ""

echo "*********************************"
echo "* Checking $domain MX record"
echo "*********************************"
mx_response="$(dig +short $domain mx)"
IFS=$'\n'
for mx_line in $mx_response
do
  mx_priority=${mx_line% *}
  mx_name=${mx_line#* }
  mx_a="$(dig +short $mx_name)"
  echo "$mx_priority $mx_name $mx_a"
done
echo ""

echo "*********************************"
echo "* Checking for domain in cpanel on source server $source.ybshosting.com"
echo "*********************************"
domainuser="$(ssh -t -i ~/.ssh/aws centos@$source.ybshosting.com -p 1969 sudo grep "$domain" /etc/domainusers 2> /dev/null)"
duser=${domainuser%:*}
ddomain=${domainuser#* }
echo "user: $duser"
echo "domain: $ddomain"
echo ""
echo "Printing zone file"
ssh -t -i ~/.ssh/aws centos@$source.ybshosting.com -p 1969 sudo cat /var/named/$domain.db 2> /dev/null
echo ""

echo "*********************************"
echo "* Checking for user details source server $source.ybshosting.com"
echo "*********************************"
ssh -t -i ~/.ssh/aws centos@$source.ybshosting.com -p 1969 sudo cat /var/cpanel/users/$duser 2> /dev/null
echo ""

echo "*********************************"
echo "* Checking for accounting logs on source server $source.ybshosting.com"
echo "*********************************"
ssh -t -i ~/.ssh/aws centos@$source.ybshosting.com -p 1969 sudo grep "$domain" /var/cpanel/accounting.log 2> /dev/null
echo ""

echo "*********************************"
echo "* Checking for 5 most recent domlogs on source server $source.ybshosting.com"
echo "*********************************"
ssh -t -i ~/.ssh/aws centos@$source.ybshosting.com -p 1969 sudo grep "$domain" /var/log/apache2/domlogs/$domain 2> /dev/null|tail -5
echo ""

echo "*********************************"
echo "* Listing domain info on source server $source.ybshosting.com"
echo "*********************************"
ssh -t -i ~/.ssh/aws centos@$source.ybshosting.com -p 1969 sudo uapi --user=$duser DomainInfo domains_data 2> /dev/null
echo ""

echo "*********************************"
echo "* Checking for mail accounts on source server $source.ybshosting.com"
echo "*********************************"
ssh -t -i ~/.ssh/aws centos@$source.ybshosting.com -p 1969 sudo uapi --user=$duser Email list_pops  2> /dev/null
echo ""

echo "*********************************"
echo "* Checking for account level mail forwards on source server $source.ybshosting.com"
echo "*********************************"
ssh -t -i ~/.ssh/aws centos@$source.ybshosting.com -p 1969 sudo uapi --user=$duser Email list_forwarders  2> /dev/null
echo ""

echo "*********************************"
echo "* Checking for domain level mail forwards on source server $source.ybshosting.com"
echo "*********************************"
ssh -t -i ~/.ssh/aws centos@$source.ybshosting.com -p 1969 sudo uapi --user=$duser Email list_domain_forwarders  2> /dev/null
echo ""

echo "*********************************"
echo "* Checking for 5 most recent maillogs on source server $source.ybshosting.com"
echo "*********************************"
ssh -t -i ~/.ssh/aws centos@$source.ybshosting.com -p 1969 sudo grep "$domain" /var/log/maillog 2> /dev/null|tail -5 
echo ""
