title: go环境变量
author: Nature丿灵然
tags:
  - go
categories:
  - 开发
date: 2020-09-14 20:21:00
---
go 有很多的环境变量记录一下常用的变量

<!--more-->

#### 查看环境变量

- go env 查看所有变量

- go env xxx 查看执行环境变量

- go help environment 查看各个环境变量的作用

#### 修改环境变量

- go 1.13以上推荐使用 go env -w NAME=VALUE 来设置环境变量

- go env -w 设置的变量根据`os.UserConfigDir()`返回的值来确定存在哪
  - Linux在$HOME/.config
  - Darwin在$HOME/Library/Application Support
  - Windows在%AppData%

- go 1.13以下使用export NAME=VALUE 写profile来设置，如.bashrc,.zshrc等

#### 常用变量说明

|环境变量|说明|默认|备注|
|-----------|--------------------------|---------------|-------------------------------------------------------|
|GOROOT     |go的安装位置                |/usr/local/bin |-                                                      |
|GOARCH     |架构类型                    |当前机器架构类型 |-                                                       |
|GOOS       |编译出文件的类型             |当前系统        |通过改变GOOS来设置交叉编译                                 |
|GOPATH     |go的项目存放目录             |$HOME/go      |在没使用gomod的时候安装的代码就存放在此                       |
|GOBIN      |`go instlal`安装的文件目录   |-             |一般将此目录加入PATH,`export PATH=$PATH:$GOBIN>$HOME/.zshrc`|
|GO111MODULE|go mod 开关                |自动           |-                                                        |
|GOPROXY    |go mod的代理地址            |-             |<https://goproxy.cn,https://mirrors.aliyun.com/goproxy/,https://goproxy.io,direct>|
