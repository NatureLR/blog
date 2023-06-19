image     := naturelingran/blog:latest
env-image := naturelingran/blog-env:latest

##@ General

.PHONY: help
help: ## 显示make帮助
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ build

build: build-local## 本地原生编译

build-local: ## 本地原生编译
	@hexo g

build-image:## 编译docker
	@docker build -t $(image) .

build-env-image:## 编译本地运行的镜像
	@docker build --target build -t $(env-image) .

build-all: build build-image build-env-image ## 编译所有
	
##@ run

run:## 本地原生运行(用于写作)
	@hexo clean && hexo g && hexo s

run-docker:## 使用编译好的docker镜像运行(用于生产)
	@docker run -d --name blog -p 4000:80 $(image)

run-local-docker:## 使用持久化docker镜像来跑(用于环境不友好写作)
	@docker run -d --name blog-persistent -v `pwd`:/data -v $$HOME/.ssh/:/root/.ssh -p 4000:4000 $(env-image) make run

##@ push

push: push-image push-env-image ## 上传所有镜像

push-image: ## 只上传运行镜像
	@docker push $(image)

push-env-image: ## 只上传环境镜像
	@docker push $(env-image)