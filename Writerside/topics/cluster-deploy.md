# 集群启动

## 1.节点划分

| ID | IP          | 节点    | 主机名         |
|----|-------------|-------|-------------|
| 1  | 172.29.0.10 | Nginx | dorix-proxy |
| 2  | 172.29.0.11 | FE    | fe-1        |
| 3  | 172.29.0.12 | FE    | fe-2        |
| 4  | 172.29.0.13 | FE    | fe-3        |
| 5  | 172.29.0.14 | BE    | be-1        |
| 6  | 172.29.0.15 | BE    | be-2        |
| 7  | 172.29.0.16 | BE    | be-3        |
| 8  | 172.29.0.17 | BE    | be-4        |
| 9  | 172.29.0.18 | BE    | be-5        |

## 2.脚本准备

## 2.1 install_jdk.sh

方便在所有的FE和BE节点上安装指定版本的JDK。

```shell
#!/bin/bash

# 设置 JDK 文件名和安装目录
JDK_FILE="/opt/jdk8.tar.gz"
JAVA_DIR="/usr/java"
JAVA_HOME="$JAVA_DIR/jdk8u352-b08"
JRE_HOME="$JAVA_HOME/jre"

# 创建 Java 目录
mkdir -p $JAVA_DIR

# 移动 JDK 到安装目录
cp -r $JDK_FILE $JAVA_DIR/jdk8.tar.gz

# 定位到 Java 安装目录并解压
cd $JAVA_DIR
if [[ ! -d "$JAVA_HOME" ]]; then
    tar -zxvf $JDK_FILE

    # 配置环境变量
    {
      echo "export JAVA_HOME=$JAVA_HOME"
      echo "export JRE_HOME=$JRE_HOME"
      echo "export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib"
      echo "export PATH=\$JAVA_HOME/bin:\$PATH"
    } >> /etc/profile.d/jdk.sh

    # 设置脚本可执行权限
    chmod u+x /etc/profile.d/jdk.sh

    # 使环境变量生效
    source /etc/profile

    # 输出 Java 版本以验证安装
    java -version
    echo "安装完成"
else
    echo "已经存在安装目录，无需重复安装"
fi
```

## 2.2 set_hostname.sh

按照集群节点的划分，对集群上的节点进行hostname的设置。

```shell
#!/bin/bash

# 定义一个关联数组
declare -A ip_to_hostname

# 填充数组，IP 地址作为键，主机名作为值
ip_to_hostname=(
    ["172.29.0.10"]="dorix-proxy"
    ["172.29.0.11"]="fe-1"
    ["172.29.0.12"]="fe-2"
    ["172.29.0.13"]="fe-3"
    ["172.29.0.14"]="be-1"
    ["172.29.0.15"]="be-2"
    ["172.29.0.16"]="be-3"
    ["172.29.0.17"]="be-4"
    ["172.29.0.18"]="be-5"
)

# 获取当前的 IP 地址
current_ip=$(hostname -I | awk '{print $1}')  
# 获取第一个 IP 地址# 从 map 中获取对应的 hostname
if [[ -n "${ip_to_hostname[$current_ip]}" ]]; then    
    new_hostname="${ip_to_hostname[$current_ip]}"
    echo "将主机名修改为: $new_hostname"
    # 修改主机名    
    echo $new_hostname > /etc/hostname
    # 验证修改结果
    current_hostname=$(cat /etc/hostname)  
    echo "当前主机名为: $current_hostname"
else
    echo "未找到与 IP 地址 $current_ip 对应的主机名。"
fi
```

## 2.3 add_hosts.sh

```shell
#!/bin/bash

cat <<EOL > /etc/hosts
127.0.0.1 localhost
172.29.0.10 dorix-proxy
172.29.0.11 fe-1
172.29.0.12 fe-2
172.29.0.13 fe-3
172.29.0.14 be-1
172.29.0.15 be-2
172.29.0.16 be-3
172.29.0.17 be-4
172.29.0.18 be-5
EOL

# 输出结果
echo "已将以下内容添加到 /etc/hosts:"
cat /etc/hosts | tail -n 9  # 显示最后四行，以确认写入的内容
```

