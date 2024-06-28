title: 配置docker支持gpu
author: Nature丿灵然
tags:
  - gpu
date: 2024-06-14 17:25:00
---
现在很多ai相关的程序会跑在docker当中，默认docker是不支持gpu的，所以需要使其支持gpu

<!--more-->

#### 安装驱动

- 打开nvidia官网的[驱动下载界面](https://www.nvidia.cn/Download/index.aspx?lang=cn)根据显卡和操作系统的类型下载对应的驱动

- 安装驱动,可能会报错缺少一些依赖，把缺少的安装即可

- centos7可能会遇到类似找不到kernel-source类似的报错需要手动添加`--kernel-source-path /usr/src/kernels/3.10.0-1160.119.1.el7.x86_64/`来配置内核源码路径

```shell
# 安装需要gcc支持
yum install gcc
yum install kernel-devel

bash NVIDIA-Linux-x86_64-440.95.01.run -a -s -Z -X 
```

- 验证安装

```shell
nvidia-smi
# Fri Jun 14 16:55:37 2024
# +-----------------------------------------------------------------------------+
# | NVIDIA-SMI 440.95.01    Driver Version: 440.95.01    CUDA Version: 10.2     |
# |-------------------------------+----------------------+----------------------+
# | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
# | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
# |===============================+======================+======================|
# |   0  Tesla V100-PCIE...  Off  | 00000000:00:03.0 Off |                    0 |
# | N/A   32C    P0    36W / 250W |      0MiB / 16160MiB |      0%      Default |
# +-------------------------------+----------------------+----------------------+
# 
# +-----------------------------------------------------------------------------+
# | Processes:                                                       GPU Memory |
# |  GPU       PID   Type   Process name                             Usage      |
# |=============================================================================|
# |  No running processes found                                                 |
# +-----------------------------------------------------------------------------+
```

#### 安装docker

- 使用官方一件脚本安装

```shell
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```

- 启动

```shell
systemctl start  docker
systemctl enable docker
```

- 验证安装

```shell
docker ps
# CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

#### 安装nvidia-toolkit

- 配置yaml仓库

```shell
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

yum-config-manager --enable nvidia-container-toolkit-experimental
```

- 安装toolkit

```shell
yum install -y nvidia-container-toolkit
```

- 配置

```shell
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker
```

- 测试,出现下面则表示安装成功

```yaml
docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
# Fri Jun 14 09:24:04 2024
# +-----------------------------------------------------------------------------+
# | NVIDIA-SMI 440.95.01    Driver Version: 440.95.01    CUDA Version: 10.2     |
# |-------------------------------+----------------------+----------------------+
# | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
# | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
# |===============================+======================+======================|
# |   0  Tesla V100-PCIE...  Off  | 00000000:00:03.0 Off |                    0 |
# | N/A   36C    P0    35W / 250W |      0MiB / 16160MiB |      0%      Default |
# +-------------------------------+----------------------+----------------------+
# 
# +-----------------------------------------------------------------------------+
# | Processes:                                                       GPU Memory |
# |  GPU       PID   Type   Process name                             Usage      |
# |=============================================================================|
# |  No running processes found                                                 |
# +-----------------------------------------------------------------------------+
```

##### k8s containerd配置

```shell
sudo nvidia-ctk runtime configure --runtime=containerd
sudo systemctl restart containerd
```

#### 参考资料

<https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html>
