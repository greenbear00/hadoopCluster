#!/bin/bash

cd $HIVE_HOME/bin
pwd
ls -l
echo "input is ...$1"

if [ "$1" == "metastore" ]
then
  # schematool -dbType postgres -initSchema --verbose &&
  # schematool -initSchema -dbType postgres --verbose &&
  echo "run hive-metastore"
  schematool -initSchema -dbType mysql --verbose &&
  hive --service metastore
else
  echo "run hiveserver2"
  hadoop fs -mkdir -p    /tmp
  hadoop fs -mkdir -p    /warehouse/tablespace/managed/hive
  hadoop fs -mkdir -p    /warehouse/tablespace/external/hive
  hadoop fs -chmod g+w   /tmp
  hadoop fs -chmod g+w  /warehouse/tablespace/managed/hive
  hadoop fs -chmod g+w  /warehouse/tablespace/external/hive

  # Add user
  groupadd hadoop
  useradd -g hadoop hadoop
  hadoop fs -mkdir -p /user/hadoop/
  hadoop fs -chown -R hadoop:hadoop /user/hadoop
  hdfs dfsadmin -refreshUserToGroupsMappings

  if [ "$DUMMY_DATA" = "1" ]; then
    DATE_FORMAT='+%Y%m%d'
    HOUR_FORMAT='+%Y%m%d%H'
    MONTH_FORMAT='+%Y%m'
    d1_dt=$(date -d "yesterday 00:00" $DATE_FORMAT)
    d6_dt=$(date -d "6 days ago" $DATE_FORMAT)
    d7_dt=$(date -d "7 days ago" $DATE_FORMAT)
    d8_dt=$(date -d "8 days ago" $DATE_FORMAT)
    h100_dt=$(date -d "100 hours ago" $HOUR_FORMAT)
    h200_dt=$(date -d "200 hours ago" $HOUR_FORMAT)
    h250_dt=$(date -d "250 hours ago" $HOUR_FORMAT)
    m1_dt=$(date -d "1 months ago" $MONTH_FORMAT)
    m2_dt=$(date -d "2 months ago" $MONTH_FORMAT)
    echo "inject ${d1_dt}"
    hive -hiveconf d1_dt="$d1_dt" \
          -hiveconf d6_dt="$d6_dt" \
          -hiveconf d7_dt="$d7_dt" \
          -hiveconf d8_dt="$d8_dt" \
          -hiveconf h100_dt="$h100_dt" \
          -hiveconf h200_dt="$h200_dt" \
          -hiveconf h250_dt="$h250_dt" \
          -hiveconf m1_dt="$m1_dt" \
          -hiveconf m2_dt="$m2_dt" \
          -f /opt/dummy_data/tmp.hql
    echo "done tmp.hql"

    hadoop fs -mkdir -p /tmp/emp
    hadoop fs -put /opt/dummy_data/test.csv /tmp/emp/test.csv
    hadoop fs -chmod 777 /tmp/emp/test.csv

    hive -f /opt/dummy_data/order.hql
    echo "done order.hql"
  fi

  echo "execute the default, which is hiveserver2"
  hiveserver2  --hiveconf hive.server2.enable.doAs=true --hiveconf hive.root.logger=DEBUG,console
fi