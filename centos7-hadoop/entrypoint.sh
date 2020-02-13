#!/usr/bin/env bash

# ssh免交互登录，进入到远程主机后，休眠2秒，然后退出远程主机，返回本机
echo "ssh login to hadoop1"
ssh -o stricthostkeychecking=no hadoop@hadoop1 "sleep 1s; exit;"
echo "logout successfully"
echo ""
sleep 2s

echo "ssh login to hadoop2"
ssh -o stricthostkeychecking=no hadoop@hadoop2 "sleep 1s; exit;"
echo "logout successfully"
echo ""
sleep 2s


echo "ssh login to hadoop3"
ssh -o stricthostkeychecking=no hadoop@hadoop3 "sleep 1s; exit;"
echo "logout successfully"
echo ""
sleep 2s

echo "ssh login to hadoop4"
ssh -o stricthostkeychecking=no hadoop@hadoop4 "sleep 1s; exit;"
echo "logout successfully"
echo ""

echo "ssh login has been completed"
