title: logrotate
author: Nature丿灵然
tags:
  - log
date: 2020-12-14 15:20:00
---
Linux系统随着时间日志越来越大，我们需要日志转储和处理以免导致磁盘爆满

<!--more-->

> logrotate是一个日志转储工具，centos默认安装并且根据策略每天执行一次

#### 安装

> 一般cnetos都是默认安装如果没有安装执行：

```shell
yum install logrotate
```

#### 常用参数

- -d 调试 logrotate -d /etc/logrotate.conf
- -f 强制运行 logrotate -f /etc/logrotate.conf
- -s 启动备用备用状态文件默认文件在`/var/lib/logrotate/logrotate.status`
- -v 详细模式
- 指定logrotate的状态文件 logrotate -vf –s /var/log/logrotate-status /etc/logrotate.conf 日志文件

#### 默认运行机制

> crontab执行`/etc/cron.daily`下的`logrotate`脚本,由脚本调用logrotate执行配置目录和配置文件下的任务

#### 配置解释

> 配置文件在`/etc/logrotate.conf`配置目录在`/etc/logrotate.d/`
> logrotate.d目录防止其他程序的配置文件比如syslog

##### 配置文件

```conf
# see "man logrotate" for details                                      # 详细情况执行`man logrotate
# rotate log files weekly                                              # 日志文件每周转储一次（全局配置）
weekly

# keep 4 weeks worth of backlogs                                       # 保存4个转储周期
rotate 4

# create new (empty) log files after rotating old ones                 # 转储模式为create
create

# use date as a suffix of the rotated file                             # 转储的文件以日期最为后缀
dateext

# uncomment this if you want your log files compressed                 # 是否压缩
compress

# RPM packages drop log rotation information into this directory       # 导入配置目录
include /etc/logrotate.d

# system-specific logs may be also be configured here.

```

##### 配置目录

> 配置目录`syslog`为例：

```conf
/var/log/cron
/var/log/maillog
/var/log/messages
/var/log/secure
/var/log/spooler
/var/log/kern.log   # 目标日志文件
{
    daily           # 执行周期还可以填写weekly,monthly，yearly
    missingok       # 转储时忽略日志错误
    sharedscripts   # 运行postrotate脚本，作用是在所有日志都轮转后统一执行一次脚本。如果没有配置这个，那么每个日志轮转后都会执行一次脚本
    postrotate      # 脚本开始
        /usr/bin/systemctl kill -s HUP rsyslog.service >/dev/null 2>&1 || true
    endscript       # 脚本结束
```

###### 其他重要参数说明

- compress                   通过gzip压缩日志
- nocompress                 不做gzip压缩处理
- copytruncate               用于还在打开中的日志文件，把当前日志备份并截断；是先拷贝再清空的方式，拷贝和清空之间有一个时间差，可能会丢失部分日志数据。
- nocopytruncate             备份日志文件不过不截断
- create mode owner group    轮转时指定创建新文件的属性，如create 0777 nobody nobody
- nocreate                   不建立新的日志文件
- delaycompress              和compress 一起使用时，转储的日志文件到下一次转储时才压缩
- nodelaycompress            覆盖 delaycompress 选项，转储同时压缩。
- missingok                  如果日志丢失，不报错继续滚动下一个日志
- errors address             专储时的错误信息发送到指定的Email 地址
- ifempty                    即使日志文件为空文件也做轮转，这个是logrotate的缺省选项。
- notifempty                 当日志文件为空时，不进行轮转
- mail address               把转储的日志文件发送到指定的E-mail 地址
- nomail                     转储时不发送日志文件
- olddir directory           转储后的日志文件放入指定的目录，必须和当前日志文件在同一个文件系统
- noolddir                   转储后的日志文件和当前日志文件放在同一个目录下
- sharedscripts              运行postrotate脚本，作用是在所有日志都轮转后统一执行一次脚本。如果没有配置这个，那么每个日志轮转后都会执行一次脚本
- prerotate                  在logrotate转储之前需要执行的指令，例如修改文件的属性等动作；必须独立成行
- postrotate                 在logrotate转储之后需要执行的指令，例如重新启动 (kill -HUP) 某个服务！必须独立成行
- daily                      指定转储周期为每天
- weekly                     指定转储周期为每周
- monthly                    指定转储周期为每月
- rotate count               指定日志文件删除之前转储的次数，0 指没有备份，5 指保留5 个备份
- dateext                    使用当期日期作为命名格式
- dateformat .%s             配合dateext使用，紧跟在下一行出现，定义文件转储后的文件名，配合dateext使用，只支持 %Y %m %d %s 这四个参数
- size(或minsize) log-size   日志文件超过多少之后就转储，可以是 100 100K  100M 100G这都是有效的

#### 参考资料

<https://wsgzao.github.io/post/logrotate>
<https://www.cnblogs.com/kevingrace/p/6307298.html>
`man logrotate`
