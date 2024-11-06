<show-structure depth="2"/>

# 集群启动

手动进行doris集群部署步骤如下：    
1.规划服务器的节点角色；  
2.设置/etc/hosts和/etc/hostname；（开启fqdn）  
3.所有的fe和be节点安装jdk、下载并解压指定版本的doris二进制包；  
4.配置fe master，启动fe master节点，将规划的节点的follower和be全部注册到fe master上；  
5.配置fe和be，逐个启动fe和be；  
6.登录fe master查看fe和be节点的状态；  
7.启动nginx服务，反向代理多个fe；

## 1.节点划分

| ID | IP          | 节点    | 主机名         | 角色       |
|----|-------------|-------|-------------|----------|
| 1  | 172.29.0.10 | Nginx | dorix-proxy |          |
| 2  | 172.29.0.11 | FE    | fe-1        | master   |
| 3  | 172.29.0.12 | FE    | fe-2        | follower |
| 4  | 172.29.0.13 | FE    | fe-3        | follower |
| 5  | 172.29.0.14 | BE    | be-1        |          |
| 6  | 172.29.0.15 | BE    | be-2        |          |
| 7  | 172.29.0.16 | BE    | be-3        |          |
| 8  | 172.29.0.17 | BE    | be-4        |          |
| 9  | 172.29.0.18 | BE    | be-5        |          |

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
    ["172.29.0.21"]="be-1"
    ["172.29.0.22"]="be-2"
    ["172.29.0.23"]="be-3"
    ["172.29.0.24"]="be-4"
    ["172.29.0.25"]="be-5"
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
source /opt/doris/set_hostname.sh 
source /opt/doris/add_hosts.sh

# 关系交换内存
echo "关闭交换内存..."
swapoff -a
# 关闭防火墙
# echo "停止防火墙服务..."
# systemctl stop firewalld.service
# systemctl disable firewalld.service
# 配置 NTP 服务
# echo "启动并启用 NTP 服务..."
# systemctl start ntpd.service
# systemctl enable ntpd.service
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
# echo "关闭透明大页..."
#echo never > /sys/kernel/mm/transparent_hugepage/enabled
#echo never > /sys/kernel/mm/transparent_hugepage/defrag
# 确认设置
echo "设置完成，当前配置："
echo "最大打开文件句柄数:"
cat /etc/security/limits.conf | tail -n 9
echo "vm.max_map_count:"
sysctl vm.max_map_count
# echo "透明大页设置:"
# cat /sys/kernel/mm/transparent_hugepage/enabledcat /sys/kernel/mm/transparent_hugepage/defrag
```

## 3.目录结构

创建一个doris目录，用于保存相关的资源和脚本文件  
opt

├── doris  
│ ├── doris-2.1.6.tar.gz
│ ├── fe.conf
│ ├── be.conf
│ ├── jdk8.tar.gz
│ ├── doris_prepare.sh   
│ ├── install_jdk.sh    
│ ├── set_hostname.sh  
│ ├── Dockerfile   
│ ├── docker-compose.yaml
│ ├── data/fe-1-meta-data
│ ├── data/fe-1-jdbc-drivers
│ ├── data/fe-2-meta-data
│ ├── data/fe-2-jdbc-drivers
│ ├── data/fe-3-meta-data
│ ├── data/fe-3-jdbc-drivers
│ ├── data/be-1-storage
│ ├── data/be-1-jdbc-drivers
│ ├── data/be-2-storage
│ ├── data/be-2-jdbc-drivers
│ ├── data/be-3-storage
│ ├── data/be-3-jdbc-drivers
│ ├── data/be-4-storage
│ ├── data/be-4-jdbc-drivers
│ ├── data/be-5-storage
│ ├── data/be-5-jdbc-drivers

## 4.容器

### 4.1 镜像

为了在测试环境进行Doris的分布式部署，使用docker容模拟出多台服务器进行手动部署。

#### 4.1.1 Dockerfile

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

COPY doris-2.1.6.tar.gz /opt/doris-2.1.6.tar.gz 
COPY install_jdk.sh /opt/install_jdk.sh
COPY jdk8.tar.gz /opt/jdk8.gz

RUN tar -zxvf doris-2.1.6.tar.gz
RUN rm -rf apache-doris-2.1.6-bin-x64/fe/doris-meta
RUN rm -rf apache-doris-2.1.6-bin-x64/fe/jdbc-drivers
RUN rm -rf apache-doris-2.1.6-bin-x64/fe/conf/fe.conf
RUN rm -rf apache-doris-2.1.6-bin-x64/be/storage
RUN rm -rf apache-doris-2.1.6-bin-x64/be/jdbc-drivers
RUN rm -rf apache-doris-2.1.6-bin-x64/be/conf/be.conf
RUN bash install_jdk.sh
```

