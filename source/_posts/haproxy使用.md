title: haproxy使用
author: Nature丿灵然
tags:
  - 网络
  - 负载均衡
date: 2023-08-22 15:46:00
---
[haproxy](https://www.haproxy.org)是一个负载均衡程序支持L4和L7,和ipvs不同的是他的实现在用户空间

<!--more-->

#### 安装

```shell
yum install -y haproxy
systemc start haproxy
```

#### 配置

- 配置的路径为`/etc/haproxy/haproxy.cfg`

- `global`为全局配置

- `defaults`则为默认配置

- `frontend backend listen`其中frontend和backend配合完成一个代理比较灵活，listen则比较方便直接能定义监听相关信息和后端地址

```conf
global # 全局配置
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000 # 最大连接数
    user        haproxy
    group       haproxy
    daemon # 以daemon方式运行

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats
defaults # 默认参数
    mode                    http # 定义模式，http为7层，tcp则为4层
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

frontend  main *:5000 # 定义前端
    acl url_static       path_beg       -i /static /images /javascript /stylesheets # acl设置7层路径前缀匹配
    acl url_static       path_end       -i .jpg .gif .png .css .js # acl设置7层路径后缀匹配，还有正则匹配

    use_backend static          if url_static # 符合url_static这个规则则使用static这个后端
    default_backend             app # 默认后端app

backend static
    balance     roundrobin
    server      static 127.0.0.1:4331 check

backend app # 后端app
    balance     roundrobin # 代理算法
    server  app1 10.7.112.201:80 check # 定义后端地址有很多个，check开启了健康检查

listen stats    #定义监控页面，通过浏览器可以查看haproxy状态
    bind *:1080                   # 绑定端口1080
    stats refresh 30s             # 每30秒更新监控数据
    stats uri /stats              # 访问监控页面的uri
    stats realm HAProxy Stats     # 监控页面的认证提示
    stats auth admin:admin        # 监控页面的用户名和密码
```

#### 参考资料

<https://www.cnblogs.com/f-ck-need-u/p/8502593.html#1-5-acl>
