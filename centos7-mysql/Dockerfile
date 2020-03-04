############################################

# Version : centos7-mysql

############################################

FROM centos7-ssh:1.0

# 镜像创建者
MAINTAINER Roy dekota@126.com

# 设定时区
ENV TIME_ZONE=Asia/Shanghai
RUN echo $TIME_ZONE > /etc/timezone \
&& ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime

# RUN yum install -y ntp && yum clean all


# 复制并解压tar包文件到镜像指定目录
ADD repos/mysql-5.7.29-1.el7.x86_64.rpm-bundle.tar /root/


WORKDIR /root

# 顺序安装rpm包
RUN rpm -ivh mysql-community-common-5.7.29-1.el7.x86_64.rpm \
&& mysql-community-libs-5.7.29-1.el7.x86_64.rpm \
&& mysql-community-libs-compat-5.7.29-1.el7.x86_64.rpm \
&& mysql-community-devel-5.7.29-1.el7.x86_64.rpm \
&& mysql-community-client-5.7.29-1.el7.x86_64.rpm \
&& mysql-community-server-5.7.29-1.el7.x86_64.rpm


ENV MYSQL_USER=root
ENV MYSQL_PASS=123456
ENV LC_ALL=en_US.UTF-8

EXPOSE 3306


