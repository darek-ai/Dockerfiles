#!/usr/bin/env bash

# ssh免交互登录，进入到远程主机后，休眠1秒，然后退出远程主机，返回本机
serverArray=("hadoop1" "hadoop2" "hadoop3" "hadoop4")
# shellcheck disable=SC2068
for node in ${serverArray[@]}; do
    echo "ssh login to $node"
    ssh -o stricthostkeychecking=no hadoop@$node "sleep 1s; exit;"
    echo "logout successfully"
    echo ""
    sleep 1s
done

echo "ssh login has been completed"
