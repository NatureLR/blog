title: ansible基本使用
author: Nature丿灵然
tags:
  - ansible
categories:
  - 运维
date: 2020-12-16 13:26:00
---
ansible是一个自动化运维工具，可以实现批量配置，部署，命令等功能

<!--more-->

#### 安装

yum 安装

```shell
yum -y install ansible
```

pip安装

```shell
pip install ansible
```

#### 配置路径

默认读取`/etc/ansible/`目录下的`主机清单`和`规则`

#### 主机清单

> 记录ansible需要执行操作的目标机器文件，默认读取`/etc/ansible/hosts`，一般通过 `-i`参数指定,也可以分类写到一个文件夹下

- \#开头为注释
- 忽略空行
- 组由[组名]定义
- 主机名和域名都可以
- 一个ip或域名可以是组的成员
- 没有分组的主机写在任意的一个组的前面

##### 连续IP

```conf
# 等价于 192.168.1.1 192.168.1.2 192.168.1.2 192.168.1.3 192.168.1.4等等
192.168.1.[1:4]

# 等价于 server1.example.com server2.example.com server3.example.com等等
server[1:3].example.com
```

##### 参数

```conf
192.168.1.1 ansible_ssh_user=root ansible_ssh_pass=root
```

###### 常用参数

- ansible_ssh_host              目标主机地址
- ansible_ssh_port              目标主机端口，默认22
- ansible_ssh_user              目标主机用户
- ansible_ssh_pass              目标主机ssh密码
- ansible_sudo_pass             sudo密码
- ansible_sudo_exe
- ansible_connection            与主机的连接类型，比如：local,ssh或者paramiko
- ansible_ssh_private_key_file  私钥地址
- ansible_shell_type            目标系统的shell类型
- ansible_python_interpreter    python版本

##### 别名

```conf
test1 ansible_ssh_port=22 ansible_ssh_host=192.168.1.1 ansible_ssh_user=root  　　# 别名test1
```

##### 主机组

```conf
[foo]
192.168.1.1
192.168.2.1
```

##### 主机组嵌套

```conf
[db]
192.168.1.1

[server]
192.168.2.1

[all:children]
db
server
```

##### 主机组参数

```conf
[test]
name1 ansible_ssh_host=192.168.1.[1:3]

[test:vars]
ansible_ssh_user=root
ansible_ssh_pass="root"
testvar="test"
```

#### 模块

> ansible的功能都是通过模块来完成的 \
> `ansible-doc -s <模块名>`查看模块的参数 \
> `ansible-doc -l` 查看所有模块

##### 常用模块

> 参数中的`free_form`是各个模块的命令或args，并不是一个存在的参数

###### command

> 在目标主机上执行命令

- 参数：
  - free_form              必选表在目标机器上执行的命令
  - chdir                  在目标主机的哪里执行命令
  - creates                文件存在时就不执行此命令
  - removes                和creates相反存在时就执行
- 例子：ansible test -m command -a "chdir=/var/log removes=kern.log cat kern.log" /var/log下kern.log存在就查看kern.log

###### shell

>和command一样不过command不支持重定向等管道操作，shell会调用`/bin/sh`执行

- 参数：  
  - free_form:             执行的命令
  - chdir:                 改变运行执行的目录
  - creates:               文件存在则不就不执行命令
  - executable:            改变命令说用的shell解释器，默认为/bin/sh
  - removes:               和creates相反存在时就执行
- 例子：ansible  test -m shell -a "cat /etc/hosts"

###### script

> 在目标主机上执行本地主机的脚本

- 参数：
  - free_form:             需要执行的脚本路径
  - chdir:                 执行脚本的目录
  - creates:               目标机器的文件存在则不执行
  - removes:               目标机器的文件存在则不执行
- 例子： ansible test -m script -a "test.sh"

###### copy

> 复制本地文件或文件夹到目标主机上

- 参数：
  - src：                   指定需要copy的文件或目录
  - dest：                  文件将被拷贝到目标主机的哪个目录中，dest为必须参数
  - content                 不适用src时用此参数写入内容
  - force:                  目标主机路径已经有文件且内容不相同时是否覆盖
  - backup:                 目标主机已经有文件且内容不同时是否备份
  - owner:                  拷贝到目标主机后的所有者
  - group:                  拷贝到目标主机后的属组
  - mode:                   拷贝到目标主机后的权限
