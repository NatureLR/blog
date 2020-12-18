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

- \# 开头为注释
- 忽略空行
- 组由\[组名\]定义
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

###### 命令类模块

> command模块：在目标主机上执行命令

- 参数：
  - free_form 必选表在目标机器上执行的命令
  - chdir 在目标主机的哪里执行命令
  - creates 文件存在时就不执行此命令
  - removes 和creates相反存在时就执行
- 例子：ansible test -m command -a "chdir=/var/log removes=kern.log cat kern.log" /var/log下kern.log存在就查看kern.log

> shell模块：和command一样不过command不支持重定向等管道操作，shell会调用`/bin/sh`执行

- 参数：  
  - free_form:             # The shell module takes a free form command to run, as a string. There is no actual parameter named 'free form'. See the examples on how to use this module.
  - chdir:改变运行执行的目录
  - cmd:                   # The command to run followed by optional arguments.
  - creates:               # A filename, when it already exists, this step will *not* be run.
  - executable:            # Change the shell used to execute the command. This expects an absolute path to the executable.
  - removes:               # A filename, when it does not exist, this step will *not* be run.
  - stdin:                 # Set the stdin of the command directly to the specified value.
  - stdin_add_newline:     # Whether to append a newline to stdin data.
  - warn:                  # Whether to enable task warnings.
- 例子：ansible  test -m shell -a "cat /etc/hosts"

> script

- ansible test -m script -a "cat /etc/hosts"

###### 文件类模块

###### 系统类模块

#### 执行命令

```shell
# ansible <主机> -m <模块> -a <模块参数>
ansible <主机> -m shell -a "cat /etc/hosts"
```

##### 指定某些机器执行

ansbile <主机> -m <模块> -a <参数> --limit <主机>  指定执行主机
ansbile <主机> -m <模块> -a <参数> --limit <!主机> 排除执行的主机
ansbile <主机> -m <模块> -a <参数> --limit <主机1：主机2> 只在主机1和主机2中执行

#### playbook编写

> 剧本就是一系列ansible命令组合类似shell脚本

```yaml
---
- hosts: all
  tasks:
  - name: 修改rsyslog配置文件
    tags: rsyslog
    lineinfile:
       dest: /etc/rsyslog.conf
       regexp: "{{ item.regexp }}"
       line: "{{ item.line }}"
    with_items:
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

#### 参考资料

<https://docs.ansible.com/>
<http://www.ansible.com.cn/>