## 2.4 doris_prepare.sh

```shell
#!/bin/bash
cd /opt
source set_hostname.sh 
source add_hosts.sh
source install_jdk.sh

# 关系交换内存
echo "关闭交换内存..."
swapoff -a
# 关闭防火墙
echo "停止防火墙服务..."
systemctl stop firewalld.service
systemctl disable firewalld.service
# 配置 NTP 服务
echo "启动并启用 NTP 服务..."
systemctl start ntpd.service
systemctl enable ntpd.service
# 设置系统最大打开文件句柄数
echo "设置最大打开文件句柄数..."
{  
    echo "* soft nofile 1000000"
    echo "* hard nofile 1000000"
} >> /etc/security/limits.conf
# 修改虚拟内存区域数量
echo "设置 vm.max_map_count..."
sysctl -w vm.max_map_count=2000000
# 关闭透明大页
echo "关闭透明大页..."
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
# 确认设置
echo "设置完成，当前配置："
echo "最大打开文件句柄数:"
cat /etc/security/limits.conf | tail -n 9
echo "vm.max_map_count:"
sysctl vm.max_map_count
echo "透明大页设置:"
cat /sys/kernel/mm/transparent_hugepage/enabledcat /sys/kernel/mm/transparent_hugepage/defrag

tar -zxvf ./doris-2.doris-2.1.6.tar.gz1.6.tar.gz
```

## 3.容器
### 3.1 Dockerfile

为了在测试环境进行Doris的分布式部署，使用docker容模拟出多台服务器进行手动部署。

```Docker
FROM centos:7.6.1810

RUN curl -o /etc/yum.repos.d/CentOS-Base.repo \
    http://mirrors.aliyun.com/repo/Centos-7.repo && \
    yum install -y epel-release net-tools firewalld ntpd && \
    yum clean all

# 安装常用工具
RUN yum install -y \
    wget \
    vim \
    tar \
    gzip \
    && yum clean all


WORKDIR /opt
```

```shell
docker build -t centos:7.6- dev .
```

