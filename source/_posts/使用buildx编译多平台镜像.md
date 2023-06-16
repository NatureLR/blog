title: 使用buildx编译多平台镜像
author: Nature丿灵然
tags:
  - docker
categories:
  - 运维
date: 2023-06-16 15:15:00
---
目前大部分使用docker的场景中不单单只是amd64平台了有时我们需要再arm和adm64上都能运行

<!--more-->

新版本的docker默认自带

#### 创建buildx

- 查看当前buildx实例

```shell
docker buildx ls
# NAME/NODE DRIVER/ENDPOINT STATUS  BUILDKIT PLATFORMS
# default * docker
#   default default         running 23.0.5   linux/amd64, linux/amd64/v2, linux/amd64/v3, linux/386
```

> 默认会有个实例叫default，default实例下有一个default的node，一个实例下可以有多个node,星号是默认使用的实例,node有很多种类型

- 创建buildx

```shell
docker buildx create --name main --node local --driver docker-container --platform linux/amd64,linux/arm64,linux/arm/v8 --use
# main
```

- 查看下

```shell
docker buildx ls
NAME/NODE DRIVER/ENDPOINT             STATUS   BUILDKIT PLATFORMS
main *    docker-container
  local   unix:///var/run/docker.sock inactive          linux/amd64*, linux/arm64*, linux/arm/v8*
default   docker
  default default                     running  23.0.5   linux/amd64, linux/amd64/v2, linux/amd64/v3, linux/386
```

|参数|说明      |
|-|----------|-|
|--name      | 实例名字|
|--drive     | 使用的驱动:docker,docker-contran,k8s,remote|
|--driver-op | 设置各个驱动的参数，比如docker-contran的镜像，k8s驱动的副本数等|
|--platform  | 编译的平台|
|--user      | 默认使用这个实例，等同于docker buildx use |

- 使用这个实例

```shell
docker buildx use main
```

- 当我们执行编译的时候会先下载buildx镜像并运行起来，然后使用这个容器运行的buildx来编译镜像

#### 编译

- --platform执行要编译的平台，其他的参数和普通的build差不多

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
docker buildx build --platform linux/amd64,linux/arm64,linux/arm -t naturelingran/m3u8-downloader --output type=tar,dest=./output.tar .
```

- 直接导入到本地docker中，只支持单平台架构

```shell
docker buildx build --platform linux/arm64 -t naturelingran/m3u8-downloader --load . 
```

#### 参考资料

<https://docs.docker.com/engine/reference/commandline/buildx_create>
