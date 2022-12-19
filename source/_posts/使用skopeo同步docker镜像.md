layout: draft
title: 使用skopeo同步docker镜像
author: Nature丿灵然
tags:
  - 镜像
categories:
  - 运维
date: 2022-12-19 17:42:00
---
<简介，将显示在首页>

<!--more-->

> 说明，模版文件不要发布出来

#### 安装

> centos7的rpm很老，建议使用容器运行

- macos

```shell
brew install skopeo
```

#### 查看镜像情况

```shell
skopeo inspect docker://docker.io/alpine:latest --override-os linux
```

#### 登录

```shell
skopeo login -u nature.zhang hub.ucloudadmin.com
```

#### 复制镜像

- 从本地复制到仓库

```shell
skopeo copy docker-daemon:alpine:latest docker://hub.ucloudadmin.com/test-zxz/alpine:latest
```

- 从一个仓库复制到另一个仓库

> --override-os linux 是因为本地是m1的mac而改镜像没有改os的所以要加上这个参数,同时还有--override-arch只不过这个是arch
> 如果仓库不是https的使用--dest-tls-verify=false  

```shell
skopeo copy docker://docker.io/busybox:latest docker://uhub.ucloudadmin.com/test-zxz/busybox:latest --override-os linux
```

- 创建保存的目录,直接mkdir貌似有问题

```shell
install -d images
```

- 普通复制

```shell
skopeo copy docker://docker.io/busybox:latest dir:images
```

- 保存oci格式

```shell
skopeo copy docker://docker.io/busybox:latest oci:images
```

#### 同步镜像

```shell
skopeo sync  --src docker --dest dir uhub.ucloudadmin.com/test-zxz/busybox:latest images
```

- 从一个仓库同步到另一个仓库

```shell
skopeo sync --src docker --dest docker docker.io/redis uhub.ucloudadmin.com/test-zxz/redis
```

#### 参考资料

<https://mp.weixin.qq.com/s/WVE6Iz6AuXH0Hu_ayBfzRw>
