layout: draft
title: PVE环境制作cloud-init模板
author: Nature丿灵然
tags:
  - pve
  - 虚拟化
categories:
  - 运维
date: 2023-05-15 00:11:00
---
<简介，将显示在首页>

# pve下载地址

<https://www.proxmox.com/en/downloads>

# 退出集群

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

# PVE环境制作cloud-init模板

```shell
id=""
img=""

# 创建机器
qm create $id --name Debian12CloudInit --net0 virtio,bridge=vmbr0
# 导入启动盘
qm importdisk $id $img local-lvm
# 添加磁盘
qm set $id --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$id-disk-0
#调整磁盘大小
qm disk resize $id scsi0 20G
# 添加cloud-init
qm set $id --ide2 local-lvm:cloudinit
# 设置启动盘
qm set $id --boot c --bootdisk scsi0
qm set $id --serial0 socket --vga serial0
qm set $id --agent enabled=1,fstrim_cloned_disks=1 #optional but recommended
qm template $id
```

- 更新apt源为国内源

```shell
deb http://mirrors.163.com/debian/ bookworm main non-free contrib
deb http://mirrors.163.com/debian/ bookworm-updates main non-free contrib
deb http://mirrors.163.com/debian/ bookworm-backports main non-free contrib
deb http://mirrors.163.com/debian-security/  bookworm/updates main non-free contrib
deb-src http://mirrors.163.com/debian/ bookworm main non-free contrib
deb-src http://mirrors.163.com/debian/ bookworm-updates main non-free contrib
deb-src http://mirrors.163.com/debian/ bookworm-backports main non-free contrib
deb-src http://mirrors.163.com/debian-security/ bookworm/updates main non-free contrib
```

- 升级并安装qga

```shell
sudo apt update
sudo apt full-upgrade
sudo apt install qemu-guest-agent
```

- cloudimages下载地址

```shell
http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-2211.qcow2
https://cloud.debian.org/images/cloud/bookworm/20230802-1460/debian-12-genericcloud-amd64-20230802-1460.qcow2
http://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.vmdk
```

# 升级pve7到8

```shell
rm -rf /etc/apt/sources.list.d/pve-install-repo.list
echo "deb https://enterprise.proxmox.com/debian/pve Bullseye pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list
wget https://mirrors.ustc.edu.cn/proxmox/debian/proxmox-release-bullseye.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg
echo "deb https://mirrors.ustc.edu.cn/proxmox/debian/pve bullseye pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
echo "deb https://mirrors.ustc.edu.cn/proxmox/debian/ceph-pacific bullseye main" > /etc/apt/sources.list.d/ceph.list
sed -i.bak "s#http://download.proxmox.com/debian#https://mirrors.ustc.edu.cn/proxmox/debian#g" /usr/share/perl5/PVE/CLI/pveceph.pm
sed -i.bak "s#ftp.debian.org/debian#mirrors.aliyun.com/debian#g" /etc/apt/sources.list
sed -i "s#security.debian.org#mirrors.aliyun.com/debian-security#g" /etc/apt/sources.list
echo "deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription" >> /etc/apt/sources.list
apt update && apt dist-upgrade -y

sed -i 's/bullseye/bookworm/g' /etc/apt/sources.list
echo "deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list
echo "deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription" > /etc/apt/sources.list.d/ceph.list
```
