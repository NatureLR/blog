---
title: nodeJS基本使用
author: Nature丿灵然
tags:
  - node
  - web
date: 2020-09-22 17:09:00
---
nodejS和相关组件常见的命令记录
<!--more-->

> 中文官方：<https://nodejs.org/zh-cn>

##### 安装Node.js

- CentOS
  - sudo yum install epel-release #安装epel源
  - sudo yum install nodejs 安装nodeJs
- MacOS
  - brew install node
  - 官网下载安装包

###### 检查是否安装成功

```shell
node --version
```

##### 安装NVM管理Nodejs版本

有些node代码有版本要求，nvm可以在各个版本时间切换

执行下面的命令安装：

```shell
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.1/install.sh | bash
```

安装确认：

```shell
nvm version
```

##### 配置淘宝源

查看源

```shell
npm get registry
```

查看修改为淘宝

```shell
npm config set registry http://registry.npm.taobao.org/
```

###### 使用nrm管理源

安装nrm

```shell
npm install -g nrm
```

查看源

```shell
nrm ls

  npm -------- https://registry.npmjs.org/
  yarn ------- https://registry.yarnpkg.com/
  cnpm ------- http://r.cnpmjs.org/
* taobao ----- https://registry.npm.taobao.org/
  nj --------- https://registry.nodejitsu.com/
  npmMirror -- https://skimdb.npmjs.com/registry/
  edunpm ----- http://registry.enpmjs.org/
```

切换源

```shell
# 切换到淘宝
nrm use taobao
```

删除源

```shell
nrm del taobao
```

增加源

```shell
nrm add <仓库名字> <仓库地址>
```

##### 安装NCU检查模块更新

```shell
npm install -g npm-check-updates
```

##### 常用命令

- npm 命令
  - npm install xxx 安装到当前目录
  - npm install -g xxx 安装全局模块
  - npm uninstall xxx 卸载模块
  - npm uninstall -g  xxx 卸载全局模块
  - npm list --depth=0 查看所有高级的模块
  - npm list --depth=0 -global 查看所有全局安装的模块
- nvm
  - nvm install xxx 安装指定版本的node
  - nvm ls 查看现在node版本情况
  - nvm use xxx 使用某个版本的node
  - nvm use system 使用系统安装的node
  - nvm uninstall xxx 卸载某个模块
- ncu
  - ncu 插件模块是否有更新
  - ncu -g 检查全局模块是否有更新
  - ncu -u 更新到package.json
  