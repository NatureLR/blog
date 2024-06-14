layout: draft
title: 本地大模型运行平台-ollama
author: Nature丿灵然
tags:
  - ai
date: 2024-06-14 17:34:00
---
ollama是一个用go写的本地大模型运行框架,支持多种大大模型，支持多平台

<!--more-->

#### 安装

- docker

```shell
docker pull ollama/ollama
```

- 脚本安装

```shell
curl -fsSL https://ollama.com/install.sh | sh
```

- 使用open-webui

```shell
docker run -d -p 3000:8080 --gpus=all -v ollama:/root/.ollama -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:ollama
```

#### 基本使用

- 这就像docker一样,运行一个llama3大模型，启动完成之后会弹出一个对话框，就可以像chartGPT那样对话了
- `ollama run`类似`docker run`如果本地没有模型则下载模型并运行

```shell
ollama run llama3
# pulling manifest
# pulling 6a0746a1ec1a... 100% ▕██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████▏ 4.7 GB
# pulling 4fa551d4f938... 100% ▕██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████▏  12 KB
# pulling 8ab4849b038c... 100% ▕██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████▏  254 B
# pulling 577073ffcc6c... 100% ▕██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████▏  110 B
# pulling 3f8eb4da87fa... 100% ▕██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████▏  485 B
# verifying sha256 digest
# writing manifest
# removing any unused layers
# success
# >>> Send a message (/? for help)
```

- 除了可以使用对话框以外还可以使命令行

```shell
ollama run llama3:latest "地球为什么是圆的"
```

- 下载模型

```shell
ollama pull <模型>
```

- 查看模型

```shell
ollama list
# NAME            ID              SIZE    MODIFIED
# llama3:latest   365c0bd3c000    4.7 GB  10 minutes ago
```

- 查看正在运行的模型

```shell
ollama ps
# NAME            ID              SIZE    PROCESSOR       UNTIL
# llama3:latest   365c0bd3c000    4.9 GB  100% CPU        About a minute from now
```

- 删除模型

```shell
ollama rm <模型>
```

- <https://ollama.com/library>可以查看ollama的模型仓库，这个和`docker hub`类似

#### 图形化界面

> 上面这是命令行的对话，部署一个界面则可以像chartGPT一样

#### modelfile

> modelfile类似dockerfile可以在基础模型之上添加一些修改

#### 参考资料

<https://github.com/ollama/ollama>
<https://docs.openwebui.com/>
