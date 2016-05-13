#!/bin/bash

SCRIPT_PATH="`dirname \"$0\"`"
SCRIPT_PATH="`( cd \"${SCRIPT_PATH}\" && pwd )`"

BACKUP_PATH="${1}"
shift

if [ -d "${BACKUP_PATH}" ]; then
    echo "Found backup path ${BACKUP_PATH}"
else
    echo "Usage: ${0} backup_location db_name/table_glob1 db_name/table_glob2 ..."
fi

RESTORE_PATH=`mktemp -d`
echo "Restoring to ${RESTORE_PATH}"

cd ${BACKUP_PATH}

# intentionally non-recursive
echo "Installing database backup dependencies"
cp * ${RESTORE_PATH}/ > /dev/null 2>&1
cp -r mysql performance_schema ${RESTORE_PATH}/

for i in "${@}"; do
    echo "Scanning ${BACKUP_PATH}/${i}"
    if [ `compgen -G ./${i}.*` ]; then
        echo "Found: ${BACKUP_PATH}/${i}"
        cp -r --parents ./${i}.* ${RESTORE_PATH}
    fi
done

echo "Preparing restoration database"
innobackupex --use-memory=128M --apply-log --export ${RESTORE_PATH} > /dev/null 2>&1

echo "Staring mysql restoration container..."

echo "docker run -d -p 3307:3306 -v ${SCRIPT_PATH}/restore.cnf:/etc/my.cnf -v ${RESTORE_PATH}:/var/lib/mysql docker.io/percona:5.6"
CONTAINER=`docker run -d -p 3307:3306 -v ${SCRIPT_PATH}/restore.cnf:/etc/my.cnf -v ${RESTORE_PATH}:/var/lib/mysql docker.io/percona:5.6`

MYSQL_ERR=1
ATTEMPT=0
while [ ${MYSQL_ERR} != 0 ]; do
    let ATTEMPT++
    echo "Waiting for mysql to start (attempt ${ATTEMPT}) ..."
    sleep 3
    mysql -uvision6 -pm1mratin -h 127.0.0.1 --port 3307
    MYSQL_ERR=$?
done

echo "Stopping mysql restoration container..."
docker stop $CONTAINER
rm -rf ${RESTORE_PATH}


