#!/usr/bin/env bash
set -e

echo '【1】MYSQL Initialize Insecure'
mysqld --initialize-insecure
echo ''

echo '【2】Starting MYSQL...'
systemctl start mysqld
echo ''

echo '【3】MYSQL Status...'
systemctl status mysqld
echo ''

echo '【4】Setting Password....'
mysql < /setpassword.sql
echo ''

echo '【5】MYSQL Installed Successfully.'
echo ''

/usr/sbin/init
