# Cloudera Manager 6.2.1 Centos7离线安装

# 1.服务器节点规划

机器名 | ip地址 | 操作系统 | 备注 |
-------------| -------------- | -------------|-------------
a.cdh.com | 192.21.0.2 | centos7.7 | cloudera manager master
b.cdh.com | 192.21.0.3 | centos7.7 | &nbsp;
c.cdh.com | 192.21.0.4 | centos7.7 | &nbsp;
e.cdh.com | 192.21.0.5 | centos7.7 | &nbsp;
mysql.cdh.com | 172.21.0.10 | mysql5.7容器 | &nbsp;


# 2.下载

## 2.1 CM软件包下载
[https://archive.cloudera.com/cm6/6.2.1/redhat7/yum/RPMS/x86_64/](https://archive.cloudera.com/cm6/6.2.1/redhat7/yum/RPMS/x86_64/)
![cm](img/2020-02-28.01.png)
下载目录中所有rpm包


## 2.2 Parcels下载
[https://archive.cloudera.com/cdh6/6.2.1/parcels/](https://archive.cloudera.com/cdh6/6.2.1/parcels/)
![parcels](img/2020-02-28.02.png)

el7 对应centos7  
el6 对应centos6

下载parcel、sha1、manifest三个文件即可。


## 2.3 仓库文件下载
[https://archive.cloudera.com/cm6/6.2.1/redhat7/yum/cloudera-manager.repo](https://archive.cloudera.com/cm6/6.2.1/redhat7/yum/cloudera-manager.repo)

目的是自定义yum安装源时，在此文件基础上修改。

## 2.4 Mysql驱动包下载
要求使用5.1.26以上版本的jdbc驱动，下载地址：
[mysql-connector-java-5.1.47.tar.gz](https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.47.tar.gz)

## 2.5 安装配置httpd
找任意一台机器，安装apache http服务,创建安装源，用于配置本地安装源，提供包下载
```shell script
yum -y install httpd createrepo

```
将下载的所有安装文件，复制到/var/www/html/目录下，其目录结构如下：
```shell script
cloudera-repos
├── cdh6.2.1
│   ├── CDH-6.2.1-1.cdh6.2.1.p0.1425774-el7.parcel
│   ├── CDH-6.2.1-1.cdh6.2.1.p0.1425774-el7.parcel.sha1
│   └── manifest.json
├── cm6.2.1
│   ├── allkeys.asc
│   ├── cloudera-manager-agent-6.2.1-1426065.el7.x86_64.rpm
│   ├── cloudera-manager-daemons-6.2.1-1426065.el7.x86_64.rpm
│   ├── cloudera-manager-server-6.2.1-1426065.el7.x86_64.rpm
│   ├── cloudera-manager-server-db-2-6.2.1-1426065.el7.x86_64.rpm
│   ├── enterprise-debuginfo-6.2.1-1426065.el7.x86_64.rpm
│   └── oracle-j2sdk1.8-1.8.0+update181-1.x86_64.rpm
└── mysql-connector-java-5.1.47.tar.gz
```
在cm6.2.1目录下生成rpm源数据
```shell script
createrepo .
```


# 3. 安装
## 3.1 MYSQL安装
官网文档强调：

* 数据库需要使用UTF8编码。对于MySQL和MariaDB，必须使用UTF8编码，而不是utf8mb4
* 对于MySQL5.7，必须要额外安装MySQL-shared-compat或者MySQL-shared包

mysql安装参考文献：[CDH 依赖的MySQL 数据库安装配置说明](https://www.cndba.cn/cndba/dave/article/3374)

CDH官网推荐mysqld.cnf配置：
```shell script
[mysqld]
datadir=/var/lib/mysql
socket=/var/run/mysqld/mysqld.sock
transaction-isolation = READ-COMMITTED
# Disabling symbolic-links is recommended to prevent assorted security risks;
# to do so, uncomment this line:
symbolic-links = 0


key_buffer_size = 32M
max_allowed_packet = 32M
thread_stack = 256K
thread_cache_size = 64
query_cache_limit = 8M
query_cache_size = 64M
query_cache_type = 1

max_connections = 550
#expire_logs_days = 10
#max_binlog_size = 100M

#log_bin should be on a disk with enough free space.
#Replace '/var/lib/mysql/mysql_binary_log' with an appropriate path for your
#system and chown the specified folder to the mysql user.
log_bin=/var/lib/mysql/mysql_binary_log

#In later versions of MySQL, if you enable the binary log and do not set
#a server_id, MySQL will not start. The server_id must be unique within
#the replicating group.
server_id=1

binlog_format = mixed

read_buffer_size = 2M
read_rnd_buffer_size = 16M
sort_buffer_size = 8M
join_buffer_size = 8M

# InnoDB settings
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit  = 2
innodb_log_buffer_size = 64M
innodb_buffer_pool_size = 4G
innodb_thread_concurrency = 8
innodb_flush_method = O_DIRECT
innodb_log_file_size = 512M

[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

sql_mode=STRICT_ALL_TABLES


# 表名不区分大小写
# lower_case_table_names=1

```

### 3.1.1 复制mysql驱动包
将mysql-connector-java-5.1.47.tar.gz文件上传至 CM Server节点上的 /usr/share/java/ 目录下并重命名为mysql-connector-java.jar（如果/usr/share/java/目录不存在，需要手动创建）
```shell script
tar zxvf mysql-connector-java-5.1.47.tar.gz 
mkdir /usr/share/java
cp mysql-connector-java-5.1.47.jar /usr/share/java/mysql-connector-java.jar
```


### 3.1.2 创建数据库、用户并授权

**服务名** | 数据库 | 用户
-----------------| -------------- |------------
Cloudera Manager Server | scm   | scm
Activity Monitor |	amon | amon
Reports Manager	| rman | rman
Hue		| hue | hue
Hive Metastore Server | hive | hive
Sentry Server | sentry | sentry
Cloudera Navigator Audit Server	| nav | nav
Cloudera Navigator Metadata Server | navms | nav
Oozie	| oozie | oozie

数据库初始化脚本

```
-- 注意scm的数据库不需要创建，在CDH 数据库初始化时会自动创建
create database scm default character set utf8 default collate utf8_general_ci;
grant all on scm.* to 'scm'@'%' identified by 'scm';

create database amon default character set utf8 default collate utf8_general_ci;
grant all on amon.* to 'amon'@'%' identified by 'amon';

create database rman default character set utf8 default collate utf8_general_ci;
grant all on rman.* to 'rman'@'%' identified by 'rman';

create database hue default character set utf8 default collate utf8_general_ci;
grant all on hue.* to 'hue'@'%' identified by 'hue';

create database hive default character set utf8 default collate utf8_general_ci;
grant all on hive.* to 'hive'@'%' identified by 'hive';

create database sentry default character set utf8 default collate utf8_general_ci;
grant all on sentry.* to 'sentry'@'%' identified by 'sentry';

create database nav default character set utf8 default collate utf8_general_ci;
grant all on nav.* to 'nav'@'%' identified by 'nav';

create database navms default character set utf8 default collate utf8_general_ci;
grant all on navms.* to 'navms'@'%' identified by 'navms';

create database oozie default character set utf8 default collate utf8_general_ci;
grant all on oozie.* to 'oozie'@'%' identified by 'oozie';
```


## 3.2 Cloudrea Manager安装

### 3.2.1 修改仓库文件
修改仓库文件cloudera-manager.repo
  
```shell script
vi cloudera-manager.repo
```

```shell script
[cloudera-manager]
name=Cloudera Manager 6.2.1
baseurl=https://a.cdh.com/cloudera-repos/cm6.2.1/  # 改为本地安装源地址
gpgcheck=0  # 不做gpg校验
enabled=1
```


* 复制repo文件到 yum 安装源
```shell script
cp cloudera-manager.repo /etc/yum.repos.d
```

 * 验证repo文件是否生效？

 ```shell script
# 清除并重新生成yum缓存
yum clean all && yum makecache
# 列举yum可用的cloudera安装包
yum list | grep cloudera
```
能列出说明仓库有效
```shell script
[root@4fe527430f25 cloudera-manager]# yum list | grep cloudera
cloudera-manager-agent.x86_64             5.16.2-1.cm5162.p0.7.el7       cloudera-manager
cloudera-manager-daemons.x86_64           5.16.2-1.cm5162.p0.7.el7       cloudera-manager
cloudera-manager-server.x86_64            5.16.2-1.cm5162.p0.7.el7       cloudera-manager
cloudera-manager-server-db-2.x86_64       5.16.2-1.cm5162.p0.7.el7       cloudera-manager
enterprise-debuginfo.x86_64               5.16.2-1.cm5162.p0.7.el7       cloudera-manager
jdk.x86_64                                2000:1.6.0_31-fcs              cloudera-manager
oracle-j2sdk1.7.x86_64                    1.7.0+update67-1               cloudera-manager
```

### 3.2.2 安装cloudera-manager
```shell script

# 安装openjdk8
yum install -y oracle-j2sdk1.8

# 安装cm manager(只需在cm server节点安装)
yum install -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server

```
### 3.2.3 配置本地Parcel存储库
Cloudera Manager Server安装完成后，进入到本地Parcel存储库目录：
```shell script
mkdir -p /opt/cloudera/parcel-repo
```
将cdh6.2.1目录下的三个parcel安装文件上传至/opt/cloudera/parcel-repo/目录下。
修改CDH-6.2.1-1.cdh6.2.1.p0.1425774-el7.parcel.sha1文件名
```shell script
mv CDH-6.2.1-1.cdh6.2.1.p0.1425774-el7.parcel.sha1 CDH-6.2.1-1.cdh6.2.1.p0.1425774-el7.parcel.sha
```

最终/opt/cloudera/parcel-repo目录内容如下：
```shell script
parcel-repo
├── CDH-6.2.1-1.cdh6.2.1.p0.1425774-el7.parcel
├── CDH-6.2.1-1.cdh6.2.1.p0.1425774-el7.parcel.sha
└── manifest.json
```


### 3.2.3 配置数据库脚本
如果mysql与cm server在同一机器，其传参格式为:  
scm_prepare_database.sh <db.type> <db.name> <db.user>

如果mysql与cm server不在同一服务器，参数格式为：
scm_prepare_database.sh <db.type> -h <mysql-host-ip> --scm-host <cm-server-ip> <db.name> <db.user>

```
[root@4fe527430f25 cloudera-scm-server]# /opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h mysql.cdh.com --scm-host a.cdh.com scm scm
Enter SCM password:
JAVA_HOME=/usr/java/jdk1.8.0_181-cloudera
Verifying that we can write to /etc/cloudera-scm-server
Creating SCM configuration file in /etc/cloudera-scm-server
Executing:  /usr/java/jdk1.8.0_181-cloudera/bin/java -cp /usr/share/java/mysql-connector-java.jar:/usr/share/java/oracle-connector-java.jar:/usr/share/java/postgresql-connector-java.jar:/opt/cloudera/cm/schema/../lib/* com.cloudera.enterprise.dbutil.DbCommandExecutor /etc/cloudera-scm-server/db.properties com.cloudera.cmf.db.
log4j:ERROR Could not find value for key log4j.appender.A
log4j:ERROR Could not instantiate appender named "A".
Wed Mar 04 19:26:53 CST 2020 WARN: Establishing SSL connection without server's identity verification is not recommended. According to MySQL 5.5.45+, 5.6.26+ and 5.7.6+ requirements SSL connection must be established by default if explicit option isn't set. For compliance with existing applications not using SSL the verifyServerCertificate property is set to 'false'. You need either to explicitly disable SSL by setting useSSL=false, or set useSSL=true and provide truststore for server certificate verification.
[2020-03-04 19:26:53,992] INFO     0[main] - com.cloudera.enterprise.dbutil.DbCommandExecutor.testDbConnection(DbCommandExecutor.java) - Successfully connected to database.
All done, your SCM database is configured correctly!
```
执行完，可查看数据库配置文件：/etc/cloudera-scm-server/db.properties
```shell script
[root@4fe527430f25 cloudera-scm-server]# cat /etc/cloudera-scm-server/db.properties
# Auto-generated by scm_prepare_database.sh on Wed Mar  4 19:26:52 CST 2020
#
# For information describing how to configure the Cloudera Manager Server
# to connect to databases, see the "Cloudera Manager Installation Guide."
#
com.cloudera.cmf.db.type=mysql
com.cloudera.cmf.db.host=mysql.cdh.com
com.cloudera.cmf.db.name=scm
com.cloudera.cmf.db.user=scm
com.cloudera.cmf.db.setupType=EXTERNAL
com.cloudera.cmf.db.password=scm

```


------


### 3.2.3 启动Cloudera-Manager
systemctl start cloudera-scm-server 或者  /etc/init.d/cloudera-scm-server start

```shell script

[root@b33dddbc5640 cloudera-manager]# systemctl start cloudera-scm-server
```


查看7180端口处于监听状态
```shell script
[root@4fe527430f25 init.d]# netstat -ntl | grep 7180
tcp        0      0 0.0.0.0:7180            0.0.0.0:*               LISTEN
```
在浏览器访问：http://a.cdh.com:7180/

默认用户名和密码均为：admin

* 进入安装向导页面
![安装向导](img/2020-03-02.03.png)

* 为CDH集群安装指定主机，手工输入机器名
![指定安装机器](img/2020-03-02.04.png)

* 下一步，选择CDH版本
![](img/2020-03-02.05.png)

* 集群安装进度
![](img/2020-03-02.06.png)
