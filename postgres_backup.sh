#!/bin/bash

#### Settings ####

DBNAME="meshi"
DBUSER="postgres"
BACKUPDIR="./backup"
DATE=`date "+%Y%m%d"`
LOGDIR="./log"

BACKUP_PERIOD="+7"

#### Function ####

function logging () {
	status=$1
	message=$2
	echo "`date "+%Y/%m/%d %H-%M-%S"` [${status}] ${message} "| tee -a ${LOGDIR}/`basename $0 .sh`_`date "+%Y%m%d"`.log
}

#### Main ####
cd `dirname $0`

logging " INFO" "Backup Process start"

logging " INFO" "pg_dump start"

pg_dump -U ${DBUSER} -Fp ${DBNAME} > ${BACKUPDIR}/${DBNAME}_${DATE}.sql
if [ $? -ne 0 ];then
	logging "ERROR" "pg_dump failed"
	logging "ERROR" "backup stopped"
	exit
fi

logging " INFO" "pg_dump finished"

logging " INFO" "gzip start"


if [ ! -f "${BACKUPDIR}/${DBNAME}_${DATE}.sql.gz" ]; then
	gzip ${BACKUPDIR}/${DBNAME}_${DATE}.sql | tee -a ${LOGDIR}/`basename $0 .sh`_`date "+%Y%m%d"`.log
	if [ $? -ne 0 ];then
		logging "ERROR" "gzip failed"
	fi
else
	logging " WARN" "gzip skipped"
fi
logging " INFO" "gzip finished"

logging " INFO" "dropbox upload start"
/opt/scripts/dropbox_uploader/dropbox_uploader.sh upload ${BACKUPDIR}/${DBNAME}_${DATE}.sql.gz `uname -n`/postgres_backup/ | tee -a ${LOGDIR}/`basename $0 .sh`_`date "+%Y%m%d"`.log
if [ $? -ne 0 ];then
	logging "ERROR" "dropbox upload failed"
	exit
fi
logging " INFO" "dropbox upload finished"

logging " INFO" "delete old backup start"
find ${BACKUPDIR} -type f -daystart -mtime ${BACKUP_PERIOD} -exec rm {} \; | tee -a ${LOGDIR}/`basename $0 .sh`_`date "+%Y%m%d"`.log
if [ $? -ne 0 ];then
	logging "ERROR" "delete old backup failed"
fi

logging " INFO" "delete old backup finished"
logging " INFO" "All Backup Process finished"
