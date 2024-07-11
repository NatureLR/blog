layout: draft
title: restic备份linux目录
author: Nature丿灵然
tags:
  - 备份
date: 2024-07-09 22:40:00
---
restic是一个用go写的快速备份程序，它不仅仅支持备份到本地还支持远程，以及支持版本管理

<!--more-->

#### 安装

- macos

```shell
brew install restic
```

- debian

```shel
apt install restic
```

- 访问restic release下载对应的二进制<https://github.com/restic/restic/releases>

```shell
wget https://github.com/restic/restic/releases/download/v0.16.5/restic_0.16.5_linux_amd64.bz2
bzip2  -d restic_0.16.5_linux_amd64.bz2
chmod +x restic_0.16.5_linux_amd64
restic version
```

#### 初始化

- 初始化一个备份需要密码

```shell
restic init --repo /tmp/backup
# enter password for new repository:
# enter password again:
# created restic repository f41ad7ac1a at /tmp/backup
# 
# Please note that knowledge of your password is required to access
# the repository. Losing your password means that your data is
# irrecoverably lost.
```

- 可以通过设置环境变量来设置备份地址和密码

```shell
export RESTIC_REPOSITORY=/tmp/backup
export RESTIC_PASSWORD=123456
restic init

# restic init
# created restic repository d79e5ccb6a at /tmp/backup
# 
# Please note that knowledge of your password is required to access
# the repository. Losing your password means that your data is
# irrecoverably lost.
```

- 还可以使用文件和shell来输入设置密码
  - 参数:--password-command，环境变量:$RESTIC_PASSWORD_COMMAND
  - 参数:--password-file，环境变量:$RESTIC_PASSWORD_FILE

##### 远程备份

- 使用sftp备份

```shell
restic -r sftp:user@host:/data/backup init
```

- 还有其他支持的类型的备份参考官方文档

#### 备份

```shell
restic -r /tmp/backup/ --verbose backup ~/work
```

- --exclude可以选择忽略备份的文件

- 可以通过snapshots查看备份

```shell
restic -r /tmp/backup snapshots
# repository d79e5ccb opened (version 2, compression level auto)
# ID        Time                 Host        Tags        Paths
# ------------------------------------------------------------------------
# eb8f1539  2024-07-11 11:20:07  docker                  /home/debian/work
# ------------------------------------------------------------------------
```

#### 备份管理

##### 查看快照

```shell
restic -r /tmp/backup snapshots
# repository d79e5ccb opened (version 2, compression level auto)
# ID        Time                 Host        Tags        Paths
# ------------------------------------------------------------------------
# eb8f1539  2024-07-11 11:20:07  docker                  /home/debian/work
# 35d7dbd3  2024-07-11 11:48:20  docker                  /home/debian/work
# ------------------------------------------------------------------------
# 2 snapshots
```

##### 挂载快照

```shell
mkdir ./mnt
restic -r /tmp/backup/ mount ./mnt
```

- 通过tree可以看到挂载后会按id以及hosts等方式来存放快照

```shell
tree ./mnt
# ./mnt
# ├── hosts
# │   └── docker
# │       ├── 2024-07-11T11:20:07+08:00
# │       │   └── home
# │       │       └── debian
# │       │           └── work
# │       │               └── 123
# │       └── latest -> 2024-07-11T11:20:07+08:00
# ├── ids
# │   └── eb8f1539
# │       └── home
# │           └── debian
# │               └── work
# │                   └── 123
# ├── snapshots
# │   ├── 2024-07-11T11:20:07+08:00
# │   │   └── home
# │   │       └── debian
# │   │           └── work
# │   │               └── 123
# │   └── latest -> 2024-07-11T11:20:07+08:00
# └── tags
# 
# 20 directories, 3 files
```

##### 比较2个快照

```shell
restic -r /tmp/backup diff eb8f1539 35d7dbd3
# repository d79e5ccb opened (version 2, compression level auto)
# comparing snapshot eb8f1539 to 35d7dbd3:
# 
# [0:00] 100.00%  2 / 2 index files loaded
# +    /home/debian/work/456
# 
# Files:           1 new,     0 removed,     0 changed
# Dirs:            0 new,     0 removed
# Others:          0 new,     0 removed
# Data Blobs:      0 new,     0 removed
# Tree Blobs:      4 new,     4 removed
#   Added:   1.722 KiB
#   Removed: 1.440 KiB
```

#### 删除快照

```shell
restic -r /tmp/backup snapshots
# repository d79e5ccb opened (version 2, compression level auto)
# ID        Time                 Host        Tags        Paths
# ------------------------------------------------------------------------
# eb8f1539  2024-07-11 11:20:07  docker                  /home/debian/work
# 35d7dbd3  2024-07-11 11:48:20  docker                  /home/debian/work
# ------------------------------------------------------------------------
# 2 snapshots

restic -r /tmp/backup forget 35d7dbd3
# repository d79e5ccb opened (version 2, compression level auto)
# [0:00] 100.00%  1 / 1 files deleted

restic -r /tmp/backup snapshots
# repository d79e5ccb opened (version 2, compression level auto)
# ID        Time                 Host        Tags        Paths
# ------------------------------------------------------------------------
# eb8f1539  2024-07-11 11:20:07  docker                  /home/debian/work
# ------------------------------------------------------------------------
# 1 snapshots
```

#### 还原

- 还原到本地的restore目录

```shell
restic -r /tmp/backup/ restore eb8f1539 --target ./restore
# repository d79e5ccb opened (version 2, compression level auto)
# 
# restoring <Snapshot eb8f1539 of [/home/debian/work] at 2024-07-11 11:20:07.329664725 +0800 CST by debian@docker> to ./restore
# Summary: Restored 4 files/dirs (4 B) in 0:00
```

- 查看备份的文件可以看到还有路径

```shell
tree ./restore/
# ./restore/
# └── home
#     └── debian
#         └── work
#             └── 123
# 
# 4 directories, 1 file
```

#### 参考资料

<https://restic.readthedocs.io/en/latest/010_introduction.html>
