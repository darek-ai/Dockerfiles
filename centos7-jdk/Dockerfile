############################################

# Version : centos7-jdk

############################################

# 镜像centos-ssh基于centos:7.7构建，安装了ssh能力
FROM centos7-ssh:1.0

ARG RELEASE_VERSION="1.0"

# 镜像创建者
MAINTAINER Roy dekota@126.com


# 设定时区
ENV TIME_ZONE=Asia/Shanghai
RUN echo $TIME_ZONE > /etc/timezone \
&& ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime


# 安装JDK
ADD jdk-8u202-linux-x64.tar.gz /usr/local/

# 配置环境变量
ENV JAVA_HOME /usr/local/jdk1.8.0_202
ENV CLASSPATH ${JAVA_HOME}/lib/dt.jar:$JAVA_HOME/lib/tools.jar
ENV PATH $PATH:${JAVA_HOME}/bin