- 例子： ansible test -m copy -a "src=/root/test.sh dest=/tmp"

###### file

> 对目标主机的文件管理

- 参数：
  - path：                  指定目标目录或文件
  - state：
    - directory：           如果目录不存在，创建目录
    - file：                即使文件不存在，也不会被创建
    - link：                创建软连接
    - hard：                创建硬连接
    - touch：               如果文件不存在，则会创建一个新的文件，如果文件或目录已存在，则更新其最后修改时
    - absent：              删除目录、文件或者取消链接文
  - src：                   当state设置为link或者hard时，需要操作的源文件
  - force:                  需要在两种情况下强制创建软连接，一种是源文件不存在但之后会建立的情况下；另一种是目标连接已存在，需要先取消之前的软连接，有两个选项：yes|no
  - owner：                 指定被操作文件的所有者，
  - group：                 指定被操作文件的所属组
  - mode：                  权限
  - recurse：               文件为目录时，递归目录
- 例子：
  - 设置权限为777所属组为minikube所有者为：ansible test -m file -a "path=/tmp/test.sh  mode=777 owner=minikube group=minikube"
  - 创建`/etc/hosts`的软连接到home目录：ansible test -m file -a "path=/root/hosts  src=/etc/hosts state=link"

###### blockinfile

> 在指定的文件里修改一段文本

- 参数：
  - path：                 必须参数，指定要操作的文件
  - block：                指定要操作的一段文本
  - marker：               ansibel默认修改时会添加一个以#开头标记，可以改为自定义
  - state:                 present为插入或者更新;absent删除
  - insertafter：          默认会将文本插入到指定的位置的后面
  - insertbefore：         默认会将文本插入到指定的位置的前面
  - backup：               是否在修改文件之前对文件进行备份。
  - create：               当要操作的文件并不存在时，是否创建对应的文件。
- 例子：
  - 在目标主机的/tmp/test文件中插入ansible-test且标记内容为teststart：ansible localhost -m blockinfile -a "path=/tmp/test block=ansible-test marker='#{mark}teststart'"

###### lineinfile

> 和`blockinfile`相似不过是一行还可以使用正则表达式

- 参数：
  - path：                  必须参数，指定要操作的文件
  - line:                   要指定的文本内容
  - regexp：                正则匹配对应的行，当替换文本时，如果有多行文本都能被匹配，则只有最后面被匹配到的那行文本才会被替换，当删除文本时，如果有多行文本都能被匹配，这么这些行都会被删除
  - state：                 absent为删除，state的默认值为present
  - backrefs：              在使用正则匹配时如果没有匹配到默认会在文件的末尾插入要替换的文本，设置为yes则不会
  - insertafter：           默认会将文本插入到指定的位置的后面
  - insertbefore：          默认会将文本插入到指定的位置的前面
  - backup：                是否在修改文件之前对文件进行备份
  - create：                当要操作的文件并不存在时，是否创建对应的文件
-例子：
  - 将/tmp/test的文件中#kern开头行换成kern.\* /var/log/kern.log:ansible localhost -m lineinfile -a 'path=/tmp/test regexp="^#kern" line="kern.* /var/log/kern.log"'

###### replace

> 文本替换模块

- 参数：
  - path：                 必须参数，指定要操作的文件，2.3版本之前，只能使用dest, destfile, name指定要操作的文件，2.4版本中，仍然可以使用这些参数名，这些参数名作为path参数的别名使用。
  - regexp:                必须参数，指定一个python正则表达式，文件中与正则匹配的字符串将会被替换。
  - replace：              指定最终要替换成的字符串。
  - backup：               是否在修改文件之前对文件进行备份，最好设置为yes。
- 例子：将/etc/test文件中所有的`localhost`换成`FOO`: ansible localhost -m replace -a 'path=/tmp/test  regexp="localhost" replace=foo'

###### systemd

> 运行systemd相关的命令