#### 4.1.2 build

```shell
docker build -t centos:7.6- dev .
```

### 4.2 容器启动

#### 4.2.1 docker-compose.yaml

```Docker
version: '3.8'

services:
  nginx:
    image: nginx:latest
    privileged: true
    container_name: nginx
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.10
    ports:
      - "8030:8030"
      - "9030:9030"
    volumes:
      - /opt/default.conf:/etc/nginx/conf.d/default.conf
    command: bash -c "nginx -c /etc/nginx/conf.d/default.conf && tail -f /dev/null"

  fe-1:
    image: centos:7.6-dev
    privileged: true
    container_name: fe-1
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.11
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/fe-1-meta-data:/opt/-x64/fe/doris-meta
      - /opt/doris/data/fe-1-jdbc-dirvers:/opt/-x64/fe/jdbc_drivers
      # 映射配置文件
      - /opt/doris/fe.conf:/opt/-x64/fe/conf/fe.conf
    command: bash -c "tail -f /dev/null"
  fe-2:
    image: centos:7.6-dev
    privileged: true
    container_name: fe-2
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.12
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/fe-2-meta-data:/opt/-x64/fe/doris-meta
      - /opt/doris/data/fe-2-jdbc-dirvers:/opt/-x64/fe/jdbc_drivers
      # 映射配置文件
      - /opt/doris/fe.conf:/opt/-x64/fe/conf/fe.conf
    command: bash -c "tail -f /dev/null"

  fe-3:
    image: centos:7.6-dev
    privileged: true
    container_name: fe-3
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.13
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/fe-3-meta-data:/opt/-x64/fe/doris-meta
      - /opt/doris/data/fe-3-jdbc-dirvers:/opt/-x64/fe/jdbc_drivers
      # 映射配置文件
      - /opt/doris/fe.conf:/opt/-x64/fe/conf/fe.conf
    command: bash -c "tail -f /dev/null"

  be-1:
    image: centos:7.6-dev
    privileged: true
    container_name: be-1
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.14
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/be-1-storage:/opt/-x64/be/storage
      - /opt/doris/data/be-1-jdbc-dirvers:/opt/-x64/be/jdbc_drivers
      # 映射配置文件
      - /opt/doris/be.conf:/opt/-x64/be/conf/be.conf
    command: tail -f /dev/null

  be-2:
    image: centos:7.6-dev
    privileged: true
    container_name: be-2
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.15
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/be-2-storage:/opt/-x64/be/storage
      - /opt/doris/data/be-2-jdbc-dirvers:/opt/-x64/be/jdbc_drivers
      # 映射配置文件
      - /opt/doris/be.conf:/opt/-x64/be/conf/be.conf
    command: tail -f /dev/null

  be-3:
    image: centos:7.6-dev
    privileged: true
    container_name: be-3
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.16
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/be-3-storage:/opt/-x64/be/storage
      - /opt/doris/data/be-3-jdbc-dirvers:/opt/-x64/be/jdbc_drivers
      # 映射配置文件
      - /opt/doris/be.conf:/opt/-x64/be/conf/be.conf
    command: tail -f /dev/null

  be-4:
    image: centos:7.6-dev
    privileged: true
    container_name: be-4
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.17
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/be-4-storage:/opt/-x64/be/storage
      - /opt/doris/data/be-4-jdbc-dirvers:/opt/-x64/be/jdbc_drivers
      # 映射配置文件
      - /opt/doris/be.conf:/opt/-x64/be/conf/be.conf
    command: tail -f /dev/null

  be-5:
    image: centos:7.6-dev
    privileged: true
    container_name: be-5
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.18
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/be-5-storage:/opt/-x64/be/storage
      - /opt/doris/data/be-5-jdbc-dirvers:/opt/-x64/be/jdbc_drivers
      # 映射配置文件
      - /opt/doris/be.conf:/opt/-x64/be/conf/be.conf
    command: tail -f /dev/null

networks:
  doris_network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.29.0.0/16

```

