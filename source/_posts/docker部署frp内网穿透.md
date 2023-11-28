layout: draft
title: docker部署frp内网穿透
author: Nature丿灵然
tags:
  - 网络
categories:
  - 运维
date: 2023-11-27 18:57:00
---

[frp](https://github.com/fatedier/frp)是一个国人开发的内网穿透工具

<!--more-->

![Alt text](../images/frp-1.png)

- frp是cs架构，访问frps(服务端)就可以访问部署在内网的frpc(客户端)

#### 服务端

```yaml
version: '3.8'

services:
  frps:
    image: snowdreamtech/frps
    container_name: frps
    restart: always
    network_mode: "host"
    volumes:
      - /etc/frp/:/etc/frp/
```

```toml
# frps.toml
bindPort = 7000
auth.token = "<密码>"

# 报表
webServer.addr= "0.0.0.0"
webServer.port = 7500
webServer.user = "admin"
webServer.password = "<密码>"
```

- 启动之后可以通过7500端口访问报表

##### 客户端

```yaml
version: '3.8'

services:
  frpc:
    image: snowdreamtech/frpc:latest
    container_name: frpc
    restart: always
    network_mode: "host"
    volumes:
      - /data/frp/:/etc/frp/
```

```toml
serverAddr = "<服务器地址>"
serverPort = 7000

auth.token = "<服务端认证token>"

webServer.port = 7400
webServer.user = "admin"
webServer.password = "<密码>"

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 6000 # 服务端远程访问的端口
```

#### 参考资料

<https://gofrp.org/zh-cn/docs/>