- 参数：
  - enabled:               是否设置为开机启动
  - name:                  systemd模块名字
  - state:                 想要设置的状态，比如`restartd`重启`started`启动、`stopped`停止、`reloaded`重新加载
  - daemon_reload:         运行daemon-reload命令
  - daemon_reexec:         运行daemon_reexec命令
- 例子：ansible test -m systemd -a "name=rsyslog state=restarted"

###### yum

> yum包管理

- 参数：
  - action: yum
  - conf_file              yum的配置文件
  - disable_gpg_check      关闭gpg_check
  - disablerepo            不启用某个源
  - enablerepo             启用某个源
  - name                   指定要安装的包，如果有多个版本需要指定版本，否则安装最新的包
  - state                  安装:`present`，安装最新版:`latest`，卸载程序包:`absent`
- 例子: 安装最新版psree命令：ansible localhost -m yum -a "name=psmisc state=latest"

###### cron

> 定时模块

- 参数：
  - backup                 如果设置，创建一个crontab备份
  - cron_file              如果指定, 使用这个文件cron.d，而不是单个用户crontab
  - day                    日应该运行的工作( 1-31, \*, */2, etc )
  - hour                   小时 ( 0-23, \*, \*/2, etc )
  - job                    指明运行的命令是什么
  - minute                 分钟( 0-59, \*, \*/2, etc )
  - month                  月( 1-12, \*, \*/2, etc )
  - name                   定时任务描述
  - reboot                 任务在重启时运行，不建议使用，建议使用special_time
  - special_time           特殊的时间范围，参数：reboot（重启时）,annually（每年）,monthly（每月）,weekly（每周）,daily（每天）,hourly（每小时）
  - state                  指定状态，默认`prsent`添加定时任务，`absent`删除定时任务
  - user                   以哪个用户的身份执行
  - weekday                周 ( 0-6 for Sunday-Saturday, *, etc )
- 例子：
  - 每天8点半执行cat /etc/hosts这个命令：ansible localhost -m cron -a "name=test minute=30 hour=8 day=* job='cat /etc/hosts'"
  - 删除test这个cronjob：ansible localhost -m cron -a "name=test state=absent"
  - 重启时rm -rf /tmp命令： ansible test -m cron -a 'name="test" special_time=reboot job="rm -rf /tmp"'

#### 执行命令

```shell
# ansible <主机> -m <模块> -a <模块参数>
ansible <主机> -m shell -a "cat /etc/hosts"
```

##### 指定某些机器执行

ansbile <主机组> -m <模块> -a <参数> --limit <主机>  指定执行主机
ansbile <主机组> -m <模块> -a <参数> --limit <!主机> 排除执行的主机
ansbile <主机组> -m <模块> -a <参数> --limit <主机1：主机2> 只在主机1和主机2中执行

#### playbook

> 剧本就是一系列ansible命令组合类似shell脚本和shell命令

一个将内核日志输出到/var/log/kern.log的剧本

```yaml
---
- hosts: all                 # 要执行的主机组
  tasks:
  - name: 修改rsyslog配置文件 # 任务名字
    tags: rsyslog            # 任务标签
    lineinfile:              # 任务模块
       dest: /etc/rsyslog.conf
       regexp: "{{ item.regexp }}"
       line: "{{ item.line }}"
    with_items:              # 循环执行
     - { regexp: '^#kern',line: 'kern.* /var/log/kern.log' }
     - { regexp: '^#\$ModLoad imklog',line: '$ModLoad imklog' }
     - { regexp: '^#\$ModLoad imjournal',line: '$ModLoad imjournal' }
  - name: 修改logrotate的syslog配置
    shell: sed -i '1i\\/var\/log\/kern.log' /etc/logrotate.d/syslog
    tags: logrotate
  - name: 重启rsyslog服务
    tags: rsyslog
    systemd:
      name: rsyslog
      state: restarted
      enabled: yes
```

##### tags

> 标签可以灵活的选择执行那些task或其他的对象

特殊的标签：

- always 当把标签设置为always即使使用--tags指定tags任务也会执行，可以使用--skip-tags always跳过
- never  和always相反即使用--tags指定也不会执行
- tagged 只执行有标签的任务
- untagged 只执行未打标签的含有always也会执行
- all 所有都执行不用指定

