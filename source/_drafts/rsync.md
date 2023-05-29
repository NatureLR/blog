layout: draft
title: rsync
author: Nature丿灵然
date: 2023-05-19 17:57:49
tags:
  - rsync
categories:
  - 运维
---
rsync是一个用于文件同步和传输的实用工具。它可以在本地或远程系统之间进行文件传输，并提供许多功能，例如增量复制、备份、远程同步等。

<!--more-->

> 说明，模版文件不要发布出来

#### 安装

- centos

```shell
sudo yum install rsync
```

- debian

```shell
sudo apt-get install rsync
```

- macos自带但是版本比较老，可以用homebrew更新

#### 基本使用

- 基本使用

```shell
rsync -r $src $dest
```

- 同步元信息比如创建时间

```shell
rsync -a $src $dest
```

- 显示进度-v

```shell
rsync -av $src $dest
```

- 压缩传输-z

```shell
rsync -avz $src $dest
```

- src末尾带`/`在目标上不创建目录,既带`/`意思是将目录下的文件传输到目标，不带则便是将`文件夹`传输到目标

#### 远程同步

- 一般只需要在目标前加上用户名和ip和冒号即可

- 上传

```shell
rsync -rv  $src root@0.0.0.0:$dest
```

- 下载

```shell
rsync -rv root@0.0.0.0:$src $dest
```

#### 断点续传

- --partial传输中断不删除
- --progress显示进度
- -P 是`--progress`和`--partial`这两个参数的结合

```shell
rsync -avP $src $dest
```

#### 镜像同步

- --delete镜像同步，目标目录和源目录一致,目标目录多余的会被删除

```shell
rsync -av --delete $src $dest
```

- --existing 只传输目标没有的
- --ignore-existing" 只传输目标有的

```shell
tree a b
a
├── 1
├── 2
└── 3
b
├── 1
└── 2
```

```shell

```

#### 设置带宽

- --bwlimit 设置带宽,单位是KB/s

```shell
rsync -av --bwlimit=1000  $src $dest
```

#### 文件过滤

- --include指定同步的文件

```shell
# 排除日志文件
rsync -av --include="*.dat" $src $dest
```

- --exclude排除同步的文件

```shell
# 排除日志文件
rsync -av --exclude="*.log" $src $dest
```

#### 参考资料

<http://blog.naturelr.cc>
