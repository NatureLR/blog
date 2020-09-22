title: hexo搭建博客
author: Nature丿灵然
tags:
  - hexo
categories:
  - 运维
date: 2020-09-16 18:20:00
---
记录一下用hexo搭建博客的过程和一些坑
<!--more-->

#### 安装 Node.js
```bash
brew install node
```
当前版本的hexo在node14中会有告警，建议安装12并使用nvm管理node版本

#### 安装 Hexo 

```bash
npm install hexo-cli -g
```

#### 初始化Hexo 

```bash
mkdir blog &&cd blog # 创建文件夹并进入
hexo init            # 初始化 hexo
```
这个时候执行`hexo g && hexo s`就可以使用localhost:4000打开一个blog，此时这个主题是默认的

##### 配置Hexo 

- blog根目录目录下的`_config.yaml`是hexo的配置文件，自定义的相关设置需要修改此文件

#### 安装 Next主题

```bash
npm install hexo-theme-next 
```
##### 配置Next主题

- 配置主题为next，在`_config.yaml`中查找`theme`并修改为next
- 配置文件中有详细的说明不再细说

#### Hexo-admin

hexo admin 是一个可以直接在网页上写文章且实时预览的插件

执行`npm install --save hexo-admin`安装,访问<http://localhost:4000/admin>