```yaml
---
- hosts: test
  remote_user: root
  tasks:
    - name: 创建文件test1
      tags: test1
      file:
        path: /tmp/test1
        state: touch
    - name: 创建文件test2
      tags: always
      file:
        path: /tmp/test2
        state: touch
    - name: 创建文件test3
      file:
        path: /tmp/test3
        state: touch
```

##### 变量

```yaml
---
- hosts: test
  remote_user: root
  vars:
    path: /tmp/
  tasks:
    - name: 创建文件test1
      tags: test1
      file:
        path: "{{ path }}test1"
        state: touch
```

##### DEBUG

> 调试打印

```yaml
---
- hosts: test
  remote_user: root
  vars:
    path: /tmp/
  tasks:
    - name: 创建文件test1
      tags: test1
      file:
        path: "{{ path }}test1"
        state: touch
    - name: print var
      debug:
        var: path
    - name: msg
      debug:
        msg: this is debug info,The test file has been touched
```

##### 循环

##### 判断

##### handler

> 在上面的例子中无论前面修改配置文件是否修改都会执行rsyslog重启，这样有些不妥 \
> handler的执行顺序与被notify的顺序无关

```yaml
# 这样只有配置文件真正被修改了才会执行重启
---
- hosts: test
  remote_user: root
  tasks:
    - name: 修改rsyslog配置文件
      tags: rsyslog
      lineinfile:
         dest: /etc/rsyslog.conf
         regexp: ^#kern
         line: kern.* /var/log/kern.log
      notify:                # 引用handlers
        重启rsyslog服务
  handlers:                  # 和tasks同级
    - name: 重启rsyslog服务
      systemd:
         name: rsyslog
         state: restarted
         enabled: yes
```

> meta关键字可以让notify之后立刻执行handlers

```yaml
---
- hosts: test
  remote_user: root
  tasks:
    - name: 修改rsyslog配置文件
      tags: rsyslog
      lineinfile:
         dest: /etc/rsyslog.conf
         regexp: ^#kern
         line: kern.* /var/log/kern.log
      notify:
        重启rsyslog服务
    - meta: flush_handlers
    
    - name: 查看配置文件状态
      shell: cat /etc/rsyslog.conf |grep "kern.\*"
      register: ps
    - debug: msg={{ ps.stdout }}

  handlers:
    - name: 重启rsyslog服务
      systemd:
         name: rsyslog
         state: restarted
         enabled: yes
```

> listen handlers组

```yaml
---
- hosts: test
  remote_user: root
  tasks:
    - name: 修改rsyslog配置文件
      tags: rsyslog
      lineinfile:
         dest: /etc/rsyslog.conf
         regexp: ^#kern
         line: kern.* /var/log/kern.log
      notify:
         handler group1 # 通知了handler group1
    - meta: flush_handlers 

    - name: 查看配置文件状态
      shell: cat /etc/rsyslog.conf |grep "kern.\*"
      register: ps
    - debug: msg={{ ps.stdout }}

  handlers:
    - name: 重启rsyslog服务
      listen: handler group1
      systemd:
        name: rsyslog
        state: restarted
        enabled: yes
    - name: 创建测试文件
      listen: handler group1
      file:
        path: /tmp/test
        state: touch
```

##### include && import tasks

> 当task越来越多的时候如果都在一个文件不是很好管理，将一些相关性很强的写到一个文件然后引用另外的yaml文件 \
> import_tasks静态的，在playbook解析阶段将所有文件中的变量读取加载 \
> include_tasks动态则是在执行playbook之前才会加载自己变量

```yaml
---
- hosts: test
  remote_user: root
  tasks:
    - name: 修改rsyslog配置文件
      tags: rsyslog
      lineinfile:
         dest: /etc/rsyslog.conf
         regexp: ^#kern
         line: kern.* /var/log/kern.log
    - name: 查看配置文件状态
      import_tasks: config.yaml
---
# config.yaml
- name: 查看配置文件状态
  shell: cat /etc/rsyslog.conf |grep "kern.\*"
  register: ps
- debug: msg={{ ps.stdout }}
```

#### 参考资料

<https://docs.ansible.com/>
<http://www.ansible.com.cn/>
