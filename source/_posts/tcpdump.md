layout: draft
title: tcpdump
author: Nature丿灵然
tags:
  - 网络
categories:
  - 运维
date: 2021-08-10 18:20:00
---
tcpdump是linux下的一个网络抓包工具

<!--more-->

> tcpdump非常强大且复杂命令，是我们平常排查网络相关问题的得力助手

#### 安装

一般linux发行版自带基本无需安装

#### 常用操作

抓取有192.168.1.1的包,来源或目的

```shell
tcpdump host 192.168.1.1
```

在所有网卡中抓取有192.168.1.1的包,来源或目的

```shell
tcpdump -i any host 192.168.1.1 
```

抓取主机是192.168.1.1 或 192.168.1.2

```shell
tcpdump -i any host 192.168.1.1 or 192.168.1.2
```

抓取除了192.168.1.1的包

```shell
tcpdump -i any host ! 192.168.1.1
```

抓取所有的流量

```shell
tcpdump -nS
```

指定端口

```shell
tcpdump -i any port 22
```

抓取192.168.1.1到192.168.1.2的80端口

```shell
tcpdump  -i any  src host  192.168.1.1 and dst host 192.168.1.2 and dst port 80
```

```shell
tcpdump -i eth0 icmp
tcpdump -i eth0 ip
tcpdump -i eth0 tcp
tcpdump -i eth0 udp
tcpdump -i eth0 arp

```

#### http协议

所有的get请求

```shell
tcpdump -i eth0 -s 0 -A 'tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420'
```

POST 请求

```shell
tcpdump -i any -s 0 -A 'tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x504F5354'
```

抓取80端口的http协议get请求的流量,只需要指定下`tcp dst port 80`指定下端口号,post同理

```shell
tcpdump -i any -s 0 -A 'tcp dst port 80 and tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420'
```

抓取192.168.1.1的80端口中get和post请求的http流量的请求和响应

```shell
tcpdump -i any -s 0 -A 'tcp dst port 80 and tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420 or tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x504F5354 or tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x48545450 or tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x3C21444F and host 192.168.1.1'
```

监控所有的get和post的主机和地址

```shell
tcpdump -i any  -s 0 -v -n -l | egrep -i "POST /|GET /|Host:"
```

#### 导出文件

-w 表示把数据报文输出到文件
-r 表示读取数据报文

抓取所有的包保存到tcpdump.pcap

```shell
tcpdump -i any -s 0 -X -w tcpdump.pcap
```

读取pcap文件

```shell
tcpdump -A -r tcpdump.pcap
```

#### 参考资料

<https://www.middlewareinventory.com/blog/tcpdump-capture-http-get-post-requests-apache-weblogic-websphere/>
<https://www.cnblogs.com/bakari/p/10748721.html>
