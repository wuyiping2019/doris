<show-structure depth="2"/>

# BE节点部署

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

其中，be是BE的二进制安装目录，be/bin含有启动和终止BE进程的shell脚本，be/conf包含配置文件。

## 1.be/bin

这个目录含有环境变量设置、启动和终止FE的Shell脚本

be/bin  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── start_be.sh:启动BE进程    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── stop_be.sh:终止BE进程

## 2.原始be/conf/fe.conf

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

CUR_DATE=`date +%Y%m%d-%H%M%S`

# Log dir
LOG_DIR="${DORIS_HOME}/log/"

JAVA_OPTS="-Xmx1024m -DlogPath=$LOG_DIR/jni.log -Xloggc:$DORIS_HOME/log/be.gc.log.$CUR_DATE -Djavax.security.auth.useSubjectCredsOnly=false -Dsun.security.krb5.debug=true -Dsun.java.command=DorisBE -XX:-CriticalJNINatives"

# For jdk 9+, this JAVA_OPTS will be used as default JVM options
JAVA_OPTS_FOR_JDK_9="-Xmx1024m -DlogPath=$DORIS_HOME/log/jni.log -Xlog:gc:$LOG_DIR/be.gc.log.$CUR_DATE -Djavax.security.auth.useSubjectCredsOnly=false -Dsun.security.krb5.debug=true -Dsun.java.command=DorisBE -XX:-CriticalJNINatives"

# For jdk 17+, this JAVA_OPTS will be used as default JVM options
JAVA_OPTS_FOR_JDK_17="-Xmx1024m -DlogPath=$LOG_DIR/jni.log -Xlog:gc:$LOG_DIR/be.gc.log.$CUR_DATE -Djavax.security.auth.useSubjectCredsOnly=false -Dsun.security.krb5.debug=true -Dsun.java.command=DorisBE -XX:-CriticalJNINatives --add-opens=java.base/java.net=ALL-UNNAMED"

# since 1.2, the JAVA_HOME need to be set to run BE process.
# JAVA_HOME=/path/to/jdk/

# https://github.com/apache/doris/blob/master/docs/zh-CN/community/developer-guide/debug-tool.md#jemalloc-heap-profile
# https://jemalloc.net/jemalloc.3.html
JEMALLOC_CONF="percpu_arena:percpu,background_thread:true,metadata_thp:auto,muzzy_decay_ms:5000,dirty_decay_ms:5000,oversize_threshold:0,prof:false,lg_prof_interval:-1"
JEMALLOC_PROF_PRFIX="jemalloc_heap_profile_"

# ports for admin, web, heartbeat service
be_port = 9060
webserver_port = 8040
heartbeat_service_port = 9050
brpc_port = 8060
arrow_flight_sql_port = -1

# HTTPS configures
enable_https = false
# path of certificate in PEM format.
ssl_certificate_path = "$DORIS_HOME/conf/cert.pem"
# path of private key in PEM format.
ssl_private_key_path = "$DORIS_HOME/conf/key.pem"


# Choose one if there are more than one ip except loopback address.
# Note that there should at most one ip match this list.
# If no ip match this rule, will choose one randomly.
# use CIDR format, e.g. 10.10.10.0/24 or IP format, e.g. 10.10.10.1
# Default value is empty.
# priority_networks = 10.10.10.0/24;192.168.0.0/16

# data root path, separate by ';'
# You can specify the storage type for each root path, HDD (cold data) or SSD (hot data)
# eg:
# storage_root_path = /home/disk1/doris;/home/disk2/doris;/home/disk2/doris
# storage_root_path = /home/disk1/doris,medium:SSD;/home/disk2/doris,medium:SSD;/home/disk2/doris,medium:HDD
# /home/disk2/doris,medium:HDD(default)
#
# you also can specify the properties by setting '<property>:<value>', separate by ','
# property 'medium' has a higher priority than the extension of path
#
# Default value is ${DORIS_HOME}/storage, you should create it by hand.
# storage_root_path = ${DORIS_HOME}/storage

# Default dirs to put jdbc drivers,default value is ${DORIS_HOME}/jdbc_drivers
# jdbc_drivers_dir = ${DORIS_HOME}/jdbc_drivers

# Advanced configurations
# INFO, WARNING, ERROR, FATAL
sys_log_level = INFO
# sys_log_roll_mode = SIZE-MB-1024
# sys_log_roll_num = 10
# sys_log_verbose_modules = *
# log_buffer_level = -1
# palo_cgroups

# aws sdk log level
#    Off = 0,
#    Fatal = 1,
#    Error = 2,
#    Warn = 3,
#    Info = 4,
#    Debug = 5,
#    Trace = 6
# Default to turn off aws sdk log, because aws sdk errors that need to be cared will be output through Doris logs
aws_log_level=0
## If you are not running in aws cloud, you can disable EC2 metadata
AWS_EC2_METADATA_DISABLED=true
```

注意：需要注意的是其中的`${DORIS_HOME}`变量指的是apache-doris-2.1.6-bin-x64/be目录，而非apache-doris-2.1.6-bin-x64目录

## 3.修改be.conf

```shell
# 这个目录非常重要
storage_root_path = ${DORIS_HOME}/storage
priority_networks = 0.0.0.0/0
```

## 4 单节点BE部署

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

### 4.3 配置be.conf

```shell
mkdir /opt/data
mkdir /opt/data/jdbc_drivers  
mkdir /opt/data/be_storage
rm -rf /opt/apache-doris-2.1.6-bin-x64/be/jdbc_drivers
ln -s /opt/data/jdbc_drivers   /opt/apache-doris-2.1.6-bin-x64/be/jdbc_drivers
rm -rf /opt/apache-doris-2.1.6-bin-x64/fe/storage
ln -s /opt/data/be_storage /opt/apache-doris-2.1.6-bin-x64/fe/storage
cd  /opt/apache-doris-2.1.6-bin-x64/be/conf
cat <<EOF >> be.conf
priority_networks = 0.0.0.0/0
EOF
```

### 4.4 注册BE
```shell
# mysql -uroot -P9030 -h127.0.0.1登录FE命令行 执行如下命令:
# XXXXXXXX是BE的IP或域名
# 开启fqdn的话 写域名
ALTER SYSTEM ADD BACKEND "XXXXXXXX:9050";
```

### 4.5 启动BE


```shell
cd /opt/apache-doris-2.1.6-bin-x64/be/bin
sh start_be.sh
```


### 4.6 查看FE和BE


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






