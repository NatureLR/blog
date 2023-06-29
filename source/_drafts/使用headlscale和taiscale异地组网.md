layout: draft
title: 使用headscale和tailscale异地组网
author: Nature丿灵然
tags:
  - 网络
categories:
  - 运维
date: 2023-06-11 15:49:00
---
[Tailscale](https://github.com/tailscale/tailscale)是一个基于[WireGuard](https://www.wireguard.com)的组网工具,不同的在用户空间实现了WireGuard协议,虽然性能稍微下降但是比较灵活

<!--more-->

tailcasle官方原版中的控制器是不开源的,[headscale](https://github.com/juanfont/headscale)是一个开源的控制器,由欧洲航天局的大佬开发

#### 使用docker部署headscale

- 创建文件夹

```shell
mkdir -p headscale/config
mkdir -p headscale/data
touch headscale/data/db.sqlite
```

- 下载配置文件

```shell
curl https://raw.githubusercontent.com/juanfont/headscale/main/config-example.yaml -o ./headscale/config/config.yaml
```

- 修改配置文件

```yaml
server_url: # 服务器的外网ip
listen_addr: 0.0.0.0：8080 # 服务监听地址
metrics_listen_addr: 0.0.0.0:9090 # 因为在docker中不能使用 127.0.0.1
ip_prefixes: # 注释ipv6

```

- 添加docker-compose文件

```shell
cat << EOF >docker-compose.yaml
version: "3"
services:
  headscale:
    image: headscale/headscale:latest
    ports:
      - "8080:8080"
      - "9090:9090"
    restart: unless-stopped
    command: headscale serve
    volumes:
      - "/root/headscale/config:/etc/headscale/"
      - "/root/headscale/data:/var/lib/headscale/"
EOF

```

- 目录结构如下

```text
headscale/
├── config
│   └── config.yaml
├── data
│   ├── db.sqlite
│   ├── noise_private.key
│   └── private.key
└── docker-compose.yaml

2 directories, 6 files
```

- 进入headscale启动

```shell
docekr compose up -d 
```

- 添加快捷命令别名

```shell
echo "alias headscale='docker exec -it headscale-headscale-1 headscale'" >> .bashrc
source .bashrc
```

#### tailscale部署

- 一键安装

```sehll
curl -fsSL https://tailscale.com/install.sh | sh
```

- docker还有些问题

#### 组网

- 创建用户

```shell
headscale users create $user
```

- tailscale注册

```shell
tailscale up --login-server=http://$headscale:8080 --accept-routes=true --accept-dns=false

# 会显示一个网页 点击打开
# To authenticate, visit:
# 
#         http://x.x.x:8080/register/nodekey:4bf3df49e4c0e19af0b41c586b0465aea2d1391bc04bbd3f58db3dc748cb680e

# 浏览器中出现类似下面这种

# headscale
# Machine registration
# Run the command below in the headscale server to add this machine to your network:
# 
# headscale nodes register --user USERNAME --key nodekey:4bf3df49e4c0e19af0b41c586b0465aea2d1391bc04bbd3f58db3dc748cb680e

```

- headscale中注册,用户中写上面创建的用户

```shell
headscale nodes register --user $user --key nodekey:4bf3df49e4c0e19af0b41c586b0465aea2d1391bc04bbd3f58db3dc748cb680e
# Machine raspberrypi registered
```

- 检查客户端的tailscale的网卡

```shell
$ ip addr show tailscale0
#4: tailscale0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1280 qdisc pfifo_fast state UNKNOWN group default qlen 500
#    link/none
#    inet 100.64.0.1/32 scope global tailscale0
#       valid_lft forever preferred_lft forever
#    inet6 fe80::7141:886e:4878:79c9/64 scope link stable-privacy
#       valid_lft forever preferred_lft forever
```

#### 参考资料

<https://headscale.net/running-headscale-container>
<https://tailscale.com/kb/1017/install>
<https://icloudnative.io/posts/how-to-set-up-or-migrate-headscale>
