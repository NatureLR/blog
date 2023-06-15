title: 使用buildx编译多平台镜像
author: Nature丿灵然
tags:
  - docker
categories:
  - 运维
date: 2020-12-14 15:15:00
---
目前大部分使用docker的场景中不单单只是amd64平台了有时我们需要再arm和adm64上都能运行

<!--more-->

新版本的docker默认自带

#### 创建buildx

- 创建buildx

```shell
docker buildx create --use desktop-linux
```

#### 编译

```shell
# 直接上传到仓库
docker buildx build --platform linux/amd64,linux/arm64,linux/arm -t naturelingran/m3u8-downloader -o type=registry .
```

- 输出本地

```shell
docker buildx build --platform linux/amd64,linux/arm64,linux/arm -t naturelingran/m3u8-downloader -o type=local,dest=./output .
```

- tar包

```shell
docker buildx build --platform linux/amd64,linux/arm64,linux/arm -t naturelingran/m3u8-downloader --output type=tar,dest=./output.tar  .
```

- 直接导入到本地docker中，只支持单平台架构

```shell
docker buildx build --platform linux/arm64 -t naturelingran/m3u8-downloader --load  . 
```

#### 参考资料

<https://docs.docker.com/engine/reference/commandline/buildx_create>
