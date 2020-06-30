#!/bin/bash

USER=$1
PASSWORD=$2
HOST=${3:-localhost}
LAG_WARNING=${4:-5}
LAG_ERROR=${5:-10}


MY_STATUS=$(/usr/bin/mysqlsh $USER:$PASSWORD@$HOST --sql -E -e "select channel_name, IO_thread, SQL_thread, concat(sum(lag_in_sec),' sec') 'tot_lag' from sys.replication_status_min group by channel_name, IO_thread, SQL_thread" 2>/dev//null)

if [[ $(echo "$MY_STATUS" | grep '_thread: ON' | wc -l) == 2 ]]
then
	#"Both threads are running"
	if [[ $(echo "$MY_STATUS" | grep 'lag:') ]]
	then
		lag=$(echo "$MY_STATUS" | grep 'lag: ' | cut -d':' -f2 | awk '{ print $1 }')
        if [[ $lag -eq 3020399 ]]
        then
            echo "OK: replication lag reached max, let's wait next check"
            exit 0
	    elif [[ $lag -ge $LAG_ERROR ]]
		then 
		   echo "ERROR: replication lag is $lag seconds"
		   exit 2
	    elif [[ $lag -ge LAG_WARNING ]]
		then 		
		   echo "WARNING: replication lag is $lag seconds"
		   exit 1
	    else
		   echo "OK: replication lag is only $lag seconds"
		   exit 0
		fi
	fi
fi
echo "Error thread running error:"
echo "$MY_STATUS" | grep '_thread: '
exit 2

