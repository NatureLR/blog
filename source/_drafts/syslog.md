title: syslog
author: Nature丿灵然
tags:
  - 日志
categories:
  - 运维
date: 2020-12-08 14:14:00
---
syslog是linux系统中常见得日志系统配合systemd-Journal使用
<!--more-->
rsyslogd是syslog的改进版本，可以将日志通过`syslog`协议发送到日志服务器

#### 查看log

> `/var/log/`下各个文件,根据配置文件设置使用`grep`查找 \
> 某些路径可以通过配置文件修改

- boot.log 系统启动日志
- message 包含整个系统的信息，mail, cron, daemon, kern, auth等相关的日志信息
- dmesg 开机启动内核缓冲日志，可以使用`dmesg`命令直接查看
- maillog mail.log 邮件服务日志
- yum.log yum安装的日志
- dnf.log centos8中使用dnf来代替yum
- cron crontab定时任务的日志
- btmp 尝试登录失败的信息，也可以使用`last -f /var/log/btmp`
- wtmp 登录信息，使用`last -f /var/log/wtmp`查看
- lastlog 最近用户登录信息，不是文本文件使用命令`lastlog`直接查看
- spooler linux 新闻群组方面的日志，内容一般是空的
- sssd 系统守护进程安全日志
- tuned 系统调优工具tuned的日志
- anaconda.log 存储安装相关的信息
- journal systemd-journal日志，使用journalctl查看
  
#### 配置文件

> syslog的配置目录在`/etc/rsyslog.conf`和`/etc/rsyslog.d/`之中，`/etc/rsyslog.conf`是默认配置的文件

```conf
#### MODULES ####                                                                               # 模块设置

module(load="imuxsock" # provides support for local system logging (e.g. via logger command)    # 提供对本地命令支持如：logger
       SysSock.Use="off") # Turn off message reception via local log socket;                    # 关闭本地套接字接受
# local messages are retrieved through imjournal now.                                           # 
module(load="imjournal" 	    # provides access to the systemd journal                          #
       StateFile="imjournal.state") # File to store the position in the journal                 #
#module(load="imklog") # reads kernel messages (the same are read from journald)                #
#module(load="immark") # provides --MARK-- message capability                                   #

# Provides UDP syslog reception                                                                 #
# for parameters see http://www.rsyslog.com/doc/imudp.html
#module(load="imudp") # needs to be done just once
#input(type="imudp" port="514")

# Provides TCP syslog reception
# for parameters see http://www.rsyslog.com/doc/imtcp.html
#module(load="imtcp") # needs to be done just once
#input(type="imtcp" port="514")

#### GLOBAL DIRECTIVES ####

# Where to place auxiliary files
global(workDirectory="/var/lib/rsyslog")

# Use default timestamp format
module(load="builtin:omfile" Template="RSYSLOG_TraditionalFileFormat")

# Include all config files in /etc/rsyslog.d/
include(file="/etc/rsyslog.d/*.conf" mode="optional")

#### RULES ####

# Log all kernel messages to the console.
# Logging much else clutters up the screen.
kern.*                                                 /dev/console

# Log anything (except mail) of level info or higher.
# Don't log private authentication messages!
*.info;mail.none;authpriv.none;cron.none                /var/log/messages

# The authpriv file has restricted access.
authpriv.*                                              /var/log/secure

# Log all the mail messages in one place.
mail.*                                                  -/var/log/maillog


# Log cron stuff
cron.*                                                  /var/log/cron

# Everybody gets emergency messages
*.emerg                                                 :omusrmsg:*

# Save news errors of level crit and higher in a special file.
uucp,news.crit                                          /var/log/spooler

# Save boot messages also to boot.log
local7.*                                                /var/log/boot.log

# ### sample forwarding rule ###
#action(type="omfwd"  
# An on-disk queue is created for this action. If the remote host is
# down, messages are spooled to disk and sent when it is up again.
#queue.filename="fwdRule1"       # unique name prefix for spool files
#queue.maxdiskspace="1g"         # 1gb space limit (use as much as possible)
#queue.saveonshutdown="on"       # save messages to disk on shutdown
#queue.type="LinkedList"         # run asynchronously
#action.resumeRetryCount="-1"    # infinite retries if host is down
# Remote Logging (we use TCP for reliable delivery)
# remote_host is: name/ip, e.g. 192.168.0.1, port optional e.g. 10514
#Target="remote_host" Port="XXX" Protocol="tcp")
```

#### 常见操作

```shell
# 查看状态
systemctl status rsyslog
# 重启
systemctl restart rsyslog
# 停止
systemctl stop rsyslog
```

#### 参考资料

<https://www.debugger.wiki/article/html/1563278670670182>
<https://www.cnblogs.com/bonelee/p/9477544.html>
<https://blog.espnlol.com/?p=599>
<https://www.cnblogs.com/cherishry/p/6775163.html>
