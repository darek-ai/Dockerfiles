############################################

# Version : centos7-ssh

############################################

FROM centos:7.7.1908

ARG RELEASE_VERSION="1.0"

# 镜像创建者
MAINTAINER Roy dekota@126.com


RUN yum install -y openssh openssh-server openssh-clients net-tools which wget sudo less \
 && yum clean all

# 配置ssh密钥登录
RUN sed -i 's~^PasswordAuthentication yes~PasswordAuthentication no~g' /etc/ssh/sshd_config \
&& sed -i 's~^#PubkeyAuthentication yes~PubkeyAuthentication yes~g' /etc/ssh/sshd_config \
&& sed -i 's~^#PermitRootLogin yes~PermitRootLogin yes~g' /etc/ssh/sshd_config \
&& sed -i 's~^#UseDNS yes~UseDNS yes~g' /etc/ssh/sshd_config


RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' \
 && ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' \
 && ssh-keygen -t dsa -f /etc/ssh/ssh_host_ed25519_key  -N ''


EXPOSE 22

USER root
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
RUN cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# 健康检查
# 每隔10秒检查一次，检查超时间2秒，超时被认为检查失败，重试3次如果都检查失败，容器被认为不健康unhealthy
HEALTHCHECK --interval=10s --timeout=2s --retries=3 CMD ["/usr/sbin/sshd"]

# ENTRYPOINT ["/usr/sbin/sshd", "-D"]
CMD ["/usr/sbin/init"]


