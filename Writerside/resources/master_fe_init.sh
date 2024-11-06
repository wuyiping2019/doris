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
    mysql -h "$HOST" -u "$USER" -p"$PASSWORD" -e "$SQL_COMMAND"
}

# 带重试逻辑的执行过程
attempt=1
while (( attempt <= MAX_RETRIES )); do
    echo "尝试连接 MySQL 并执行 SQL (第 $attempt 次尝试)..."
    if run_sql; then
        echo "SQL 执行成功。"
        exit 0
    else
        echo "SQL 执行失败，等待 $RETRY_INTERVAL 秒后重试..."
        sleep "$RETRY_INTERVAL"  # 等待指定的秒数再重试
    fi
    ((attempt++))
done

echo "已达到最大重试次数，无法执行 SQL。"
exit 1
