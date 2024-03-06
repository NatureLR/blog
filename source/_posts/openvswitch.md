layout: draft
title: openvswitch
author: Nature丿灵然
tags:
  - 网络
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
epel-release \
rpm-build \
rpmlint \
yum-utils \
rpmdevtools \
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
python3-sphinx \ # 需要epel源
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
rpmdev-setuptree
wget https://www.openvswitch.org/releases/openvswitch-2.16.0.tar.gz
tar -C ~/rpmbuild/SOURCES/ -xzf  openvswitch-2.16.0.tar.gz

# 编译为rpm
rpmbuild -bb --nocheck ~/rpmbuild/SOURCES/openvswitch-2.16.0/rhel/openvswitch-fedora.spec

# 安装
yum -y install ~/rpmbuild/SOURCES/openvswitch-2.16.0-1.el7.x86_64.rpm

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
ovs-vsctl list interface veth | grep "ofport"
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

cookie=0x0, duration=17.496s, table=0, n_packets=0, n_bytes=0, priority=0 actions=NORMAL
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

#### flow语法

一般语法为: `基本 匹配规则 actions` 组成

如：`"table=0, priority=0 actions=NORMAL"`

基本:

- duration_sec – 生效时间
- table_id – 所属表项，id越小匹配靠前
- priority – 优先级,数越大优先级越高
- n_packets – 处理数据包数量
- idle_timeout – 空闲超时时间（秒），超时则自动删除该表规则，0 表示该流规则永不过期。

idle_timeout 不包含在 ovs-ofctl dump-flows br_name 的输出。

匹配字段:

in_port – vSwitch 的 INPUT Port 号
dl_src (Data Link layer) – 源 MAC 地址
dl_dst – 目的 MAC 地址
nw_src (Network layer) – 源 IP 地址
nw_dst – 目的 IP 地址
tp_src – TCP/UDP 源端口号
tp_dst – TCP/UDP 目的端口号
dl_type – 以太网协议类型，又称数据包（Packet）类型
ARP Packet – dl_type=0x0806
IP Packet – dl_type=0x0800
RARP Packet – dl_type=0x8035
nw_proto – 网络层协议类型，与 dl_type 一起使用
ICMP Packet – dl_type=0x0800,nw_proto=1
TCP Packet – dl_type=0x0800,nw_proto=6
UDP Packet – dl_type=0x0800,nw_proto=17

actions:

- NORMAL 和普通交换机一样正常转发
- OUTPUT 转发到某个端口
- GROUP 指定某个grup在处理
- DROP 丢弃

例子：

```shell
# 增加一条flows匹配端口id是1的端口，将他的数据转发到端口是2的接口上
ovs-ofctl add-flow vbr0 "table=1,priority=1,in_port=1,actions=output:2"
```

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
ovs-ofctl add-group vbr0 <group>
```

##### group语法

组表需要在流表上跳转，一个group有很多bucket，很具类型选择执行

group有很多类型(type)

- select 随机执行一个Bucket，一般用于负载均衡

- all 所有的Bucket 都执行

group表有很多可以参考后面的地址

```shell
# 将目标地址是192.168.1.66的流量跳转到group:1去
ovs-ofctl add-flow vbr0 "table=0,priority=888,in_port=5,dl_type=0x0800,nw_dst:192.168.1.66/32,actions=group:1"

# 修改ip地址为172.16.1.1或172.16.1.1者然后从vbr0发出
ovs-ofctl add-group vbr0 group_id=1,type=select,bucket=actions=mod_nw_dst:172.16.1.1,output:vbr0,bucket=actions=mod_nw_dst:172.16.1..2,output:vbr0
```

#### ovs-docker

> docker默认未集成ovs驱动，我们可以通过创建个无网络的容器通过`ovs-docker`这个工具配置网络

```shell
# 启动一个无网络的容器
docker run --net=none --privileged=true -it ubuntu:14.04 bash
# 在容器id为04c864c8ec59 中创建一个叫eth0的网卡并连接在vbr0,
ovs-docker add-port vbr0 eth0 04c864c8ec59 --ipaddress="192.168.1.2/24" --gateway=192.168.1.1

```

#### 参考资料

<https://zhuanlan.zhihu.com/p/37408341>
<https://www.cnblogs.com/jmilkfan-fanguiju/p/11825081.html>
<https://docs.openvswitch.org/en/latest>
