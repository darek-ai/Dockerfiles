#!/usr/bin/env bash


if [ "$1"x == "init"x ]; then

   read -p "你确定要重新初始化吗？这将导致以前的初始化数据丢失！（yN）: " answer
   echo ""

   if [ "$answer"x == "y"x ]; then
      echo "---------------开始初始化hadoop集群---------------"
      echo ""

      echo "---------------启动journalnode-----------------"
      jnodes=("hadoop1" "hadoop2" "hadoop3")
      # shellcheck disable=SC2068
      for jnode in ${jnodes[@]}; do
          ssh -q hadoop@$jnode "$HADOOP_HOME/sbin/hadoop-daemon.sh start journalnode"
          echo "$jnode journalnode started done."
      done

      echo "---------------格式化hdfs-----------------"
      ssh -q hadoop@hadoop1 "$HADOOP_HOME/bin/hadoop namenode -format"
      echo ""

      sleep 3

      echo "---------------启动namenode-----------------"
      ssh -q hadoop@hadoop1 "$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode"
      echo ""

      sleep 3

      echo "---------------同步namenode元数据---------------"
      ssh -q hadoop@hadoop2 "$HADOOP_HOME/bin/hadoop namenode -bootstrapStandby"
      echo ""

      sleep 3

      echo "---------------初始化ZKFC-----------------"
      ssh -q hadoop@hadoop1 "$HADOOP_HOME/bin/hdfs zkfc -formatZK"
      echo ""

   fi
fi

echo "---------------开始启动hadoop集群-----------------"
echo ""

echo "---------------启动hdfs-----------------"
ssh -q hadoop@hadoop1 "$HADOOP_HOME/sbin/start-dfs.sh"
echo "HDFS started done."
echo ""

echo "---------------启动Yarn-----------------"
ssh -q hadoop@hadoop1 "$HADOOP_HOME/sbin/start-yarn.sh"
echo "YARN started done."
echo ""

# 启动ResourceManager
rmArray=("hadoop3" "hadoop4")
# shellcheck disable=SC2068
for rnode in ${rmArray[@]}; do
    ssh -q hadoop@$rnode "$HADOOP_HOME/sbin/yarn-daemon.sh start resourcemanager"
    echo "$rnode resourcemanager started done."
done
echo ""

echo "---------------启动jobhistory----------"
ssh -q hadoop@hadoop1 "$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver"
echo "jobhistory started done."
echo ""

echo "---------------启动Hbase---------------"
ssh -q hadoop@hadoop4 "$HBASE_HOME/bin/start-hbase.sh"
echo "Hbase started done."
echo ""

echo "----------------------集群启动成功----------------------"


