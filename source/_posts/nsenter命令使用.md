---
layout: draft
title: nsenter命令使用
author: Nature丿灵然
tags: []
date: 2021-04-26 17:14:00
---
nsenter在不同的命名空间中执行命令

<!--more-->

> namespace是linux中用于个隔离资源的特性，大名鼎鼎的docker就是基于此，而nsenter就是可以在不用`docker exec`的情况下进入别的namespace
> 常用的使用场景是很多容器都很精简，一些命令没有对于调试网络来说很麻烦，这个时候可以只进入改容器的网络命名空间，调试更加方便

#### 安装

一般linux发行版自带,位于util-linux包中

##### 选项说明

-t, --target pid：指定被进入命名空间的目标进程的pid
-m, --mount[=file]：进入mount命令空间。如果指定了file，则进入file的命令空间
-u, --uts[=file]：进入uts命令空间。如果指定了file，则进入file的命令空间
-i, --ipc[=file]：进入ipc命令空间。如果指定了file，则进入file的命令空间
-n, --net[=file]：进入net命令空间。如果指定了file，则进入file的命令空间
-p, --pid[=file]：进入pid命令空间。如果指定了file，则进入file的命令空间
-U, --user[=file]：进入user命令空间。如果指定了file，则进入file的命令空间
-G, --setgid gid：设置运行程序的gid
-S, --setuid uid：设置运行程序的uid
-r, --root[=directory]：设置根目录
-w, --wd[=directory]：设置工作目录

##### 例子

```shell
# 获取容器的pid
docker inspect alpine -f '{{.State.Pid}}'

# 进入pid对应的namespace的ns命名空间，这时可以执行节点的ip addr命令查看对应pid的网络情况
sudo nsenter --target $PID --net

# 等同于 docker exec
nsenter --target $PID --mount --uts --ipc --net --pid 
```

#### 参考资料

<https://man7.org/linux/man-pages/man1/nsenter.1.html>
<https://staight.github.io/2019/09/23/nsenter%E5%91%BD%E4%BB%A4%E7%AE%80%E4%BB%8B/>
