title: Centos8 web console(cockpit)
author: Nature丿灵然
tags:
  - linux
categories:
  - 运维
date: 2020-08-03 17:35:00
---
有些时候我们不想登录上centos的服务器执行一些操作这个时候就需要一个图形化界面

<!--more-->

##### 安装

    dnf -y install cockpit

##### 启动

    systemctl start cockpit

##### 开机自动启动

    systemctl enable cockpit

##### 访问

在浏览器中输入<服务器的IP:9090>即可登录到web界面

输入账号密码后进去如类似下界面

![upload successful](/images/pasted-2.png)

> 端口号可以在 `/usr/lib/systemd/system/cockpit.socket`中修改
