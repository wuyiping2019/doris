<show-structure depth="2"/>

# FE节点部署

单节点部署FE的话，请直接进入&nbsp;&nbsp;[4.单节点FE部署](fe_deploy.md#4-fe)

下载doris二进制安装包后解析 的目录层级结构如下:  
apache-doris-2.1.6-bin-x64  
├── be  
│ ├── bin  
│ ├── conf  
│ ├── dict  
│ ├── lib  
│ ├── LICENSE-dist.txt  
│ ├── licenses  
│ ├── log  
│ ├── NOTICE.txt  
│ ├── storage  
│ └── www  
├── extensions  
│ └── apache_hdfs_broker  
└── fe  
│ ├── bin  
│ ├── conf  
│ ├── doris-meta  
│ ├── lib  
│ ├── LICENSE-dist.txt  
│ ├── licenses  
│ ├── log  
│ ├── minidump  
│ ├── mysql_ssl_default_certificate  
│ ├── NOTICE.txt  
│ ├── spark-dpp  
│ └── webroot

其中，fe是FE的二进制安装目录，fe/bin含有启动和终止FE进程的shell脚本，fe/conf包含配置文件。

## 1.fe/bin

这个目录含有环境变量设置、启动和终止FE的Shell脚本

fe/bin  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── profile_fe.sh:设置环境变量  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── start_fe.sh:启动FE进程    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── stop_fe.sh:终止FE进程

## 2.原始fe/conf/fe.conf

```shell
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

#####################################################################
## The uppercase properties are read and exported by bin/start_fe.sh.
## To see all Frontend configurations,
## see fe/src/org/apache/doris/common/Config.java
#####################################################################

CUR_DATE=`date +%Y%m%d-%H%M%S`

# Log dir
LOG_DIR = ${DORIS_HOME}/log

# CMS JAVA OPTS
# JAVA_OPTS="-Dsun.security.krb5.debug=true -Djavax.security.auth.useSubjectCredsOnly=false -Xss4m -Xmx8192m -XX:+UseMembar -XX:SurvivorRatio=8 -XX:MaxTenuringThreshold=7 -XX:+PrintGCDateStamps -XX:+PrintGCDetails -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled -XX:-CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=80 -XX:SoftRefLRUPolicyMSPerMB=0 -Xloggc:$DORIS_HOME/log/fe.gc.log.$CUR_DATE"

# G1 JAVA OPTS
JAVA_OPTS="-Djavax.security.auth.useSubjectCredsOnly=false -Xss4m -Xmx8192m -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+PrintGCDateStamps -XX:+PrintGCDetails -Xloggc:$LOG_DIR/fe.gc.log.$CUR_DATE -Dlog4j2.formatMsgNoLookups=true"

# For jdk 9+, this JAVA_OPTS_FOR_JDK_9 will be used as default CMS JVM options
# JAVA_OPTS_FOR_JDK_9="-Dsun.security.krb5.debug=true -Djavax.security.auth.useSubjectCredsOnly=false -Xss4m -Xmx8192m -XX:SurvivorRatio=8 -XX:MaxTenuringThreshold=7 -XX:+CMSClassUnloadingEnabled -XX:-CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=80 -XX:SoftRefLRUPolicyMSPerMB=0 -Xlog:gc*:$DORIS_HOME/log/fe.gc.log.$CUR_DATE:time"

# For jdk 9+, this JAVA_OPTS_FOR_JDK_9 will be used as default G1 JVM options
JAVA_OPTS_FOR_JDK_9="-Djavax.security.auth.useSubjectCredsOnly=false -Xss4m -Xmx8192m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Xlog:gc*:$LOG_DIR/fe.gc.log.$CUR_DATE:time -Dlog4j2.formatMsgNoLookups=true"

# For jdk 17+, this JAVA_OPTS will be used as default JVM options
JAVA_OPTS_FOR_JDK_17="-Djavax.security.auth.useSubjectCredsOnly=false -XX:+UseZGC -Xmx8192m -Xms8192m -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$LOG_DIR/ -Xlog:gc*:$LOG_DIR/fe.gc.log.$CUR_DATE:time"

##
## the lowercase properties are read by main program.
##

# store metadata, must be created before start FE.
# Default value is ${DORIS_HOME}/doris-meta
# meta_dir = ${DORIS_HOME}/doris-meta

# Default dirs to put jdbc drivers,default value is ${DORIS_HOME}/jdbc_drivers
# jdbc_drivers_dir = ${DORIS_HOME}/jdbc_drivers

http_port = 8030
rpc_port = 9020
query_port = 9030
edit_log_port = 9010
arrow_flight_sql_port = -1

# Choose one if there are more than one ip except loopback address.
# Note that there should at most one ip match this list.
# If no ip match this rule, will choose one randomly.
# use CIDR format, e.g. 10.10.10.0/24 or IP format, e.g. 10.10.10.1
# Default value is empty.
# priority_networks = 10.10.10.0/24;192.168.0.0/16

# Advanced configurations
# log_roll_size_mb = 1024
# INFO, WARN, ERROR, FATAL
sys_log_level = INFO
# NORMAL, BRIEF, ASYNC
sys_log_mode = NORMAL
# sys_log_roll_num = 10
# sys_log_verbose_modules = org.apache.doris
# audit_log_dir = $LOG_DIR
# audit_log_modules = slow_query, query
# audit_log_roll_num = 10
# meta_delay_toleration_second = 10
# qe_max_connection = 1024
# qe_query_timeout_second = 300
# qe_slow_log_ms = 5000

```

注意：需要注意的是其中的`${DORIS_HOME}`变量指的是apache-doris-2.1.6-bin-x64/fe目录，而非apache-doris-2.1.6-bin-x64目录

## 3.修改fe.conf

```shell
# 由于FE和BE中都存在jdbc_drivers_dir配置项，用于存储使用到的jdbc驱动  
# 将jdbc_drivers_dir设置为解压后得到的apache-doris-2.1.6-bin-x64目录下与fe和be同级的目录  
# 方便需要上传jdbc jar包时统一上传   
# 默认值${DORIS_HOME}/jdbc_drivers
jdbc_drivers_dir = ${DORIS_HOME}/jdbc_drivers
# 这个属性用于FE存储元数据 这个目录非常重要
# 默认值：DorisFE.DORIS_HOME_DIR + "/doris-meta"
meta_dir=${DORIS_HOME}/jdbc_drivers/doris-meta
# 设置允许通信的节点范围
# 如果所有节点存在于一个子网中，通过掩码设置IP前三位.0/24
# 如果存在多个子网，使用逗号进行配置多个
# 还可以使用0.0.0.0/24允许所有节点通信
priority_networks=172.29.0/24  
#用于控制用户表表名大小写是否敏感 默认值：0  
# 0：表名按指定存储，比较区分大小写。 
# 1：表名以小写形式存储，比较不区分大小写。 
# 2：表名按指定存储，但以小写形式进行比较。
lower_case_table_names=1  
# 启用基于 FQDN（Fully Qualified Domain Name，完全限定域名）  默认值：false
# 启动这个配置需要满足四个条件：
# 1.设置 enable_fqdn_mode = true
# 2.集群中的所有机器都必须配置有主机名
# 3.必须在集群中每台机器的 /etc/hosts 文件中指定集群中其他机器对应的 IP 地址和 FQDN
# 4./etc/hosts 文件中不能有重复的 IP 地址
# 注意：当在k8s环境中部署启用FQDN时，将允许更改be的重建pod的ip
enable_fqdn_mode = true  
# 用于控制最大的表名长度 默认值：64
table_name_length_limit=128
```

## 4 单节点FE部署

### 4.1 下载并安装JDK8

#### 4.1.1 下载指定版本JDK

[下载JDK](resource_download.md#2-jdk8)

#### 4.1.2 安装JDK8

[安装JDK](scripts_prepare.md#1-install-jdk-sh)

### 4.2 下载并解压doris

#### 4.2.1 下载doris

[下载Doris](resource_download.md#3-doris)

#### 4.2.2 解压doris

```shell
cd /opt
tar -zxvf doris-2.1.6.tar.gz
```

### 4.3 配置fe.conf

```shell
mkdir /opt/data
mkdir /opt/data/jdbc_drivers  
mkdir /opt/data/fe_meta_dir
ln -s /opt/data/jdbc_drivers   /opt/apache-doris-2.1.6-bin-x64/fe/jdbc_drivers
ln -s /opt/data/fe_meta_dir /opt/apache-doris-2.1.6-bin-x64/fe/meta_dir
cd  /opt/apache-doris-2.1.6-bin-x64/fe/conf
cat <<EOF >> fe.conf
priority_networks=0.0.0.0/24
lower_case_table_names=1  
enable_fqdn_mode = true  
table_name_length_limit=128
EOF
```

### 4.4 启动FE

```shell
cd /opt/apache-doris-2.1.6-bin-x64/fe/bin
sh start_fe.sh
```

### 4.5 登录

启动FE进程后，默认登录用户名为root，密码是空字符串

#### 4.5.1 命令行登录

```shell
(base) [root@VM-8-10-centos bin]# mysql -uroot -P9030 -h127.0.0.1
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 1
Server version: 5.7.99

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| __internal_schema  |
| information_schema |
| mysql              |
+--------------------+
3 rows in set (0.00 sec)

MySQL [(none)]> 

```

#### 4.5.2 网页登录
访问http://[ip]:8030

![登录页面](doris_login.png){ width=400 }{border-effect=line}

#### 4.5.3 修改root密码

```shell
(base) [root@VM-8-10-centos bin]# mysql -uroot -P9030 -h127.0.0.1
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.99

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> SET PASSWORD = PASSWORD('User123$');
Query OK, 0 rows affected (0.04 sec)

```

#### 4.5.4 查看FE和BE

目前，只启动了一个FE节点，默认就是Master节点，没有启动BE节点。

```shell
(base) [root@VM-8-10-centos bin]# mysql -uroot -P9030 -h127.0.0.1
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 3
Server version: 5.7.99

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> show frontends;
+-----------------------------------------+----------------+-------------+----------+-----------+---------+--------------------+----------+----------+------------+------+-------+-------------------+---------------------+---------------------+----------+--------+-----------------------------+------------------+
| Name                                    | Host           | EditLogPort | HttpPort | QueryPort | RpcPort | ArrowFlightSqlPort | Role     | IsMaster | ClusterId  | Join | Alive | ReplayedJournalId | LastStartTime       | LastHeartbeat       | IsHelper | ErrMsg | Version                     | CurrentConnected |
+-----------------------------------------+----------------+-------------+----------+-----------+---------+--------------------+----------+----------+------------+------+-------+-------------------+---------------------+---------------------+----------+--------+-----------------------------+------------------+
| fe_1b8ea833_a549_42f2_bc75_8b19889693b2 | VM-8-10-centos | 9010        | 8030     | 9030      | 9020    | -1                 | FOLLOWER | true     | 1714803857 | true | true  | 291               | 2024-11-03 18:39:46 | 2024-11-03 18:51:57 | true     |        | doris-2.1.6-rc04-653e315ba5 | Yes              |
+-----------------------------------------+----------------+-------------+----------+-----------+---------+--------------------+----------+----------+------------+------+-------+-------------------+---------------------+---------------------+----------+--------+-----------------------------+------------------+
1 row in set (0.05 sec)

MySQL [(none)]> show backends;
Empty set (0.00 sec)

MySQL [(none)]> 
```

## 5 添加FE

默认第一个启动的FE就是Master节点，可以增加FE的FOLLOWER和OBSERVER角色，一般增加2个FOLLOWER即可。

### 5.1 注册

```shell
# 注册即将启动的FE节点到Master中 注册为FOLLOWER
ALTER SYSTEM ADD FOLLOWER "XXXXXX:9010";
# 注册即将启动的FE节点到Master中 注册为OBSERVER
ALTER SYSTEM ADD OBSERVER "XXXXXX:9010";
```

### 5.2 启动

```shell
# XXXXX是Master的IP地址或域名 
./bin/start_fe.sh --helper XXXXXX:9010 --daemon
```






