# blog

使用hexo的next主题,生成的web资源上传到github另一个[pages项目](https://github.com/NatureLingRan/NatureLingRan.github.io)
效果预览<https://blog.naturelingran.xyz>

## 安装

1. 安装npm 根据各个平台具体查看我写的[blog](https://blog.naturelingran.xyz/2020/09/22/NodeJs%E5%9F%BA%E6%9C%AC%E4%BD%BF%E7%94%A8/)

2. 克隆本项目并进入`git clone https://github.com/NatureLingRan/blog.git`，进入项目

3. 初始化npm:在当前目录下执行 `npm install`

## 常用操作

* 增加博文 hexo new <文章名字>

* 生成静态文件 hexo generate 缩写 hexo g

* 开启本地服务 hexo server 缩写 hexo s

* 清理文件 hexo clean

* hexo d 发布到github page,或者在hexo-admin中的`deploy`中执行deploy

* 如果是本地服务器可以在127.0.0.1:4000/admin中进行写作

* <http://localhost:4000/admin/>进去hexo-admin后台界面

## 目录说明

```directory
├── README.md
├── _admin-config.yml  # Hexo-admin插件配置文件
├── _config.next.yml   # next主题配置文件
├── _config.yml        # hexo配置文件
├── db.json
├── deploy.sh*         # hexo-admin执行发布的脚本
├── package-lock.json
├── package.json
├── scaffolds/
├── source/CNAME       # gitlab Pags的域名
```
