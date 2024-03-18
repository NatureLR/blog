layout: draft
title: linux中swap管理
author: Nature丿灵然
tags:
  - swap
  - memory
date: 2024-03-15 11:21:00
---
swap交换空叫或者叫虚拟内存，是linux中的一直机制，它允许使用磁盘来作为内存使用，用于内存不是很高的机器中

<!--more-->

由于是用磁盘来当做内存使用会导致磁盘的读写变多

#### 查看swap

```shell
# swap中不为0则表示开启了
free -h

swapon -s
```

#### 添加swap

- 创建swap文件，例子是1G大小

```shell
fallocate -l 1G /swapfile
```

或

```shell
dd if=/dev/zero of=/swapfile bs=1024 count=2097152
```

- 设置权限

```shell
chmod 600 /swapfile
```

- 格式化文件

mkswap /swapfile

- 添加

```shell
swapon /swapfile
```

- 持久化

```shell
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
```

- 验证

```shell
free -h
#                total        used        free      shared  buff/cache   available
# Mem:           3.8Gi       3.4Gi       180Mi        95Mi       628Mi       476Mi
# Swap:          1.0Gi       604Mi       419Mi
```

#### 关闭swap

- 停止swap

```shell
swapoff -v /swapfile
```

- 删除或注释 `/etc/fstab`中类似`/swapfile swap swap defaults 0 0`

- 删除文件

```shell
rm /swapfile
```

- 或者直接关闭所有

```shell
swapoff -a
```

#### 调整交换频率Swappiness

内核中有个参数`Swappiness`可以调整内存到虚拟内存的频率

- 临时修改

```shell
sudo sysctl -w vm.swappiness=10
```

- 持久化

```shell
echo "vm.swappiness=10" >> /etc/sysctl.conf
```

- 生效

```shell
sysctl -p
```

`

#### 参考资料

<https://u.sb/debian-swap/>
