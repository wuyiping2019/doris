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