#!/bin/bash

cat <<EOL >> /etc/hosts
172.29.0.10 dorix-proxy
172.29.0.11 fe-1
172.29.0.12 fe-2
172.29.0.13 fe-3
172.29.0.21 be-1
172.29.0.22 be-2
172.29.0.23 be-3
172.29.0.24 be-4
172.29.0.25 be-5
EOL

# 输出结果
echo "已将以下内容添加到 /etc/hosts:"
cat /etc/hosts | tail -n 9