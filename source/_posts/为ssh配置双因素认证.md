---
layout: draft
title: 为ssh配置双因素认证
author: Nature丿灵然
tags:
  - 安全
date: 2022-12-30 15:48:00
---
双因素认证使用totp算法来生成动态的验证码来验证

<!--more-->

#### 安装google-authenticator

- 安装epel源，国内也可以使用阿里的

```shell
yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum install -y google-authenticator
```

#### 配置google-authenticator

```shell
echo "auth required pam_google_authenticator.so" >>/etc/pam.d/sshd

echo "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config

systemctl restart sshd
```

#### 使用google-authenticator

- 会问你几个问题，一路y即可，之后会有个二维码拿手机支持totp的软件扫码即可

- 同时会在当前用户的家目录下生产一个`.google_authenticator`文件

```shell
google-authenticator
```

#### 配置秘钥登录也使用双因数认证

- 默认情况下只有使用密码才会验证双因素

```shell
echo "AuthenticationMethods publickey,password publickey,keyboard-interactive" >> /etc/ssh/sshd_config
```

- 在/etc/pam.d/sshd中将 `auth  substack  password-auth`注释掉

- 重启sshd服务

```shell
systemctl restart sshd
```

#### 参考资料

<https://blog.csdn.net/m0_37886429/article/details/103609673>
