# 表结构

## 1.dwd_channel_code_count_1d

```sql
CREATE TABLE `dwd_channel_code_count_1d` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `channel_code` varchar(100) DEFAULT NULL COMMENT '渠道码',
  `bank_name` varchar(255) DEFAULT NULL COMMENT '银行名称',
  `bank_no` varchar(255) DEFAULT NULL COMMENT '银行编码',
  `bank_branch_code` varchar(255) DEFAULT NULL COMMENT '分行、网点编码',
  `bank_branch_name` varchar(255) DEFAULT NULL COMMENT '分行、网点名称',
  `employee_code` varchar(255) DEFAULT NULL COMMENT '员工编码',
  `employee_number` varchar(255) DEFAULT NULL COMMENT '员工工号',
  `employee_name` varchar(255) DEFAULT NULL COMMENT '员工名称',
  `scfw` int(11) DEFAULT NULL COMMENT '首次访问数目',
  `fw` int(11) DEFAULT NULL COMMENT '访问数目',
  `dxzc` int(11) DEFAULT NULL COMMENT '短信验证码注册数目',
  `wxzc` int(11) DEFAULT NULL COMMENT '微信手机号注册数目',
  `smrz` int(11) DEFAULT NULL COMMENT '实名认证数目',
  `dwsqtj` int(11) DEFAULT NULL COMMENT '单位申请提交数目',
  `grsqtj` int(11) DEFAULT NULL COMMENT '个人申请提交数目',
  `dbsqtj` int(11) DEFAULT NULL COMMENT '代办申请提交数目',
  `cx` int(11) DEFAULT NULL COMMENT '撤销数目',
  `qy` int(11) DEFAULT NULL COMMENT '启用数目',
  `zkcg` int(11) DEFAULT NULL COMMENT '制卡成功',
  `zksb` int(11) DEFAULT NULL COMMENT '制卡失败',
  `khsb` int(11) DEFAULT NULL COMMENT '开户失败',
  `zpshsb` int(11) DEFAULT NULL COMMENT '照片审核失败',
  `zx` int(11) DEFAULT NULL COMMENT '注销',
  `dwjbrtj` int(11) DEFAULT NULL COMMENT '单位经办人提交',
  `date_year` int(11) DEFAULT NULL COMMENT '年份 如2024',
  `date_month` int(11) DEFAULT NULL COMMENT '月份 01-12',
  `date_week` int(11) DEFAULT NULL COMMENT '周 1~7',
  `date_day` int(11) DEFAULT NULL COMMENT '01-31',
  `date_hour` int(11) DEFAULT NULL COMMENT '时  00-23',
  `date_point` int(11) DEFAULT NULL COMMENT '分 00,05,10,15,20,25,30,35,40,45,50,55\r\n向后包含（00-05)等于00、(05-10)等于05、(55-00)等于55\r\n例: 45< x  <= 50',
  `date_total` datetime DEFAULT NULL COMMENT '统计时间',
  `active` bit(1) DEFAULT NULL COMMENT '是否激活',
  `create_time` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `channel_code_date` (`channel_code`,`date_year`,`date_month`,`date_day`) USING BTREE COMMENT '渠道码 时间',
  KEY `date_branch_code` (`channel_code`,`date_total`) USING BTREE COMMENT '渠道码 时间'
) ENGINE=InnoDB AUTO_INCREMENT=6487 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='渠道码按天统计表'
```

## 2.sql_search_config

```sql
CREATE TABLE `sql_search_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `sql_type` varchar(100) DEFAULT NULL,
  `sql` text NOT NULL,
  `desc` varchar(100) NOT NULL,
  `active_flag` int(1) DEFAULT 0,
  `delete_flag` int(1) DEFAULT 0,
  `create_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `update_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4
```