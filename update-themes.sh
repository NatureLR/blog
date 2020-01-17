#! /bin/bash

# 自动更新主题

echo  将原来的主题文件夹改名
mv themes/next themes/next-old

echo 下载最新的主题
git clone https://github.com/theme-next/hexo-theme-next themes/next

echo 将原来的主题文件覆盖到新的主题
mv themes/next-old/_config.yml themes/next/_config.yml

echo 删除老的主题
rm -rf themes/next-old

rm -rf themes/next/.git
