#!/usr/bin/env bash

echo "容器启动成功！"

sudo /usr/sbin/sshd -D &
echo "SSHD服务启动成功!"

sleep 1


myfolder="/home/hadoop/data/zookeeper/data"
if [ ! -d "$myfolder" ]; then
  echo "创建文件目录：$myfolder"
  mkdir -p "$myfolder"
fi

sleep 1s

# 为zookeeper集群安装指定当前服务器序号，创建纯文本文件，文件名为：myid，文件内容为：环境变量$ZK_SERVER_ID的值
myidFile="/home/hadoop/data/zookeeper/data/myid"
if [ ! -f "$myidFile" ]; then
  # 如果文件不存在，则创建
  echo "创建纯文本文件：$myidFile"
  touch "$myidFile"
  echo $ZK_SERVER_ID >> /home/hadoop/data/zookeeper/data/myid
fi


echo "正在启动Zookeeper..."
/usr/local/zookeeper/bin/zkServer.sh start
echo "Zookeeper启动成功."



echo "完成一次与其它服务器的ssh访问"
./ssh-login.sh


/bin/bash
