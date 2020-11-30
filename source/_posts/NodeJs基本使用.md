title: NodeJS基本使用
author: Nature丿灵然
tags:
  - node
  - web
categories:
  - 运维
date: 2020-09-22 17:09:00
---
nodejS和相关组件常见的命令记录
<!--more-->
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

`curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.1/install.sh | bash`

安装确认：

`nvm version`

##### 配置淘宝源

查看源

`npm get registry`

查看修改为淘宝

`npm config set registry http://registry.npm.taobao.org/`


##### 安装NCU检查模块更新

`npm install -g npm-check-updates`

##### 常用命令

- npm 命令
  - npm install xxx 安装到当前目录
  - npm install -g xxx 安装全局模块
  - npm uninstall xxx 卸载模块
  - npm uninstall -g  xxx 卸载全局模块
  - npm moudles npm list --depth=0 查看所有高级的模块
  - npm list --depth=0 -global 查看所有全局安装的模块
- nvm
  - nvm install xxx 安装指定版本的node
  - nvm ls 查看现在node版本情况
  - nvm use xxx 使用某个版本的node
  - nvm use system 使用系统安装的node
  - nvm uninstall xxx 卸载某个版
- ncu
  - ncu 插件模块是否有更新
  - ncu -g 检查全局模块是否有更新
  - ncu -u 更新到package.json