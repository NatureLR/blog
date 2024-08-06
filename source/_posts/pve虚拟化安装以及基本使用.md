---
layout: draft
title: pve虚拟化安装以及基本使用
author: Nature丿灵然
tags:
  - pve
  - 虚拟化
date: 2024-04-01 17:34:00
---
pve是一个虚拟化平台，基于debian

<!--more-->

#### pve下载地址

<https://www.proxmox.com/en/downloads>

- 通过`ventoy`或者其他工具安装系统，安装过程有图形化ui很简单

#### 安装pve-tools

- pve tools内置了一些常用的设置比如改国内源，去除企业版提示

```shell
git clone https://github.com/ivanhao/pvetools.git
```

#### 虚机假死

```shell
id=""
ps -ef|grep "/usr/bin/kvm -id $id"|grep -v grep

kill -9 $id
```

#### 退出集群

```shell
systemctl stop pve-cluster.service
systemctl stop corosync.service
pmxcfs  -l

rm /etc/pve/corosync.conf
rm -rf /etc/corosync/*
killall pmxcfs
systemctl start pve-cluster.service

rm -rf  /etc/pve/nodes/<节点名字>
```
