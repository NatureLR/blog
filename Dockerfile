FROM node:16-alpine3.18 as build

LABEL blog.naturelr.cc="good" \
      MAINTAINER="naturelr"

RUN npm config set registry http://registry.npm.taobao.org/ && \
    apk add make git  openssh-client

RUN npm install hexo-cli -g

WORKDIR /data

COPY . .

RUN hexo g

FROM nginx:alpine

COPY --from=build /data/public /usr/share/nginx/html/