#### 4.2.2 启动容器

```shell
# 启动9个容器 模拟集群
docker compose up -d
```

## 5 启动FE和BE

### 5.1 启动FE Master

```shell
# 进入容器
docker exec -it fe-1 bash
sh doris_prepare.sh
cd /opt/-x64-x64/fe/conf
cat <<EOF >> fe.conf
enable_fqdn_mode = true
EOF

cd /opt/apache-doris-2.1.6-bin-x64/fe/bin
sh start_fe.sh --daemon
# 退出容器
exit
# 登录FE 密码空字符串
mysql -uroot -P9030 -h172.29.0.11 -p
# 查看内部数据
show databases; 
# 查看FE 只有当前一个FE
show frontends;
# 查看BE 没有BE
show backends;
```

### 5.2 注册FE Follower和BE

```shell
mysql -uroot -P9030 -h172.29.0.11 -p
alter system add follower "fe-2:9010";
alter system add follower "fe-3:9010";

alter system add backend "be-1:9050";
alter system add backend "be-2:9050";
alter system add backend "be-3:9050";
alter system add backend "be-4:9050";
alter system add backend "be-5:9050";

# 查看FE和BE
# 除了FE Master外 其他的节点的Alive字段都处于false状态
show frontends;
show backends;

```

### 5.3 启动FE Follower

以启动fe-2为例

```shell
docker exec -it fe-2 bash
sh doris_prepare.sh
cd /opt/apache-doris-2.1.6-bin-x64/fe/conf
cat <<EOF >> fe.conf
enable_fqdn_mode = true
EOF
cd /opt/apache-doris-2.1.6-bin-x64/fe/bin
sh start_fe.sh --helper "fe-1:9010" --daemon
```

### 5.4 启动BE

以启动be-1为例。

```shell
docker exec -it be-1 bash
sh doris_prepare.sh
cd /opt/apache-doris-2.1.6-bin-x64/be/bin
sh start_fe.sh --daemon
```

## 6.一步到位

