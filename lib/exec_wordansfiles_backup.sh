#!/bin/sh
# Production
PATH_ENV="/www/izishirt"

cd $PATH_ENV

/usr/bin/expect /www/izishirt/lib/rsync.expect
# echo "executing..."
sleep 86400

/bin/sh $PATH_ENV/lib/exec_izishirtfiles_backup.sh &
