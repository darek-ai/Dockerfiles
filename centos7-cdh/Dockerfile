############################################

# Version : centos7-cdh

############################################

FROM centos7-jdk:1.0


ARG RELEASE_VERSION="1.0"

# 镜像创建者
MAINTAINER Roy dekota@126.com

USER root
WORKDIR /root

COPY ssh-login.sh ssh-login.sh
RUN chmod +x ssh-login.sh

