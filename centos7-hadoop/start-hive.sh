#!/usr/bin/env bash

if [ "$1"x == "init"x ]; then
  echo "--------------- 在HDFS创建Hive数据存储目录 -----------------"

  echo "hadoop fs -mkdir /hive"
  $HADOOP_HOME/bin/hadoop fs -mkdir /hive
  echo "hadoop fs -mkdir /hive/warehouse"
  $HADOOP_HOME/bin/hadoop fs -mkdir /hive/warehouse
  echo "hadoop fs -mkdir /hive/tmp"
  $HADOOP_HOME/bin/hadoop fs -mkdir /hive/tmp
  echo "hadoop fs -mkdir /hive/logs"
  $HADOOP_HOME/bin/hadoop fs -mkdir /hive/logs
  echo "给目录赋读写权限..."
  $HADOOP_HOME/bin/hadoop fs -chmod -R 777 /hive/warehouse
  $HADOOP_HOME/bin/hadoop fs -chmod -R 777 /hive/tmp
  $HADOOP_HOME/bin/hadoop fs -chmod -R 777 /hive/logs

  echo ""

  echo "--------------- 初始化Hive元数据库 -----------------"
  $HIVE_HOME/bin/schematool -dbType mysql -initSchema
  echo ""

fi


echo "--------------- 启动Hive metastore元数据服务 -----------------"
echo "hadoop3节点启动metastore..."
ssh -q hadoop@hadoop3 "nohup $HIVE_HOME/bin/hive --service metastore >/dev/null 2>&1 &"
echo ""

echo "hadoop4节点启动metastore..."
ssh -q hadoop@hadoop4 "nohup $HIVE_HOME/bin/hive --service metastore >/dev/null 2>&1 &"
echo ""


#echo "--------------- 启动Hive hiveserver2服务 -----------------"
#echo "hadoop3节点启动hiveserver2..."
#ssh -q hadoop@hadoop3 "nohup $HIVE_HOME/bin/hive --service hiveserver2 >/dev/null 2>&1 &"
#echo ""

#echo "hadoop4节点启动hiveserver2..."
#ssh -q hadoop@hadoop4 "nohup $HIVE_HOME/bin/hive --service hiveserver2 >/dev/null 2>&1 &"
#echo ""

echo "--------------- 启动Hive服务启动完成 -----------------"

