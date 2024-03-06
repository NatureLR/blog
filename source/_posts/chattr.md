title: chattr
author: Nature丿灵然
tags:
  - lsattr
date: 2022-05-21 13:00:00
---
chattr是一个可以修改文件属性的命令

<!--more-->

> linux是一个多用户系统，防止一个用户删除了另一个用户的文件，有些病毒入侵服务器之后就会修改此属性让管理员无法删除和修改文件

#### 基本参数说明

> 格式为 chattr [-pRVf] [-+=aAcCdDeijPsStTu] [-v version] files...

选项:

- R：用于递归显示目录的列表属性及其内容。
- V：它将显示程序的版本。
- a：用于列出目录的所有文件，其中还包括名称以句点（'.'）开头的文件。
- d：此选项会将目录列为常规文件，而不是列出其内容。
- v：用于显示文件的版本

操作符:

- -：删除文件一个属性
- +：添加文件一个属性
- =：使选定的属性成为文件所具有的唯一属性

操作属性:

- a：让文件或目录仅供附加用途。
- b：不更新文件或目录的最后存取时间。
- c：将文件或目录压缩后存放。
- d：将文件或目录排除在倾倒操作之外。
- e: 此属性表示文件正在使用扩展数据块映射磁盘上的块。不能使用chattr修改e属性。
- i：不得任意更动文件或目录。
- s：保密性删除文件或目录。
- S：即时更新文件或目录。
- u：预防意外删除。

#### 查看文件属性lsattr

列出文件属性

```shell
lsattr file
```

只显示了"e"属性

```shell
--------------e---- file
```

#### 例子

添加"i"属性

```shell
sudo chattr +i file
```

查看文件属性

```shell
lsattr file
```

增加了"e"属性

```shell
----i---------e---- file
```

这个时候写入文件时

```shell
sudo echo "test" > file
# zsh: operation not permitted: file
```

删除文件

```shell
sudo rm -rf file
rm: cannot remove 'file': Operation not permitted
```

删除"i"属性

```shell
sudo chattr -i file
```

这个时候就可以写入和删除操作了

添加唯一属性

```shell
sudo chattr "=i" file
```

再查看只有一个"i"属性

```shell
lsattr file
----i-------------- file
```

#### 参考资料

<https://www.runoob.com/linux/linux-comm-chattr.html>
<https://www.geeksforgeeks.org/chattr-command-in-linux-with-examples>