```shell
cd /opt
mkdir doris
cd doris
mkdir -p data/fe-1-meta-data
mkdir -p data/fe-1-jdbc-drivers

mkdir -p data/fe-2-meta-data
mkdir -p data/fe-2-jdbc-drivers

mkdir -p data/fe-3-meta-data
mkdir -p data/fe-3-jdbc-drivers

mkdir -p data/be-1-storage
mkdir -p data/be-1-jdbc-drivers

mkdir -p data/be-2-storage
mkdir -p data/be-2-jdbc-drivers

mkdir -p data/be-3-storage
mkdir -p data/be-3-jdbc-drivers

mkdir -p data/be-4-storage
mkdir -p data/be-4-jdbc-drivers

mkdir -p data/be-5-storage
mkdir -p data/be-5-jdbc-drivers


if grep -q avx2 /proc/cpuinfo; then
    doris_url="https://apache-doris-releases.oss-accelerate.aliyuncs.com/apache-doris-2.1.6-bin-x64.tar.gz"
else
    doris_url="https://apache-doris-releases.oss-accelerate.aliyuncs.com/apache-doris-2.1.6-bin-x64-noavx2.tar.gz"
fi
doris_tar="doris-2.1.6.tar.gz"
wget -q "$doris_url" -O "$doris_tar" || { echo "Doris 下载失败"; exit 1; }

jdk_url="https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u352-b08/OpenJDK8U-jdk_x64_linux_hotspot_8u352b08.tar.gz"
jdk_tar="jdk8.tar.gz"
wget -q "$jdk_url" -O "$jdk_tar" || { echo "JDK 下载失败"; exit 1; }

cat <<EOF > install_jdk.sh
#!/bin/bash

# 设置 JDK 文件名和安装目录
JDK_FILE="/opt/jdk8.tar.gz"
JAVA_DIR="/usr/java"
JAVA_HOME="\$JAVA_DIR/jdk8u352-b08"
JRE_HOME="\$JAVA_HOME/jre"

# 创建 Java 目录
mkdir -p \$JAVA_DIR

# 移动 JDK 到安装目录
cp -r \$JDK_FILE \$JAVA_DIR/jdk8.tar.gz

# 定位到 Java 安装目录并解压
cd \$JAVA_DIR
if [[ ! -d "\$JAVA_HOME" ]]; then
    tar -zxvf \$JDK_FILE

    # 配置环境变量
    {
      echo "export JAVA_HOME=\$JAVA_HOME"
      echo "export JRE_HOME=\$JRE_HOME"
      echo "export CLASSPATH=.:\$JAVA_HOME/lib:\$JRE_HOME/lib"
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
EOF

cat <<EOF > set_hostname.sh
#!/bin/bash

# 定义一个关联数组
declare -A ip_to_hostname

# 填充数组，IP 地址作为键，主机名作为值
ip_to_hostname=(
    ["172.29.0.10"]="dorix-proxy"
    ["172.29.0.11"]="fe-1"
    ["172.29.0.12"]="fe-2"
    ["172.29.0.13"]="fe-3"
    ["172.29.0.21"]="be-1"
    ["172.29.0.22"]="be-2"
    ["172.29.0.23"]="be-3"
    ["172.29.0.24"]="be-4"
    ["172.29.0.25"]="be-5"
)

# 获取当前的 IP 地址
current_ip=\$(hostname -I | awk '{print \$1}')
# 获取第一个 IP 地址# 从 map 中获取对应的 hostname
if [[ -n "\${ip_to_hostname[\$current_ip]}" ]]; then
    new_hostname="\${ip_to_hostname[\$current_ip]}"
    echo "将主机名修改为: \$new_hostname"
    # 修改主机名
    echo \$new_hostname > /etc/hostname
    # 验证修改结果
    current_hostname=\$(cat /etc/hostname)
    echo "当前主机名为: \$current_hostname"
else
    echo "未找到与 IP 地址 \$current_ip 对应的主机名。"
fi
EOF

cat <<EOF > add_hosts.sh
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
EOF

cat <<EOF > doris_prepare.sh
#!/bin/bash
cd /opt
source /opt/doris/set_hostname.sh 
source /opt/doris/add_hosts.sh

# 关系交换内存
echo "关闭交换内存..."
swapoff -a
# 关闭防火墙
# echo "停止防火墙服务..."
# systemctl stop firewalld.service
# systemctl disable firewalld.service
# 配置 NTP 服务
# echo "启动并启用 NTP 服务..."
# systemctl start ntpd.service
# systemctl enable ntpd.service
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
# echo "关闭透明大页..."
#echo never > /sys/kernel/mm/transparent_hugepage/enabled
#echo never > /sys/kernel/mm/transparent_hugepage/defrag
# 确认设置
echo "设置完成，当前配置："
echo "最大打开文件句柄数:"
cat /etc/security/limits.conf | tail -n 9
echo "vm.max_map_count:"
sysctl vm.max_map_count
# echo "透明大页设置:"
# cat /sys/kernel/mm/transparent_hugepage/enabledcat /sys/kernel/mm/transparent_hugepage/defrag
EOF



cat <<EOF > fe_master_init.sh
#!/bin/bash

# MySQL 连接配置
HOST="127.0.0.1"             # MySQL 主机地址
USER="root"                  # MySQL 用户名
PASSWORD=""     # MySQL 密码 空字符

SQL_COMMAND='
  ALTER SYSTEM ADD FOLLOWER "fe-2:9010";
  ALTER SYSTEM ADD FOLLOWER "fe-3:9010";
  ALTER SYSTEM ADD BACKEND "be-1:9050", "be-2:9050", "be-3:9050", "be-4:9050", "be-5:9050";
'
# 重试配置
MAX_RETRIES=5                # 最大重试次数
RETRY_INTERVAL=10            # 每次重试之间的等待时间（秒）

# 执行 SQL 的函数
run_sql() {
    mysql -h"\$HOST" -u"\$USER" -p"\$PASSWORD" -P9030 -e "\$SQL_COMMAND"
}

# 带重试逻辑的执行过程
attempt=1
while (( attempt <= MAX_RETRIES )); do
    echo "尝试连接 MySQL 并执行 SQL (第 \$attempt 次尝试)..."
    if run_sql; then
        echo "SQL 执行成功。"
        exit 0
    else
        echo "SQL 执行失败，等待 \$RETRY_INTERVAL 秒后重试..."
        sleep "\$RETRY_INTERVAL"  # 等待指定的秒数再重试
    fi
    ((attempt++))
done

echo "已达到最大重试次数，无法执行 SQL。"
exit 1
EOF



cat <<EOF > Dockerfile
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
    mysql \
    && yum clean all


WORKDIR /opt

COPY doris-2.1.6.tar.gz /opt/doris-2.1.6.tar.gz 
COPY install_jdk.sh /opt/install_jdk.sh
COPY jdk8.tar.gz /opt/jdk8.tar.gz

RUN tar -zxvf doris-2.1.6.tar.gz
RUN rm -rf apache-doris-2.1.6-bin-x64/fe/doris-meta
RUN rm -rf apache-doris-2.1.6-bin-x64/fe/jdbc-drivers
RUN rm -rf apache-doris-2.1.6-bin-x64/fe/conf/fe.conf
RUN rm -rf apache-doris-2.1.6-bin-x64/be/storage
RUN rm -rf apache-doris-2.1.6-bin-x64/be/jdbc-drivers
RUN rm -rf apache-doris-2.1.6-bin-x64/be/conf/be.conf
RUN bash install_jdk.sh
EOF

cat <<EOF > default.conf
#user  nobody;

worker_processes  1;
# 日志文件路径和其他配置
#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;

events {
    worker_connections  1024;
}

# HTTP 块
http {
    # 上游服务器组
    upstream backend_servers {
        server 172.29.0.11:8030;
        server 172.29.0.12:8030;
        server 172.29.0.13:8030;
    }

    # HTTP 服务器配置
    server {
        listen 8030;

        location / {
            proxy_pass http://backend_servers;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_read_timeout 3600s;  # 读取响应的超时时间
            proxy_send_timeout 3600s;  # 发送请求的超时时间
            proxy_connect_timeout 300s;  # 连接后端服务器的超时时间
        }
    }
}

# Stream 块用于处理 TCP/UDP 代理负载均衡
stream {
    upstream mysqld {
        hash \$remote_addr consistent;
        server 172.29.0.11:9030 weight=1 max_fails=2 fail_timeout=60s;
        server 172.29.0.12:9030 weight=1 max_fails=2 fail_timeout=60s;
        server 172.29.0.13:9030 weight=1 max_fails=2 fail_timeout=60s;
    }

    server {
        listen 9030;
        proxy_connect_timeout 300s;
        proxy_timeout 300s;
        proxy_pass mysqld;
    }
}
EOF

cat <<EOF > docker-compose.yaml
version: '3.8'

services:
  nginx:
    image: nginx:latest
    privileged: true
    container_name: nginx
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.10
    ports:
      - "8030:8030"
      - "9030:9030"
    volumes:
      - /opt/doris/default.conf:/etc/nginx/conf.d/default.conf
    command: bash -c "nginx -c /etc/nginx/conf.d/default.conf && tail -f /dev/null"

  fe-1:
    image: centos:7.6-dev
    privileged: true
    container_name: fe-1
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.11
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/fe-1-meta-data:/opt/apache-doris-2.1.6-bin-x64/fe/doris-meta
      - /opt/doris/data/fe-1-jdbc-dirvers:/opt/apache-doris-2.1.6-bin-x64/fe/jdbc_drivers
      # 映射配置文件
      - /opt/doris/fe.conf:/opt/apache-doris-2.1.6-bin-x64/fe/conf/fe.conf
      # 初始化脚本
      - /opt/doris/fe_master_init.sh:/opt/fe_master_init.sh
    command: >
      bash -c "
      sh /opt/doris_prepare.sh && source /etc/profile.d/jdk.sh &&
      sh /opt/apache-doris-2.1.6-bin-x64/fe/bin/start_fe.sh --damoen &&
      sh /opt/fe_master_init.sh &&
      tail -f /opt/apache-doris-2.1.6-bin-x64/fe/log/fe.log
      "
    #command: >
    #  bash -c "tail -f /dev/null"
  fe-2:
    image: centos:7.6-dev
    privileged: true
    container_name: fe-2
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
      - HELPER=fe-1:9010
    networks:
      doris_network:
        ipv4_address: 172.29.0.12
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/fe-2-meta-data:/opt/apache-doris-2.1.6-bin-x64/fe/doris-meta
      - /opt/doris/data/fe-2-jdbc-dirvers:/opt/apache-doris-2.1.6-bin-x64/fe/jdbc_drivers
      # 映射配置文件
      - /opt/doris/fe.conf:/opt/apache-doris-2.1.6-bin-x64/fe/conf/fe.conf
    depends_on:
      - fe-1
    command: >
      bash -c "
      sh /opt/doris_prepare.sh &&
      sh /opt/apache-doris-2.1.6-bin-x64/fe/bin/start_fe.sh --helper \$\$HELPER
      "
    #command: >
    #  bash -c "tail -f /dev/null"
  fe-3:
    image: centos:7.6-dev
    privileged: true
    container_name: fe-3
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
      - HELPER=fe-1:9010
    networks:
      doris_network:
        ipv4_address: 172.29.0.13
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/fe-3-meta-data:/opt/apache-doris-2.1.6-bin-x64/fe/doris-meta
      - /opt/doris/data/fe-3-jdbc-dirvers:/opt/apache-doris-2.1.6-bin-x64/fe/jdbc_drivers
      # 映射配置文件
      - /opt/doris/fe.conf:/opt/apache-doris-2.1.6-bin-x64/fe/conf/fe.conf
    depends_on:
        - fe-1
    command: >
      bash -c "
      sh /opt/doris_prepare.sh &&
      sh /opt/apache-doris-2.1.6-bin-x64/fe/bin/start_fe.sh --helper \$\$HELPER
      "
    #command: >
    #  bash -c "tail -f /dev/null"
  be-1:
    image: centos:7.6-dev
    privileged: true
    container_name: be-1
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.14
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/be-1-storage:/opt/apache-doris-2.1.6-bin-x64/be/storage
      - /opt/doris/data/be-1-jdbc-dirvers:/opt/apache-doris-2.1.6-bin-x64/be/jdbc_drivers
      # 映射配置文件
      - /opt/doris/be.conf:/opt/apache-doris-2.1.6-bin-x64/be/conf/be.conf
    depends_on:
        - fe-1
    command: >
      bash -c "
      sh /opt/doris_prepare.sh && source /etc/profile.d/jdk.sh &&
      sh /opt/apache-doris-2.1.6-bin-x64/be/bin/start_be.sh
      "
    #command: >
    #  bash -c "tail -f /dev/null"

  be-2:
    image: centos:7.6-dev
    privileged: true
    container_name: be-2
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.15
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/be-2-storage:/opt/apache-doris-2.1.6-bin-x64/be/storage
      - /opt/doris/data/be-2-jdbc-dirvers:/opt/apache-doris-2.1.6-bin-x64/be/jdbc_drivers
      # 映射配置文件
      - /opt/doris/be.conf:/opt/apache-doris-2.1.6-bin-x64/be/conf/be.conf
    depends_on:
        - fe-1
    command: >
      bash -c "
      sh /opt/doris_prepare.sh && source /etc/profile.d/jdk.sh &&
      sh /opt/apache-doris-2.1.6-bin-x64/be/bin/start_be.sh
      "
    #command: >
    #  bash -c "tail -f /dev/null"

  be-3:
    image: centos:7.6-dev
    privileged: true
    container_name: be-3
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.16
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/be-3-storage:/opt/apache-doris-2.1.6-bin-x64/be/storage
      - /opt/doris/data/be-3-jdbc-dirvers:/opt/apache-doris-2.1.6-bin-x64/be/jdbc_drivers
      # 映射配置文件
      - /opt/doris/be.conf:/opt/apache-doris-2.1.6-bin-x64/be/conf/be.conf
    depends_on:
        - fe-1
    command: >
      bash -c "
      sh /opt/doris_prepare.sh && source /etc/profile.d/jdk.sh &&
      sh /opt/apache-doris-2.1.6-bin-x64/be/bin/start_be.sh
      "
    #command: >
    #  bash -c "tail -f /dev/null"

  be-4:
    image: centos:7.6-dev
    privileged: true
    container_name: be-4
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.17
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/be-4-storage:/opt/apache-doris-2.1.6-bin-x64/be/storage
      - /opt/doris/data/be-4-jdbc-dirvers:/opt/apache-doris-2.1.6-bin-x64/be/jdbc_drivers
      # 映射配置文件
      - /opt/doris/be.conf:/opt/apache-doris-2.1.6-bin-x64/be/conf/be.conf
    depends_on:
        - fe-1
    command: >
      bash -c "
      sh /opt/doris_prepare.sh && source /etc/profile.d/jdk.sh &&
      sh /opt/apache-doris-2.1.6-bin-x64/be/bin/start_be.sh
      "
    #command: >
    #  bash -c "tail -f /dev/null"

  be-5:
    image: centos:7.6-dev
    privileged: true
    container_name: be-5
    environment:
      - TZ=Asia/Shanghai  # 设置时区为上海
    networks:
      doris_network:
        ipv4_address: 172.29.0.18
    volumes:
      - /opt/doris/set_hostname.sh:/opt/set_hostname.sh
      - /opt/doris/add_hosts.sh:/opt/add_hosts.sh
      - /opt/doris/doris_prepare.sh:/opt/doris_prepare.sh
      # 映射数据
      - /opt/doris/data/be-5-storage:/opt/apache-doris-2.1.6-bin-x64/be/storage
      - /opt/doris/data/be-5-jdbc-dirvers:/opt/apache-doris-2.1.6-bin-x64/be/jdbc_drivers
      # 映射配置文件
      - /opt/doris/be.conf:/opt/apache-doris-2.1.6-bin-x64/be/conf/be.conf
    depends_on:
        - fe-1
    command: >
      bash -c "
      sh /opt/doris_prepare.sh && source /etc/profile.d/jdk.sh &&
      sh /opt/apache-doris-2.1.6-bin-x64/be/bin/start_be.sh
      "
    #command: >
    #  bash -c "tail -f /dev/null"

networks:
  doris_network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.29.0.0/16
EOF


cat <<EOF > fe.conf
CUR_DATE=\$(date +%Y%m%d-%H%M%S)

LOG_DIR = \${DORIS_HOME}/log
JAVA_OPTS="-Djavax.security.auth.useSubjectCredsOnly=false -Xss4m -Xmx8192m -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+PrintGCDateStamps -XX:+PrintGCDetails -Xloggc:\$LOG_DIR/fe.gc.log.\$CUR_DATE -Dlog4j2.formatMsgNoLookups=true"

JAVA_OPTS_FOR_JDK_9="-Djavax.security.auth.useSubjectCredsOnly=false -Xss4m -Xmx8192m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Xlog:gc*:\$LOG_DIR/fe.gc.log.\$CUR_DATE:time -Dlog4j2.formatMsgNoLookups=true"

JAVA_OPTS_FOR_JDK_17="-Djavax.security.auth.useSubjectCredsOnly=false -XX:+UseZGC -Xmx8192m -Xms8192m -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=\$LOG_DIR/ -Xlog:gc*:\$LOG_DIR/fe.gc.log.\$CUR_DATE:time"

meta_dir = \${DORIS_HOME}/doris-meta

jdbc_drivers_dir = \${DORIS_HOME}/jdbc_drivers

http_port = 8030
rpc_port = 9020
query_port = 9030
edit_log_port = 9010
arrow_flight_sql_port = -1
sys_log_level = INFO
sys_log_mode = NORMAL
enable_fqdn_mode = true
EOF

cat <<EOF > be.conf
CUR_DATE=\$(date +%Y%m%d-%H%M%S)

LOG_DIR="\${DORIS_HOME}/log/"

JAVA_OPTS="-Xmx1024m -DlogPath=\$LOG_DIR/jni.log -Xloggc:\$DORIS_HOME/log/be.gc.log.\$CUR_DATE -Djavax.security.auth.useSubjectCredsOnly=false -Dsun.security.krb5.debug=true -Dsun.java.command=DorisBE -XX:-CriticalJNINatives"

JEMALLOC_CONF="percpu_arena:percpu,background_thread:true,metadata_thp:auto,muzzy_decay_ms:5000,dirty_decay_ms:5000,oversize_threshold:0,prof:false,lg_prof_interval:-1"
JEMALLOC_PROF_PRFIX="jemalloc_heap_profile_"

be_port = 9060
webserver_port = 8040
heartbeat_service_port = 9050
brpc_port = 8060
arrow_flight_sql_port = -1

enable_https = false
ssl_certificate_path = "\$DORIS_HOME/conf/cert.pem"
ssl_private_key_path = "\$DORIS_HOME/conf/key.pem"
sys_log_level = INFO
aws_log_level=0
AWS_EC2_METADATA_DISABLED=true

EOF
docker build -t centos:7.6-dev .
docker compose up -d



```

