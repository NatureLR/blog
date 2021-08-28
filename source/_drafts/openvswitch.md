layout: draft
title: openvswitch
author: Nature丿灵然
tags:
  - 网络
categories:
  - 运维
date: 2021-08-24 17:46:00
---
ovs是一个开源的虚拟交换机，具有强大的功能

<!--more-->

> ovs通过flow能实现很多策略和功能

#### 安装

apt

```shell
sudo apt install openvswitch-switch 
```

yum

官方未提供yum源需要编译安装

```shell

# 安装编译依赖
yum -y install 
gcc  \
gcc-c++ \
autoconf  \
automake  \
libtool \
systemd-units  \
openssl \
openssl-devel \
python3-devel \
desktop-file-utils \
groff  \
graphviz \
checkpolicy \
selinux-policy-devel \
python3-sphinx \
procps-ng \
libcap-ng \
libcap-ng-devel \
libpcap-devel  \
numactl-devel \
dpdk-devel \
libbpf-devel \
numactl-devel \
unbound  \
unbound-devel

# 创建并切换到ovs用户
useradd ovs && su - ovs 

# 创建编译的文件夹
mkdir -p ~/rpmbuild/SOURCES
cd  ~/rpmbuild/SOURCES
wget https://www.openvswitch.org/releases/openvswitch-2.16.0.tar.gz
tar xfz openvswitch-2.9.2.tar.gz

# 编译为rpm
rpmbuild -bb --nocheck openvswitch-2.9.2/rhel/openvswitch-fedora.spec

# 安装rpm
yum -y install openvswitch-2.16.0-1.el7.x86_64.rpm

# 启动服务
systemctl start openvswitch
systemctl enable openvswitch
```

#### bridge

查看

```shell
ovs-vsctl list-br
```

增加

```shell
# 增加一个网桥叫vbr0
ovs-vsctl add-br vbr0
```

删除

```shell
ovs-vsctl del-br ovs-switch
```

#### port

查看所有ports

```shell
ovs-vsctl list-ports BRIDGE
```

查看端口id

```shell
ovs-vsctl list interface veth | grep "ofport "
```

增加

```shell
ovs-vsctl  add-port BRIDGE PORT
```

删除

```shell
ovs-vsctl del-port BRIDGE PORT
```

#### flow

> flow翻译为流表，其表示一些规则，能够控制数据包的转发

显示 vbr0的 flow

```shell
ovs-ofctl dump-flows vbr0
```

清除vbr0所有flows

```shell
ovs-ofctl del-flows vbr0
```

显示vbr0的groups表

```shell
ovs-ofctl dump-groups vbr0
```

增加流表

```shell
ovs-ofctl add-flow vbr0 "table=0, priority=0 actions=NORMAL"
```

基本
- duration_sec – 
- table_id – 所属表项
- priority – 优先级
- n_packets – 处理的数据包数量
- idle_timeout – 空闲超时时间（秒），超时则自动删除该表规则，0 表示该流规则永不过期。
idle_timeout 不包含在 ovs-ofctl dump-flows br_name 的输出。

条件

actions:动作
  - NORMAL 和普通交换机一样正常转发
  - OUTPUT 转发到某个端口
  

##### group

查看

```shell
ovs-ofctl dump-groups vbr0
```

全部删除

```shll
ovs-ofctl del-groups vbr0
```

增加group表

```shell
ovs-ofctl add-group vbr0 group_id=1,type=select,bucket=actions=mod_nw_dst:10.179.60.189,output:vbr0,bucket=actions=mod_nw_dst:10.179.60.190,output:vbr0
```

```sehll
ovs-ofctl -O OpenFlow13 add-group vbr0 "group_id=1,type=select,bucket=resubmit(,1)"

cookie=0x0, duration=11.056s, table=0, n_packets=0, n_bytes=0, priority=0 actions=NORMAL

ovs-ofctl add-flow vbr0 "table=1,priority=1,in_port=1,actions=output:4"
ovs-ofctl add-flow vbr0 "table=1,priority=2,in_port=4,actions=output:1"
ovs-ofctl dump-flows vbr0

ovs-ofctl -O OpenFlow15 add-group br0 'group_id=1234,type=select,selection_method=hash,fields(eth_dst,ip_dst,tcp_dst),bucket=output:10,bucket=output:11

docker run --net=none --privileged=true -it ubuntu:14.04 bash

ovs-docker add-port vbr0 eth0 04c864c8ec59 --ipaddress="192.168.1.2/24" --gateway=192.168.1.1

ovs-ofctl add-flow vswitch0 "table=1,priority=1,in_port=1,actions=output:4"
ovs-ofctl add-flow vswitch0 "table=1,priority=2,in_port=4,actions=output:1"

ovs-ofctl add-flow vbr0 "table=0, priority=0 actions=NORMAL"

ovs-ofctl add-flow vbr0 "table=0,priority=888,in_port=5,dl_type=0x0800,nw_dst:192.168.1.66/32,actions=group:1"

ovs-ofctl add-group vbr0 group_id=1,type=select,bucket=actions=mod_nw_dst:10.179.60.189,output:vbr0,bucket=actions=mod_nw_dst:10.179.60.190,output:vbr0

vs-ofctl add-flow vbr0 "table=0,priority=888,dl_type=0x0800,nw_dst:192.168.1.66/32,actions=group:1"

192.168.1.0/24 dev eth0  proto kernel  scope link  src 192.168.1.2

src 192.168.1.1 dst 192.168.1.66   src 192.168.1.1 dst 10.179.60.189
```

#### 参考资料

<https://zhuanlan.zhihu.com/p/37408341>
<https://www.cnblogs.com/jmilkfan-fanguiju/p/11825081.html>
<https://docs.openvswitch.org/en/latest>