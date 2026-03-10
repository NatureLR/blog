---
title: 使用linuxkit用yaml文件自定义linux系统
author: Nature丿灵然
tags:
  - 虚拟化
date: 2026-03-10 15:15:00
---

linuxkit是一个可以通过yaml文件定制linux配置并可以生成iso文件

<!--more-->

可以利用此工具实现不可变资源和最小化系统安装

#### 安装

- 在官方[release](https://github.com/linuxkit/linuxkit/releases)中下载对应的二进制文件

```shell
wget https://github.com/linuxkit/linuxkit/releases/download/v1.8.2/linuxkit-linux-amd64
chmod +x linuxkit-linux-amd64
mv linuxkit-linux-amd64 /usr/local/bin/linuxkit
linuxkit version
```

#### 使用

- linuxkit 编译以来docker需要先安装docker
- 官方的[examples](https://github.com/linuxkit/linuxkit/tree/master/examples)中有很多这里使用getty

```shell
mkdir demo && cd demo
wget https://raw.githubusercontent.com/linuxkit/linuxkit/refs/heads/master/examples/getty.yml
```

- 构建iso镜像

```shell
linuxkit build  --name demo --format iso-bios getty.yml 
# Extract kernel image: docker.io/linuxkit/kernel:6.12.59
# Add init containers:
# Process init image: docker.io/linuxkit/init:b5506cc74a6812dc40982cacfd2f4328f8a4b12a
# Process init image: docker.io/linuxkit/runc:9442aa234715e751a16144f1d4ae3fd1a00fd492
# Process init image: docker.io/linuxkit/containerd:ba19f64efd3331a8fd0a33e00eabd14f6ee1780e
# Process init image: docker.io/linuxkit/ca-certificates:256f1950df59f2f209e9f0b81374177409eb11de
# Add onboot containers:
#   Create OCI config for linuxkit/sysctl:43ac1d39da329c3567fcb9689e5ca99de6d169b6
#   Create OCI config for linuxkit/dhcpcd:b87e9ececac55a65eaa592f4dd8b4e0c3009afdb
# Add service containers:
#   Create OCI config for linuxkit/getty:a86d74c8f89be8956330c3b115b0b1f2e09ef6e0
#   Create OCI config for linuxkit/rngd:984eb580ecb63986f07f626b61692a97aacd7198
# Add files:
#   etc/getty.shadow
# Create outputs:
#   demo.iso
```

- 使用qemu运行需要先安装qemu

```shell
sudo apt -y install qemu-system-x86
```

- 启动运行

```shell
linuxkit run qemu --iso demo.iso
# 
# 账号：root 密码：abcdefgh
# linuxkit-825a53e5e70e login: root
# Password: 
# Welcome to LinuxKit!
# 
# NOTE: This system is namespaced.
# The namespace you are currently in may not be the root.
# System services are namespaced; to access, use `ctr -n services.linuxkit ...`
```

#### 参考资料

<http://blog.naturelr.cc>
