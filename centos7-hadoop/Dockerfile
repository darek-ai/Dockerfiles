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
RUN groupadd hadoop && \
    useradd -m hadoop -g hadoop && \
    echo "hadoop:hadoop" | chpasswd && \
    usermod -aG wheel hadoop && \
    echo "hadoop ALL= NOPASSWD: ALL" >> /etc/sudoers


# ===============================================================
#
# 安装配置 zookeeper
#
# ===============================================================
ADD apache-zookeeper-3.5.6-bin.tar.gz /usr/local/
RUN chown -R hadoop:hadoop /usr/local/apache-zookeeper-3.5.6-bin && \
    cd /usr/local/ && ln -s ./apache-zookeeper-3.5.6-bin zookeeper

# 配置环境变量
ENV ZOOKEEPER_HOME=/usr/local/zookeeper
ENV PATH=$PATH:$ZOOKEEPER_HOME/bin


# ===============================================================
#
# 安装和配置 hadoop
#
# ===============================================================
ADD hadoop-2.7.7.tar.gz /usr/local/
RUN chown -R hadoop:hadoop /usr/local/hadoop-2.7.7 && \
    cd /usr/local && ln -s ./hadoop-2.7.7 hadoop

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
RUN chown -R hadoop:hadoop /usr/local/hbase-1.4.12 && \
    cd /usr/local && ln -s ./hbase-1.4.12 hbase && \
    cd /usr/local/hbase/conf && \
    ln -s /usr/local/hadoop/etc/hadoop/core-site.xml core-site.xml && \
    ln -s /usr/local/hadoop/etc/hadoop/hdfs-site.xml hdfs-site.xml

# 配置环境变量
ENV HBASE_HOME=/usr/local/hbase
ENV PATH=$PATH:$HBASE_HOME/bin


# ===============================================================
#
# 安装配置hive
#
# ===============================================================
ADD apache-hive-2.3.6-bin.tar.gz /usr/local/
RUN chown -R hadoop:hadoop /usr/local/apache-hive-2.3.6-bin && \
    cd /usr/local && ln -s ./apache-hive-2.3.6-bin hive

# 环境变量
ENV HIVE_HOME=/usr/local/hive
ENV PATH=$PATH:$HIVE_HOME/bin

# 复制mysql驱动包
COPY mysql-connector-java-5.1.47.jar $HIVE_HOME/lib/



# ===============================================================
#
# 复制配置文件
#
# ===============================================================
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

# 复制hive配置文件
COPY hive-conf/hive-env.sh      $HIVE_HOME/conf/hive-env.sh
COPY hive-conf/hive-site.xml    $HIVE_HOME/conf/hive-site.xml
COPY hive-conf/hive-log4j2.properties $HIVE_HOME/conf/hive-log4j2.properties
COPY hive-conf/hive-exec-log4j2.properties $HIVE_HOME/conf/hive-exec-log4j2.properties



# 切换工作目录
WORKDIR /home/hadoop
# 切换用户
USER hadoop

# 在hadoop用户下创建ssh密钥
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys


# 该脚本负责启动sshd,zookeeper服务,entrypoint入口，容器启动完成后执行
COPY --chown=hadoop:hadoop bootstrap.sh bootstrap.sh
# 该脚本用于在所有机器间完成一次ssh免交互登录
COPY --chown=hadoop:hadoop ssh-login.sh ssh-login.sh
# 该脚本负责启动hadoop集群
COPY --chown=hadoop:hadoop start-cluster.sh start-cluster.sh
COPY --chown=hadoop:hadoop start-hive.sh start-hive.sh


# 创建目录
RUN mkdir -p /home/hadoop/data && mkdir -p /home/hadoop/logs/hive && \
    sudo chmod +x /home/hadoop/bootstrap.sh && \
    sudo chmod +x /home/hadoop/ssh-login.sh && \
    sudo chmod +x /home/hadoop/start-cluster.sh && \
    sudo chmod +x /home/hadoop/start-hive.sh


# 健康检查
# 每隔10秒检查一次，检查超时间2秒，超时被认为检查失败，重试3次如果都检查失败，容器被认为不健康unhealthy
HEALTHCHECK --interval=10s --timeout=2s --retries=3 CMD ["/bin/bash"]

# 容器启动后，执行初始化脚本
# 启动脚本改由docker-compose entrypoint执行
# ENTRYPOINT ["/bin/bash","-c","sudo /home/hadoop/bootstrap.sh"]

CMD ["/bin/bash"]