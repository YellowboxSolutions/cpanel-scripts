#!/bin/bash

user=${1// }
if [[ -z $user ]]; then
  echo "wrong params"
  echo "hacksearch.sh user"
  exit 0
fi


echo "*********************************"
echo "* hackfix $user"
echo "*********************************"

userdir=/home/$user

echo "Remove directories in ~/etc"
sudo -u $user -- find $userdir/etc -type d \( -iname *anonymousFox* -o -iname *smtpfox* -o -iname *pwcache* \) -exec rm -rf {} \;

echo "Remove files in ~/mail"
sudo -u $user -- find $userdir/mail \( -iname *anonymousFox* -o -iname *smtpfox* -o -iname *pwcache* \) -exec rm -rf {} \;

echo "Remove bad entries from ~/etc/shadow"
if [ -f "$userdir/etc/shadow" ]; then
	sudo -u $user -- mv -f $userdir/etc/shadow $userdir/etc/shadow.old
	#sudo -u $user -- grep -v $userdir/etc/shadow.old > $userdir/etc/shadow
	#sudo -u $user -- rm $userdir/etc/shadow.old
fi


