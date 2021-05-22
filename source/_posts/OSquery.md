layout: draft
title: OSquery
author: Nature丿灵然
tags: []
categories:
  - 运维
date: 2021-05-23 00:17:00
---
osquery是一个由FaceBook开源用于对系统进行查询、监控以及分析的一款软件，其最意思的地方是使用sql来查询系统的一些信息

<!--more-->

#### 安装

##### macos

```shell
brew install --cask osquery
```

##### ubuntu

```shell
export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys $OSQUERY_KEY
sudo add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'
sudo apt-get update
sudo apt-get install osquery
```

##### centos

```shell
curl -L https://pkg.osquery.io/rpm/GPG | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-osquery
sudo yum-config-manager --add-repo https://pkg.osquery.io/rpm/osquery-s3-rpm.repo
sudo yum-config-manager --enable osquery-s3-rpm-repo
sudo yum install osquer
```

#### 使用

> osquery存在两种运行模式，分别是osqueryi(交互式模式类似sqllite)、osqueryd(后台进程模式)。

##### osqueryi

```shell
# 进入交互模式
osqueryi
```

> 查看所有的表

```sql
.table
```

> 查看dns这个图表的所有内容

```sql
.all dns_resolvers
select * from dns_resolvers
```

> 查看dns这个图表的所有内容

```sql
 dns_resolvers
```

> 查看表结构

```sql
 .schema dns_resolvers
```

> 设置显示模式

```sql
.mod csv
```

> 查看帮助

```sql
 .help
```

#### 参考资料

<https://osquery.io/>

[Spoock's Blog | osquery初识](http://blog.spoock.com/2018/11/26/osquery-intro/)