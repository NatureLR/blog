layout: draft
title: 使用velero备份k8s集群
author: Nature丿灵然
tags:
  - 备份
  - k8s
categories:
  - 运维
date: 2022-12-12 16:28:00
---
velero是k8s的备份还原工具，他不同于etcd的数据库级备份是一个应用级的备份

<!--more-->

#### 客户端安装

- macos

```shell
brew install velero
```

- 在<https://github.com/vmware-tanzu/velero/releases>中下载对应系统的二进制文件

#### 服务端安装

verero使用可以使用s3协议作为存储后端

- 创建s3认证文件

```text
[default]
aws_access_key_id=<公钥>
aws_secret_access_key=<私钥>

```

- 安装服务端

> plugins的版本根据verero可以选择对应的版本,这里使用了minio作为后端

```shell
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.6.0 \
    --bucket velero \
    --secret-file ./cert \
    --use-volume-snapshots=false \
    --use-node-agent \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.minio.svc.cluster.local:80
```

#### 备份

- 备份指定命名空间,可以多个ns，`*`为所有的命名空间,默认备份所有命名空间

|参数|说明|
|--------------------|-----------------
|-w(--wait)          |可以实时查看备份进度
|--ttl               |备份回收的时间
|-l(--selector)      |使用标签来选择备份资源
|--include-namespaces|包含的ns
|--exclude-namespaces|不包含的ns
|--storage-location  |备份的位置

```shell
velero backup create <备份的名字> --include-namespaces <指定命名空间>
```

- 查看备份

```shell
velero backup get
```

- 查看备份详情

```shell
velero backup describe <备份的名字>
```

- 查看备份日志

```shell
velero backup logs <备份的名字>
```

- 删除备份

```shell
velero backup delete <备份的名字>
```

#### 还原

```shel
velero restore create --from-backup <备份的名字>
```

- 查看还原

```shell
velero restore get
```

- 查看还原详细信息

```shell
velero restore describe <还原的名字>
```

- 查看还原的日志

```shell
velero restore logs <还原的名字>
```

#### 定时备份

定时备份和手动备份差不多只不过添加了一个类似cron的参数

- 每天备份指定命名空间

```shel
velero schedule create <备份的名字> --schedule="@daily" --include-namespaces <指定命名空间>
```

- 使用cron语法来定时备份

```shell
velero schedule create <备份的名字> --schedule="0 1 * * *" --include-namespaces <指定命名空间>
```

#### 备份位置

velero可也设置备份多个位置

```shell
velero backup-location get
```

#### 卸载

```shell
velero uninstall
```

#### pvc备份

- pvc备份需要2个条件一个是安装的时候需要有`--use-node-agent`参数

- pod上需要有下面的注释

```shell
backup.velero.io/backup-volumes: '<卷名字1,卷名字2...>'
```

#### 集群迁移

- 使用备份还原迁移集群时2个使用同一个后端存储，最好安装的命令和参数一致
- 集群的pvc等也要一致，如a集群备份使用的是`nfs`,那么b集群也要有nfs这个存储类否则还原会失败

#### 参考资料

<https://velero.io/docs/>
