# 安装

Doris集群主要有FE和BE两种进程，FE分为MASTER、FOLLOWER和OBSERVER三种角色。  
集群部署时一般只需要首先启动一个FE进程，该进程自动成为MASTER进程，然后登录FE MASTER注册若干FOLLOWER和BE即可。
完成FOLLOWER和BACKEND注册之后，依次启动即可。
使用Doris二进制安装包安装非常简单，以下基于Doris-2.1.6的版本：

## 1.服务器配置

安装JDK8，请参开[2.下载JDK8](resource_download.md#2-jdk8)下载指定版本的JDK。

## 2.二进制包下载和安装

下载Doris-2.1.6的二进制安装包，请参开[3.下载doris](resource_download.md#3-doris)指定版本的Doris然后解压缩即可。

## 3.配置文件修改

解压二进制安装包后看到的目录结构，请参考[FE节点部署](fe_deploy.md)。
其中，重点的是fe/conf/fe.conf和be/conf/be.conf两个配置文件，可以在部署FE
MASTER时，也就是部署第一个FE节点时修改好这两个配置文件，然后使用scp命令将解压后配置好的二进制安装包分发到其他的所有节点。

### 3.1 修改fe/conf/fe.conf

在集群部署时操作IP是件麻烦的事，可以开启FQDN，使用IP的地方全部使用域名替换，如注册、删除FOLLOWER或BACKEND的命令中都必须使用域名，否则可能会出现问题。

开启FQDN需要设置集群中所有节点的hostname和hosts文件，让节点能够正确解析域名。

```shell
# 开启FQDN
enable_fqdn_mode = true

# 这个目录非常重要 用于FE存储元数据 推荐的方法是在该目录使用SSD磁盘，独立出来
# 这个目录默认值是DorisFE.DORIS_HOME_DIR + "/doris-meta" 
# 推荐的配置方法是不修改这个配置项，但是在希望保存元数据的SSD磁盘下创建一个文件夹软连接到这个默认目录
meta_dir=DorisFE.DORIS_HOME_DIR + "/doris-meta"
# 用于配置集群网络，表示这个节点运行通信的网段，默认空字符串
priority_networks= 
```

### 3.2 修改be/conf/be/conf

## 4.FE MASTER启动

启动的第一个FE节点自动成为MASTER进程，具体操作查看[FE节点部署](fe_deploy.md)。

## 5.注册FE FOLLOWER

启动FE MASTER之后，命令行登录后执行`ALTER SYSTEM ADD FOLLOWER "follower_host:edit_log_port"`注册FOLLOWER。
具体操作请参考[FE节点部署](fe_deploy.md)和[注册FOLLOWER](node.md#1-1-follower)

## 6.注册BACKEND

启动FE MASTER之后，命令行登录后执行`ALTER SYSTEM ADD BACKEND "<be_ip_address>:<be_heartbeat_service_port>"`注册FOLLOWER。
具体操作请参考[BE节点部署](be_deploy.md)和[注册BACKEND](node.md#3-1-be)

## 7.FE FOLLOWER启动

启动FE MASTER之后，完成FOLLOW和BACKEND的注册之后，就可以启动其他的FE和BE进程了。
启动FOLLOWER，请参考[5.添加FE](fe_deploy.md#5-2)。  
启动BACKEND，请参开[4.5 启动BE](be_deploy.md#4-5-be)。

## 8.Nginx反向代理

在操作Doris时，客户端需要与FE进程进行交互，集群部署时存在多个FE进程，可以使用Nginx对FE进程进行反向代理。
具体配置反向代理，可以参开[启动Nginx](cluster-deploy.md#6-nginx)




