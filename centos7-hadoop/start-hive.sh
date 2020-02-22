#!/usr/bin/env bash

if [ "$1"x == "init"x ]; then
  echo "--------------- 在HDFS创建Hive数据存储目录 -----------------"

  $HADOOP_HOME/bin/hadoop fs -mkdir /hive/warehouse
  $HADOOP_HOME/bin/hadoop fs -mkdir /hive/tmp
  $HADOOP_HOME/bin/hadoop fs -mkdir /hive/logs
  $HADOOP_HOME/bin/hadoop fs -chmod -R 777 /hive/warehouse
  $HADOOP_HOME/bin/hadoop fs -chmod -R 777 /hive/tmp
  $HADOOP_HOME/bin/hadoop fs -chmod -R 777 /hive/logs

  echo ""

  sleep 3

  echo "--------------- 初始化Hive元数据库 -----------------"
  $HIVE_HOME/bin/schematool -dbType mysql -initSchema
  echo ""

fi


echo "--------------- 启动Hive metestore元数据服务 -----------------"

ssh -q hadoop@hadoop1 "$HIVE_HOME/bin/hive --service metastore &"
ssh -q hadoop@hadoop2 "$HIVE_HOME/bin/hive --service metastore &"
echo ""


#echo "--------------- 启动Hive hiveserver2服务 -----------------"
#ssh -q hadoop@hadoop1 "$HIVE_HOME/bin/hive --service hiveserver2 &"
#ssh -q hadoop@hadoop2 "$HIVE_HOME/bin/hive --service hiveserver2 &"
#echo ""

echo "--------------- 启动Hive服务启动完成 -----------------"

