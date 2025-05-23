repo                   := naturelr
image-name             := $(repo)/blog
env-image-name         := $(repo)/blog-env
image-name-latest      := $(image-name):latest
env-image-name-latest  := $(env-image-name):latest
image-name-current     := $(image-name):$(shell date +%Y%m%d)
env-image-name-current := $(env-image-name):$(shell date +%Y%m%d)

##@ General

.PHONY: help
help: ## 显示make帮助
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ build

build: build-image build-env-image## 编译所有

build-local: ## 本地原生编译
	@hexo g

build-image:## 编译docker
	@docker buildx build --platform linux/amd64,linux/arm64 -t $(image-name-latest) -t $(image-name-current) -o type=registry . 

build-env-image:## 编译本地运行的镜像
	@docker buildx build --platform linux/amd64,linux/arm64 --target build -t $(env-image-name-latest) -t $(image-name-current) -o type=registry .

##@ run

run:## 本地原生运行(用于写作)
	@hexo clean && hexo g && hexo s

run-docker:## 使用编译好的docker镜像运行(用于生产)
	@docker run -d --name blog -p 4000:80 $(image-name)

run-local-docker:## 使用持久化docker镜像来跑(用于环境不友好写作)
	@docker run -d --name blog-persistent -v `pwd`:/data -v $$HOME/.ssh/:/root/.ssh -v $$HOME/.gitconfig:/root/.gitconfig -p 4000:4000 $(env-image-name) make run

##@ push

push: push-image push-env-image ## 上传所有镜像

push-image: ## 只上传运行镜像
	@docker push $(image)

push-env-image: ## 只上传环境镜像
	@docker push $(env-image)