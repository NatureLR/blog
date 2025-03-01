---
title: 初尝firecracker
author: Nature丿灵然
tags:
  - firecracker
  - 虚拟化
  - kvm
date: 2025-03-01 21:25:00
---
firecracker 是aws使用rust开发的一个轻型虚拟机,可以在一秒之内移动一个轻量虚拟机(microVM)

<!--more-->

不同于qemu等虚拟机不同并没有模拟全部的设备比如bios

#### 安装

- 从GitHub上下载<https://github.com/firecracker-microvm/firecracker/releases>

- 使用脚本一键下载

```shell
ARCH="$(uname -m)"
release_url="https://github.com/firecracker-microvm/firecracker/releases"
latest=$(basename $(curl -fsSLI -o /dev/null -w  %{url_effective} ${release_url}/latest))
curl -L ${release_url}/download/${latest}/firecracker-${latest}-${ARCH}.tgz \
| tar -xz

# Rename the binary to "firecracker"
mv release-${latest}-$(uname -m)/firecracker-${latest}-${ARCH} firecracker
```

#### 简单启动一个虚拟机

- 如果在虚拟机中需要打开嵌套虚拟化，修改kvm权限

```shell
chmod 777 /dev/kvm
```

- 启动一个firecracker实例

```shell
API_SOCKET="/tmp/firecracker.socket"
sudo rm -f $API_SOCKET
sudo ./firecracker --api-sock "${API_SOCKET}"
```

- 启动一个虚拟机需要2个文件一个`rootfs`一个是`linux`内核,这点和docker不同
- 下面的脚本会下载一个内核文件和一个rootfs,然后在rootfs中创建添加一个ssh公钥重新打包为一个rootfs

```shell
ARCH="$(uname -m)"

latest=$(wget "http://spec.ccfc.min.s3.amazonaws.com/?prefix=firecracker-ci/v1.11/$ARCH/vmlinux-5.10&list-type=2" -O - 2>/dev/null | grep -oP "(?<=<Key>)(firecracker-ci/v1.11/$ARCH/vmlinux-5\.10\.[0-9]{1,3})(?=</Key>)")

# Download a linux kernel binary
wget "https://s3.amazonaws.com/spec.ccfc.min/${latest}"

# Download a rootfs
wget -O ubuntu-24.04.squashfs.upstream "https://s3.amazonaws.com/spec.ccfc.min/firecracker-ci/v1.11/${ARCH}/ubuntu-24.04.squashfs"

# Create an ssh key for the rootfs
unsquashfs ubuntu-24.04.squashfs.upstream
ssh-keygen -f id_rsa -N ""
cp -v id_rsa.pub squashfs-root/root/.ssh/authorized_keys
mv -v id_rsa ./ubuntu-24.04.id_rsa
# create ext4 filesystem image
sudo chown -R root:root squashfs-root
truncate -s 400M ubuntu-24.04.ext4
sudo mkfs.ext4 -d squashfs-root -F ubuntu-24.04.ext4
```

- 启动一个虚拟机，下面这个脚本创建主要是创建了一个tap网卡和网络的一些设置
- 然后通过api启动了一个虚机

```shell
TAP_DEV="tap0"
TAP_IP="172.16.0.1"
MASK_SHORT="/30"

# Setup network interface
sudo ip link del "$TAP_DEV" 2> /dev/null || true
sudo ip tuntap add dev "$TAP_DEV" mode tap
sudo ip addr add "${TAP_IP}${MASK_SHORT}" dev "$TAP_DEV"
sudo ip link set dev "$TAP_DEV" up

# Enable ip forwarding
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -P FORWARD ACCEPT

# This tries to determine the name of the host network interface to forward
# VM's outbound network traffic through. If outbound traffic doesn't work,
# double check this returns the correct interface!
HOST_IFACE=$(ip -j route list default |jq -r '.[0].dev')

# Set up microVM internet access
sudo iptables -t nat -D POSTROUTING -o "$HOST_IFACE" -j MASQUERADE || true
sudo iptables -t nat -A POSTROUTING -o "$HOST_IFACE" -j MASQUERADE

API_SOCKET="/tmp/firecracker.socket"
LOGFILE="./firecracker.log"


touch $LOGFILE

# Set 日志文件
sudo curl -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"log_path\": \"${LOGFILE}\",
        \"level\": \"Debug\",
        \"show_level\": true,
        \"show_log_origin\": true
    }" \
    "http://localhost/logger"

KERNEL="./$(ls vmlinux* | tail -1)"
KERNEL_BOOT_ARGS="console=ttyS0 reboot=k panic=1 pci=off"

ARCH=$(uname -m)

if [ ${ARCH} = "aarch64" ]; then
    KERNEL_BOOT_ARGS="keep_bootcon ${KERNEL_BOOT_ARGS}"
fi

# 设置启动 源 也就是内核文件地址
sudo curl -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"kernel_image_path\": \"${KERNEL}\",
        \"boot_args\": \"${KERNEL_BOOT_ARGS}\"
    }" \
    "http://localhost/boot-source"

ROOTFS="./ubuntu-24.04.ext4"

#  设置 rootfs
sudo curl -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"drive_id\": \"rootfs\",
        \"path_on_host\": \"${ROOTFS}\",
        \"is_root_device\": true,
        \"is_read_only\": false
    }" \
    "http://localhost/drives/rootfs"

# The IP address of a guest is derived from its MAC address with
# `fcnet-setup.sh`, this has been pre-configured in the guest rootfs. It is
# important that `TAP_IP` and `FC_MAC` match this.
FC_MAC="06:00:AC:10:00:02"

# 设置网卡
sudo curl -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"iface_id\": \"net1\",
        \"guest_mac\": \"$FC_MAC\",
        \"host_dev_name\": \"$TAP_DEV\"
    }" \
    "http://localhost/network-interfaces/net1"

# API requests are handled asynchronously, it is important the configuration is
# set, before `InstanceStart`.
sleep 0.015s

# 启动虚机
sudo curl -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"action_type\": \"InstanceStart\"
    }" \
    "http://localhost/actions"

# API requests are handled asynchronously, it is important the microVM has been
# started before we attempt to SSH into it.
sleep 2s

# Setup internet access in the guest
ssh -i ./ubuntu-24.04.id_rsa root@172.16.0.2  "ip route add default via 172.16.0.1 dev eth0"

# Setup DNS resolution in the guest
ssh -i ./ubuntu-24.04.id_rsa root@172.16.0.2  "echo 'nameserver 8.8.8.8' > /etc/resolv.conf"

# SSH into the microVM
ssh -i ./ubuntu-24.04.id_rsa root@172.16.0.2

# Use `root` for both the login and password.
# Run `reboot` to exit.
```

#### 参考资料

<https://github.com/firecracker-microvm/firecracker/blob/main/docs/getting-started.md>
