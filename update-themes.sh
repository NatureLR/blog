#! /bin/bash

# 自动更新主题
theme=next
themeAddress="https://github.com/theme-next/hexo-theme-next"
oldTheme=$theme-old

cd themes

echo  将原来的主题文件夹改名
mv next $oldTheme

echo 下载最新的主题
git clone $themeAddress $theme

echo 将原来的主题文件覆盖到新的主题
mv $oldTheme/_config.yml $theme/_config.yml

echo 删除老的主题
rm -rf $oldTheme

echo 删除.git
rm -rf $theme/.git
