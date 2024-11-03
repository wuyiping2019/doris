#!/bin/bash

# 设置工作目录
cd /opt || { echo "无法进入 /opt 目录"; exit 1; }

# 下载并重命名 JDK
jdk_url="https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u352-b08/OpenJDK8U-jdk_x64_linux_hotspot_8u352b08.tar.gz"
jdk_tar="jdk8.tar.gz"

echo "正在下载 JDK..."
wget -q "$jdk_url" -O "$jdk_tar" || { echo "JDK 下载失败"; exit 1; }
echo "JDK 下载并重命名为 $jdk_tar"

# 检查 CPU 是否支持 AVX2
echo "检测 CPU 是否支持 AVX2..."
if grep -q avx2 /proc/cpuinfo; then
    doris_url="https://apache-doris-releases.oss-accelerate.aliyuncs.com/apache-doris-2.1.6-bin-x64.tar.gz"
    echo "检测到 AVX2 支持，选择下载支持 AVX2 的 Doris 版本"
else
    doris_url="https://apache-doris-releases.oss-accelerate.aliyuncs.com/apache-doris-2.1.6-bin-x64-noavx2.tar.gz"
    echo "未检测到 AVX2 支持，选择下载不支持 AVX2 的 Doris 版本"
fi

doris_tar="doris-2.1.6.tar.gz"

# 下载并重命名 Doris
echo "正在下载 Doris..."
wget -q "$doris_url" -O "$doris_tar" || { echo "Doris 下载失败"; exit 1; }
echo "Doris 下载并重命名为 $doris_tar"

# 下载并重命名 Nginx
nginx_url="http://nginx.org/download/nginx-1.18.0.tar.gz"
nginx_tar="nginx-1.18.0.tar.gz"

echo "正在下载 Nginx..."
wget -q "$nginx_url" -O "$nginx_tar" || { echo "Nginx 下载失败"; exit 1; }
echo "Nginx 下载并重命名为 $nginx_tar"

echo "所有文件已成功下载并重命名。"
