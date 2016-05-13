# xtrabackup-restore-table

Basic instructions:
- install docker
- copy your backup's /etc/my.cnf to (script path)/restore.cnf so it knows how to bring it up inside the docker image
- ./restore_table.sh /my_xtrabackup_path/  table1 table2 table_glob1* etc
- the script will automatically connect you to the console
- if you want to dump or otherwise manipulate the data, simply leave the console open, and connect on another terminal on 127.0.0.1 port 3307
