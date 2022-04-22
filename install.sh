#!/bin/bash

for fl in domlog_hits.sh domlog_ips.sh hacksearch.sh hackfix.sh ip_count.sh 
do
	filepath=/usr/local/bin/$fl
	echo "Installing $fl"
	if [ -f $filepath ]
	then
		echo "Removing old $filepath"
		rm $filepath
	fi

	cp ./bin/$fl $filepath
	chmod 755 $filepath
done
