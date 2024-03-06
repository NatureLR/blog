layout: draft
title: linux内核升级
author: Nature丿灵然
tags:
  - 内核
date: 2022-05-02 16:23:00
---
centos内核升级

<!--more-->

> 升级centos内核

#### 包管理安装

##### 添加epel仓库

```shell
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm

yum --enablerepo="elrepo-kernel" list --showduplicates | sort -r | grep kernel-ml.x86_64
```

###### 替换清华源

```shell
# 备份
sudo cp /etc/yum.repos.d/elrepo.repo /etc/yum.repos.d/elrepo.repo.bak

# 然后编辑 /etc/yum.repos.d/elrepo.repo 文件，在 mirrorlist= 开头的行前面加 # 注释掉；
sed  -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/elrepo.repo

# 并将 elrepo.org/linux 替换为 mirrors.tuna.tsinghua.edu.cn/elrepo
sed -i 's/elrepo.org\/linux/mirrors.tuna.tsinghua.edu.cn\/elrepo/g' /etc/yum.repos.d/elrepo.repo

# 注释掉其他仓库
sed  -i '/http:\/\/mirrors.coreix/d' /etc/yum.repos.d/elrepo.repo
sed  -i '/http:\/\/mirror.rackspace.com/d' /etc/yum.repos.d/elrepo.repo
sed  -i '/http:\/\/repos.lax-noc.com/d' /etc/yum.repos.d/elrepo.repo

# 更新软件包缓存
sudo yum makecache
```

##### 安装内核

```shell
# 稳定版本
yum --enablerepo=elrepo-kernel install  kernel-ml-devel kernel-ml -y

# 安装长期支持版本
yum --enablerepo=elrepo-kernel install kernel-lt-devel kernel-lt -y
```

##### 设置启动

```shell
# 查看安装的内核
awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg

# 设置启动顺序
grub2-set-default 0

# 重启生效
reboot

```

#### 源码安装

##### 下载源码

{% note info %}
mainline 最新稳定版
stable 稳定版本
longterm 长时间支持版本
{% endnote %}

[官方](https://kernel.org/)国内[清华](https://mirror.tuna.tsinghua.edu.cn/kernel/v4.x/?C=M&O=D)镜像源

```shell
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.17.5.tar.xz

tar xvf linux-5.17.5.tar.xz
```

##### 安装编译工具

{% note info %}
centos7默认4.8.5目前最新的5.17内核需要5.1.0以上
{% endnote %}

```shell

# 编译工具
yum install -y ncurses-devel make gcc bc bison flex elfutils-libelf-devel openssl-devel

# 升级gcc版本
yum install  -y centos-release-scl
yum install  -y devtoolset-7-gcc*
scl enable devtoolset-7 bash
gcc --version
```

##### 配置内核参数

{% note info %}
参数有两种配置方式：手动配置或者复制当前内核配置，最终在源码目录生成.config文件
{% endnote %}

###### 直接复制当前内核的参数

```sehll
cp -v /boot/config-$(uname -r) .config
```

###### 手动配置

```shell
make menuconfig
```

新的配置界面

```shell
make nconfig
```

##### 编译安装内核

###### 编译源码

{% note info %}
-j 参数根据cpu数量来设置以加快编译速度，通常是cpu数量的2倍
{% endnote %}

```shell
make -j 8
```

###### 安装

```shell
make modules_install install
```

##### 设置开机启动

```shell
# 查看启动顺序
awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg

# 设置启动顺序(编号是上面命令看的的顺序)
grub2-set-default 0

# 重启生效
reboot
```

#### 编译rpm包

```shell

# 安装rpm构建工具
yum install -y rpm-build rpmlint yum-utils rpmdevtools

# 构建rpm包
make rpm-pkg

# 安装
yum install -y xx.rpm

# 重新生成grub.cfg
grub2-mkconfig -o /boot/grub2/grub.cfg

# 设置启动顺序(编号是上面命令看的的顺序)
grub2-set-default 0

# 重启生效
reboot
```

#### 参考资料

<https://ahelpme.com/linux/centos7/how-to-install-new-gcc-and-development-tools-under-centos-7/>
<https://nestealin.com/8bab8c2c/>
<https://github.com/torvalds/linux>
<https://www.kernel.org/doc/html/latest>
