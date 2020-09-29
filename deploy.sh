#!/usr/bin/env sh
# hexo-admin调用的脚本
set -e 

hexo clean
hexo generate
hexo deploy

git add .
git commit -m "hexo-admin:deploy"
git push
