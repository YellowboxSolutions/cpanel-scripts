#!/bin/bash

user=${1// }
if [[ -z $user ]]; then
  echo "wrong params"
  echo "hacksearch.sh user"
  exit 0
fi


echo "*********************************"
echo "* Checking $user"
echo "*********************************"

echo "Checking cPanel contact email"
cat /home/$user/.contactemail
echo "."

echo "Listing Wordpress Files"
echo "* www"
ls -la /home/$user/public_html
echo "."

echo "* www/wp-content/plugins"
ls -la /home/$user/public_html/wp-content/plugins
echo "."

echo "* www/wp-content/themes"
ls -la /home/$user/public_html/wp-content/themes
echo "."

echo "Checking for files modified in the last 60 minutes"
find /home/$user/public_html/wp-content -mmin -60 -ls
find /home/$user/public_html/wp-includes -mmin -60 -ls
echo "."

echo "Checking ~/etc"
ls -R /home/$user/etc
echo "."

echo "Printing ~/etc/shadow"
cat /home/$user/etc/shadow
echo "."

echo "Checking for suspicious named files"
find /home/$user \( -iname *anonymousFox* -o -iname *smtpfox* -o -iname *lock360* \) -ls
echo "."

echo "Checking for suspicious processes"
ps -aux|grep [l]ock360
echo "."

echo "Showing cronjobs"
crontab -u $user -l
echo "."

echo "Checking wordpress users"
sudo -u $user -- /usr/local/bin/php /usr/bin/wp --path=/home/$user/public_html user list 2>/dev/null
echo "."

echo "Checking wordpress checksums"
echo "* core"
sudo -u $user -- /usr/local/bin/php /usr/bin/wp --path=/home/$user/public_html core verify-checksums 2>/dev/null
echo "* plugins"
sudo -u $user -- /usr/local/bin/php /usr/bin/wp --path=/home/$user/public_html plugin verify-checksums --all 2>/dev/null
echo "."
