title: 模版
author: Nature丿灵然
tags:
  - 模版
categories:
  - 运维
date: 2020-12-14 15:15:00
---
<简介，将显示在首页>

<!--more-->

> 说明，模版文件不要发布出来

#### 标题一

```shell
# 直接上传到仓库
docker buildx build --platform linux/amd64,linux/arm64,linux/arm -t naturelingran/m3u8-downloader -o type=registry .

# 输出本地
docker buildx build --platform linux/amd64,linux/arm64,linux/arm -t naturelingran/m3u8-downloader -o type=local,dest=./output .

# tar包
docker buildx build --platform linux/amd64,linux/arm64,linux/arm -t naturelingran/m3u8-downloader  --output type=tar,dest=./output.tar  .

# 直接导入到本地docker中，只支持单平台架构
docker buildx build --platform linux/arm64 -t naturelingran/m3u8-downloader --load  . 

docker buildx create --use desktop-linux
```

#### 参考资料

<https://docs.docker.com/engine/reference/commandline/buildx_create>
