title: 基于web的远程客户端Apache Guacamole
author: Nature丿灵然
tags:
  - 终端
categories:
  - 运维
date: 2020-10-29 14:35:00
---
Apache Guacamole是一个基于web的远程终端支持vpn，ssh，rdp等协议
<!--more-->

#### 架构图如下

官网地址：<http://guacamole.apache.org>

![guac-arch](/images/pasted-4.png)

> 从图中可看出分为guacamole服务和guacd服务，guacd服务负责连接远程的vpc，rdp，ssh等服务器

#### 安装部署

这里使用k8s部署，注意本安装仅用于测试使用，由于mysql没做持久化重启之后数据会丢失

##### 部署guacamole

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: guacamole
spec:
  selector:
    matchLabels:
      app: guacamole
  template:
    metadata:
      labels:
        app: guacamole
    spec:
      containers:
      - env:
        - name: GUACD_HOSTNAME # guacd地址
          value: guacamole-guacd
        - name: MYSQL_DATABASE # mysql数据库
          value: guacamole
        - name: MYSQL_HOSTNAME # mysql地址
          value: guacamole-mysql
        - name: MYSQL_PASSWORD # mysql密码
          value: root
        - name: MYSQL_USER # mysql用户
          value: root
        image: guacamole/guacamole:latest # 这里使用了最新版
        name: guacamole
        ports:
        - containerPort: 8080
          name: 8080tcp02
          protocol: TCP
        resources: {}
---
apiVersion: v1
kind: Service
metadata:
  name: guacamole
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: guacamole
  type: NodePort # 使用nodeport进行访问，也可以用ingress
```

##### 部署guacd

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: guacamole-guacd
spec:
  selector:
    matchLabels:
      app: guacamole-guacd
  template:
    metadata:
      labels:
        app: guacamole-guacd
    spec:
      containers:
      - name: guacamole-guacd
        image: guacamole/guacd:latest
        resources: {}
        ports:
        - containerPort: 4822
---
apiVersion: v1
kind: Service
metadata:
  name: guacamole-guacd
spec:
  selector:
    app: guacamole-guacd
  ports:
  - port: 4822
    targetPort: 4822
```

##### 部署mysql

> mysql可以使用已经有的,且以下资源未做持久化重启之后数据会丢失不要用于生产！！！

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: guacamole-mysql
spec:
  selector:
    matchLabels:
      app: guacamole-mysql
  template:
    metadata:
      labels:
        app: guacamole-mysql
    spec:
      containers:
      - name: guacamole-mysql
        image: mysql:latest
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: root
        resources: {}
        ports:
        - containerPort: 3306
---
apiVersion: v1
kind: Service
metadata:
  name: guacamole-mysql
spec:
  selector:
    app: guacamole-mysql
  ports:
  - port: 3306
    targetPort: 3306
```

##### 初始化mysql

1. 将guacamole的Entrypoint改为`sleep 1h`以方便进入容器

2. 容器里执行`/opt/guacamole/bin/initdb.sh --mysql > initdb.sql` 导出mysql的表结构

3. `apt update && apt install mysql-client`安装mysql客户端

4. `mysql -h guacamole-mysql -uroot -proot`登录mysql数据库
    - 如果出现 ERROR 2059 (HY000): Authentication plugin 'caching_sha2_password' cannot be loaded 错误则需要在guacamole-mysql容器里登录数据库执行
    `ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'root';`

5. `create database guacamole;` 创建数据库

6. `use guacamole;` 进入数据库， `source initdb.sql`导入表结构

##### 登录

- 因为是nodeport所有可以使用 \<nodePort\>/guacamole
- 默认账号密码为guacadmin/guacadmin

##### 添加链接

![upload successful](/images/pasted-5.png)

进入配置界面配置根据目标主机的情况填写
