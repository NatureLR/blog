title: gitlab部署配置
author: Nature丿灵然
tags:
  - gitlab
categories:
  - 运维
date: 2023-11-23 16:38:00
---
gitlab是一个功能非常强大的私有化git仓库

<!--more-->

#### 部署

- yum安装

```shell
yum install -y curl policycoreutils-python openssh-server
systemctl enable sshd
systemctl start sshd
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash
yum install -y gitlab-ce
```

#### 备份

#### 设置定时备份

- crobjob设置定时备份

```shell
0 23 * * * /opt/gitlab/bin/gitlab-backup create SKIP=builds,artifacts,lfs,terraform_state
```

#### 设置备份保留时间

- 保留三天

```ruby
gitlab_rails['backup_keep_time'] = 259200
```

#### 备份到挂载在本地的存储

- 修改配置文件，/mnt/nfs为nfs挂载点

```ruby
gitlab_rails['backup_upload_connection'] = {
  :provider => 'Local',
  :local_root => '/mnt/nfs'
}

gitlab_rails['backup_upload_remote_directory'] = 'gitlab-backups'
```

- 执行`gitalb-ctl reconfigure`生效

#### 还原

```shell
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
# Verify
sudo gitlab-ctl status

gitlab-backup restore BACKUP=1684312462_2023_05_17_14.9.5
```

#### 升级

- 查看升级计划 <https://docs.gitlab.com/ee/update/index.html#upgrade-paths>

- 根据升级计划下载中间版本和目标版本的二进制文件<https://packages.gitlab.com/gitlab/gitlab-ce>

- gitlab各个版本发行说明<https://about.gitlab.com/releases/categories/releases/>

注意14版本以上增加了后台迁移任务，后台迁移任务未跑完成时升级会报错 <https://docs.gitlab.com/ee/update/index.html#batched-background-migrations>

- 下载并安装

```bash
wget --content-disposition https://packages.gitlab.com/gitlab/gitlab-ce/packages/el/7/gitlab-ce-13.12.12-ce.0.el7.x86_64.rpm/download.rpm
yum -y install gitlab-ce-13.12.12-ce.0.el7.x86_64.rpm
```

#### gitalb-pages

- 设置pages的地址，不要和gitlab的域名一致，dns是是泛域名解析到gitlab服务器

```ruby
pages_external_url "http://pages.example.com/"
gitlab_pages['enable'] = true
```

##### 实例

```yaml
pages:
  stage: deploy
  script:
    - mkdir .public
    - cp -r * .public
    - mv .public public
  artifacts:
    paths:
      - public
  only:
```

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <h1>测试</h1>
</body>
</html>
```