### 3.2 容器启动
```Docker
version: '3.8'

services:
  nginx:
    image: centos:7.6-dev
    privileged: true
    container_name: nginx
    networks:
      doris_network:
        ipv4_address: 172.29.0.10
    ports:
      - "8030:8030"
      - "9030:9030"
    volumes:
      - /opt/nginx-1.18.0.tar.gz:/opt/nginx-1.18.0.tar.gz
      - /opt/default.conf:/etc/nginx/conf.d/default.conf
    command: bash -c "nginx -c /etc/nginx/conf.d/default.conf && tail -f /dev/null"

  fe-1:
    image: centos:7.6-dev
    privileged: true
    container_name: fe-1
    networks:
      doris_network:
        ipv4_address: 172.29.0.11
    volumes:
      - /opt/doris-2.1.6.tar.gz:/opt/doris-2.1.6.tar.gz
      - /opt/jdk8.tar.gz:/opt/jdk8.tar.gz
      - /opt/install_jdk.sh:/opt/install_jdk.sh
      - /opt/set_hostname.sh:/opt/set_hostname.sh
      - /opt/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris_prepare.sh:/opt/doris_prepare.sh
    command: bash -c "sh doris_prepare.sh && cd apache-doris-2.1.6-bin-x64/bin && sh start_fe.sh"


  fe-2:
    image: centos:7.6-dev
    privileged: true
    container_name: fe-2
    networks:
      doris_network:
        ipv4_address: 172.29.0.12
    volumes:
      - /opt/doris-2.1.6.tar.gz:/opt/doris-2.1.6.tar.gz
      - /opt/jdk8.tar.gz:/opt/jdk8.tar.gz
      - /opt/install_jdk.sh:/opt/install_jdk.sh
      - /opt/set_hostname.sh:/opt/set_hostname.sh
      - /opt/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris_prepare.sh:/opt/doris_prepare.sh
    command: bash -c "sh doris_prepare.sh && cd apache-doris-2.1.6-bin-x64/bin && sh start_fe.sh --helper 172.29.0.11:9010"

  fe-3:
    image: centos:7.6-dev
    privileged: true
    container_name: fe-3
    networks:
      doris_network:
        ipv4_address: 172.29.0.13
    volumes:
      - /opt/doris-2.1.6.tar.gz:/opt/doris-2.1.6.tar.gz
      - /opt/jdk8.tar.gz:/opt/jdk8.tar.gz
      - /opt/install_jdk.sh:/opt/install_jdk.sh
      - /opt/set_hostname.sh:/opt/set_hostname.sh
      - /opt/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris_prepare.sh:/opt/doris_prepare.sh
    command: bash -c "sh doris_prepare.sh && cd apache-doris-2.1.6-bin-x64/bin && sh start_fe.sh --helper 172.29.0.11:9010"

  be-1:
    image: centos:7.6-dev
    privileged: true
    container_name: be-1
    networks:
      doris_network:
        ipv4_address: 172.29.0.14
    volumes:
      - /opt/doris-2.1.6.tar.gz:/doris-2.1.6.tar.gz
      - /opt/jdk8.tar.gz:/opt/jdk8.tar.gz
      - /opt/install_jdk.sh:/opt/install_jdk.sh
      - /opt/set_hostname.sh:/opt/set_hostname.sh
      - /opt/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris_prepare.sh:/opt/doris_prepare.sh
    command: tail -f /dev/null

  be-2:
    image: centos:7.6-dev
    privileged: true
    container_name: be-2
    networks:
      doris_network:
        ipv4_address: 172.29.0.15
    volumes:
      - /opt/doris-2.1.6.tar.gz:/opt/doris-2.1.6.tar.gz
      - /opt/jdk8.tar.gz:/opt/jdk8.tar.gz
      - /opt/install_jdk.sh:/opt/install_jdk.sh
      - /opt/set_hostname.sh:/opt/set_hostname.sh
      - /opt/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris_prepare.sh:/opt/doris_prepare.sh
    command: tail -f /dev/null

  be-3:
    image: centos:7.6-dev
    privileged: true
    container_name: be-3
    networks:
      doris_network:
        ipv4_address: 172.29.0.16
    volumes:
      - /opt/doris-2.1.6.tar.gz:/opt/doris-2.1.6.tar.gz
      - /opt/jdk8.tar.gz:/opt/jdk8.tar.gz
      - /opt/install_jdk.sh:/opt/install_jdk.sh
      - /opt/set_hostname.sh:/opt/set_hostname.sh
      - /opt/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris_prepare.sh:/opt/doris_prepare.sh
    command: tail -f /dev/null

  be-4:
    image: centos:7.6-dev
    privileged: true
    container_name: be-4
    networks:
      doris_network:
        ipv4_address: 172.29.0.17
    volumes:
      - /opt/doris-2.1.6.tar.gz:/opt/doris-2.1.6.tar.gz
      - /opt/jdk8.tar.gz:/opt/jdk8.tar.gz
      - /opt/install_jdk.sh:/opt/install_jdk.sh
      - /opt/set_hostname.sh:/opt/set_hostname.sh
      - /opt/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris_prepare.sh:/opt/doris_prepare.sh
    command: tail -f /dev/null

  be-5:
    image: centos:7.6-dev
    privileged: true
    container_name: be-5
    networks:
      doris_network:
        ipv4_address: 172.29.0.18
    volumes:
      - /opt/doris-2.1.6.tar.gz:/opt/doris-2.1.6.tar.gz
      - /opt/jdk8.tar.gz:/opt/jdk8.tar.gz
      - /opt/install_jdk.sh:/opt/install_jdk.sh
      - /opt/set_hostname.sh:/opt/set_hostname.sh
      - /opt/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris_prepare.sh:/opt/doris_prepare.sh
    command: tail -f /dev/null

networks:
  doris_network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.29.0.0/16

```

## 4.目录结构

创建一个doris目录，用于保存相关的资源和脚本文件  
opt  
├── jdk8.tar.gz   
├── doris-2.1.6.tar.gz  
├── doris_prepare.sh   
├── install_jdk.sh    
├── set_hostname.sh  
├── doris
│ ├── Dockerfile  
│ ├── docker-compose.yaml   

### 5.启动
```shell
docker compose up -d
```

