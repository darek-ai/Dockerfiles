############################################

# Version : centos7-cdh

############################################

FROM centos7-ssh:1.0


ARG RELEASE_VERSION="1.0"

# 镜像创建者
MAINTAINER Roy dekota@126.com

# 设定时区
ENV TIME_ZONE=Asia/Shanghai
RUN echo $TIME_ZONE > /etc/timezone \
&& ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime


RUN yum install -y ntp && yum clean all

USER root
WORKDIR /root

COPY ssh-login.sh ssh-login.sh
RUN chmod +x ssh-login.sh