## 7.启动Nginx

### 7.1 nginx配置

使用Ngxin进行反向代理多个FE，自动进行负载均衡。

```shell
#user  nobody;

worker_processes  1;
# 日志文件路径和其他配置
#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;

events {
    worker_connections  1024;
}

# HTTP 块
http {
    # 上游服务器组
    upstream backend_servers {
        server 172.29.0.11:8030;
        server 172.29.0.12:8030;
        server 172.29.0.13:8030;
    }

    # HTTP 服务器配置
    server {
        listen 8030;

        location / {
            proxy_pass http://backend_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 3600s;  # 读取响应的超时时间
            proxy_send_timeout 3600s;  # 发送请求的超时时间
            proxy_connect_timeout 300s;  # 连接后端服务器的超时时间
        }
    }
}

# Stream 块用于处理 TCP/UDP 代理负载均衡
stream {
    upstream mysqld {
        hash $remote_addr consistent;
        server 172.29.0.11:9030 weight=1 max_fails=2 fail_timeout=60s;
        server 172.29.0.12:9030 weight=1 max_fails=2 fail_timeout=60s;
        server 172.29.0.13:9030 weight=1 max_fails=2 fail_timeout=60s;
    }

    server {
        listen 9030;
        proxy_connect_timeout 300s;
        proxy_timeout 300s;
        proxy_pass mysqld;
    }
}
```

### 7.2 访问nginx

```shell
(base) [root@VM-8-10-centos doris]# mysql -uroot -P9030 -h172.29.0.10 -p
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.

Your MySQL connection id is 0
Server version: 5.7.99

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]>

```