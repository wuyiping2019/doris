# RuoYi-Vue3

## 1.开发环境准备

```Shell
yum install git
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
nvm install v18
use v18
npm install -g cnpm --registry=https://registry.npmmirror.com
cnpm install
```

## 2.Vite知识

Vite是一个基于Node.js的开发服务器和构建工具。在一个基于Vue3和Vite的前端项目中，会存在一个index.html、package.json、vite.config.js、src/main.js、src/App.vue、.env.development、.env.production和.env.staging文件。
当使用Vite直接启动项目时，会执行vite.config.js文件并启动一个web服务，