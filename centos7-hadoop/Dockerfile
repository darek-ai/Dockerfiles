#***************************************************************
#
# Version : centos7-hadoop
#
#***************************************************************


FROM centos7-jdk:1.0

ARG RELEASE_VERSION="1.0"

# 镜像创建者
MAINTAINER Roy dekota@126.com

# ===============================================================
#
# 新建hadoop用户和用户组
#
# ===============================================================
RUN groupadd hadoop
RUN useradd -m hadoop -g hadoop
RUN echo "hadoop:hadoop" | chpasswd

# hadoop用户加入wheel用户组 sudo免密
RUN usermod -aG wheel hadoop
# 赋予hadoop用户sudo权限
RUN echo "hadoop ALL= NOPASSWD: ALL" >> /etc/sudoers


# ===============================================================
#
# 安装配置 zookeeper
#
# ===============================================================
ADD apache-zookeeper-3.5.6-bin.tar.gz /usr/local/
RUN chown -R hadoop:hadoop /usr/local/apache-zookeeper-3.5.6-bin
# 建立软连接
RUN cd /usr/local/ && ln -s ./apache-zookeeper-3.5.6-bin zookeeper
# 配置环境变量
ENV ZOOKEEPER_HOME=/usr/local/zookeeper
ENV PATH=$PATH:$ZOOKEEPER_HOME/bin


# ===============================================================
#
# 安装和配置 hadoop
#
# ===============================================================
ADD hadoop-2.7.7.tar.gz /usr/local/
RUN chown -R hadoop:hadoop /usr/local/hadoop-2.7.7
# 建立软连接
RUN cd /usr/local && ln -s ./hadoop-2.7.7 hadoop
# 配置环境变量
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_HDFS_HOME=$HADOOP_HOME
ENV YARN_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
ENV HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib"
ENV JAVA_LIBRARY_PATH=$HADOOP_HOME/lib/native:$JAVA_LIBRARY_PATH
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin
ENV PATH=$PATH:$HADOOP_HOME/sbin



# ===============================================================
#
# 安装配置hbase
#
# ===============================================================
ADD hbase-1.4.12-bin.tar.gz /usr/local/
RUN chown -R hadoop:hadoop /usr/local/hbase-1.4.12
# 建立软连接
RUN cd /usr/local && ln -s ./hbase-1.4.12 hbase
# 将core-site.xml hdfs-site.xml两文件连接到hadoop的配置文件，否则hbase集群启动可能找不到nameservice
RUN cd /usr/local/hbase/conf && ln -s /usr/local/hadoop/etc/hadoop/core-site.xml core-site.xml && ln -s /usr/local/hadoop/etc/hadoop/hdfs-site.xml hdfs-site.xml

# 配置环境变量
ENV HBASE_HOME=/usr/local/hbase
ENV PATH=$HBASE_HOME/bin:$PATH




USER hadoop

# 在hadoop用户下创建ssh密钥
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
RUN cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys


# 切换工作目录
WORKDIR /home/hadoop
# 创建目录
RUN mkdir -p /home/hadoop/data


# 复制zookeeper配置文件
COPY zookeeper-conf/zoo.cfg         $ZOOKEEPER_HOME/conf/zoo.cfg

# 复制hadoop配置文件
COPY hadoop-conf/core-site.xml      $HADOOP_CONF_DIR/core-site.xml
COPY hadoop-conf/hdfs-site.xml      $HADOOP_CONF_DIR/hdfs-site.xml
COPY hadoop-conf/mapred-site.xml    $HADOOP_CONF_DIR/mapred-site.xml
COPY hadoop-conf/yarn-site.xml      $HADOOP_CONF_DIR/yarn-site.xml
COPY hadoop-conf/hadoop-env.sh      $HADOOP_CONF_DIR/hadoop-env.sh
COPY hadoop-conf/mapred-env.sh      $HADOOP_CONF_DIR/mapred-env.sh
COPY hadoop-conf/yarn-env.sh        $HADOOP_CONF_DIR/yarn-env.sh
COPY hadoop-conf/slaves             $HADOOP_CONF_DIR/slaves

# 复制hbase配置文件
COPY hbase-conf/hbase-env.sh    $HBASE_HOME/conf/hbase-env.sh
COPY hbase-conf/hbase-site.xml  $HBASE_HOME/conf/hbase-site.xml
COPY hbase-conf/regionservers   $HBASE_HOME/conf/regionservers
COPY hbase-conf/backup-masters  $HBASE_HOME/conf/backup-masters


# 导入启动脚本
COPY --chown=hadoop:hadoop bootstrap.sh bootstrap.sh
RUN sudo chmod +x /home/hadoop/bootstrap.sh

# 该脚本与上面等效，只为学习docker-compose entrypoint
COPY --chown=hadoop:hadoop entrypoint.sh entrypoint.sh
RUN sudo chmod +x /home/hadoop/entrypoint.sh

# 添加集群启动脚本
COPY --chown=hadoop:hadoop start-cluster.sh start-cluster.sh
RUN sudo chmod +x /home/hadoop/start-cluster.sh


# 健康检查
# 每隔10秒检查一次，检查超时间2秒，超时被认为检查失败，重试3次如果都检查失败，容器被认为不健康unhealthy
HEALTHCHECK --interval=10s --timeout=2s --retries=3 CMD ["/bin/bash"]

# 容器启动后，执行初始化脚本
# 启动脚本改由docker-compose entrypoint执行
# ENTRYPOINT ["/bin/bash","-c","sudo /home/hadoop/bootstrap.sh"]

CMD ["/bin/bash"]