FROM node:23-alpine AS build

LABEL blog.naturelr.cc="good"
LABEL MAINTAINER="naturelr"

RUN npm config set registry http://registry.npm.taobao.org/ && \
    apk add make git  openssh-client

RUN npm install --force

RUN npm install hexo-cli -g

WORKDIR /data

COPY . .

RUN ls

RUN hexo g

FROM nginx:alpine

COPY --from=build /data/public /usr/share/nginx/html/
