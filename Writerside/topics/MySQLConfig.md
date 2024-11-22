# MySQL配置

## 1.开启BinLog

```properties
[mysqld]
log-bin=mysql-bin # 开启binlog
binlog-format=ROW # 选择row模式
server_id=1 # serverid唯一
```

## 2.授权
```SQL
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'canal'@'%' IDENTIFIED BY 'canal';
FLUSH PRIVILEGES;
```

