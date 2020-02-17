# Centos+Hadoop+Hbase+Zookeeper HA集群部署

## 服务器列表

IP地址 | 机器名 | 操作系统
:---------: | :---------: | :-------:
192.18.0.2 | hadoop1  | centos7
192.18.0.3 | hadoop2  | centos7
192.18.0.4 | hadoop3  | centos7
192.18.0.5 | hadoop4  | centos7

## 组件版本
| 名称          |  版本号   | 下载地址
|-------------- |--------- |---------
| JDK           | 1.8      | [国内镜像](https://repo.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz)
| Zookeeper     | 3.5.6    | [官网下载](http://mirror.bit.edu.cn/apache/zookeeper/zookeeper-3.5.6/apache-zookeeper-3.5.6-bin.tar.gz)
| Hadoop        | 2.7.7    | [国内镜像](https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz)
| Hbase         | 1.4.12   | [国内镜像](https://mirrors.tuna.tsinghua.edu.cn/apache/hbase/hbase-1.4.12/hbase-1.4.12-bin.tar.gz)


## 集群规划
|  &nbsp;     | hadoop1    | hadoop2   | hadoop3  | hadoop4 |  &nbsp;
| ----------- | :-------:  | :-------: | :-------:| :-------: |---------
QuorumPeerMain   | &spades;   | &spades;  | &spades; | &nbsp; | Zookeeper节点
JournalNode    | &spades; | &spades;| &spades; | &nbsp; | 共享存储服务，用于namenode元数据日志同步
NameNode    | &spades;   | &spades;  | &nbsp;   | &nbsp; | HDFS主节点，元数据
DataNode    | &spades;   | &spades;  | &spades; | &spades; | HDFS从节点，数据存储
DFSZKFailoverController| &spades;  | &spades; | &nbsp;   | &nbsp; | 通过Zookeeper实现namenode故障切换
ResourceManager| &nbsp;   | &nbsp;  | &spades;  | &spades; | Yarn主节点，MapReduce资源协调
NodeManager    | &spades; | &spades;| &spades; | &spades; | Yarn从节点，MapReduce处理计算任务
JobHistoryServer| &spades;  | &nbsp; | &nbsp;   | &nbsp; | MapReduce历史任务服务器
HMaster       | &nbsp;   | &nbsp;  | &spades;   | &spades; | Hbase 主节点
RegionServer  | &spades;  | &spades; | &spades; | &spades; | Hbase 从节点



## 安装配置Zookeeper
### 配置conf/zoo.cfg
``` 
tickTime=2000

initLimit=10

syncLimit=5

# 数据存储目录
dataDir=/home/hadoop/data/zookeeper

clientPort=2181

# 集群
server.1=hadoop1:2888:3888
server.2=hadoop2:2888:3888
server.3=hadoop3:2888:3888

```
格式说明：<br>
server.{id}={host/ip}:{port1}:{port1} <br>
**id**: 需要集群机器{dataDir}定义的数据存储目录，放一个名字叫：myid的文件，文件内容为对应的id。
* 在hadoop1机器/home/hadoop/data/zookeeper目录下，放一个myid文件，文件内容为：1
* 在hadoop2机器/home/hadoop/data/zookeeper目录下，放一个myid文件，文件内容为：2
* 以此类推
**host/ip**: 服务器ip或ip映射的主机名
**port1**: Leader和Follower或Observer交换数据使用 <br>
**port2**: 用于Leader选举<br>

## 启动Zookeeper
需进入到集群的每个节点，分别进行启动操作
```shell
# 启动
[hadoop@465b84797d44 bin]$ ./zkServer.sh start
ZooKeeper JMX enabled by default
Using config: /usr/local/apache-zookeeper-3.5.6-bin/bin/../conf/zoo.cfg
Starting zookeeper ... STARTED

# 验证
[hadoop@465b84797d44 bin]$ jps
15057 Jps
14935 QuorumPeerMain


# 查看状态
[hadoop@6841f424bbd8 apache-zookeeper-3.5.6-bin]$ bin/zkServer.sh status
ZooKeeper JMX enabled by default
Using config: /usr/local/apache-zookeeper-3.5.6-bin/bin/../conf/zoo.cfg
Client port found: 2181. Client address: localhost.
Mode: leader

```

QuorumPeerMain为zookeeper进程

Mode: leader 代表当前节点为领导者


## 启动hadoop
### 1.启动JournalNode共享存储进程
在规划的节点分别启动journalnode进程
```
[hadoop@465b84797d44 sbin]$ ./hadoop-daemon.sh start journalnode
starting journalnode, logging to /usr/local/hadoop-2.7.7/logs/hadoop-hadoop-journalnode-465b84797d44.out

# 看到JournalNode进程表示启动成功
[hadoop@465b84797d44 sbin]$ jps
14935 QuorumPeerMain
29867 Jps
29628 JournalNode
```

### 2.格式化NameNode
在Active NameNode节点(hadoop1)执行格式化：hadoop namenode -format
```
[hadoop@465b84797d44 ~]$ hadoop namenode -format
DEPRECATED: Use of this script to execute hdfs command is deprecated.
Instead use the hdfs command for it.

20/02/06 09:56:33 INFO namenode.NameNode: STARTUP_MSG:
/************************************************************
STARTUP_MSG: Starting NameNode
STARTUP_MSG:   host = 465b84797d44/172.17.0.2
STARTUP_MSG:   args = [-format]
STARTUP_MSG:   version = 2.7.7
STARTUP_MSG:   classpath = /usr/local/hadoop-2.7.7/etc/hadoop:/usr/local/hadoop/share/hadoop/common/lib/apacheds-kerberos-codec-2.0.0-M15.jar:/usr/local/hadoop/share/hadoop/common/lib/api-util-1.0.0-M20.jar:/usr/local/hadoop/share/hadoop/common/lib/jsch-0.1.54.jar:/usr/local/hadoop/share/hadoop/common/lib/stax-api-1.0-2.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-httpclient-3.1.jar:/usr/local/hadoop/share/hadoop/common/lib/httpcore-4.2.5.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-io-2.4.jar:/usr/local/hadoop/share/hadoop/common/lib/log4j-1.2.17.jar:/usr/local/hadoop/share/hadoop/common/lib/xmlenc-0.52.jar:/usr/local/hadoop/share/hadoop/common/lib/mockito-all-1.8.5.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-collections-3.2.2.jar:/usr/local/hadoop/share/hadoop/common/lib/jetty-6.1.26.jar:/usr/local/hadoop/share/hadoop/common/lib/httpclient-4.2.5.jar:/usr/local/hadoop/share/hadoop/common/lib/jetty-sslengine-6.1.26.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-digester-1.8.jar:/usr/local/hadoop/share/hadoop/common/lib/api-asn1-api-1.0.0-M20.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-cli-1.2.jar:/usr/local/hadoop/share/hadoop/common/lib/jettison-1.1.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-logging-1.1.3.jar:/usr/local/hadoop/share/hadoop/common/lib/jersey-core-1.9.jar:/usr/local/hadoop/share/hadoop/common/lib/slf4j-log4j12-1.7.10.jar:/usr/local/hadoop/share/hadoop/common/lib/hadoop-annotations-2.7.7.jar:/usr/local/hadoop/share/hadoop/common/lib/jsp-api-2.1.jar:/usr/local/hadoop/share/hadoop/common/lib/jetty-util-6.1.26.jar:/usr/local/hadoop/share/hadoop/common/lib/protobuf-java-2.5.0.jar:/usr/local/hadoop/share/hadoop/common/lib/jsr305-3.0.0.jar:/usr/local/hadoop/share/hadoop/common/lib/jaxb-api-2.2.2.jar:/usr/local/hadoop/share/hadoop/common/lib/xz-1.0.jar:/usr/local/hadoop/share/hadoop/common/lib/jaxb-impl-2.2.3-1.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-beanutils-1.7.0.jar:/usr/local/hadoop/share/hadoop/common/lib/servlet-api-2.5.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-configuration-1.6.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-lang-2.6.jar:/usr/local/hadoop/share/hadoop/common/lib/htrace-core-3.1.0-incubating.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-codec-1.4.jar:/usr/local/hadoop/share/hadoop/common/lib/curator-recipes-2.7.1.jar:/usr/local/hadoop/share/hadoop/common/lib/gson-2.2.4.jar:/usr/local/hadoop/share/hadoop/common/lib/jersey-json-1.9.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-net-3.1.jar:/usr/local/hadoop/share/hadoop/common/lib/java-xmlbuilder-0.4.jar:/usr/local/hadoop/share/hadoop/common/lib/curator-client-2.7.1.jar:/usr/local/hadoop/share/hadoop/common/lib/junit-4.11.jar:/usr/local/hadoop/share/hadoop/common/lib/jets3t-0.9.0.jar:/usr/local/hadoop/share/hadoop/common/lib/activation-1.1.jar:/usr/local/hadoop/share/hadoop/common/lib/jersey-server-1.9.jar:/usr/local/hadoop/share/hadoop/common/lib/zookeeper-3.4.6.jar:/usr/local/hadoop/share/hadoop/common/lib/jackson-core-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-compress-1.4.1.jar:/usr/local/hadoop/share/hadoop/common/lib/paranamer-2.3.jar:/usr/local/hadoop/share/hadoop/common/lib/asm-3.2.jar:/usr/local/hadoop/share/hadoop/common/lib/hadoop-auth-2.7.7.jar:/usr/local/hadoop/share/hadoop/common/lib/guava-11.0.2.jar:/usr/local/hadoop/share/hadoop/common/lib/jackson-mapper-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/common/lib/curator-framework-2.7.1.jar:/usr/local/hadoop/share/hadoop/common/lib/snappy-java-1.0.4.1.jar:/usr/local/hadoop/share/hadoop/common/lib/netty-3.6.2.Final.jar:/usr/local/hadoop/share/hadoop/common/lib/apacheds-i18n-2.0.0-M15.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-math3-3.1.1.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-beanutils-core-1.8.0.jar:/usr/local/hadoop/share/hadoop/common/lib/jackson-jaxrs-1.9.13.jar:/usr/local/hadoop/share/hadoop/common/lib/avro-1.7.4.jar:/usr/local/hadoop/share/hadoop/common/lib/jackson-xc-1.9.13.jar:/usr/local/hadoop/share/hadoop/common/lib/slf4j-api-1.7.10.jar:/usr/local/hadoop/share/hadoop/common/lib/hamcrest-core-1.3.jar:/usr/local/hadoop/share/hadoop/common/hadoop-nfs-2.7.7.jar:/usr/local/hadoop/share/hadoop/common/hadoop-common-2.7.7-tests.jar:/usr/local/hadoop/share/hadoop/common/hadoop-common-2.7.7.jar:/usr/local/hadoop/share/hadoop/hdfs:/usr/local/hadoop/share/hadoop/hdfs/lib/netty-all-4.0.23.Final.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-io-2.4.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/log4j-1.2.17.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/xmlenc-0.52.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jetty-6.1.26.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-cli-1.2.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-logging-1.1.3.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jersey-core-1.9.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jetty-util-6.1.26.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/protobuf-java-2.5.0.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jsr305-3.0.0.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-daemon-1.0.13.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/servlet-api-2.5.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-lang-2.6.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/htrace-core-3.1.0-incubating.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-codec-1.4.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/xml-apis-1.3.04.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jersey-server-1.9.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jackson-core-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/asm-3.2.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/guava-11.0.2.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jackson-mapper-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/xercesImpl-2.9.1.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/netty-3.6.2.Final.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/leveldbjni-all-1.8.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-nfs-2.7.7.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-2.7.7.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-2.7.7-tests.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/stax-api-1.0-2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-client-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-io-2.4.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/log4j-1.2.17.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-collections-3.2.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jetty-6.1.26.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-cli-1.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jettison-1.1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-logging-1.1.3.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-core-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jetty-util-6.1.26.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/protobuf-java-2.5.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jsr305-3.0.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jaxb-api-2.2.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/xz-1.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jaxb-impl-2.2.3-1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/servlet-api-2.5.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/zookeeper-3.4.6-tests.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-lang-2.6.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-codec-1.4.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-json-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/guice-3.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/activation-1.1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-server-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/javax.inject-1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/zookeeper-3.4.6.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jackson-core-asl-1.9.13.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-compress-1.4.1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/asm-3.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/guava-11.0.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jackson-mapper-asl-1.9.13.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/netty-3.6.2.Final.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/leveldbjni-all-1.8.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/guice-servlet-3.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/aopalliance-1.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-guice-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jackson-jaxrs-1.9.13.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jackson-xc-1.9.13.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-applicationhistoryservice-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-sharedcachemanager-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-client-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-applications-distributedshell-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-web-proxy-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-resourcemanager-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-common-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-api-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-registry-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-nodemanager-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-applications-unmanaged-am-launcher-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-common-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-tests-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/commons-io-2.4.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/log4j-1.2.17.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jersey-core-1.9.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/hadoop-annotations-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/protobuf-java-2.5.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/xz-1.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/guice-3.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/junit-4.11.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jersey-server-1.9.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/javax.inject-1.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jackson-core-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/commons-compress-1.4.1.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/paranamer-2.3.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/asm-3.2.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jackson-mapper-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/snappy-java-1.0.4.1.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/netty-3.6.2.Final.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/leveldbjni-all-1.8.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/guice-servlet-3.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/aopalliance-1.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jersey-guice-1.9.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/avro-1.7.4.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/hamcrest-core-1.3.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.7.7-tests.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-common-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-core-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-hs-plugins-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-shuffle-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-app-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-hs-2.7.7.jar:/usr/local/hadoop/contrib/capacity-scheduler/*.jar:/usr/local/hadoop/contrib/capacity-scheduler/*.jar
STARTUP_MSG:   build = Unknown -r c1aad84bd27cd79c3d1a7dd58202a8c3ee1ed3ac; compiled by 'stevel' on 2018-07-18T22:47Z
STARTUP_MSG:   java = 1.8.0_202
************************************************************/
20/02/06 09:56:33 INFO namenode.NameNode: registered UNIX signal handlers for [TERM, HUP, INT]
20/02/06 09:56:33 INFO namenode.NameNode: createNameNode [-format]
Formatting using clusterid: CID-a931c2ab-44eb-410f-8a5e-c5745f69ec21
20/02/06 09:56:33 INFO namenode.FSNamesystem: No KeyProvider found.
20/02/06 09:56:33 INFO namenode.FSNamesystem: fsLock is fair: true
20/02/06 09:56:33 INFO namenode.FSNamesystem: Detailed lock hold time metrics enabled: false
20/02/06 09:56:34 INFO blockmanagement.DatanodeManager: dfs.block.invalidate.limit=1000
20/02/06 09:56:34 INFO blockmanagement.DatanodeManager: dfs.namenode.datanode.registration.ip-hostname-check=true
20/02/06 09:56:34 INFO blockmanagement.BlockManager: dfs.namenode.startup.delay.block.deletion.sec is set to 000:00:00:00.000
20/02/06 09:56:34 INFO blockmanagement.BlockManager: The block deletion will start around 2020 Feb 06 09:56:34
20/02/06 09:56:34 INFO util.GSet: Computing capacity for map BlocksMap
20/02/06 09:56:34 INFO util.GSet: VM type       = 64-bit
20/02/06 09:56:34 INFO util.GSet: 2.0% max memory 889 MB = 17.8 MB
20/02/06 09:56:34 INFO util.GSet: capacity      = 2^21 = 2097152 entries
20/02/06 09:56:34 INFO blockmanagement.BlockManager: dfs.block.access.token.enable=false
20/02/06 09:56:34 INFO blockmanagement.BlockManager: defaultReplication         = 3
20/02/06 09:56:34 INFO blockmanagement.BlockManager: maxReplication             = 512
20/02/06 09:56:34 INFO blockmanagement.BlockManager: minReplication             = 1
20/02/06 09:56:34 INFO blockmanagement.BlockManager: maxReplicationStreams      = 2
20/02/06 09:56:34 INFO blockmanagement.BlockManager: replicationRecheckInterval = 3000
20/02/06 09:56:34 INFO blockmanagement.BlockManager: encryptDataTransfer        = false
20/02/06 09:56:34 INFO blockmanagement.BlockManager: maxNumBlocksToLog          = 1000
20/02/06 09:56:34 INFO namenode.FSNamesystem: fsOwner             = hadoop (auth:SIMPLE)
20/02/06 09:56:34 INFO namenode.FSNamesystem: supergroup          = supergroup
20/02/06 09:56:34 INFO namenode.FSNamesystem: isPermissionEnabled = true
20/02/06 09:56:34 INFO namenode.FSNamesystem: Determined nameservice ID: hadoopcluster
20/02/06 09:56:34 INFO namenode.FSNamesystem: HA Enabled: true
20/02/06 09:56:34 INFO namenode.FSNamesystem: Append Enabled: true
20/02/06 09:56:34 INFO util.GSet: Computing capacity for map INodeMap
20/02/06 09:56:34 INFO util.GSet: VM type       = 64-bit
20/02/06 09:56:34 INFO util.GSet: 1.0% max memory 889 MB = 8.9 MB
20/02/06 09:56:34 INFO util.GSet: capacity      = 2^20 = 1048576 entries
20/02/06 09:56:34 INFO namenode.FSDirectory: ACLs enabled? false
20/02/06 09:56:34 INFO namenode.FSDirectory: XAttrs enabled? true
20/02/06 09:56:34 INFO namenode.FSDirectory: Maximum size of an xattr: 16384
20/02/06 09:56:34 INFO namenode.NameNode: Caching file names occuring more than 10 times
20/02/06 09:56:34 INFO util.GSet: Computing capacity for map cachedBlocks
20/02/06 09:56:34 INFO util.GSet: VM type       = 64-bit
20/02/06 09:56:34 INFO util.GSet: 0.25% max memory 889 MB = 2.2 MB
20/02/06 09:56:34 INFO util.GSet: capacity      = 2^18 = 262144 entries
20/02/06 09:56:34 INFO namenode.FSNamesystem: dfs.namenode.safemode.threshold-pct = 0.9990000128746033
20/02/06 09:56:34 INFO namenode.FSNamesystem: dfs.namenode.safemode.min.datanodes = 0
20/02/06 09:56:34 INFO namenode.FSNamesystem: dfs.namenode.safemode.extension     = 30000
20/02/06 09:56:34 INFO metrics.TopMetrics: NNTop conf: dfs.namenode.top.window.num.buckets = 10
20/02/06 09:56:34 INFO metrics.TopMetrics: NNTop conf: dfs.namenode.top.num.users = 10
20/02/06 09:56:34 INFO metrics.TopMetrics: NNTop conf: dfs.namenode.top.windows.minutes = 1,5,25
20/02/06 09:56:34 INFO namenode.FSNamesystem: Retry cache on namenode is enabled
20/02/06 09:56:34 INFO namenode.FSNamesystem: Retry cache will use 0.03 of total heap and retry cache entry expiry time is 600000 millis
20/02/06 09:56:34 INFO util.GSet: Computing capacity for map NameNodeRetryCache
20/02/06 09:56:34 INFO util.GSet: VM type       = 64-bit
20/02/06 09:56:34 INFO util.GSet: 0.029999999329447746% max memory 889 MB = 273.1 KB
20/02/06 09:56:34 INFO util.GSet: capacity      = 2^15 = 32768 entries
20/02/06 09:56:35 INFO namenode.FSImage: Allocated new BlockPoolId: BP-970697586-172.17.0.2-1580982995298
20/02/06 09:56:35 INFO common.Storage: Storage directory /home/hadoop/data/namenode has been successfully formatted.
20/02/06 09:56:35 INFO namenode.FSImageFormatProtobuf: Saving image file /home/hadoop/data/namenode/current/fsimage.ckpt_0000000000000000000 using no compression
20/02/06 09:56:35 INFO namenode.FSImageFormatProtobuf: Image file /home/hadoop/data/namenode/current/fsimage.ckpt_0000000000000000000 of size 323 bytes saved in 0 seconds.
20/02/06 09:56:35 INFO namenode.NNStorageRetentionManager: Going to retain 1 images with txid >= 0
20/02/06 09:56:35 INFO util.ExitUtil: Exiting with status 0
20/02/06 09:56:35 INFO namenode.NameNode: SHUTDOWN_MSG:
/************************************************************
SHUTDOWN_MSG: Shutting down NameNode at 465b84797d44/172.17.0.2
************************************************************/
[hadoop@465b84797d44 ~]$
```

启动Active NameNode
```
[hadoop@465b84797d44 sbin]$ ./hadoop-daemon.sh start namenode
starting namenode, logging to /usr/local/hadoop-2.7.7/logs/hadoop-hadoop-namenode-465b84797d44.out
[hadoop@465b84797d44 sbin]$ jps
53905 Jps
14935 QuorumPeerMain
53739 NameNode
29628 JournalNode
```


### 3.将NameNode元数据同步到Standby NameNode
在Standby NameNode节点执行:<br>
hadoop namenode -bootstrapStandby <br>
将Active NameNode节点元数据同步过来
```
[hadoop@6841f424bbd8 ~]$ hadoop namenode -bootstrapStandby
DEPRECATED: Use of this script to execute hdfs command is deprecated.
Instead use the hdfs command for it.

20/02/06 10:26:37 INFO namenode.NameNode: STARTUP_MSG:
/************************************************************
STARTUP_MSG: Starting NameNode
STARTUP_MSG:   host = 6841f424bbd8/172.17.0.3
STARTUP_MSG:   args = [-bootstrapStandby]
STARTUP_MSG:   version = 2.7.7
STARTUP_MSG:   classpath = /usr/local/hadoop-2.7.7/etc/hadoop:/usr/local/hadoop/share/hadoop/common/lib/apacheds-kerberos-codec-2.0.0-M15.jar:/usr/local/hadoop/share/hadoop/common/lib/api-util-1.0.0-M20.jar:/usr/local/hadoop/share/hadoop/common/lib/jsch-0.1.54.jar:/usr/local/hadoop/share/hadoop/common/lib/stax-api-1.0-2.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-httpclient-3.1.jar:/usr/local/hadoop/share/hadoop/common/lib/httpcore-4.2.5.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-io-2.4.jar:/usr/local/hadoop/share/hadoop/common/lib/log4j-1.2.17.jar:/usr/local/hadoop/share/hadoop/common/lib/xmlenc-0.52.jar:/usr/local/hadoop/share/hadoop/common/lib/mockito-all-1.8.5.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-collections-3.2.2.jar:/usr/local/hadoop/share/hadoop/common/lib/jetty-6.1.26.jar:/usr/local/hadoop/share/hadoop/common/lib/httpclient-4.2.5.jar:/usr/local/hadoop/share/hadoop/common/lib/jetty-sslengine-6.1.26.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-digester-1.8.jar:/usr/local/hadoop/share/hadoop/common/lib/api-asn1-api-1.0.0-M20.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-cli-1.2.jar:/usr/local/hadoop/share/hadoop/common/lib/jettison-1.1.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-logging-1.1.3.jar:/usr/local/hadoop/share/hadoop/common/lib/jersey-core-1.9.jar:/usr/local/hadoop/share/hadoop/common/lib/slf4j-log4j12-1.7.10.jar:/usr/local/hadoop/share/hadoop/common/lib/hadoop-annotations-2.7.7.jar:/usr/local/hadoop/share/hadoop/common/lib/jsp-api-2.1.jar:/usr/local/hadoop/share/hadoop/common/lib/jetty-util-6.1.26.jar:/usr/local/hadoop/share/hadoop/common/lib/protobuf-java-2.5.0.jar:/usr/local/hadoop/share/hadoop/common/lib/jsr305-3.0.0.jar:/usr/local/hadoop/share/hadoop/common/lib/jaxb-api-2.2.2.jar:/usr/local/hadoop/share/hadoop/common/lib/xz-1.0.jar:/usr/local/hadoop/share/hadoop/common/lib/jaxb-impl-2.2.3-1.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-beanutils-1.7.0.jar:/usr/local/hadoop/share/hadoop/common/lib/servlet-api-2.5.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-configuration-1.6.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-lang-2.6.jar:/usr/local/hadoop/share/hadoop/common/lib/htrace-core-3.1.0-incubating.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-codec-1.4.jar:/usr/local/hadoop/share/hadoop/common/lib/curator-recipes-2.7.1.jar:/usr/local/hadoop/share/hadoop/common/lib/gson-2.2.4.jar:/usr/local/hadoop/share/hadoop/common/lib/jersey-json-1.9.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-net-3.1.jar:/usr/local/hadoop/share/hadoop/common/lib/java-xmlbuilder-0.4.jar:/usr/local/hadoop/share/hadoop/common/lib/curator-client-2.7.1.jar:/usr/local/hadoop/share/hadoop/common/lib/junit-4.11.jar:/usr/local/hadoop/share/hadoop/common/lib/jets3t-0.9.0.jar:/usr/local/hadoop/share/hadoop/common/lib/activation-1.1.jar:/usr/local/hadoop/share/hadoop/common/lib/jersey-server-1.9.jar:/usr/local/hadoop/share/hadoop/common/lib/zookeeper-3.4.6.jar:/usr/local/hadoop/share/hadoop/common/lib/jackson-core-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-compress-1.4.1.jar:/usr/local/hadoop/share/hadoop/common/lib/paranamer-2.3.jar:/usr/local/hadoop/share/hadoop/common/lib/asm-3.2.jar:/usr/local/hadoop/share/hadoop/common/lib/hadoop-auth-2.7.7.jar:/usr/local/hadoop/share/hadoop/common/lib/guava-11.0.2.jar:/usr/local/hadoop/share/hadoop/common/lib/jackson-mapper-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/common/lib/curator-framework-2.7.1.jar:/usr/local/hadoop/share/hadoop/common/lib/snappy-java-1.0.4.1.jar:/usr/local/hadoop/share/hadoop/common/lib/netty-3.6.2.Final.jar:/usr/local/hadoop/share/hadoop/common/lib/apacheds-i18n-2.0.0-M15.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-math3-3.1.1.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-beanutils-core-1.8.0.jar:/usr/local/hadoop/share/hadoop/common/lib/jackson-jaxrs-1.9.13.jar:/usr/local/hadoop/share/hadoop/common/lib/avro-1.7.4.jar:/usr/local/hadoop/share/hadoop/common/lib/jackson-xc-1.9.13.jar:/usr/local/hadoop/share/hadoop/common/lib/slf4j-api-1.7.10.jar:/usr/local/hadoop/share/hadoop/common/lib/hamcrest-core-1.3.jar:/usr/local/hadoop/share/hadoop/common/hadoop-nfs-2.7.7.jar:/usr/local/hadoop/share/hadoop/common/hadoop-common-2.7.7-tests.jar:/usr/local/hadoop/share/hadoop/common/hadoop-common-2.7.7.jar:/usr/local/hadoop/share/hadoop/hdfs:/usr/local/hadoop/share/hadoop/hdfs/lib/netty-all-4.0.23.Final.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-io-2.4.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/log4j-1.2.17.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/xmlenc-0.52.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jetty-6.1.26.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-cli-1.2.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-logging-1.1.3.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jersey-core-1.9.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jetty-util-6.1.26.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/protobuf-java-2.5.0.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jsr305-3.0.0.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-daemon-1.0.13.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/servlet-api-2.5.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-lang-2.6.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/htrace-core-3.1.0-incubating.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-codec-1.4.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/xml-apis-1.3.04.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jersey-server-1.9.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jackson-core-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/asm-3.2.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/guava-11.0.2.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jackson-mapper-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/xercesImpl-2.9.1.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/netty-3.6.2.Final.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/leveldbjni-all-1.8.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-nfs-2.7.7.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-2.7.7.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-2.7.7-tests.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/stax-api-1.0-2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-client-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-io-2.4.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/log4j-1.2.17.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-collections-3.2.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jetty-6.1.26.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-cli-1.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jettison-1.1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-logging-1.1.3.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-core-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jetty-util-6.1.26.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/protobuf-java-2.5.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jsr305-3.0.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jaxb-api-2.2.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/xz-1.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jaxb-impl-2.2.3-1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/servlet-api-2.5.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/zookeeper-3.4.6-tests.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-lang-2.6.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-codec-1.4.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-json-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/guice-3.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/activation-1.1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-server-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/javax.inject-1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/zookeeper-3.4.6.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jackson-core-asl-1.9.13.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-compress-1.4.1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/asm-3.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/guava-11.0.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jackson-mapper-asl-1.9.13.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/netty-3.6.2.Final.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/leveldbjni-all-1.8.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/guice-servlet-3.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/aopalliance-1.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-guice-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jackson-jaxrs-1.9.13.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jackson-xc-1.9.13.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-applicationhistoryservice-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-sharedcachemanager-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-client-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-applications-distributedshell-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-web-proxy-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-resourcemanager-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-common-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-api-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-registry-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-nodemanager-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-applications-unmanaged-am-launcher-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-common-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-tests-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/commons-io-2.4.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/log4j-1.2.17.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jersey-core-1.9.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/hadoop-annotations-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/protobuf-java-2.5.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/xz-1.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/guice-3.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/junit-4.11.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jersey-server-1.9.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/javax.inject-1.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jackson-core-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/commons-compress-1.4.1.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/paranamer-2.3.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/asm-3.2.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jackson-mapper-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/snappy-java-1.0.4.1.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/netty-3.6.2.Final.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/leveldbjni-all-1.8.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/guice-servlet-3.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/aopalliance-1.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jersey-guice-1.9.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/avro-1.7.4.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/hamcrest-core-1.3.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.7.7-tests.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-common-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-core-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-hs-plugins-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-shuffle-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-app-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-hs-2.7.7.jar:/usr/local/hadoop/contrib/capacity-scheduler/*.jar:/usr/local/hadoop/contrib/capacity-scheduler/*.jar
STARTUP_MSG:   build = Unknown -r c1aad84bd27cd79c3d1a7dd58202a8c3ee1ed3ac; compiled by 'stevel' on 2018-07-18T22:47Z
STARTUP_MSG:   java = 1.8.0_202
************************************************************/
20/02/06 10:26:37 INFO namenode.NameNode: registered UNIX signal handlers for [TERM, HUP, INT]
20/02/06 10:26:37 INFO namenode.NameNode: createNameNode [-bootstrapStandby]
=====================================================
About to bootstrap Standby ID nn2 from:
           Nameservice ID: hadoopcluster
        Other Namenode ID: nn1
  Other NN's HTTP address: http://hadoop1:50070
  Other NN's IPC  address: hadoop1/172.17.0.2:9000
             Namespace ID: 560322791
            Block pool ID: BP-970697586-172.17.0.2-1580982995298
               Cluster ID: CID-a931c2ab-44eb-410f-8a5e-c5745f69ec21
           Layout version: -63
       isUpgradeFinalized: true
=====================================================
20/02/06 10:26:38 INFO common.Storage: Storage directory /home/hadoop/data/namenode has been successfully formatted.
20/02/06 10:26:39 INFO namenode.TransferFsImage: Opening connection to http://hadoop1:50070/imagetransfer?getimage=1&txid=0&storageInfo=-63:560322791:0:CID-a931c2ab-44eb-410f-8a5e-c5745f69ec21
20/02/06 10:26:39 INFO namenode.TransferFsImage: Image Transfer timeout configured to 60000 milliseconds
20/02/06 10:26:39 INFO namenode.TransferFsImage: Transfer took 0.01s at 0.00 KB/s
20/02/06 10:26:39 INFO namenode.TransferFsImage: Downloaded file fsimage.ckpt_0000000000000000000 size 323 bytes.
20/02/06 10:26:39 INFO util.ExitUtil: Exiting with status 0
20/02/06 10:26:39 INFO namenode.NameNode: SHUTDOWN_MSG:
/************************************************************
SHUTDOWN_MSG: Shutting down NameNode at 6841f424bbd8/172.17.0.3
************************************************************/
[hadoop@6841f424bbd8 ~]$
```

### 4.格式化ZKFC
在Active NameNode节点上运行：
```
[hadoop@465b84797d44 ~]$ hdfs zkfc -formatZK
20/02/06 10:33:51 INFO tools.DFSZKFailoverController: Failover controller configured for NameNode NameNode at hadoop1/172.17.0.2:9000
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:zookeeper.version=3.4.6-1569965, built on 02/20/2014 09:09 GMT
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:host.name=465b84797d44
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:java.version=1.8.0_202
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:java.vendor=Oracle Corporation
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:java.home=/usr/local/jdk1.8.0_202/jre
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:java.class.path=/usr/local/hadoop-2.7.7/etc/hadoop:/usr/local/hadoop/share/hadoop/common/lib/apacheds-kerberos-codec-2.0.0-M15.jar:/usr/local/hadoop/share/hadoop/common/lib/api-util-1.0.0-M20.jar:/usr/local/hadoop/share/hadoop/common/lib/jsch-0.1.54.jar:/usr/local/hadoop/share/hadoop/common/lib/stax-api-1.0-2.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-httpclient-3.1.jar:/usr/local/hadoop/share/hadoop/common/lib/httpcore-4.2.5.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-io-2.4.jar:/usr/local/hadoop/share/hadoop/common/lib/log4j-1.2.17.jar:/usr/local/hadoop/share/hadoop/common/lib/xmlenc-0.52.jar:/usr/local/hadoop/share/hadoop/common/lib/mockito-all-1.8.5.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-collections-3.2.2.jar:/usr/local/hadoop/share/hadoop/common/lib/jetty-6.1.26.jar:/usr/local/hadoop/share/hadoop/common/lib/httpclient-4.2.5.jar:/usr/local/hadoop/share/hadoop/common/lib/jetty-sslengine-6.1.26.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-digester-1.8.jar:/usr/local/hadoop/share/hadoop/common/lib/api-asn1-api-1.0.0-M20.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-cli-1.2.jar:/usr/local/hadoop/share/hadoop/common/lib/jettison-1.1.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-logging-1.1.3.jar:/usr/local/hadoop/share/hadoop/common/lib/jersey-core-1.9.jar:/usr/local/hadoop/share/hadoop/common/lib/slf4j-log4j12-1.7.10.jar:/usr/local/hadoop/share/hadoop/common/lib/hadoop-annotations-2.7.7.jar:/usr/local/hadoop/share/hadoop/common/lib/jsp-api-2.1.jar:/usr/local/hadoop/share/hadoop/common/lib/jetty-util-6.1.26.jar:/usr/local/hadoop/share/hadoop/common/lib/protobuf-java-2.5.0.jar:/usr/local/hadoop/share/hadoop/common/lib/jsr305-3.0.0.jar:/usr/local/hadoop/share/hadoop/common/lib/jaxb-api-2.2.2.jar:/usr/local/hadoop/share/hadoop/common/lib/xz-1.0.jar:/usr/local/hadoop/share/hadoop/common/lib/jaxb-impl-2.2.3-1.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-beanutils-1.7.0.jar:/usr/local/hadoop/share/hadoop/common/lib/servlet-api-2.5.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-configuration-1.6.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-lang-2.6.jar:/usr/local/hadoop/share/hadoop/common/lib/htrace-core-3.1.0-incubating.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-codec-1.4.jar:/usr/local/hadoop/share/hadoop/common/lib/curator-recipes-2.7.1.jar:/usr/local/hadoop/share/hadoop/common/lib/gson-2.2.4.jar:/usr/local/hadoop/share/hadoop/common/lib/jersey-json-1.9.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-net-3.1.jar:/usr/local/hadoop/share/hadoop/common/lib/java-xmlbuilder-0.4.jar:/usr/local/hadoop/share/hadoop/common/lib/curator-client-2.7.1.jar:/usr/local/hadoop/share/hadoop/common/lib/junit-4.11.jar:/usr/local/hadoop/share/hadoop/common/lib/jets3t-0.9.0.jar:/usr/local/hadoop/share/hadoop/common/lib/activation-1.1.jar:/usr/local/hadoop/share/hadoop/common/lib/jersey-server-1.9.jar:/usr/local/hadoop/share/hadoop/common/lib/zookeeper-3.4.6.jar:/usr/local/hadoop/share/hadoop/common/lib/jackson-core-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-compress-1.4.1.jar:/usr/local/hadoop/share/hadoop/common/lib/paranamer-2.3.jar:/usr/local/hadoop/share/hadoop/common/lib/asm-3.2.jar:/usr/local/hadoop/share/hadoop/common/lib/hadoop-auth-2.7.7.jar:/usr/local/hadoop/share/hadoop/common/lib/guava-11.0.2.jar:/usr/local/hadoop/share/hadoop/common/lib/jackson-mapper-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/common/lib/curator-framework-2.7.1.jar:/usr/local/hadoop/share/hadoop/common/lib/snappy-java-1.0.4.1.jar:/usr/local/hadoop/share/hadoop/common/lib/netty-3.6.2.Final.jar:/usr/local/hadoop/share/hadoop/common/lib/apacheds-i18n-2.0.0-M15.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-math3-3.1.1.jar:/usr/local/hadoop/share/hadoop/common/lib/commons-beanutils-core-1.8.0.jar:/usr/local/hadoop/share/hadoop/common/lib/jackson-jaxrs-1.9.13.jar:/usr/local/hadoop/share/hadoop/common/lib/avro-1.7.4.jar:/usr/local/hadoop/share/hadoop/common/lib/jackson-xc-1.9.13.jar:/usr/local/hadoop/share/hadoop/common/lib/slf4j-api-1.7.10.jar:/usr/local/hadoop/share/hadoop/common/lib/hamcrest-core-1.3.jar:/usr/local/hadoop/share/hadoop/common/hadoop-nfs-2.7.7.jar:/usr/local/hadoop/share/hadoop/common/hadoop-common-2.7.7-tests.jar:/usr/local/hadoop/share/hadoop/common/hadoop-common-2.7.7.jar:/usr/local/hadoop/share/hadoop/hdfs:/usr/local/hadoop/share/hadoop/hdfs/lib/netty-all-4.0.23.Final.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-io-2.4.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/log4j-1.2.17.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/xmlenc-0.52.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jetty-6.1.26.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-cli-1.2.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-logging-1.1.3.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jersey-core-1.9.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jetty-util-6.1.26.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/protobuf-java-2.5.0.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jsr305-3.0.0.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-daemon-1.0.13.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/servlet-api-2.5.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-lang-2.6.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/htrace-core-3.1.0-incubating.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/commons-codec-1.4.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/xml-apis-1.3.04.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jersey-server-1.9.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jackson-core-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/asm-3.2.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/guava-11.0.2.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/jackson-mapper-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/xercesImpl-2.9.1.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/netty-3.6.2.Final.jar:/usr/local/hadoop/share/hadoop/hdfs/lib/leveldbjni-all-1.8.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-nfs-2.7.7.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-2.7.7.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-2.7.7-tests.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/stax-api-1.0-2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-client-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-io-2.4.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/log4j-1.2.17.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-collections-3.2.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jetty-6.1.26.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-cli-1.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jettison-1.1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-logging-1.1.3.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-core-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jetty-util-6.1.26.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/protobuf-java-2.5.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jsr305-3.0.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jaxb-api-2.2.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/xz-1.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jaxb-impl-2.2.3-1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/servlet-api-2.5.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/zookeeper-3.4.6-tests.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-lang-2.6.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-codec-1.4.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-json-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/guice-3.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/activation-1.1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-server-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/javax.inject-1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/zookeeper-3.4.6.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jackson-core-asl-1.9.13.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/commons-compress-1.4.1.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/asm-3.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/guava-11.0.2.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jackson-mapper-asl-1.9.13.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/netty-3.6.2.Final.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/leveldbjni-all-1.8.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/guice-servlet-3.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/aopalliance-1.0.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jersey-guice-1.9.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jackson-jaxrs-1.9.13.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/lib/jackson-xc-1.9.13.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-applicationhistoryservice-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-sharedcachemanager-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-client-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-applications-distributedshell-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-web-proxy-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-resourcemanager-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-common-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-api-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-registry-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-nodemanager-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-applications-unmanaged-am-launcher-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-common-2.7.7.jar:/usr/local/hadoop-2.7.7/share/hadoop/yarn/hadoop-yarn-server-tests-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/commons-io-2.4.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/log4j-1.2.17.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jersey-core-1.9.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/hadoop-annotations-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/protobuf-java-2.5.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/xz-1.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/guice-3.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/junit-4.11.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jersey-server-1.9.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/javax.inject-1.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jackson-core-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/commons-compress-1.4.1.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/paranamer-2.3.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/asm-3.2.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jackson-mapper-asl-1.9.13.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/snappy-java-1.0.4.1.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/netty-3.6.2.Final.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/leveldbjni-all-1.8.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/guice-servlet-3.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/aopalliance-1.0.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/jersey-guice-1.9.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/avro-1.7.4.jar:/usr/local/hadoop/share/hadoop/mapreduce/lib/hamcrest-core-1.3.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.7.7-tests.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-common-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-core-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-hs-plugins-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-shuffle-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-app-2.7.7.jar:/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-hs-2.7.7.jar:/usr/local/hadoop/contrib/capacity-scheduler/*.jar
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:java.library.path=/usr/local/hadoop/lib/native:
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:java.io.tmpdir=/tmp
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:java.compiler=<NA>
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:os.name=Linux
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:os.arch=amd64
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:os.version=4.9.184-linuxkit
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:user.name=hadoop
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:user.home=/home/hadoop
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Client environment:user.dir=/home/hadoop
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Initiating client connection, connectString=hadoop1:2181,hadoop2:2181,hadoop3:2181 sessionTimeout=1000 watcher=org.apache.hadoop.ha.ActiveStandbyElector$WatcherWithClientRef@37afeb11
20/02/06 10:33:51 INFO zookeeper.ClientCnxn: Opening socket connection to server hadoop2/172.17.0.3:2181. Will not attempt to authenticate using SASL (unknown error)
20/02/06 10:33:51 INFO zookeeper.ClientCnxn: Socket connection established to hadoop2/172.17.0.3:2181, initiating session
20/02/06 10:33:51 INFO zookeeper.ClientCnxn: Session establishment complete on server hadoop2/172.17.0.3:2181, sessionid = 0x200008d342e0000, negotiated timeout = 4000
20/02/06 10:33:51 INFO ha.ActiveStandbyElector: Successfully created /hadoop-ha/hadoopcluster in ZK.
20/02/06 10:33:51 INFO ha.ActiveStandbyElector: Session connected.
20/02/06 10:33:51 INFO zookeeper.ZooKeeper: Session: 0x200008d342e0000 closed
20/02/06 10:33:51 INFO zookeeper.ClientCnxn: EventThread shut down
[hadoop@465b84797d44 ~]$
```

### 5.启动HDFS
在Active NameNode节点运行：./start-dfs.sh
```
[hadoop@465b84797d44 sbin]$ ./start-dfs.sh
Starting namenodes on [hadoop1 hadoop2]
The authenticity of host 'hadoop1 (172.17.0.2)' can't be established.
ECDSA key fingerprint is SHA256:G9B1hjmnFc1SJEqECoA8TtH52NKaNQW3z11KReMMPlE.
ECDSA key fingerprint is MD5:78:79:d8:98:d7:33:2d:00:65:79:df:1d:92:6c:9d:ce.
Are you sure you want to continue connecting (yes/no)? hadoop2: starting namenode, logging to /usr/local/hadoop-2.7.7/logs/hadoop-hadoop-namenode-6841f424bbd8.out
yes
hadoop1: Warning: Permanently added 'hadoop1,172.17.0.2' (ECDSA) to the list of known hosts.
hadoop1: namenode running as process 53739. Stop it first.
hadoop2: starting datanode, logging to /usr/local/hadoop-2.7.7/logs/hadoop-hadoop-datanode-6841f424bbd8.out
hadoop3: starting datanode, logging to /usr/local/hadoop-2.7.7/logs/hadoop-hadoop-datanode-87399d89ebbc.out
hadoop4: starting datanode, logging to /usr/local/hadoop-2.7.7/logs/hadoop-hadoop-datanode-df53065b1ead.out
hadoop1: starting datanode, logging to /usr/local/hadoop-2.7.7/logs/hadoop-hadoop-datanode-465b84797d44.out
Starting journal nodes [hadoop1 hadoop2 hadoop3]
hadoop2: journalnode running as process 31488. Stop it first.
hadoop3: journalnode running as process 31604. Stop it first.
hadoop1: journalnode running as process 29628. Stop it first.
Starting ZK Failover Controllers on NN hosts [hadoop1 hadoop2]
hadoop2: starting zkfc, logging to /usr/local/hadoop-2.7.7/logs/hadoop-hadoop-zkfc-6841f424bbd8.out
hadoop1: starting zkfc, logging to /usr/local/hadoop-2.7.7/logs/hadoop-hadoop-zkfc-465b84797d44.out

[hadoop@465b84797d44 sbin]$ jps
98215 Jps
14935 QuorumPeerMain
97610 DataNode
98058 DFSZKFailoverController
53739 NameNode
29628 JournalNode
```
查看主备节点多了DataNode进程和DFSZKFailoverController进程。
查看其它从节点多了DataNode进程

### 6.启动YARN
* 1.在namenode主备中选择其中任一台运行：./start-yarn.sh
```
[hadoop@6841f424bbd8 sbin]$ ./start-yarn.sh
starting yarn daemons
starting resourcemanager, logging to /usr/local/hadoop-2.7.7/logs/yarn-hadoop-resourcemanager-6841f424bbd8.out
The authenticity of host 'hadoop2 (172.17.0.3)' can't be established.
ECDSA key fingerprint is SHA256:+X474viU2FHQ9spLsdnG+QxwHS69V70MRxSGCGlDLg4.
ECDSA key fingerprint is MD5:46:d5:7a:a3:9a:55:88:d0:0d:dc:b7:3b:3f:fd:15:a5.
Are you sure you want to continue connecting (yes/no)? hadoop3: starting nodemanager, logging to /usr/local/hadoop-2.7.7/logs/yarn-hadoop-nodemanager-87399d89ebbc.out
hadoop1: starting nodemanager, logging to /usr/local/hadoop-2.7.7/logs/yarn-hadoop-nodemanager-465b84797d44.out
hadoop4: starting nodemanager, logging to /usr/local/hadoop-2.7.7/logs/yarn-hadoop-nodemanager-df53065b1ead.out
yes
hadoop2: Warning: Permanently added 'hadoop2,172.17.0.3' (ECDSA) to the list of known hosts.
hadoop2: starting nodemanager, logging to /usr/local/hadoop-2.7.7/logs/yarn-hadoop-nodemanager-6841f424bbd8.out

[hadoop@6841f424bbd8 sbin]$ jps
31488 JournalNode
89265 Jps
97107 DFSZKFailoverController
89049 NodeManager
96843 DataNode
15276 QuorumPeerMain
96572 NameNode
```
查看其它节点：NodeManager进程已启动成功！

* 2.在规划节点分别启动ResourceManager进程<br>
运行：./yarn-daemon.sh start resourcemanager
```
[hadoop@87399d89ebbc sbin]$ ./yarn-daemon.sh start resourcemanager
starting resourcemanager, logging to /usr/local/hadoop-2.7.7/logs/yarn-hadoop-resourcemanager-87399d89ebbc.out
[hadoop@87399d89ebbc sbin]$
[hadoop@87399d89ebbc sbin]$ jps
96419 DataNode
87957 NodeManager
31604 JournalNode
15509 QuorumPeerMain
97306 Jps
96990 ResourceManager
```
查看hadoop3,hadoop4节点ResourceManager进程已启动成功

### 7.启动MapReduce历史任务服务
在规划节点运行：./mr-jobhistory-daemon.sh start historyserver 启动历史任务服务器
```
[hadoop@7cdd51acc5b8 sbin]$ ./mr-jobhistory-daemon.sh start historyserver
chown: missing operand after '/usr/local/hadoop/logs'
Try 'chown --help' for more information.
starting historyserver, logging to /usr/local/hadoop/logs/mapred--historyserver-7cdd51acc5b8.out

[hadoop@7cdd51acc5b8 sbin]$ jps
7408 DFSZKFailoverController
13057 JobHistoryServer
4743 JournalNode
8583 NodeManager
13128 Jps
5401 NameNode
3898 QuorumPeerMain
6990 DataNode
[hadoop@7cdd51acc5b8 sbin]$

```



## 查看各主从节点状态
### 通过命令行查看
#### hadoop1
```
[hadoop@7cdd51acc5b8 sbin]$ hdfs haadmin -getServiceState nn1
standby
```

#### hadoop2
```
[hadoop@ae5e2418e756 sbin]$ hdfs haadmin -getServiceState nn2
active
```

### hadoop3
```
[hadoop@e77a3eebb7fe sbin]$ yarn rmadmin -getServiceState rm1
active
```

### hadoop4
```
[hadoop@fb4288b0403c sbin]$ yarn rmadmin -getServiceState rm2
standby
```

## 通过Web UI查看集群状态
因为是docker容器部署，相应主机端口已映射到本地宿主机，对应如下：

http://hadoop1:50070/   -->     http://localhost:50070/
![image](https://raw.githubusercontent.com/gifer/Dockerfiles/master/centos7-hadoop/docs-images/50070.png)
<br>
<br>

http://hadoop2:50070/   -->     http://localhost:50071/
![image](https://raw.githubusercontent.com/gifer/Dockerfiles/master/centos7-hadoop/docs-images/50071.png)
<br>
<br>


http://hadoop1:19888/   -->     http://localhost:19888/
![image](https://raw.githubusercontent.com/gifer/Dockerfiles/master/centos7-hadoop/docs-images/19888.png)
<br>
<br>

http://hadoop3:8088/    -->     http://localhost:18086/
![image](https://raw.githubusercontent.com/gifer/Dockerfiles/master/centos7-hadoop/docs-images/18086.png)
<br>
<br>


## 验证HA故障切换
* 1.干掉hadoop2的NameNode进程，看hadoop1的NameNode是否由standby转为active
* 2.干掉hadoop3的ResourceManager进程，看hadoop4的ResourceManager是否由standby转为active


## 启动Hbase
在确保HDFS和Zookeeper集群启动成功后，运行HBase 集群启动命令：start-hbase.sh，在哪台节点上执行此命令，哪个节点就是主节点。
```
[hadoop@e77a3eebb7fe bin]$ start-hbase.sh
hadoop2: running zookeeper, logging to /usr/local/hbase/bin/../logs/hbase-hadoop-zookeeper-ae5e2418e756.out
hadoop4: running zookeeper, logging to /usr/local/hbase/bin/../logs/hbase-hadoop-zookeeper-fb4288b0403c.out
hadoop3: running zookeeper, logging to /usr/local/hbase/bin/../logs/hbase-hadoop-zookeeper-e77a3eebb7fe.out
hadoop1: running zookeeper, logging to /usr/local/hbase/bin/../logs/hbase-hadoop-zookeeper-7cdd51acc5b8.out
running master, logging to /usr/local/hbase/logs/hbase--master-e77a3eebb7fe.out
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option PermSize=128m; support was removed in 8.0
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=128m; support was removed in 8.0
hadoop2: running regionserver, logging to /usr/local/hbase/bin/../logs/hbase-hadoop-regionserver-ae5e2418e756.out
hadoop3: running regionserver, logging to /usr/local/hbase/bin/../logs/hbase-hadoop-regionserver-e77a3eebb7fe.out
hadoop4: running regionserver, logging to /usr/local/hbase/bin/../logs/hbase-hadoop-regionserver-fb4288b0403c.out
hadoop1: running regionserver, logging to /usr/local/hbase/bin/../logs/hbase-hadoop-regionserver-7cdd51acc5b8.out
hadoop2: Java HotSpot(TM) 64-Bit Server VM warning: ignoring option PermSize=128m; support was removed in 8.0
hadoop2: Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=128m; support was removed in 8.0
hadoop4: Java HotSpot(TM) 64-Bit Server VM warning: ignoring option PermSize=128m; support was removed in 8.0
hadoop4: Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=128m; support was removed in 8.0
hadoop3: Java HotSpot(TM) 64-Bit Server VM warning: ignoring option PermSize=128m; support was removed in 8.0
hadoop1: Java HotSpot(TM) 64-Bit Server VM warning: ignoring option PermSize=128m; support was removed in 8.0
hadoop3: Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=128m; support was removed in 8.0
hadoop1: Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=128m; support was removed in 8.0

[hadoop@e77a3eebb7fe bin]$ jps
7920 ResourceManager
41697 HMaster
4179 JournalNode
3396 QuorumPeerMain
41847 HRegionServer
5820 DataNode
41949 Jps
6974 NodeManager
[hadoop@e77a3eebb7fe bin]$
```

查看当前节点，多了HMaster进程和HRegionServer进程，其它节点多出HRegionServer进程。

### 单独启动备用节点HMaster
在备用节点上执行命令：hbase-daemon.sh start master
```
[hadoop@7cdd51acc5b8 bin]$ hbase-daemon.sh start master
running master, logging to /usr/local/hbase/logs/hbase--master-7cdd51acc5b8.out
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option PermSize=128m; support was removed in 8.0
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=128m; support was removed in 8.0

```

### 单独启动HRegionServer
当节点异常宕机发生时，单独启动
```
hbase-daemon.sh start regionserver 
```

### 验证Hbase集群启动状态
容器端口已映射到宿住机，对应如下：<br>
http://hadoop3:16010/   -->     http://localhost:16011/
![image](https://raw.githubusercontent.com/gifer/Dockerfiles/master/centos7-hadoop/docs-images/16011.png)
<br>
<br>
http://hadoop4:16010/   -->     http://localhost:16013/
![image](https://raw.githubusercontent.com/gifer/Dockerfiles/master/centos7-hadoop/docs-images/16013.png)


<br/>
<br/>
<br/> 

## Hive 安装配置（补充）

### 准备工作
在mysql中创建hive要用的元数据库，库名与配置文件中保持一致，并创建独立用户，并授权远程机器访问.

### 【1】 安装配置
安装参见Dockerfile，配置参见hive配置文件

### 【2】初始化元数据库
```
cd /usr/local/hive/bin

schematool -dbType mysql -initSchema
```

### 【3】启动metastore服务进程
在namenode节点启动
```
./hive --service metastore &
```

### 【4】运行hive客户端
可在任意节点启动
```
./hive
```




