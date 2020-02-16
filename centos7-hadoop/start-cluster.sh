#!/usr/bin/env bash


if [ "$1"x == "init"x ]; then

   read -p "你确定要重新初始化吗？这将导致以前的初始化数据丢失！（yN）: " answer

   if [ "$answer"x == "y"x ]; then
      echo "开始初始化hadoop集群..."

   else
      echo "开始启动hadoop集群..."
   fi

else
   echo "开始启动hadoop集群..."

fi


echo "启动hdfs"
ssh -q hadoop@hadoop1 "$HADOOP_HOME/sbin/start-dfs.sh"
echo "HDFS started done."

echo "启动Yarn"
ssh -q hadoop@hadoop1 "$HADOOP_HOME/sbin/start-yarn.sh"
echo "YARN started done."

# 启动ResourceManager
rmArray=("hadoop3" "hadoop4")
# shellcheck disable=SC2068
for rnode in ${rmArray[@]}; do
    ssh -q hadoop@$rnode "$HADOOP_HOME/sbin/yarn-daemon.sh start resourcemanager"
    echo "$rnode resourcemanager start done."
done

echo "启动jobhistory"
ssh -q hadoop@hadoop1 "$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver"
echo "jobhistory started done."


echo "启动Hbase"
ssh -q hadoop@hadoop4 "$HBASE_HOME/bin/start-hbase.sh"
echo "Hbase started done."




