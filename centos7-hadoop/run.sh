#!/usr/bin/env bash

# docker run --privileged -it --name hadoop --restart=always -d  centos7-hadoop:1.0

# 运行一个临时容器，用于将配置文件复制到宿住机
# docker run -it --name hadoop --restart=always -u 0:1000 -d centos7-hadoop:1.0
# docker cp d39545067217:/usr/local/hadoop/etc/hadoop /Users/roy/Docker/hadoop/etc/
# docker cp d39545067217:/usr/local/hbase/conf /Users/roy/Docker/hbase/
# docker stop d39545067217
# docker rm d39545067217


# 运行hadoop集群容器，并挂载配置文件，数据存储目录
# hadoop1
docker run --privileged -it --name hadoop1 --restart=always \
-p 50070:50070 -p 16010:16010 -p 19888:19888 \
-v /Users/roy/Docker/hadoop/zookeeper/conf/zoo.cfg:/usr/local/zookeeper/conf/zoo.cfg \
-v /Users/roy/Docker/hadoop/etc/hadoop/core-site.xml:/usr/local/hadoop/etc/hadoop/core-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/hdfs-site.xml:/usr/local/hadoop/etc/hadoop/hdfs-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/mapred-site.xml:/usr/local/hadoop/etc/hadoop/mapred-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/yarn-site.xml:/usr/local/hadoop/etc/hadoop/yarn-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/hadoop-env.sh:/usr/local/hadoop/etc/hadoop/hadoop-env.sh \
-v /Users/roy/Docker/hadoop/etc/hadoop/mapred-env.sh:/usr/local/hadoop/etc/hadoop/mapred-env.sh \
-v /Users/roy/Docker/hadoop/etc/hadoop/yarn-env.sh:/usr/local/hadoop/etc/hadoop/yarn-env.sh \
-v /Users/roy/Docker/hadoop/etc/hadoop/slaves:/usr/local/hadoop/etc/hadoop/slaves \
-v /Users/roy/Docker/hadoop/hbase/conf/hbase-site.xml:/usr/local/hbase/conf/hbase-site.xml \
-v /Users/roy/Docker/hadoop/hbase/conf/hbase-env.sh:/usr/local/hbase/conf/hbase-env.sh \
-v /Users/roy/Docker/hadoop/hbase/conf/regionservers:/usr/local/hbase/conf/regionservers \
-v /Users/roy/Docker/hadoop/hadoop1:/home/hadoop/data \
--net staticip --ip 192.18.0.2 \
-d centos7-hadoop:1.0

# hadoop2
docker run --privileged -it --name hadoop2 --restart=always \
-p 50071:50070 -p 16011:16010 -p 19889:19888 \
-v /Users/roy/Docker/hadoop/zookeeper/conf/zoo.cfg:/usr/local/zookeeper/conf/zoo.cfg \
-v /Users/roy/Docker/hadoop/etc/hadoop/core-site.xml:/usr/local/hadoop/etc/hadoop/core-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/hdfs-site.xml:/usr/local/hadoop/etc/hadoop/hdfs-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/mapred-site.xml:/usr/local/hadoop/etc/hadoop/mapred-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/yarn-site.xml:/usr/local/hadoop/etc/hadoop/yarn-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/hadoop-env.sh:/usr/local/hadoop/etc/hadoop/hadoop-env.sh \
-v /Users/roy/Docker/hadoop/etc/hadoop/mapred-env.sh:/usr/local/hadoop/etc/hadoop/mapred-env.sh \
-v /Users/roy/Docker/hadoop/etc/hadoop/yarn-env.sh:/usr/local/hadoop/etc/hadoop/yarn-env.sh \
-v /Users/roy/Docker/hadoop/etc/hadoop/slaves:/usr/local/hadoop/etc/hadoop/slaves \
-v /Users/roy/Docker/hadoop/hbase/conf/hbase-site.xml:/usr/local/hbase/conf/hbase-site.xml \
-v /Users/roy/Docker/hadoop/hbase/conf/hbase-env.sh:/usr/local/hbase/conf/hbase-env.sh \
-v /Users/roy/Docker/hadoop/hbase/conf/regionservers:/usr/local/hbase/conf/regionservers \
-v /Users/roy/Docker/hadoop/hadoop2:/home/hadoop/data \
--net staticip --ip 192.18.0.3 \
-d centos7-hadoop:1.0

