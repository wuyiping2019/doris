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
