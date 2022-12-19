layout: draft
title: 使用skopeo同步docker镜像
author: Nature丿灵然
tags:
  - 镜像
categories:
  - 运维
date: 2022-12-19 17:42:00
---
在大部分场景下我们内部都会有一个镜像仓库来保证k8s活着cicd在拉镜像下的体验,以往我们需要使用docker pull

<!--more-->

下载下镜像然后使用docker push上传到内部仓库这个过程很繁琐,skopeo就是为了解决这个问题而诞生

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
skopeo login -u <用户名> <仓库地址>
```

#### 复制镜像

- 从本地复制到仓库

```shell
skopeo copy docker-daemon:alpine:latest docker://uhub.service.ucloud.cn/naturelr/test-zxz/alpine:latest
```

- 从一个仓库复制到另一个仓库

> --override-os linux 是因为本地是m1的mac而改镜像没有改os的所以要加上这个参数,同时还有--override-arch只不过这个是arch
> 如果仓库不是https的使用--dest-tls-verify=false  

```shell
skopeo copy docker://docker.io/busybox:latest docker://uhub.service.ucloud.cn/naturelr/test-zxz/busybox:latest --override-os linux
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
skopeo sync --src docker --dest dir uhub.service.ucloud.cn/naturelr/test-zxz/busybox:latest images
```

- 从一个仓库同步到另一个仓库

```shell
skopeo sync --src docker --dest docker docker.io/redis uhub.service.ucloud.cn/naturelr/test-zxz/redis
```

#### 参考资料

<https://mp.weixin.qq.com/s/WVE6Iz6AuXH0Hu_ayBfzRw>
