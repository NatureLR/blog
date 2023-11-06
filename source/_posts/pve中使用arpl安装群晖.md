title: pve中使用arpl安装群晖.md
author: Nature丿灵然
tags:
  - 虚拟化
  - pve
categories:
  - 运维
date: 2023-11-05 23:17:00
---
群辉很强大，但是配置拉胯，且价格感人，使用pve虚拟化安装群辉

<!--more-->

使用开源的arpl固件安装

#### 下载arpl固件

- arpl有几个版本原版是巴西的[fbelavenuto](https://github.com/fbelavenuto)项目地址<https://github.com/fbelavenuto/arpl/releases>但是fbelavenuto因为个人原因停更了

- 第二个是国内的[wjz304](https://github.com/wjz304)根据fbelavenuto汉化并加速了不过因为原作者停更也停更了,项目地址<https://github.com/wjz304/arpl-zh_CN>

- 第三个还是[wjz304](https://github.com/wjz304)的第二个则是因为原作者停更了不想破坏发布流程重新弄得一个项目<https://github.com/wjz304/rr>

pve则选择带img的

#### 创建pve虚拟机

- 上传到pve

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-1.png)

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-2.png)

- 创建虚机，起个名字

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-3.png)

- 操作系统稍后安装这里选择不要操作系统

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-4.png)

- 这里注意这个机型要选择q35

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-5.png)

- 磁盘同样不要，稍后添加
![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-6.png)

- cpu根据宿主机情况选择

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-7.png)

- 内存编译的时候最好大于4g

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-8.png)

- 网络默认即可

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-9.png)

- 确认页

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-10.png)

- 将最开始导入的img文件导入到创建的虚拟机中

```shell
qm importdisk 106 /var/lib/vz/template/iso/arpl_rr_4GB.img local-lvm
```

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-11.png)

- 将手动导入的磁盘修改为sata类型的磁盘

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-12.png)

- 双击 即可修改

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-13.png)

- 再添加一个sata的磁盘作为系统盘

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-14.png)

- 修改引导顺序为刚刚导入的第一个磁盘

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-15.png)

- 启动虚拟机则看到此界面则启动成功，浏览器打开提示的地址

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-16.png)


#### 构建固件

- 打开之后则进入构建界面

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-17.png)

- 我这个版本是有中文版本的选择修改语言

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-18.png)

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-19.png) 

- 改完语言后选择选择型号

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-20.png) 

- 我这里选择ds923+

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-21.png)

- 然后选择版本

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-22.png)

- 这里选择7.2版本了

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-23.png)

- 然后开始编译引导，稍等片刻

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-24.png)

- 编译完成后有个启动

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-25.png)

- 等待一会后则进入提示的地址,就进入了群辉安装引导界面了,按提示选择安装大概十分钟左

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-26.png)

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-27.png)

- 稍等则进入dsm系统

![Alt text](../images/pve%E4%B8%AD%E4%BD%BF%E7%94%A8arpl%E5%AE%89%E8%A3%85%E7%BE%A4%E6%99%96-28.png)

#### 参考资料

<https://www.cnblogs.com/mokou/p/17042705.html>
