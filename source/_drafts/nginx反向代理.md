---
layout: draft
title: nginx反向代理
author: Nature丿灵然
tags:
  - 负载均衡
  - 网络
date: 2023-05-15 16:11:00
---
nginx除了做为web服务器，常用来做为反代

<!--more-->

#### 安装

- yum

```shell
yum install nginx
```

- docker镜像

#### 反向代理

```nginx
server {
    listen        8080;
    root          /data/nginx/;
    server_name   www.baidu.com;
    location / {
        root          /data/nginx/domain5;
        autoindex     on;
    }
    location /tset   {
        return  301  http://test.naturelr.cc/home;
    }
}
```

#### 参考资料

<http://blog.naturelr.cc>
