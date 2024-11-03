#!/bin/bash
cd /opt

# 1.设置hostname
source set_hostname.sh
# 2.设置hosts
source add_hosts.sh

# 1.安装JDK
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