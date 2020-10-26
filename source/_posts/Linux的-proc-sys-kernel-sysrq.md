title: Linux的/proc/sys/kernel/sysrq
author: Nature丿灵然
tags:
  - linux
categories:
  - 运维
date: 2020-09-29 17:34:00
---
利用`/proc/sys/kernel/sysrq`处理Linux系统不能正常响应用户请求，比如不能重启这时可以使用
强制重启`echo b >/proc/sys/kernel/sysrq`，
<!--more-->
SysRq也称为魔法键，可以使用键盘快捷键的，但还是使用命令明确一些

###### 检查当前状态

  cat /proc/sys/kernel/sysrq

各个数字对应的含义

- 0 完全关闭
- 1 开启sysrq所有功能
- \>1 允许的sysrq函数的位掩码 具体请看官方[文档](https://www.kernel.org/doc/html/v4.11/admin-guide/sysrq.html)

###### 更改SysRq

可以使用下面你的命令设置

  echo \<number> >/proc/sys/kernel/sysrq

或者使用sysctl

  sysctl -w kernel.sysrq=\<number>
  
###### 使用SysRq

  echo \<command> > /proc/sysrq-trigger

常用的command如下

- b 立即重启,但是不同步磁盘
- s 尝试同步磁盘
- 其他的可以参考[文档](https://www.kernel.org/doc/html/v4.11/admin-guide/sysrq.html)