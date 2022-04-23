#!/bin/bash

user=${1// }
if [[ -z $user ]]
then
	user=$(stat . -c %U)
	trust=false
else
	trust=true
fi

echo "*********************************"
echo "* hackfix $user"
echo "*********************************"

userdir=/home/$user

echo "Remove directories in ~/etc"
find $userdir/etc -type d \( -iname *anonymousFox* -o -iname *smtpfox* -o -iname *pwcache* \) -exec rm -rf {} \;

echo "Remove files in ~/mail"
find $userdir/mail \( -iname *anonymousFox* -o -iname *smtpfox* -o -iname *pwcache* \) -exec rm -rf {} \;

echo "Remove bad entries from ~/etc/shadow"
if [ -f "$userdir/etc/shadow" ]; then
	mv -f $userdir/etc/shadow $userdir/etc/shadow.old
	grep -v $userdir/etc/shadow.old > $userdir/etc/shadow
	rm $userdir/etc/shadow.old
fi


