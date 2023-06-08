layout: draft
title: rsync使用
author: Nature丿灵然
date: 2023-06-07 16:41:49
tags:
  - rsync
categories:
  - 运维
---
rsync是一个用于文件同步和传输的实用工具。它可以在本地或远程系统之间进行文件传输，并提供许多功能，例如增量复制、备份、远程同步等。

<!--more-->

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

#### SSH远程同步

- 一般只需要在目标前加上用户名和ip和冒号即可

```shell
rsync -rv -e ssh $src root@0.0.0.0:$dest
```

- 上传,`-e ssh`可以省略

```shell
rsync -rv $src root@0.0.0.0:$dest
```

- 下载

```shell
rsync -rv root@0.0.0.0:$src $dest
```

- 指定ssh端口

```shell
rsync -rv -e "ssh -p2222" $src root@0.0.0.0:$dest
```

#### rsync协议同步

##### 服务端部署

###### 创建配置文件

```shell
cat << EOF > rsyncd.conf
uid = root
gid = root
port = 873
fake super = yes
use chroot = yes
max connections = 200
timeout = 600
ignore errors
read only = no
list = yes
auth users = rsync
secrets file = /root/rsync/rsyncd.passwd
log file = /root/rsync/rsyncd.log
pid file = /root/rsync/rsyncd.pid
lock  file = /root/rsync/rsyncd.lock
#####################################
[rsync]
comment = rsync
path = /root/rsync/data/
EOF
```

- 参数说明

参阅 <https://docs.rockylinux.org/books/learning_rsync/04_rsync_configure/>

| 项                                         | 说明                                            |
| ----------------------------------------- | ----------------------------------------------- |
| address = 192.168.100.4                   | rsync默认监听的IP地址|
| port = 873                                | rsync默认监听的端口|
| pid file = /var/run/rsyncd.pid            | 进程pid的文件位置|
| log file = /var/log/rsyncd.log            | 日志的文件位置|
| [share]                                   | 共享名称|
| comment = rsync                           | 备注或者描述信息|
| path = /rsync/                            | 所在的系统路径位置|
| read only = yes                           | yes表示只读，no表示可读可写|
| list = yes                                | yes表示可以看到共享名字|
| dont compress = \*.gz \*.gz2 \*.zip       | 哪些文件类型不对它进行压缩|
| auth users = rsync                        | 启用虚拟用户，定义个虚拟用户叫什么。 需要自行创建|
| secrets file = /etc/rsyncd_users.db       | 用来指定虚拟用户的密码文件位置，必须以.db结尾。 文件的内容格式是"用户名:密码"，一行一个|
| fake super  = yes                         | yes表示不需要daemon以root运行，就可以存储文件的完整属性。|
| uid =                                     | |
| gid =                                     | 两个参数用来指定当以root身份运行rsync守护进程时，指定传输文件所使用的用户和组，默认都是nobody 默认是nobody|
| use chroot  =  yes                        | 传输前是否需要进行根目录的锁定，yes是，no否。 rsync为了增加安全性，默认值为yes。|
| max  connections  =  4                    | 允许最大的连接数，默认值为0，表示不做限制|
| lock file = /var/run/rsyncd.lock          | 指定的锁文件，和“max  connections ”参数关联|
| exclude  =  lost+found/                   | 排除不需要传输的目录|
| transfer logging  =  yes                  | 是否启用类似ftp的日志格式来记录rsync的上传和下载|
| timeout =  900                            | 指定超时时间。 指定超时的时间，如果在指定时间内没有数据被传输，则rsync将直接退出。 单位为秒，默认值为0表示永不超时|
| ignore nonreadable = yes                  | 是否忽略用户没有访问权限的文件|
| motd file = /etc/rsyncd/rsyncd.motd       | 用于指定消息文件的路径。 默认情况下，是没有 motd 文件的。 这个消息就是当用户登录以后显示的欢迎信息。|
| hosts allow = 10.1.1.1/24                 | 用于指定哪些IP或者网段的客户端允许访问。 可填写ip、网段、主机名、域下面的主机，多个用空格隔开。 默认允许所有人访问|
| hosts deny =  10.1.1.20                   | 用户指定哪些ip或者网段的客户端不允许访问。 如果hosts allow和hosts deny有相同的匹配结果，则该客户端最终不能访问。 如果客户端的地址即不在hosts allow中，也不在hosts deny中，则该客户端允许访问。 默认情况下，没有该参数|
| auth  users = li                          | 启用虚拟用户，多个用户用英语状态的逗号进行隔开|
| syslog facility  = daemon                 | 定义系统日志的级别， 有这些值可填：auth、authpriv、cron、daemon、ftp、kern、lpr、mail、news、 security、syslog、user、uucp、 local0、local1、local2、local3、local4、local5、local6和local7。 默认值是daemon |

