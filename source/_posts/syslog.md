title: syslog
author: Nature丿灵然
tags:
  - 日志
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
> 下面以`centos8`为例解释

```conf
#### MODULES ####                                                                                      # 模块设置

module(load="imuxsock" # provides support for local system logging (e.g. via logger command)           # 提供对本地命令支持如：logger
       SysSock.Use="off") # Turn off message reception via local log socket;                           # 关闭本地套接字接受
# local messages are retrieved through imjournal now.                                                  # 从systemd-journal获取消息
module(load="imjournal" # provides access to the systemd journal                                       
       StateFile="imjournal.state") # File to store the position in the journal                        #
#module(load="imklog") # reads kernel messages (the same are read from journald)                       # 读取内核消息，有一些来自journald
#module(load="immark") # provides --MARK-- message capability                                          # MARK消息

# Provides UDP syslog reception                                                                        # 接受udp syslog消息
# for parameters see http://www.rsyslog.com/doc/imudp.html
#module(load="imudp") # needs to be done just once                                                     # 只需要做一次
#input(type="imudp" port="514")

# Provides TCP syslog reception                                                                        # 接受tpc syslog消息
# for parameters see http://www.rsyslog.com/doc/imtcp.html
#module(load="imtcp") # needs to be done just once
#input(type="imtcp" port="514")

#### GLOBAL DIRECTIVES ####                                                                            # 全局目录设置

# Where to place auxiliary files                                                                       # 在那放辅助文件
global(workDirectory="/var/lib/rsyslog")

# Use default timestamp format                                                                         # 使用默认的时间戳格式
module(load="builtin:omfile" Template="RSYSLOG_TraditionalFileFormat")

# Include all config files in /etc/rsyslog.d/                                                          # 导入目录下的所有文件
include(file="/etc/rsyslog.d/*.conf" mode="optional")

#### RULES ####                                                                                        # 规则文件

# Log all kernel messages to the console.                                                              # 收集内核日志到控制台
# Logging much else clutters up the screen.                                                            # 日志太多会把屏幕弄乱
#kern.*                                                 /dev/console

# Log anything (except mail) of level info or higher.                                                  # 记录任何除了邮件的日志
# Don't log private authentication messages!                                                           # 不要记录认真消息
*.info;mail.none;authpriv.none;cron.none                /var/log/messages

# The authpriv file has restricted access.                                                             # 认证相关的消息存放的路径
authpriv.*                                              /var/log/secure

# Log all the mail messages in one place.                                                              # 所有的右键消息存放位置，- 表示异步因为数据库比较多
mail.*                                                  -/var/log/maillog


# Log cron stuff                                                                                       # 定时任务的日志
cron.*                                                  /var/log/cron

# Everybody gets emergency messages                                                                    # 记录所有的大于等于emerg级别信息, 以wall方式发送给每个登录到系统的人
*.emerg                                                 :omusrmsg:*

# Save news errors of level crit and higher in a special file.                                         # 记录uucp,news.crit等存放在/var/log/spooler
uucp,news.crit                                          /var/log/spooler

# Save boot messages also to boot.log                                                                  # 启动相关的消息
local7.*                                                /var/log/boot.log

# ### sample forwarding rule ###                                                                       # 转发规则
#action(type="omfwd"  
# An on-disk queue is created for this action. If the remote host is                                   # 为此操作创建一个磁盘队列。 如果远程主机是down掉，消息被假脱机到磁盘，并在重新启动时发送。
# down, messages are spooled to disk and sent when it is up again.
#queue.filename="fwdRule1"       # unique name prefix for spool files                                  # 假脱机文件的唯一名称前缀
#queue.maxdiskspace="1g"         # 1gb space limit (use as much as possible)                           # 最多1gb的空间(尽可能多的使用)
#queue.saveonshutdown="on"       # save messages to disk on shutdown                                   # 关机是保存消息到磁盘
#queue.type="LinkedList"         # run asynchronously                                                  # 使用链接列表模式
#action.resumeRetryCount="-1"    # infinite retries if host is down                                    # 主机关机则无限重试
# Remote Logging (we use TCP for reliable delivery)                                                    # 远程日志，（使用可靠的tcp）
# remote_host is: name/ip, e.g. 192.168.0.1, port optional e.g. 10514                                  # 远程机器是名字/ip
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
