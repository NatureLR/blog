---
title: rpm包构建
author: Nature丿灵然
tags:
  - rpm
date: 2020-11-16 16:57:00
---
RPM（Redhat Package Manager）是Rhel，Centos，Fedora等系统的软件包管理格式

<!--more-->

##### 安装

> 在centos等使用rpm的系统中安装

```shell
yum install -y rpm-build rpmlint yum-utils rpmdevtools
```

##### 生成目录结构

初始化目录结构：

```shell
rpmdev-setuptree
```

在`home`目录下生成目录结构如下

```shell
rpmbuild
├── BUILD
├── BUILDROOT
├── RPMS
├── SOURCES
├── SPECS
└── SRPMS
```

目录位置|宏代码|说明|用途|
-|-|-|-|
BUILD    |%_builddir    |编译目录|`%build`阶段在此目录执行编译
BUILDROOT|%_buildrootdir|安装虚拟目录|`%install`阶段在此目录执行安装脚本
RPMS     |%_rpmdir      |rpm目录|生成的rpm包所在目录
SOURCES  |%_sourcedir   |源码目录|源码包目录,`%prep`阶段从此目录找需要解压的包
SRPMS    |%_srcrpmdir   |源码rpm目录|生成的rpm源码包所在目录
SPECS    |%_specdir     |Spec目录|spec文件存放的目录

##### 编写spec文件

```spec
%global debug_package %{nil}

Name:           {{.project}}
Version:        %{_version}
Release:        1%{?dist}
Summary:        {{.ShortDescribe}}

Group:          Application/WebServer
License:        Apache 2.0
URL:            http://www.baidu.com
Source0:        %{name}.tar.gz

# 构建依赖
BuildRequires:  git
BuildRequires:  make

# 详细描述
%description

{{.LongDescribe}}

# 构建之前执行的脚本，一般为解压缩将在source目录的压缩包解压到build目录
%prep

# %setup 不加任何选项，仅将软件包打开。
# %setup -a 切换目录前，解压指定 Source 文件，例如 "-a 0" 表示解压 "Source0"
# %setup -n newdir 将软件包解压在newdir目录。
# %setup -c 解压缩之前先产生目录。
# %setup -b num 将第 num 个 source 文件解压缩。
# %setup -D 解压前不删除目录
# %setup -T 不使用default的解压缩操作。
# %setup -q 不显示解包过程
# %setup -T -b 0 将第 0 个源代码文件解压缩。
# %setup -c -n newdir 指定目录名称 newdir，并在此目录产生 rpm 套件。
# %setup -q 不打印解压日志

%setup -q -c -n src -a 0

# 编译脚本
%build

cd {{.project}} && make

# 检查
%check

{{.project}}/bin/{{.project}} version

# 安装脚本,将build目录产生的可执行文件复制到buildroot虚拟目录中
%install

install -D  -p  -m 0755 ${RPM_BUILD_DIR}/src/{{.project}}/bin/{{.project}} ${RPM_BUILD_ROOT}%{_bindir}/{{.project}}
install -D -m 0644 ${RPM_BUILD_DIR}/src/{{.project}}/{{.project}}.service ${RPM_BUILD_ROOT}%{_unitdir}/{{.project}}.service

# 说明%{buildroot}中那些文件和目录需要打包到rpm中
%files

%{_bindir}/{{.project}}
%{_unitdir}/{{.project}}.service

# 变更记录
%changelog
```

将上面的文件保存到`rpmbuild/SPECS`目录

##### 构建

将上面的spec文件保存为test.spec到`~/rpmbuild/SPECS/`中执行

```sehll
rpmbuild -ba ~/rpmbuild/SPECS/test.spec
```

脚本如果没有问题的话在`~/rpmbuild/RPMS`目录下生成rpm文件`~/rpmbuild/SRPMS`为rpm源码包

###### 常用选项

- -ba 表示构建二进制包和源码包
- -bb 只构建二进制包
- --clean 构建完成后清理
- --define="k v" 定义spec中的变量
- --help 查看帮助

##### 参考

<https://www.cnblogs.com/michael-xiang/p/10480809.html>
<https://www.cnblogs.com/jing99/p/9672295.html>
