title: iptables
author: Nature丿灵然
date: 2020-12-03 17:16:35
tags:
---
### iptables

> iptables是大多数发型版本中支持的防火墙,iptables是个前端其真正的后端是linux的netfilter框架

#### 链

> 在linuxn内核中的五个钩子(hook)，iptable中还可以自定义链，自定义只能被默认链引用才能使用

- INPUT 发送到用户空间的钩子
- OUTPUT 从用户空间发发出的钩子
- PREROUTING 路由前的钩子
- FORWARD 转发的钩子
- POSTROUTING 路由后的钩子

#### 表

- filter表：负责过滤功能，防火墙；内核模块：iptables_filter
- nat表：network address translation，网络地址转换功能；内核模块：
iptable_nat
- mangle表：拆解报文，做出修改，并重新封装 的功能；iptable_mangle
- raw表：关闭nat表上启用的连接追踪机制；iptable_raw

#### 查看规则

```sehll
iptables --line-numbers -nvL -t <表>
iptables --line-numbers -nv -L <链> -t <表>
```
![images](/images/pasted-10.png)

##### 命令说明
- -L 列出规则,L后面可也接受指定链
- -v 可以查看更多的信息
- -n 不对地址做名称反解 直接显示原来的IP地址
- -t 执行表名，默认为`filter`表
- --line-numbers 显示规则序列号,缩写为--line
- -x 精确数值
##### 返回说明
- 红色部分：
	- chain：链名，括号里的policy默认策略这里是drop
	- packets：默认策略匹配到的包的数量
	- bytes：当前链默认策略匹配到的所有包的大小总和
- 绿色部分：
 	- bytes:对应匹配到的报文包的大小总和
 	- target:规则对应的target，往往表示规则对应的"动作"，即规则匹配成功后需要采取的措施
 	- prot:表示规则对应的协议，是否只针对某些协议应用此规则
 	- opt:表示规则对应的选项
 	- in:表示数据包由哪个接口(网卡)流入
 	- out:表示数据包由哪个接口(网卡)流出
 	- source:表示规则对应的源头IP或网段
 	- destination:表示规则对应的目标IP或网段
- 黄色部分：规则序列号

#### 增加规则

> iptables是自上而下匹配规则的所以顺序很重要 \
> -A 尾部增加 \
> -I 头部增加 后面加上序列号则是指定序列号位置 

##### 尾部增加规则
在 filter表INPUT链中`尾部`增加一条丢弃从192.168.1.1发送过来数据的规则
```Shell
# iptables -t <表名> -A <链名> <匹配条件> -j <动作>
iptables -t filter -A INPUT -s 192.168.1.1 -j DROP
``` 
##### 头部增加规则
在 filter表INPUT链中`头部`增加一条丢弃从192.168.1.2发送过来数据的规则
```shell
# iptables -t <表名> -I <链名> <匹配条件> -j <动作>
iptables -t filter -I INPUT -s 192.168.1.2 -j DROP
```

##### 指定位置增加规则
在 filter表INPUT链中`指定位置`增加一条丢弃从192.168.1.3发送过来数据的规则
```shell
# iptables -t <表名> -I <链名> <规则序号>  <匹配条件> -j <动作>
iptables -t filter -I INPUT  3 -s 192.168.1.2 -j DROP
```

#### 修改规则

将序列号为2的规则的动作修改为accept
```shell
# iptables -t <表名> -R <链名> <规则序号> <原本的匹配条件> -j <动作>
iptables -t filter -R INPUT 2 -s 192.168.1.146 -j ACCEPT
```
#### 删除规则

##### 按照规则序号删除规则

```Shell
# iptables -t <表名> -D <链名> <规则序号>
iptables -t filter -D INPUT 3
```
##### 按照具体的匹配条件与动作删除规则
```Shell
# iptables -t <表名> -D <链名> <匹配条件> -j <动作>
iptables -t filter -D INPUT -s 192.168.1.2 -j DROP
```
##### 删除所有规则

> 谨慎操作！！！

清除filter表
```Shell
# iptables -t <表名> -F
iptables -t filter -F
```

#### 参考资料

[朱双印个人博客](http://www.zsythink.net/archives/category/%e8%bf%90%e7%bb%b4%e7%9b%b8%e5%85%b3/iptables/)
