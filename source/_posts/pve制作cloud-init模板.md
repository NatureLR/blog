layout: draft
title: PVE环境制作cloud-init模板
author: Nature丿灵然
tags:
  - pve
  - 虚拟化
date: 2024-03-28 20:32:00
---
cloudinit模版可以让我们在通过模板创建系统的时候设置好ip，用户名密码等无需开机进入后在设置

<!--more-->

#### 下载cloudinit镜像

- cloudimages下载地址

|名字|地址|
|-----------|-----|
|centos7|<http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-2211.qcow2>|
|debian12|<https://cloud.debian.org/images/cloud/bookworm/20230802-1460/debian-12-genericcloud-amd64-20230802-1460.qcow2>|
|ubuntu22.04|<http://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.vmdk>|

#### 导入pve中

```shell
img="" # 虚拟机镜像
id="" # 虚拟机id
name="" # 虚拟机名字
disk="" # 虚拟机存放磁盘的存储池

# 创建机器
qm create $id --name $name --net0 virtio,bridge=vmbr0
# 导入启动盘
qm importdisk $id $img $disk
# 添加磁盘
qm set $id --scsihw virtio-scsi-pci --scsi0 $disk:vm-$id-disk-0
#调整磁盘大小
qm disk resize $id scsi0 20G
# 添加cloud-init
qm set $id --ide2 $disk:cloudinit
# 设置启动盘
qm set $id --boot c --bootdisk scsi0
qm set $id --serial0 socket --vga serial0
qm set $id --agent enabled=1,fstrim_cloned_disks=1 #optional but recommended
```

#### 配置模版

> 此时pve界面中已经可以看到这个虚拟机，启动他，然后设置这个虚拟机，后面就不用每次都要设置一些东西了

- 换源：更新apt源为国内源，这里有坑有些cloudinit官方镜像（debian）使用了cloudinit代管了apt源，这就导致修改源的时候会被cloudinit给改回去
正确的做法是修改cloudinit配置

```shell
vim /etc/cloud/cloud.cfg
```

```yaml
   package_mirrors:
     - arches: [default]
      # 修改这里
       failsafe:
         primary: https://deb.debian.org/debian 
         security: https://deb.debian.org/debian-security
```

- 升级并安装qga

```shell
sudo apt update
sudo apt full-upgrade
sudo apt install qemu-guest-agent

sudo systemctl start qemu-guest-agent
sudo systemctl enable qemu-guest-agent
```

- 修改时区

```shell
sudo timedatectl set-timezone Asia/Shanghai
```

#### 转换为模版

- 设置为模版,也可以在ui上直接设置为模板

```shell
qm template $id
```
