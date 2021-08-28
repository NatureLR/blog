title: docker镜像分析工具dive
author: Nature丿灵然
tags:
  - docker
categories:
  - 运维
date: 2020-09-29 15:59:00
---
通过可视化分析docker镜像
<!--more-->

##### 安装

###### MacOs

    brew install dive

其他平台查看官方文档:<https://github.com/wagoodman/dive#installation>

##### 介绍

一般我们查看镜像可以使用`docker inspect`命令查看镜像的信息

使用`dive <image:tage>`来查看一个镜像，默认tag为`latest`没有镜像则会下载

![upload successful](/images/pasted-3.png)

如图之所示左边显示阶段和执行的命令，右边是文件系统，\<tab\>键切换到右边的文件系统，↑↓键则启动光标
