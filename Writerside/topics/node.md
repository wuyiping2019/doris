<show-structure depth="2"/>

# 节点

## 1.增加Follower

### 1.1 注册Follower

默认edit_log_port端口是9010。

```shell
# 1.登录后向集群注册Follower
mysql -uroot -h127.0.0.1 -P9030 -p
# 输入密码
ALTER SYSTEM ADD FOLLOWER "follower_host:edit_log_port"

```

### 1.2 启动Follower

在指定的服务器上安装和配置FE。 可以直接分发已经安装好的FE节点安装包，需要保证meta-data文件夹为空。  
使用如下命令启动一个FOLLOWER节点，启动后会自动以FOLLOWER角色加入集群。  
注意：此处的IP是当前集群任意存活的FE节点即可。

```shell
sh start_fe.sh --helper "IP:9010" --daemon
```

## 2.增加OBSERVER

### 2.1 注册OBSERVER

默认edit_log_port端口是9010。

```shell
ALTER SYSTEM ADD OBSERVER "follower_host:edit_log_port"
```

### 2.2 启动OBSERVER

[同1.2 启动Follower](node.md#1-2-follower)

## 3.增加BE

### 3.1 注册BE

默认heartbeat_port是9050。

```shell
ALTER SYSTEM ADD BACKEND "<be_ip_address>:<be_heartbeat_service_port>"

```

### 3.2 启动BE

```shell
bin/start_be.sh --daemon

```

## 4.删除FE Master
通过`show frontends`查看FE节点，如果要删除的节点是Master节点，可以先停止FE Master进程，Master节点汇自动转移到其他的FOLLOWER节点，然后按照[5.删除FOLLOWER](node.md#5-follower)

## 5.删除FOLLOWER

默认edit_log_port端口是9010。

```shell
ALTER SYSTEM DROP FOLLOWER "follower_host:edit_log_port"

```

## 6.删除OBSERVER

默认edit_log_port端口是9010。

```shell
ALTER SYSTEM DROP OBSERVER "follower_host:edit_log_port"

```

## 7.删除BE

默认heartbeat_port是9050。

```shell
ALTER SYSTEM DROP BACKEND "host:heartbeat_port"[,"host:heartbeat_port"...]
```