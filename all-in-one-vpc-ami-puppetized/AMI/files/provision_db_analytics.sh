#!/bin/bash
table=$1;
DB=$2;
# exists=$(mysql -N -s -h CF_DB_HOST -P CF_DB_PORT WSO2AM_DB -u CF_DB_USERNAME -pCF_DB_PASSWORD -e "select count(*) from information_schema.tables where table_schema='WSO2AM_DB' and table_name='UM_USER';")
# if [ "$exists" != "1" ]; then
    echo "Running DB scripts..."
    mysql -u CF_DB_USERNAME -pCF_DB_PASSWORD -h CF_DB_HOST -P CF_DB_PORT WSO2AM_DB < /mnt/wso2am-analytics-2.1.0/dbscripts/mysql.sql
    mysql -u CF_DB_USERNAME -pCF_DB_PASSWORD -h CF_DB_HOST -P CF_DB_PORT WSO2AM_DB < /mnt/wso2am-analytics-2.1.0/dbscripts/identity/mysql.sql
    mysql -u CF_DB_USERNAME -pCF_DB_PASSWORD -h CF_DB_HOST -P CF_DB_PORT WSO2AM_DB < /mnt/wso2am-analytics-2.1.0/dbscripts/metrics/mysql.sql
# fi
