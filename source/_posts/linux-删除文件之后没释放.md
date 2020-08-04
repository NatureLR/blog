title: linux 删除文件之后磁盘没释放
author: Nature丿灵然
tags:
  - linux
categories:
  - linux
date: 2020-08-04 16:42:00
---
<!--more-->

####  

原因则执行删除的时候是解除链接，如果文件是被打开的，进程会继续读取那个文件

正确是置空文件，命令如下

```cat /dev/null>xxx.log```


可以用下面的命令查找一下类似的文件然后重启对应的读取即可

```lsof | grep deleted```