##### 创建密码文件

- 这个要和配置文件对应一致

```shell
# 账户名:密码
echo "rsync:123456" > rsyncd.passwd
chmod 600 rsyncd.passwd
```

##### 管理脚本

> 管理脚本有很多种可以自己创建一个systemd管理，这里我就简单点使用脚本管理

- 启动脚本

```shell
cat <<EOF > start.sh
#! /bin/bash
rsync --daemon --config=./rsyncd.conf
EOF

```

- 停止脚本

```shell
cat << EOF > stop.sh
#! /bin/bash
kill -15 $(cat rsyncd.pid)
EOF
```

##### 目录总览

```tree
.
├── data
├── rsyncd.conf
├── rsyncd.lock
├── rsyncd.log
├── rsyncd.passwd
├── start.sh
└── stop.sh
```

##### rsync客户端访问

- 在前面加了个`rsync://`或者`::`指定协议
- module是rsync守护进程指定的
- 默认交互式输入名

```shell
# 这个用户名是rsync配置文件里的虚拟用户
rsync -rvP $src/ $user@$ip::/$module/$dest 
rsync -rvP $src/ rsync://$user@$ip/$module/$dest
# 例子
# rsync -rvp src/ rsync@192.168.1.1::rsync
# rsync -rvp src/ rsync://rsync@192.168.1.1/rsync
```

- 显示所有模块

```shell
rsync -rvP $src/ rsync://$user@$ip/
rsync -rvP $src/ $user@$ip::
# 例子
# rsync -rvp src/ rsync://rsync@10.69.202.146/
# rsync -rvp src/ rsync@10.69.202.146::
```

- 使用变量的方式传入密码

```shell
RSYNC_PASSWORD=$passwd rsync -rvP $src/ $user@$ip::$module
# 例子
# RSYNC_PASSWORD=123456 rsync -rvp src/ rsync@192.168.1.1::rsync   
```

- 使用文件传入密码

- 创建密码文件,权限需要600,这个文件的格式和服务端的不一致

```shell
echo "123456" > rsync.passwd
chown 600 rsync.passwd
```

- 格式

```shell
rsync -rvp $src/ $user@$addr::$module --password-file=$paaswdfile
# 例子
# rsync -rvp src/ rsync@192.168.1.1::rsync --password-file=rsync.passwd
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

- --existing 只传输目标有的的

- --ignore-existing 只传输目标没有的

#### 设置带宽

- --bwlimit 设置带宽,单位是KB/s

```shell
rsync -rv --bwlimit=1000  $src $dest
```

#### 文件过滤

- --include指定同步的文件

```shell
# 排除日志文件
rsync -rv --include="*.dat" $src $dest
```

- --exclude排除同步的文件

```shell
# 排除日志文件
rsync -rv --exclude="*.log" $src $dest
```

#### 增量备份

- --link-dest=$DIR 和基准目录不一样的文件创建链接,注意这个目录需要时`绝对路径`

```shell
rsync -a -v --link-dest=$base $src $dest
```

#### 参考资料

<https://www.ruanyifeng.com/blog/2020/08/rsync.html>
