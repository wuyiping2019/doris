# JDBC Catalog

## 1.创建JDBC Catalog

```sql
CREATE CATALOG XXXXXXX PROPERTIES (
    "type"="jdbc",
    "user"="xxxx",
    "password"="xxxxxxxxxxxxxx",
    "jdbc_url" = "jdbc:mysql://xxxxxx:xxxx/xxxxxx?serverTimezone=Asia/Shanghai&useUnicode=true&characterEncoding=utf-8&useSSL=false&useOldAliasMetadataBehavior=true",
    "driver_url" = "mysql-connector-j-8.3.0.jar",
    "driver_class" = "com.mysql.cj.jdbc.Driver",
    "lower_case_meta_names"="true",
    "only_specified_database"="true"
);
```

## 1。1 docker-compose.yaml

为了方便测试，可以使用docker启动一个MySQL数据：

```docker
version: '3'

services:
  # MySQL
  db:
    container_name: mysql8
    image: mysql:8.0
    command: mysqld --default-authentication-plugin=mysql_native_password --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: User123$
      MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
    ports:
      - '3306:3306'
    volumes:
      - './db/data:/var/lib/mysql'
      - './db/my.cnf:/etc/mysql/conf.d/my.cnf'
```

### 1.2 my.cnf

使用到的my.cnf配置文件如下：

```shell
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

[client]
default-character-set=utf8mb4
```

### 1.3 启动MySQL

启动MySQL:

```shell
docker compose up -d
```

### 1.4 一步完成

```shell
cd /opt
mkdir mysql8
cd mysql8
mkdir -p ./db/data
cat <<EOF > db/my.cnf
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

[client]
default-character-set=utf8mb4
EOF

cat <<EOF > docker-compose.yaml
version: '3'

services:
  # MySQL
  db:
    container_name: mysql8
    image: mysql:8.0
    command: mysqld --default-authentication-plugin=mysql_native_password --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    environment:
      MYSQL_ROOT_PASSWORD: User123$
      MYSQL_DATABASE: test
      MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
    ports:
      - '3306:3306'
    volumes:
      - './db/data:/var/lib/mysql'
      - './db/my.cnf:/etc/mysql/conf.d/my.cnf'
EOF
docker compose up -d
mysql -uroot -h127.0.0.1 -pUser123$
```

## 2.创建同步目标表

以同步表user_table为例，MySQL建表语句如下：

```shell
CREATE TABLE user_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    age INT,
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

```

需要针对user_table创建对应的Doris的表，SQL如下：

```sql
create database if not exists ods;
CREATE TABLE ods.ods_user_table (
    id INT,
    name STRING,
    age INT,
    email STRING,
    created_at DATETIME
)
DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 10;
```

## 3.向源端数据库插入100w条数据

```sql
DELIMITER //

CREATE PROCEDURE insert_sample_data()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 1000000 DO
        INSERT INTO user_table (name, age, email)
        VALUES (
            CONCAT('User_', i),
            FLOOR(RAND() * 60) + 20, -- 年龄在20到80之间
            CONCAT('user', i, '@example.com')
        );
        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;
-- 执行插入
insert_sample_data()
```

## 3.使用INSERT语句进行同步

```sql
insert into ods.ods_user_table 
select * from jdbc
```