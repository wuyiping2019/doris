# 开发环境

## 1.python环境准备

使用Python的版本 1.10

```SHELL
conda create -n superset-dev python==3.10
```

## 2.源码拷贝

在PyCharm中从版本控制新建项目`git clone https://gitee.com/wuyiping2020/superset.git`

设置远程解释器supset-dev

设置映射：

本地：E:/PycharmProjects/superset

远程：/opt/superset

## 3.依赖安装

```Shell
conda activate superset-dev
pip install --upgrade pip
pip install --upgrade setuptools pip-compile-multi
yum install mysql-devel
pip-compile-multi
```

