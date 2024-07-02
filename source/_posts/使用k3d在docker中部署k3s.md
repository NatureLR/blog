layout: draft
title: 使用k3d在docker中部署k3s
author: Nature丿灵然
tags:
  - k8s
  - k3s
  - docker
  - gpu
date: 2024-07-02 10:30:00
---
k3d是一个在docker里面运行k3s的项目,主要用于本地开发k8s环境，这minikube很相似

<!--more-->

#### 部署

- 需要事先安装好docker和kubectl

```shel
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

#### 基本操作

- 创建集群

```shell
k3d cluster create <集群名字>
```

- 三节点master

```shell
k3d cluster create <集群名字> --servers 3
```

- 删除集群

```shell
k3d cluster delete <集群名字>
```

- 添加节点

```shell
k3d node create <节点名> -c <集群名>
```

- 将docker的镜像导入到k3d中

```shell
k3d image import <镜像名> -c <集群名字>
```

#### GPU

- 默认k3d的镜像是没法使用gpu的需要手动构建gpu镜像,[官方](https://k3d.io/v5.6.3/usage/advanced/cuda/#dockerfile)提供了一个dockerfile文件，`cuda版本需要和节点的相同`

```dockerfile
ARG K3S_TAG="v1.28.8-k3s1"
ARG CUDA_TAG="12.4.1-base-ubuntu22.04"

FROM rancher/k3s:$K3S_TAG as k3s
FROM nvcr.io/nvidia/cuda:$CUDA_TAG

# Install the NVIDIA container toolkit
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
      tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
    && apt-get update && apt-get install -y nvidia-container-toolkit \
    && nvidia-ctk runtime configure --runtime=containerd

COPY --from=k3s / / --exclude=/bin
COPY --from=k3s /bin /bin

# Deploy the nvidia driver plugin on startup
COPY device-plugin-daemonset.yaml /var/lib/rancher/k3s/server/manifests/nvidia-device-plugin-daemonset.yaml

VOLUME /var/lib/kubelet
VOLUME /var/lib/rancher/k3s
VOLUME /var/lib/cni
VOLUME /var/log

ENV PATH="$PATH:/bin/aux"

ENTRYPOINT ["/bin/k3s"]
CMD ["agent"]
```

- 还需要nvidia-device-plugin

```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: nvidia
handler: nvidia
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nvidia-device-plugin-daemonset
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: nvidia-device-plugin-ds
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        name: nvidia-device-plugin-ds
    spec:
      runtimeClassName: nvidia # Explicitly request the runtime
      tolerations:
      - key: nvidia.com/gpu
        operator: Exists
        effect: NoSchedule
      # Mark this pod as a critical add-on; when enabled, the critical add-on
      # scheduler reserves resources for critical add-on pods so that they can
      # be rescheduled after a failure.
      # See https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
      priorityClassName: "system-node-critical"
      containers:
      - image: nvcr.io/nvidia/k8s-device-plugin:v0.15.0-rc.2
        name: nvidia-device-plugin-ctr
        env:
          - name: FAIL_ON_INIT_ERROR
            value: "false"
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
        volumeMounts:
        - name: device-plugin
          mountPath: /var/lib/kubelet/device-plugins
      volumes:
      - name: device-plugin
        hostPath:
          path: /var/lib/kubelet/device-plugins
```

- 使用编译脚本编译,需要实际填写自己的镜像仓库地址

```shell
#!/bin/bash

set -euxo pipefail

K3S_TAG=${K3S_TAG:="v1.28.8-k3s1"} # replace + with -, if needed
CUDA_TAG=${CUDA_TAG:="12.4.1-base-ubuntu22.04"}
IMAGE_REGISTRY=${IMAGE_REGISTRY:="<镜像仓库>"}
IMAGE_REPOSITORY=${IMAGE_REPOSITORY:="rancher/k3s"}
IMAGE_TAG="$K3S_TAG-cuda-$CUDA_TAG"
IMAGE=${IMAGE:="$IMAGE_REGISTRY/$IMAGE_REPOSITORY:$IMAGE_TAG"}

echo "IMAGE=$IMAGE"

docker build \
  --build-arg K3S_TAG=$K3S_TAG \
  --build-arg CUDA_TAG=$CUDA_TAG \
  -t $IMAGE .
docker push $IMAGE
echo "Done!"
```

- 使用gpu镜像,其中环境变量是设置nvidia驱动功能这里设置了全部开启，不然测试pod会跑不起来，这些环境你变量在[nvidia官网文档](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/docker-specialized.html)

```shell
k3d cluster create gputest --image=<GPU镜像> --gpus=1 -e "NVIDIA_DRIVER_CAPABILITIES=compute,utility,compat32,graphics,video,display@server:0"
```

- 部署这个测试pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vector-add
spec:
  runtimeClassName: nvidia # Explicitly request the runtime
  restartPolicy: OnFailure
  containers:
    - name: cuda-vector-add
      image: "k8s.gcr.io/cuda-vector-add:v0.1"
      resources:
        limits:
          nvidia.com/gpu: 1
```

- pod日志结果,部署成功

```shell
kubectl logs -f cuda-vector-add
# [Vector addition of 50000 elements]
# Copy input data from the host memory to the CUDA device
# CUDA kernel launch with 196 blocks of 256 threads
# Copy output data from the CUDA device to the host memory
# Test PASSED
# Done
```

#### 参考资料

<https://k3d.io/v5.6.3/usage/configfile/>