# hadoop3
docker run --privileged -it --name hadoop3 --restart=always \
-p 18088:8088 -p 16010:16010 \
-v /Users/roy/Docker/hadoop/zookeeper/conf/zoo.cfg:/usr/local/zookeeper/conf/zoo.cfg \
-v /Users/roy/Docker/hadoop/etc/hadoop/core-site.xml:/usr/local/hadoop/etc/hadoop/core-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/hdfs-site.xml:/usr/local/hadoop/etc/hadoop/hdfs-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/mapred-site.xml:/usr/local/hadoop/etc/hadoop/mapred-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/yarn-site.xml:/usr/local/hadoop/etc/hadoop/yarn-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/hadoop-env.sh:/usr/local/hadoop/etc/hadoop/hadoop-env.sh \
-v /Users/roy/Docker/hadoop/etc/hadoop/mapred-env.sh:/usr/local/hadoop/etc/hadoop/mapred-env.sh \
-v /Users/roy/Docker/hadoop/etc/hadoop/yarn-env.sh:/usr/local/hadoop/etc/hadoop/yarn-env.sh \
-v /Users/roy/Docker/hadoop/etc/hadoop/slaves:/usr/local/hadoop/etc/hadoop/slaves \
-v /Users/roy/Docker/hadoop/hbase/conf/hbase-site.xml:/usr/local/hbase/conf/hbase-site.xml \
-v /Users/roy/Docker/hadoop/hbase/conf/hbase-env.sh:/usr/local/hbase/conf/hbase-env.sh \
-v /Users/roy/Docker/hadoop/hbase/conf/regionservers:/usr/local/hbase/conf/regionservers \
-v /Users/roy/Docker/hadoop/hadoop3:/home/hadoop/data \
--net staticip --ip 192.18.0.4 \
-d centos7-hadoop:1.0


# hadoop4
docker run --privileged -it --name hadoop4 --restart=always \
-p 18089:8088 -p 16011:16010 \
-v /Users/roy/Docker/hadoop/zookeeper/conf/zoo.cfg:/usr/local/zookeeper/conf/zoo.cfg \
-v /Users/roy/Docker/hadoop/etc/hadoop/core-site.xml:/usr/local/hadoop/etc/hadoop/core-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/hdfs-site.xml:/usr/local/hadoop/etc/hadoop/hdfs-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/mapred-site.xml:/usr/local/hadoop/etc/hadoop/mapred-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/yarn-site.xml:/usr/local/hadoop/etc/hadoop/yarn-site.xml \
-v /Users/roy/Docker/hadoop/etc/hadoop/hadoop-env.sh:/usr/local/hadoop/etc/hadoop/hadoop-env.sh \
-v /Users/roy/Docker/hadoop/etc/hadoop/mapred-env.sh:/usr/local/hadoop/etc/hadoop/mapred-env.sh \
-v /Users/roy/Docker/hadoop/etc/hadoop/yarn-env.sh:/usr/local/hadoop/etc/hadoop/yarn-env.sh \
-v /Users/roy/Docker/hadoop/etc/hadoop/slaves:/usr/local/hadoop/etc/hadoop/slaves \
-v /Users/roy/Docker/hadoop/hbase/conf/hbase-site.xml:/usr/local/hbase/conf/hbase-site.xml \
-v /Users/roy/Docker/hadoop/hbase/conf/hbase-env.sh:/usr/local/hbase/conf/hbase-env.sh \
-v /Users/roy/Docker/hadoop/hbase/conf/regionservers:/usr/local/hbase/conf/regionservers \
-v /Users/roy/Docker/hadoop/hadoop4:/home/hadoop/data \
--net staticip --ip 192.18.0.5 \
-d centos7-hadoop:1.0