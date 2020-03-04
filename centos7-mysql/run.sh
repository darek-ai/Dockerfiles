#!/usr/bin/env bash

docker run --name mysql -p 3306:3306 --privileged -itd centos7-mysql:5.7