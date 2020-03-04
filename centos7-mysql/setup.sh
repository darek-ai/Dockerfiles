#!/usr/bin/env bash

set -e

echo '【1】MYSQL Initialize Insecure'
mysqld --initialize-insecure --user=mysql
echo ''

echo '【2】Starting MYSQL...'
# /etc/init.d/mysqld restart
systemctl start mysqld
echo ''

echo '【3】MYSQL Status...'
systemctl status mysqld
echo ''

echo '【4】Setting Password....'
mysql < /root/setpassword.sql
echo ''

echo '【5】MYSQL Installed Successfully.'
echo ''