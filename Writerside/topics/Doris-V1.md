<show-structure depth="3"/>

# V1

将渠道码系统迁移到Doris的第一个版本：

- 完成卡管系统和换发日志表系统的数据同步。
- 完成原有基于MySQL数据库集合XXLJob执行的任务调度，该调度生成dwd_channel_code_count_1d宽表逻辑。
- 完成msk-operation-data-center微服务数据库切换到doris并进行测试兼容性。

## 1.1 数据同步

特别之处，第一个版本为了避免网络问题和卡管系统数据需要进行解密-加密操作的过程，数据的同步过程是保留原有MySQL数据库，将其当做数据ETL的中转。
因此，同步卡管系统和换发日志表系统都是同步中台MySQL数据库。

### 1.1.1 卡管系统

#### 1.1.1.1 JDBC Catalog

创建JDBC Catalog用于数据同步。

```sql
DROP CATALOG if exists jdbc_hmsk_sjzt;
CREATE CATALOG jdbc_hmsk_sjzt PROPERTIES (
    "type"="jdbc",
    "user"="opdbcenter",
    "password"="Q2heVTnW%PhBudad",
    "jdbc_url" = "jdbc:mysql://10.26.8.28:3306/bjcard_makeuse?allowPublicKeyRetrieval=true&useUnicode=true&characterEncoding=utf8&useSSL=false&zeroDateTimeBehavior=convertToNull&useOldAliasMetadataBehavior=true",
    "driver_url" = "mysql-connector-j-8.3.0.jar",
    "driver_class" = "com.mysql.cj.jdbc.Driver",
    "lower_case_meta_names"="true",
    "only_specified_database"="true"
);
```

#### 1.1.1.2 csk_ac01

##### 1.1.1.2.1 建表

```SQL
drop table if exists ods.ods_sjzt_csk_ac01;
CREATE TABLE if not exists ods.`ods_sjzt_csk_ac01` (
    `ID` INT NOT NULL COMMENT '序号',
    `userCalcId` VARCHAR(1000),
    `AAC001` VARCHAR(100) COMMENT '个人编号',
    `AAC002` VARCHAR(500) COMMENT '证件号码',
    `AAC003` VARCHAR(1000) COMMENT '姓名',
    `AAC004` VARCHAR(10) COMMENT '性别',
    `AAC005` VARCHAR(20) COMMENT '民族',
    `AAC006` DATE COMMENT '出生日期',
    `AAC008` VARCHAR(100) COMMENT '人员参保状态',
    `AAC009` VARCHAR(200) COMMENT '户口性质',
    `AAC010` VARCHAR(1000) COMMENT '户口所在地',
    `AAC031` VARCHAR(100) COMMENT '个人缴费状态',
    `AAE005` VARCHAR(1000) COMMENT '联系电话',
    `AAE006` TEXT COMMENT '通讯地址(常住所在地地址)',
    `AAE007` VARCHAR(60) COMMENT '邮政编码',
    `AAE015` VARCHAR(1000) COMMENT '电子信箱',
    `AAC161` VARCHAR(100) COMMENT '国籍  默认CHN',
    `AAB301_ID` VARCHAR(120) COMMENT '所属区域',
    `AAC058` VARCHAR(20) COMMENT '证件类型',
    `ACC009` VARCHAR(500) COMMENT '证件有效期起始日期',
    `ACC010` VARCHAR(500) COMMENT '证件有效期终止日期',
    `CREATE_BY` VARCHAR(1000) COMMENT '创建人',
    `CREATE_DATE` DATETIME COMMENT '创建时间',
    `UPDATE_BY` VARCHAR(1000) COMMENT '操作员',
    `UPDATE_DATE` DATETIME COMMENT '操作时间',
    `DEL_FLAG` varchar(10) COMMENT '删除标记',
    `REMARKS` VARCHAR(1000) COMMENT '备注',
    `occupation` VARCHAR(320) COMMENT '职业',
    `addreesPer` string COMMENT '户籍地址',
    `tel` VARCHAR(1000) COMMENT '固定电话不能同时为空',
    `AAB301` VARCHAR(150) COMMENT '常住区域编码',
    `AAC007` VARCHAR(500) COMMENT '社会保障号码',
    `PASSWORD` VARCHAR(1000) COMMENT '服务密码',
    `sync_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
    `update_timestamp` datetime default current_timestamp on update current_timestamp comment '更新时间戳'
) ENGINE=OLAP
UNIQUE KEY(`ID`)
COMMENT '个人基本信息同步表'
DISTRIBUTED BY HASH(`ID`) BUCKETS 10
PROPERTIES (
    "replication_allocation" = "tag.location.default: 3"
);

```

##### 1.1.1.2.2 创建全量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_csk_ac01';
CREATE JOB sync_ods_sjzt_csk_ac01
        ON SCHEDULE
        -- 注意：这个时间必须是未来的时间
        AT '2024-11-08 00:01:00'
DO
INSERT INTO ods.`ods_sjzt_csk_ac01` (
    ID,
    userCalcId,
    AAC001,
    AAC002,
    AAC003,
    AAC004,
    AAC005,
    AAC006,
    AAC008,
    AAC009,
    AAC010,
    AAC031,
    AAE005,
    AAE006,
    AAE007,
    AAE015,
    AAC161,
    AAB301_ID,
    AAC058,
    ACC009,
    ACC010,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE,
    DEL_FLAG,
    REMARKS,
    occupation,
    addreesPer,
    tel,
    AAB301,
    AAC007,
    PASSWORD
)
SELECT 
    ID,
    userCalcId,
    AAC001,
    AAC002,
    AAC003,
    AAC004,
    AAC005,
    AAC006,
    AAC008,
    AAC009,
    AAC010,
    AAC031,
    AAE005,
    AAE006,
    AAE007,
    AAE015,
    AAC161,
    AAB301_ID,
    AAC058,
    ACC009,
    ACC010,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE,
    DEL_FLAG,
    REMARKS,
    occupation,
    addreesPer,
    tel,
    AAB301,
    AAC007,
    PASSWORD
FROM jdbc_hmsk_sjzt.bjcard_makeuse.csk_ac01;
-- select count(1) from ods.ods_sjzt_csk_ac01;
-- select count(1) from jdbc_hmsk_sjzt.bjcard_makeuse.csk_ac01;
```

##### 1.1.1.2.3 创建增量同步JOB

创建一个定时任务，每隔1h执行一次，每次执行都是将当前时间之前的两小时的增量数据插入到目标表。

```SQL
DROP JOB if exists where jobName='bsync_ods_sjzt_csk_ac01';
CREATE JOB bsync_ods_sjzt_csk_ac01
        -- quantity { WEEK | DAY | HOUR | MINUTE }
        ON SCHEDULE EVERY 1 HOUR
        -- 注意：这个时间必须是未来的时间
        STARTS '2024-01-01 03:00:00'
DO
INSERT INTO ods.`ods_sjzt_csk_ac01` (
    ID,
    userCalcId,
    AAC001,
    AAC002,
    AAC003,
    AAC004,
    AAC005,
    AAC006,
    AAC008,
    AAC009,
    AAC010,
    AAC031,
    AAE005,
    AAE006,
    AAE007,
    AAE015,
    AAC161,
    AAB301_ID,
    AAC058,
    ACC009,
    ACC010,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE,
    DEL_FLAG,
    REMARKS,
    occupation,
    addreesPer,
    tel,
    AAB301,
    AAC007,
    PASSWORD
)
SELECT 
    ID,
    userCalcId,
    AAC001,
    AAC002,
    AAC003,
    AAC004,
    AAC005,
    AAC006,
    AAC008,
    AAC009,
    AAC010,
    AAC031,
    AAE005,
    AAE006,
    AAE007,
    AAE015,
    AAC161,
    AAB301_ID,
    AAC058,
    ACC009,
    ACC010,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE,
    DEL_FLAG,
    REMARKS,
    occupation,
    addreesPer,
    tel,
    AAB301,
    AAC007,
    PASSWORD
FROM jdbc_hmsk_sjzt.bjcard_makeuse.csk_ac01
-- 当前时间之前俩小时
where ifnull(UPDATE_DATE,CREATE_DATE) >= DATE_SUB(NOW(), INTERVAL 2 HOUR)
;
```

#### 1.1.1.3 card_status

##### 1.1.1.3.1 建表

```SQL
drop table if exists ods.ods_sjzt_card_status;
CREATE TABLE if not exists ods.`ods_sjzt_card_status` (
  `ID` INT COMMENT '序号',
  `cc02_id` INT,
  `aac002` VARCHAR(500) COMMENT '身份证号码',
  `aac003` VARCHAR(1000) COMMENT '姓名',
  `aac018` INT COMMENT '制卡流程状态',
  `aac019` INT COMMENT '金融状态',
  `modify_flag` varchar(10) COMMENT '修改标记 0未修改 1已修改',
  `aaz502` INT COMMENT '0封存 1正常，2挂失，3应用锁定 4临时挂失 6:特殊制卡数据作废 9注销',
  `card_type` varchar(10) COMMENT '类型',
  `AAZ161` VARCHAR(500) COMMENT '发卡日期',
  `AAZ162` VARCHAR(500) COMMENT '卡片有效期',
  `AAZ163` varchar(10) COMMENT '自动解挂标识（1:自动解挂 2:不自动解挂）',
  `AAZ164` VARCHAR(500) COMMENT '金融自动解挂时间',
  `AAZ165` VARCHAR(500) COMMENT '民生自动解挂时间',
  `AAC042` VARCHAR(500) COMMENT '代办人证件号码',
  `AAC044` VARCHAR(1000) COMMENT '代办人姓名',
  `AAC043` VARCHAR(100) COMMENT '代办人证件类型',
  `AAE165` VARCHAR(1000) COMMENT '开户失败原因',
  `AAE200` VARCHAR(100) COMMENT '挂失原因编码',
  `AAE001` VARCHAR(1000) COMMENT '制卡失败原因',
  `AAE300` VARCHAR(100) COMMENT '补换卡原因编码',
  `AAE400` VARCHAR(1000) COMMENT '销户原因',
  `AAE500` varchar(10) COMMENT '卡回收标志',
  `ckkStatus` varchar(10) COMMENT '持卡库当前卡状态',
  `CREATE_BY` VARCHAR(500) COMMENT '创建者',
  `CREATE_DATE` DATETIME COMMENT '创建时间',
  `UPDATE_BY` VARCHAR(500) COMMENT '更新者',
  `UPDATE_DATE` DATETIME COMMENT '更新时间',
  `REMARKS` VARCHAR(500) COMMENT '备注',
  `DEL_FLAG` VARCHAR(10) COMMENT '删除标记',
  `sync_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime default current_timestamp on update current_timestamp comment '更新时间戳'
) ENGINE=OLAP
UNIQUE KEY(`ID`)
COMMENT '个人基本信息同步表'
DISTRIBUTED BY HASH(`ID`) BUCKETS 10
PROPERTIES (
    "replication_allocation" = "tag.location.default: 3"
);
```

##### 1.1.1.3.2 创建全量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_card_status';
CREATE JOB sync_ods_sjzt_card_status
        ON SCHEDULE
        AT '2024-11-08 00:01:00'
DO
INSERT INTO ods.`ods_sjzt_card_status` (
    ID,
    cc02_id,
    aac002,
    aac003,
    aac018,
    aac019,
    modify_flag,
    aaz502,
    card_type,
    AAZ161,
    AAZ162,
    AAZ163,
    AAZ164,
    AAZ165,
    AAC042,
    AAC044,
    AAC043,
    AAE165,
    AAE200,
    AAE001,
    AAE300,
    AAE400,
    AAE500,
    ckkStatus,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE,
    REMARKS,
    DEL_FLAG
)
SELECT 
    ID,
    cc02_id,
    aac002,
    aac003,
    aac018,
    aac019,
    modify_flag,
    aaz502,
    card_type,
    AAZ161,
    AAZ162,
    AAZ163,
    AAZ164,
    AAZ165,
    AAC042,
    AAC044,
    AAC043,
    AAE165,
    AAE200,
    AAE001,
    AAE300,
    AAE400,
    AAE500,
    ckkStatus,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE,
    REMARKS,
    DEL_FLAG
FROM jdbc_hmsk_sjzt.bjcard_makeuse.card_status;
-- select count(1) from ods.ods_sjzt_card_status;
-- select count(1) from jdbc_hmsk_sjzt.bjcard_makeuse.card_status;
```

##### 1.1.1.3.3 创建增量同步JOB

```SQL
DROP JOB if exists where jobName='bsync_ods_sjzt_card_status';
CREATE JOB bsync_ods_sjzt_card_status
         -- quantity { WEEK | DAY | HOUR | MINUTE }
        ON SCHEDULE EVERY 1 HOUR
        -- 注意：这个时间必须是未来的时间
        STARTS '2024-01-01 03:00:00'
DO
INSERT INTO ods.`ods_sjzt_card_status` (
    ID,
    cc02_id,
    aac002,
    aac003,
    aac018,
    aac019,
    modify_flag,
    aaz502,
    card_type,
    AAZ161,
    AAZ162,
    AAZ163,
    AAZ164,
    AAZ165,
    AAC042,
    AAC044,
    AAC043,
    AAE165,
    AAE200,
    AAE001,
    AAE300,
    AAE400,
    AAE500,
    ckkStatus,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE,
    REMARKS,
    DEL_FLAG
)
SELECT 
    ID,
    cc02_id,
    aac002,
    aac003,
    aac018,
    aac019,
    modify_flag,
    aaz502,
    card_type,
    AAZ161,
    AAZ162,
    AAZ163,
    AAZ164,
    AAZ165,
    AAC042,
    AAC044,
    AAC043,
    AAE165,
    AAE200,
    AAE001,
    AAE300,
    AAE400,
    AAE500,
    ckkStatus,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE,
    REMARKS,
    DEL_FLAG
FROM jdbc_hmsk_sjzt.bjcard_makeuse.card_status
-- 当前时间之前俩小时
where ifnull(UPDATE_DATE,CREATE_DATE) >= DATE_SUB(NOW(), INTERVAL 2 HOUR)
```

#### 1.1.1.4 csk_cc02

##### 1.1.1.4.1 建表

```SQL
drop table if exists ods.ods_sjzt_csk_cc02;
CREATE TABLE if not exists ods.`ods_sjzt_csk_cc02` (
  `ID` INT COMMENT '个人申领ID',
  `AC01_ID` INT COMMENT '个人基本信息ID',
  `AAB001` VARCHAR(200) COMMENT '单位编号',
  `AAB004` VARCHAR(500) COMMENT '单位名称',
  `ACA014` VARCHAR(20) COMMENT '申领渠道：1柜面渠道  2.自助申请  3.网上申请 4.银行线上渠道 5:银行线下渠道',
  `ACA017` VARCHAR(10) COMMENT '制卡类型：1:新开户、2 :补卡，3:换卡，4:同号换卡',
  `ACA016` VARCHAR(10) COMMENT '申领类型 1个人，2单位',
  `ACA015` VARCHAR(20) COMMENT '制卡方式（1.即时制卡 2.工厂制卡）',
  `AAC019` VARCHAR(200) COMMENT '金融状态',
  `AAC018` INT COMMENT '制卡流程状态（以card_status表aac018状态为准）',
  `AAZ500` VARCHAR(100) COMMENT '民生卡卡号',
  `AAE010` VARCHAR(500) COMMENT '银行卡号',
  `AAE010A` VARCHAR(500) COMMENT '金融账号',
  `AAE008` VARCHAR(200) COMMENT '银行编码',
  `AAE009` VARCHAR(200) COMMENT '网点编码',
  `AAB301` VARCHAR(150) COMMENT '所属区域',
  `ACC044` VARCHAR(200) COMMENT '未成年人标识 0否1是',
  `AAE165` VARCHAR(1000) COMMENT '开户失败的原因',
  `BATCH` VARCHAR(500) COMMENT '打包批次',
  `BATCH_NO` VARCHAR(640) COMMENT '制卡批次(未用到)',
  `SERVICE_NO` VARCHAR(640) COMMENT '办事编号',
  `personstatus` VARCHAR(20) COMMENT '11在职 21退休',
  `personcategory` VARCHAR(10) COMMENT '1为单位参保2为个人',
  `insurance` VARCHAR(1000) COMMENT '参保险种',
  `card_validity` VARCHAR(200) COMMENT '社保卡有效期',
  `upload_status` VARCHAR(10) COMMENT '上传标识',
  `CREATE_BY` VARCHAR(500) COMMENT '创建人',
  `CREATE_DATE` DATETIME COMMENT '创建时间',
  `UPDATE_BY` VARCHAR(500) COMMENT '更新人',
  `UPDATE_DATE` DATETIME  COMMENT '更新时间',
  `REMARKS` VARCHAR(1000) COMMENT '备注',
  `DEL_FLAG` VARCHAR(10) COMMENT '删除标识',
  `department` VARCHAR(640) COMMENT '所在部门',
  `emsName` VARCHAR(320) COMMENT 'ems 联系人',
  `emsPhone` VARCHAR(320) COMMENT 'ems 联系电话',
  `emsCode` VARCHAR(320) COMMENT 'ems 邮编',
  `emAddress` VARCHAR(1000) COMMENT 'ems 联系地址',
  `bhyyType` INT COMMENT '补换卡原因',
  `reason` INT COMMENT '挂失原因编号',
  `serialNumber` VARCHAR(640) COMMENT '行内提交交易流水号(对应个人领卡接口的业务单据号)',
  `platformSeqId` VARCHAR(500) COMMENT '外部平台流水号',
  `AAE001` VARCHAR(1000) COMMENT '制卡失败原因',
  `pbatchNum` VARCHAR(1000) COMMENT '外部平台批次',
  `ACA018` VARCHAR(100) COMMENT '领卡方式：1个人网点领卡，2银行邮寄，3单位代领',
  `AAB005` VARCHAR(500) COMMENT '单位经办人证件号码',
  `CNL001` VARCHAR(200) COMMENT '申领提交渠道号',
  `personId` VARCHAR(1000) COMMENT '持卡库部级人员id',
  `confirmFlag` VARCHAR(10) COMMENT '制卡失败确认标识(0:未确认 1:已确认)',
  `lockFlag` VARCHAR(10) COMMENT '锁定标识(0:未锁定 1:已锁定)',
  `confirmSource` VARCHAR(100) COMMENT '申领信息确认渠道(网上申领渠道有此值)',
  `workPermitNumber` VARCHAR(500) COMMENT '来华外国人工作许可证号码',
  `sync_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime default current_timestamp on update current_timestamp comment '更新时间戳'
) UNIQUE KEY(`ID`)
DISTRIBUTED BY HASH(`ID`) BUCKETS 10
PROPERTIES (
  "replication_allocation" = "tag.location.default: 3"
);

```

##### 1.1.1.4.2 创建全量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_csk_cc02';
CREATE JOB sync_ods_sjzt_csk_cc02
        ON SCHEDULE
        -- 注意：这个时间必须是未来的时间
        AT '2024-11-08 00:01:00'
DO
INSERT INTO ods.`ods_sjzt_csk_cc02` (
    ID,
    AC01_ID,
    AAB001,
    AAB004,
    ACA014,
    ACA017,
    ACA016,
    ACA015,
    AAC019,
    AAC018,
    AAZ500,
    AAE010,
    AAE010A,
    AAE008,
    AAE009,
    AAB301,
    ACC044,
    AAE165,
    BATCH,
    BATCH_NO,
    SERVICE_NO,
    personstatus,
    personcategory,
    insurance,
    card_validity,
    upload_status,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE
)
SELECT
    ID,
    AC01_ID,
    AAB001,
    AAB004,
    ACA014,
    ACA017,
    ACA016,
    ACA015,
    AAC019,
    AAC018,
    AAZ500,
    AAE010,
    AAE010A,
    AAE008,
    AAE009,
    AAB301,
    ACC044,
    AAE165,
    BATCH,
    BATCH_NO,
    SERVICE_NO,
    personstatus,
    personcategory,
    insurance,
    card_validity,
    upload_status,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE
FROM jdbc_hmsk_sjzt.bjcard_makeuse.csk_cc02;
-- select count(1) from ods.ods_sjzt_csk_cc02;
-- select count(1) from jdbc_hmsk_sjzt.bjcard_makeuse.csk_cc02;

```

##### 1.1.1.4.3 创建增量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_csk_cc02';
CREATE JOB sync_ods_sjzt_csk_cc02
        -- quantity { WEEK | DAY | HOUR | MINUTE }
        ON SCHEDULE EVERY 1 HOUR
        STARTS '2024-01-01 03:00:00'
DO
INSERT INTO ods.`ods_sjzt_csk_cc02` (
    ID,
    AC01_ID,
    AAB001,
    AAB004,
    ACA014,
    ACA017,
    ACA016,
    ACA015,
    AAC019,
    AAC018,
    AAZ500,
    AAE010,
    AAE010A,
    AAE008,
    AAE009,
    AAB301,
    ACC044,
    AAE165,
    BATCH,
    BATCH_NO,
    SERVICE_NO,
    personstatus,
    personcategory,
    insurance,
    card_validity,
    upload_status,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE
)
SELECT
    ID,
    AC01_ID,
    AAB001,
    AAB004,
    ACA014,
    ACA017,
    ACA016,
    ACA015,
    AAC019,
    AAC018,
    AAZ500,
    AAE010,
    AAE010A,
    AAE008,
    AAE009,
    AAB301,
    ACC044,
    AAE165,
    BATCH,
    BATCH_NO,
    SERVICE_NO,
    personstatus,
    personcategory,
    insurance,
    card_validity,
    upload_status,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE
FROM jdbc_hmsk_sjzt.bjcard_makeuse.csk_cc02
-- 当前时间之前俩小时
where ifnull(UPDATE_DATE,CREATE_DATE) >= DATE_SUB(NOW(), INTERVAL 2 HOUR)
;
```

#### 1.1.1.5 csk_cz05

##### 1.1.1.5.1 建表

```SQL
drop table if exists ods.ods_sjzt_csk_cz05;
CREATE TABLE ods.`ods_sjzt_csk_cz05` (
  `ID` INT COMMENT 'ID',
  `CC02_ID` INT COMMENT '个人申领表id',
  `AAC018` VARCHAR(30) COMMENT '制卡流程状态',
  `AAC018A` VARCHAR(1000) COMMENT '流程状态描述',
  `AAZ500` VARCHAR(1000) COMMENT '民生卡号',
  `AAE165` VARCHAR(1000) COMMENT '开户失败原因',
  `AAE200` VARCHAR(100) COMMENT '挂失原因编码',
  `AAE001` VARCHAR(1000) COMMENT '制卡失败原因',
  `AAE300` VARCHAR(100) COMMENT '补换卡原因编码',
  `AAE400` VARCHAR(1000) COMMENT '销户原因',
  `CREATE_BY` VARCHAR(500) COMMENT '创建人',
  `CREATE_DATE` DATETIME COMMENT '创建时间',
  `UPDATE_BY` VARCHAR(500) COMMENT '操作员',
  `UPDATE_DATE` DATETIME COMMENT '操作时间',
  `REMARKS` VARCHAR(1000) COMMENT '备注',
  `DEL_FLAG` VARCHAR(10) COMMENT '删除标记',
  `platformSeqId` VARCHAR(1000) COMMENT '渠道平台流水号',
  `sync_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime default current_timestamp on update current_timestamp comment '更新时间戳'
) ENGINE=OLAP
UNIQUE KEY(`ID`)
COMMENT '个人申领流程日志表'
DISTRIBUTED BY HASH(`ID`) BUCKETS 10
PROPERTIES (
    "replication_allocation" = "tag.location.default: 3"
);

```

##### 1.1.1.5.2 创建全量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_csk_cz05';
CREATE JOB sync_ods_sjzt_csk_cz05
        ON SCHEDULE
        -- 注意：这个时间必须是未来的时间
        AT '2024-11-08 00:01:00'
DO
INSERT INTO ods.`ods_sjzt_csk_cz05` (
    ID,
    CC02_ID,
    AAC018,
    AAC018A,
    AAZ500,
    AAE165,
    AAE200,
    AAE001,
    AAE300,
    AAE400,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE,
    REMARKS,
    DEL_FLAG,
    platformSeqId
)
SELECT
      ID,
    CC02_ID,
    AAC018,
    AAC018A,
    AAZ500,
    AAE165,
    AAE200,
    AAE001,
    AAE300,
    AAE400,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE,
    REMARKS,
    DEL_FLAG,
    platformSeqId
FROM jdbc_hmsk_sjzt.bjcard_makeuse.csk_cz05;
-- select count(1) from ods.ods_sjzt_csk_cz05;
-- select count(1) from jdbc_hmsk_sjzt.bjcard_makeuse.csk_cz05;

```

##### 1.1.1.5.3 创建增量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_csk_cz05';
CREATE JOB sync_ods_sjzt_csk_cz05
        -- quantity { WEEK | DAY | HOUR | MINUTE }
        ON SCHEDULE EVERY 1 HOUR
        STARTS '2024-01-01 03:00:00'
DO
INSERT INTO ods.`ods_sjzt_csk_cz05` (
    ID,
    CC02_ID,
    AAC018,
    AAC018A,
    AAZ500,
    AAE165,
    AAE200,
    AAE001,
    AAE300,
    AAE400,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE,
    REMARKS,
    DEL_FLAG,
    platformSeqId
)
SELECT
    ID,
    CC02_ID,
    AAC018,
    AAC018A,
    AAZ500,
    AAE165,
    AAE200,
    AAE001,
    AAE300,
    AAE400,
    CREATE_BY,
    CREATE_DATE,
    UPDATE_BY,
    UPDATE_DATE,
    REMARKS,
    DEL_FLAG,
    platformSeqId
FROM jdbc_hmsk_sjzt.bjcard_makeuse.csk_cz05
-- 当前时间之前俩小时
where ifnull(UPDATE_DATE,CREATE_DATE) >= DATE_SUB(NOW(), INTERVAL 2 HOUR)
;
```

### 1.1.2 换发日志表系统

#### 1.1.2.1 JDBC Catalog

同1.1.1.1中的[JDBC Catalog](Doris-V1.md#1-1-1-1-jdbc-catalog)，无需创建。

#### 1.1.2.2 t_rbsj_qxhftj

##### 1.1.2.2.1 建表

```SQL
drop table if exists ods.ods_sjzt_t_rbsj_qxhftj
CREATE TABLE if not exists ods.`ods_sjzt_t_rbsj_qxhftj` (
  `qb` VARCHAR(200) COMMENT '期别',
  `qxbm` INT COMMENT '区县编码',
  `qxmc` VARCHAR(500) COMMENT '区县名称',
  `mbdws` INT COMMENT '目标单位数',
  `yktqys` INT COMMENT '已开通企业数',
  `ktqyzb` VARCHAR(200) COMMENT '开通企业占比',
  `ljtjslrs` INT COMMENT '累计提交申领人数',
  `ljslrs` INT COMMENT '累计申领人数',
  `ljzkrs` INT COMMENT '累计制卡人数',
  `ljqyrs` INT COMMENT '累计启用人数',
  `xzktqys` INT COMMENT '新增开通企业',
  `xztjslrs` INT COMMENT '新增提交申领人数',
  `xzslrs` INT COMMENT '新增申领人数',
  `xzzkrs` INT COMMENT '新增制卡人数',
  `xzqyrs` INT COMMENT '新增启用人数',
  `sync_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime default current_timestamp on update current_timestamp comment '更新时间戳'
) ENGINE=OLAP
UNIQUE KEY(`qb`, `qxbm`)
DISTRIBUTED BY HASH(`qb`, `qxbm`) BUCKETS 10
PROPERTIES (
    "replication_allocation" = "tag.location.default: 3"
);

```

##### 1.1.2.2.2 创建全量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_t_rbsj_qxhftj';
CREATE JOB sync_ods_sjzt_t_rbsj_qxhftj
        ON SCHEDULE
        -- 注意：这个时间必须是未来的时间
        AT '2024-11-08 00:01:00'
DO
INSERT INTO ods.`ods_sjzt_t_rbsj_qxhftj` (
    qb,
    qxbm,
    qxmc,
    mbdws,
    yktqys,
    ktqyzb,
    ljtjslrs,
    ljslrs,
    ljzkrs,
    ljqyrs,
    xzktqys,
    xztjslrs,
    xzslrs,
    xzzkrs,
    xzqyrs
)
SELECT
    qb,
    qxbm,
    qxmc,
    mbdws,
    yktqys,
    ktqyzb,
    ljtjslrs,
    ljslrs,
    ljzkrs,
    ljqyrs,
    xzktqys,
    xztjslrs,
    xzslrs,
    xzzkrs,
    xzqyrs
FROM jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_qxhftj;
-- select count(1) from ods.ods_sjzt_t_rbsj_qxhftj;
-- select count(1) from jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_qxhftj;
```

##### 1.1.2.2.3 创建增量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_t_rbsj_qxhftj';
CREATE JOB sync_ods_sjzt_t_rbsj_qxhftj
        -- quantity { WEEK | DAY | HOUR | MINUTE }
        ON SCHEDULE EVERY 1 DAY
        STARTS '2024-01-01 05:00:00'
DO
INSERT INTO ods.`ods_sjzt_t_rbsj_qxhftj` (
    qb,
    qxbm,
    qxmc,
    mbdws,
    yktqys,
    ktqyzb,
    ljtjslrs,
    ljslrs,
    ljzkrs,
    ljqyrs,
    xzktqys,
    xztjslrs,
    xzslrs,
    xzzkrs,
    xzqyrs
)
SELECT
    qb,
    qxbm,
    qxmc,
    mbdws,
    yktqys,
    ktqyzb,
    ljtjslrs,
    ljslrs,
    ljzkrs,
    ljqyrs,
    xzktqys,
    xztjslrs,
    xzslrs,
    xzzkrs,
    xzqyrs
FROM jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_qxhftj
-- 当前同步时间的昨天凌晨
WHERE qb >= date_format(DATE_SUB(CURDATE(), INTERVAL 1 DAY),'%Y-%m-%d')
```

#### 1.1.2.3 t_rbsj_rqhftj

##### 1.1.2.3.1 建表

```SQL
drop table if exists ods.ods_sjzt_t_rbsj_rqhftj;
CREATE TABLE ods.`ods_sjzt_t_rbsj_rqhftj` (
  `qb` varchar(200) COMMENT '期别',
  `rqbm` int COMMENT '人群编码',
  `rqdl` varchar(500) COMMENT '人群大类',
  `rqmc` varchar(500)  COMMENT '人群名称',
  `mbrs` varchar(500)  COMMENT '目标人数',
  `mbdws` varchar(500)  COMMENT '目标单位数',
  `sjdws` varchar(500)  COMMENT '涉及单位数量',
  `sjdwzb` varchar(500)  COMMENT '涉及单位占比',
  `ktdws` varchar(500)  COMMENT '开通单位申领企业数',
  `ktdwzb` varchar(500)  COMMENT '单位开通申领占比',
  `ljtjslrs` varchar(500)  COMMENT '累计提交申领人数',
  `ljslrs` varchar(500)  COMMENT '累计申领人数',
  `ljzkrs` varchar(500)  COMMENT '累计制卡人数',
  `ljqyrs` varchar(500)  COMMENT '累计启用人数',
  `slwczb` varchar(500)  COMMENT '申领完成占比',
  `zkwczb` varchar(500)  COMMENT '制卡完成占比',
  `qywczb` varchar(500)  COMMENT '启用完成占比',
  `xzktqys` varchar(500)  COMMENT '新增开通企业数',
  `xztjslrs` varchar(500)  COMMENT '新增提交申领人数',
  `xzslrs` varchar(500)  COMMENT '新增申领人数',
  `xzzkrs` varchar(500)  COMMENT '新增制卡人数',
  `xzqyrs` varchar(500)  COMMENT '新增启用人数',
  `bz` string COMMENT '备注',
  `sync_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime default current_timestamp on update current_timestamp comment '更新时间戳'
)ENGINE=OLAP
UNIQUE KEY(`qb`, `rqbm`)
DISTRIBUTED BY HASH(`qb`, `rqbm`) BUCKETS 10
PROPERTIES (
    "replication_allocation" = "tag.location.default: 3"
);

```

##### 1.1.2.3.2 创建全量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_t_rbsj_rqhftj';
CREATE JOB sync_ods_sjzt_t_rbsj_rqhftj
        ON SCHEDULE
        -- 注意：这个时间必须是未来的时间
        AT '2024-11-08 00:01:00'
DO
INSERT INTO ods.`ods_sjzt_t_rbsj_rqhftj` (
    qb,
    rqbm,
    rqdl,
    rqmc,
    mbrs,
    mbdws,
    sjdws,
    sjdwzb,
    ktdws,
    ktdwzb,
    ljtjslrs,
    ljslrs,
    ljzkrs,
    ljqyrs,
    slwczb,
    zkwczb,
    qywczb,
    xzktqys,
    xztjslrs,
    xzslrs,
    xzzkrs,
    xzqyrs,
    bz
)
SELECT
    qb,
    rqbm,
    rqdl,
    rqmc,
    mbrs,
    mbdws,
    sjdws,
    sjdwzb,
    ktdws,
    ktdwzb,
    ljtjslrs,
    ljslrs,
    ljzkrs,
    ljqyrs,
    slwczb,
    zkwczb,
    qywczb,
    xzktqys,
    xztjslrs,
    xzslrs,
    xzzkrs,
    xzqyrs,
    bz
FROM jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_rqhftj;
-- select count(1) from ods.ods_sjzt_t_rbsj_rqhftj;
-- select count(1) from jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_rqhftj;
```

##### 1.1.2.3.3 创建增量同步JOB

```SQL
DROP JOB if exists where jobName='bsync_ods_sjzt_t_rbsj_rqhftj';
CREATE JOB bsync_ods_sjzt_t_rbsj_rqhftj
        -- quantity { WEEK | DAY | HOUR | MINUTE }
        ON SCHEDULE EVERY 1 DAY
        STARTS '2024-01-01 05:00:00'
DO
INSERT INTO ods.`ods_sjzt_t_rbsj_rqhftj` (
    qb,
    rqbm,
    rqdl,
    rqmc,
    mbrs,
    mbdws,
    sjdws,
    sjdwzb,
    ktdws,
    ktdwzb,
    ljtjslrs,
    ljslrs,
    ljzkrs,
    ljqyrs,
    slwczb,
    zkwczb,
    qywczb,
    xzktqys,
    xztjslrs,
    xzslrs,
    xzzkrs,
    xzqyrs,
    bz
)
SELECT
    qb,
    rqbm,
    rqdl,
    rqmc,
    mbrs,
    mbdws,
    sjdws,
    sjdwzb,
    ktdws,
    ktdwzb,
    ljtjslrs,
    ljslrs,
    ljzkrs,
    ljqyrs,
    slwczb,
    zkwczb,
    qywczb,
    xzktqys,
    xztjslrs,
    xzslrs,
    xzzkrs,
    xzqyrs,
    bz
FROM jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_rqhftj
-- 当前同步时间的昨天凌晨
WHERE qb >= date_format(DATE_SUB(CURDATE(), INTERVAL 1 DAY),'%Y-%m-%d')
```

#### 1.1.2.4 t_rbsj_yhhftj

##### 1.1.2.4.1 建表

```SQL
drop table if exists ods.ods_sjzt_t_rbsj_yhhftj;
CREATE TABLE ods.`ods_sjzt_t_rbsj_yhhftj` (
  `qb` varchar(200)  COMMENT '期别',
  `yhbm` varchar(200)  COMMENT '银行编码',
  `yhmc` varchar(500)  COMMENT '银行名称',
  `sjdws` int  COMMENT '涉及单位数量',
  `ktdws` int  COMMENT '开通单位数量',
  `ljplzktjslrs` int  COMMENT '批量制卡提交申领人数',
  `ljjszktjslrs` int  COMMENT '即时制卡提交申领人数',
  `ljtjslrs` int  COMMENT '累计提交申领人数',
  `ljslrs` int  COMMENT '累计申领人数',
  `ljplzkrs` int  COMMENT '累计批量制卡人数',
  `ljjszkrs` int  COMMENT '累计即时制卡人数',
  `ljzkrs` int  COMMENT '累计制卡人数',
  `ljqyrs` int  COMMENT '累计启用人数',
  `xzktqys` int  COMMENT '新增开通企业',
  `xzplzktjslrs` int  COMMENT '新增批量制卡提交申领人数',
  `xzjszktjslrs` int  COMMENT '新增即时制卡提交申领人数',
  `xztjslrs` int  COMMENT '新增提交申领人数',
  `xzslrs` int  COMMENT '新增申领人数',
  `xzzkrs` int  COMMENT '新增制卡人数',
  `xzqyrs` int  COMMENT '新增启用人数',
  `sync_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime default current_timestamp on update current_timestamp comment '更新时间戳'
) ENGINE=OLAP
UNIQUE KEY(`qb`,`yhbm`)
DISTRIBUTED BY HASH(`qb`,`yhbm`) BUCKETS 10
PROPERTIES (
  "replication_allocation" = "tag.location.default: 3"
);
```

##### 1.1.2.4.2 创建全量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_t_rbsj_yhhftj';
CREATE JOB sync_ods_sjzt_t_rbsj_yhhftj
        ON SCHEDULE
        -- 注意：这个时间必须是未来的时间
        AT '2024-11-08 00:01:00'
DO
INSERT INTO ods.`ods_sjzt_t_rbsj_yhhftj` (
    qb,
    yhbm,
    yhmc,
    sjdws,
    ktdws,
    ljplzktjslrs,
    ljjszktjslrs,
    ljtjslrs,
    ljslrs,
    ljplzkrs,
    ljjszkrs,
    ljzkrs,
    ljqyrs,
    xzktqys,
    xzplzktjslrs,
    xzjszktjslrs,
    xztjslrs,
    xzslrs,
    xzzkrs,
    xzqyrs
)
SELECT
    qb,
    yhbm,
    yhmc,
    sjdws,
    ktdws,
    ljplzktjslrs,
    ljjszktjslrs,
    ljtjslrs,
    ljslrs,
    ljplzkrs,
    ljjszkrs,
    ljzkrs,
    ljqyrs,
    xzktqys,
    xzplzktjslrs,
    xzjszktjslrs,
    xztjslrs,
    xzslrs,
    xzzkrs,
    xzqyrs
FROM jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_yhhftj;
-- select count(1) from ods.ods_sjzt_t_rbsj_yhhftj;
-- select count(1) from jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_yhhftj;
```

##### 1.1.2.4.3 创建增量同步JOB

```SQL
DROP JOB if exists where jobName='bsync_ods_sjzt_t_rbsj_yhhftj';
CREATE JOB bsync_ods_sjzt_t_rbsj_yhhftj
        -- quantity { WEEK | DAY | HOUR | MINUTE }
        ON SCHEDULE EVERY 1 DAY
        STARTS '2024-01-01 05:00:00'
DO
INSERT INTO ods.`ods_sjzt_t_rbsj_yhhftj` (
    qb,
    yhbm,
    yhmc,
    sjdws,
    ktdws,
    ljplzktjslrs,
    ljjszktjslrs,
    ljtjslrs,
    ljslrs,
    ljplzkrs,
    ljjszkrs,
    ljzkrs,
    ljqyrs,
    xzktqys,
    xzplzktjslrs,
    xzjszktjslrs,
    xztjslrs,
    xzslrs,
    xzzkrs,
    xzqyrs
)
SELECT
    qb,
    yhbm,
    yhmc,
    sjdws,
    ktdws,
    ljplzktjslrs,
    ljjszktjslrs,
    ljtjslrs,
    ljslrs,
    ljplzkrs,
    ljjszkrs,
    ljzkrs,
    ljqyrs,
    xzktqys,
    xzplzktjslrs,
    xzjszktjslrs,
    xztjslrs,
    xzslrs,
    xzzkrs,
    xzqyrs
FROM jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_yhhftj
-- 当前同步时间的昨天凌晨
WHERE qb >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m-%d')
```

#### 1.1.2.5 t_rbsj_ykztqkfx

##### 1.1.2.5.1 建表

```SQL
drop table if exists ods.ods_sjzt_t_rbsj_ykztqkfx;
CREATE TABLE if not exists ods.`ods_sjzt_t_rbsj_ykztqkfx` (
  `qb` varchar(200) COMMENT '期别',
  `qxbm` int COMMENT '区县编码',
  `qx` varchar(500) COMMENT '区县',
  `sjrysl` int COMMENT '涉及人员数量',
  `ykzcs` int COMMENT '用卡总次数',
  `yyykcs` int COMMENT '医院用卡次数',
  `ydykcs` int COMMENT '药店用卡次数',
  `sbsykcs` int COMMENT '社保所用卡次数',
  `tsgykcs` int COMMENT '图书馆用卡次数',
  `sync_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime default current_timestamp on update current_timestamp comment '更新时间戳'
) ENGINE=OLAP
UNIQUE KEY(`qb`,`qxbm`)
DISTRIBUTED BY HASH(`qb`,`qxbm`) BUCKETS 10
PROPERTIES (
  "replication_allocation" = "tag.location.default: 3"
);
```

##### 1.1.2.5.2 创建全量同步JOB

```SQL

DROP JOB if exists where jobName='sync_ods_sjzt_t_rbsj_ykztqkfx';
CREATE JOB sync_ods_sjzt_t_rbsj_ykztqkfx
        ON SCHEDULE
        -- 注意：这个时间必须是未来的时间
        AT '2024-11-08 00:01:00'
DO
INSERT INTO ods.`ods_sjzt_t_rbsj_ykztqkfx` (
    qb,
    qxbm,
    qx,
    sjrysl,
    ykzcs,
    yyykcs,
    ydykcs,
    sbsykcs,
    tsgykcs
)
SELECT
    qb,
    qxbm,
    qx,
    sjrysl,
    ykzcs,
    yyykcs,
    ydykcs,
    sbsykcs,
    tsgykcs
FROM jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_ykztqkfx;
-- select count(1) from ods.ods_sjzt_t_rbsj_ykztqkfx;
-- select count(1) from jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_ykztqkfx;
```

##### 1.1.2.5.3 创建增量同步JOB

```SQL
DROP JOB if exists where jobName='bsync_ods_sjzt_t_rbsj_ykztqkfx';
CREATE JOB bsync_ods_sjzt_t_rbsj_ykztqkfx
        -- quantity { WEEK | DAY | HOUR | MINUTE }
        ON SCHEDULE EVERY 1 DAY
        STARTS '2024-01-01 05:00:00'
DO
INSERT INTO ods.`ods_sjzt_t_rbsj_ykztqkfx` (
    qb,
    qxbm,
    qx,
    sjrysl,
    ykzcs,
    yyykcs,
    ydykcs,
    sbsykcs,
    tsgykcs
)
SELECT
    qb,
    qxbm,
    qx,
    sjrysl,
    ykzcs,
    yyykcs,
    ydykcs,
    sbsykcs,
    tsgykcs
FROM jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_ykztqkfx
-- 当前同步时间的昨天凌晨
WHERE qb >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m-%d')

```

#### 1.1.2.6 t_rbsj_yljgykfx

##### 1.1.2.6.1 建表

```SQL
drop table if exists ods.ods_sjzt_t_rbsj_yljgykfx;
CREATE TABLE if not exists ods.`ods_sjzt_t_rbsj_yljgykfx` (
  `qb` varchar(200) COMMENT '期别',
  `zbbm` int COMMENT '指标编码',
  `zbmc` varchar(500) COMMENT '指标名称',
  `yys` int COMMENT '医院数',
  `yds` int COMMENT '药店数',
  `heji` int COMMENT '小计',
  `sync_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime default current_timestamp on update current_timestamp comment '更新时间戳'
) ENGINE=OLAP
UNIQUE KEY(`qb`,`zbbm`)
DISTRIBUTED BY HASH(`qb`,`zbbm`) BUCKETS 10
PROPERTIES (
  "replication_allocation" = "tag.location.default: 3"
);
```

##### 1.1.2.6.2 创建全量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_t_rbsj_yljgykfx';
CREATE JOB sync_ods_sjzt_t_rbsj_yljgykfx
        ON SCHEDULE
        -- 注意：这个时间必须是未来的时间
        AT '2024-11-08 00:01:00'
DO
INSERT INTO ods.`ods_sjzt_t_rbsj_yljgykfx` (
    qb,
    zbbm,
    zbmc,
    yys,
    yds,
    heji
)
SELECT
    qb,
    zbbm,
    zbmc,
    yys,
    yds,
    heji
FROM jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_yljgykfx;
-- select count(1) from ods.ods_sjzt_t_rbsj_yljgykfx;
-- select count(1) from jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_yljgykfx;
```

##### 1.1.2.6.3 创建增量同步JOB

```SQL
CREATE JOB bsync_ods_sjzt_t_rbsj_yljgykfx
        -- quantity { WEEK | DAY | HOUR | MINUTE }
        ON SCHEDULE EVERY 1 DAY
        STARTS '2024-01-01 05:00:00'
DO
INSERT INTO ods.`ods_sjzt_t_rbsj_yljgykfx` (
    qb,
    zbbm,
    zbmc,
    yys,
    yds,
    heji
)
SELECT
    qb,
    zbbm,
    zbmc,
    yys,
    yds,
    heji
FROM jdbc_hmsk_sjzt.bjcard_makeuse.t_rbsj_yljgykfx
-- 当前同步时间的昨天凌晨
WHERE qb >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m-%d')
```

### 1.1.3 渠道码系统

#### 1.1.3.1 channel_code_trace

##### 1.1.3.1.1 建表

```sql
drop table if exists ods.ods_sjzt_channel_code_trace;
CREATE TABLE ods.`ods_sjzt_channel_code_trace` (
  `id` bigint,
  `channel_code` varchar(1000) COMMENT '渠道整体编码字段',
  `uid` bigint COMMENT '用户id',
  `uname` varchar(1000) COMMENT '用户姓名',
  `id_type` varchar(600) COMMENT '证件类型',
  `id_no` varchar(1000) COMMENT '证件号码(加密)',
  `user_calc_id` varchar(1000) COMMENT '三要素摘要',
  `phone` varchar(1000) COMMENT '手机号(加密)',
  `usci` varchar(1000) COMMENT '企业信用代码',
  `bank_no` varchar(1000) COMMENT '银行编码',
  `bank_branch_code` varchar(1000) COMMENT '银行网点编码',
  `bank_agree_flag` varchar(20) COMMENT '是否同意某银行协议标识(0:不同意 1:同意)',
  `sync_flag` varchar(20) COMMENT '同步标识 0-未同步 1-已同步',
  `action_type` varchar(100) COMMENT '事件类型  第一次扫码进入1 访问2 短信验证码注册3  微信手机号注册4  实名认证5 单位申请提交6 个人申请提交7 代办申请提交8 撤销9 启用10 制卡成功 11 制卡失败 12开户失败 13照片审核失败 14 注销 15',
  `active` int(1) COMMENT '是否激活 0-未激活(删除)1-激活(正常)',
  `create_time` datetime COMMENT '创建时间',
  `sync_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime default current_timestamp on update current_timestamp comment '更新时间戳'
  -- PRIMARY KEY (`id`) USING BTREE,
  -- KEY `time_code` (`channel_code`,`action_type`,`create_time`) USING BTREE COMMENT '埋点时间 渠道码',
  -- KEY `branch_code_type` (`bank_branch_code`,`action_type`,`create_time`) USING BTREE COMMENT '银行网点 事件类型',
  -- KEY `user_calc_id` (`user_calc_id`) USING BTREE COMMENT '用户三要素',
  -- KEY `bank_file` (`bank_no`,`bank_agree_flag`,`sync_flag`) USING BTREE COMMENT '银行 同步标识',
  -- KEY `action_type` (`action_type`) USING BTREE COMMENT '操作类型',
  -- KEY `create_time` (`create_time`) USING BTREE COMMENT '时间 定时任务'
) ENGINE=OLAP
unique key(`id`)
COMMENT '埋点-事件记录表'
DISTRIBUTED BY HASH(`id`) BUCKETS 10
PROPERTIES (
  "replication_allocation" = "tag.location.default: 3"
);
```

##### 1.1.3.1.2 创建全量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_channel_code_trace';
CREATE JOB sync_ods_sjzt_channel_code_trace
        ON SCHEDULE
        -- 注意：这个时间必须是未来的时间
        AT '2024-11-08 00:01:00'
DO
INSERT INTO ods.`ods_sjzt_channel_code_trace` (
    id,
    channel_code,
    uid,
    uname,
    id_type,
    id_no,
    user_calc_id,
    phone,
    usci,
    bank_no,
    bank_branch_code,
    bank_agree_flag,
    sync_flag,
    action_type,
    active,
    create_time
)
SELECT
    id,
    channel_code,
    uid,
    uname,
    id_type,
    id_no,
    user_calc_id,
    phone,
    usci,
    bank_no,
    bank_branch_code,
    bank_agree_flag,
    sync_flag,
    action_type,
    active,
    create_time
FROM jdbc_hmsk_sjzt.bjcard_makeuse.channel_code_trace;
-- select count(1) from ods.ods_sjzt_channel_code_trace;
-- select count(1) from jdbc_hmsk_sjzt.bjcard_makeuse.channel_code_trace;
```

##### 1.1.3.1.3 创建增量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_channel_code_trace';
CREATE JOB sync_ods_sjzt_channel_code_trace
        -- quantity { WEEK | DAY | HOUR | MINUTE }
        ON SCHEDULE EVERY 1 HOUR
        -- 注意：这个时间必须是未来的时间
        STARTS '2024-01-01 03:00:00'
DO
INSERT INTO ods.`ods_sjzt_channel_code_trace` (
    id,
    channel_code,
    uid,
    uname,
    id_type,
    id_no,
    user_calc_id,
    phone,
    usci,
    bank_no,
    bank_branch_code,
    bank_agree_flag,
    sync_flag,
    action_type,
    active,
    create_time
)
SELECT
    id,
    channel_code,
    uid,
    uname,
    id_type,
    id_no,
    user_calc_id,
    phone,
    usci,
    bank_no,
    bank_branch_code,
    bank_agree_flag,
    sync_flag,
    action_type,
    active,
    create_time
FROM jdbc_hmsk_sjzt.bjcard_makeuse.channel_code_trace
where create_time >= DATE_SUB(NOW(), INTERVAL 2 HOUR)
;

```

#### 1.1.3.2 channel

##### 1.1.3.2.1 建表

```SQL
drop table if exists ods.ods_sjzt_channel;
CREATE TABLE if not exists ods.`ods_sjzt_channel` (
  `id` bigint COMMENT '自增主键',
  `region_id` bigint COMMENT '分区ID',
  `channel_code` varchar(100) COMMENT '渠道编码',
  `channel_type` int COMMENT '内部码 1 外部码 2',
  `bank_no` varchar(1000) COMMENT '银行编码',
  `bank_name` varchar(1000) COMMENT '银行名称',
  `bank_branch_code` varchar(1000) COMMENT '分行、网点编码',
  `bank_branch_name` varchar(1000) COMMENT '分行、网点名称',
  `employee_code` varchar(1000) COMMENT '员工编码',
  `employee_number` varchar(1000) COMMENT '员工工号',
  `employee_name` varchar(1000) COMMENT '员工名称',
  `file_id` varchar(1000) COMMENT '文件id',
  `logo_img_url` varchar(1000) COMMENT '个性化Logo上传地址',
  `status` int(1) COMMENT '状态 0-下架 1-上架',
  `remark` varchar(1000) COMMENT '备注',
  `active` int(1) COMMENT '是否激活',
  `create_time` datetime COMMENT '创建时间',
  `sync_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime default current_timestamp on update current_timestamp comment '更新时间戳'
  -- PRIMARY KEY (`id`) USING BTREE,
  -- UNIQUE KEY `channel_code` (`channel_code`) USING BTREE COMMENT '渠道码'
) ENGINE=OLAP
unique key(`id`)
COMMENT '渠道码'
DISTRIBUTED BY HASH(`id`) BUCKETS 10
PROPERTIES (
  "replication_allocation" = "tag.location.default: 3"
);
```

##### 1.1.3.2.2 创建全量同步JOB

```sql
DROP JOB if exists where jobName='sync_ods_sjzt_channel';
CREATE JOB sync_ods_sjzt_channel
        ON SCHEDULE
        -- 注意：这个时间必须是未来的时间
        AT '2024-11-08 00:01:00'
DO
INSERT INTO ods.`ods_sjzt_channel` (
    id,
    region_id,
    channel_code,
    channel_type,
    bank_no,
    bank_name,
    bank_branch_code,
    bank_branch_name,
    employee_code,
    employee_number,
    employee_name,
    file_id,
    logo_img_url,
    status,
    remark,
    active,
    create_time
)
SELECT
    id,
    region_id,
    channel_code,
    channel_type,
    bank_no,
    bank_name,
    bank_branch_code,
    bank_branch_name,
    employee_code,
    employee_number,
    employee_name,
    file_id,
    logo_img_url,
    status,
    remark,
    active,
    create_time
FROM jdbc_hmsk_sjzt.bjcard_makeuse.channel;
-- select count(1) from ods.ods_sjzt_channel;
-- select count(1) from jdbc_hmsk_sjzt.bjcard_makeuse.channel;
```

##### 1.1.3.2.3 创建增量同步JOB

```SQL
DROP JOB if exists where jobName='sync_ods_sjzt_channel';
CREATE JOB sync_ods_sjzt_channel
        -- quantity { WEEK | DAY | HOUR | MINUTE }
        ON SCHEDULE EVERY 1 HOUR
        -- 注意：这个时间必须是未来的时间
        STARTS '2024-01-01 03:00:00'
DO
INSERT INTO ods.`ods_sjzt_channel` (
    id,
    region_id,
    channel_code,
    channel_type,
    bank_no,
    bank_name,
    bank_branch_code,
    bank_branch_name,
    employee_code,
    employee_number,
    employee_name,
    file_id,
    logo_img_url,
    status,
    remark,
    active,
    create_time
)
SELECT
    id,
    region_id,
    channel_code,
    channel_type,
    bank_no,
    bank_name,
    bank_branch_code,
    bank_branch_name,
    employee_code,
    employee_number,
    employee_name,
    file_id,
    logo_img_url,
    status,
    remark,
    active,
    create_time
FROM jdbc_hmsk_sjzt.bjcard_makeuse.channel
where create_time >= DATE_SUB(NOW(), INTERVAL 2 HOUR)
;
```

## 1.2 dwd_channel_code_count_1d

### 1.2.1 建表

```SQL
drop table if exists dwd.dwd_channel_code_count_1d;

CREATE TABLE dwd.`dwd_channel_code_count_1d`
(
    `date_total`       date not null COMMENT '统计时间',
    `channel_code`     varchar(1000) COMMENT '渠道码',
    `bank_name`        varchar(1000) COMMENT '银行名称',
    `bank_no`          varchar(1000) COMMENT '银行编码',
    `bank_branch_code` varchar(1000) COMMENT '分行、网点编码',
    `bank_branch_name` varchar(1000) COMMENT '分行、网点名称',
    `employee_code`    varchar(1000) COMMENT '员工编码',
    `employee_number`  varchar(1000) COMMENT '员工工号',
    `employee_name`    varchar(1000) COMMENT '员工名称',
    `scfw`             int COMMENT '首次访问数目',
    `fw`               int COMMENT '访问数目',
    `dxzc`             int COMMENT '短信验证码注册数目',
    `wxzc`             int COMMENT '微信手机号注册数目',
    `smrz`             int COMMENT '实名认证数目',
    `dwsqtj`           int COMMENT '单位申请提交数目',
    `grsqtj`           int COMMENT '个人申请提交数目',
    `dbsqtj`           int COMMENT '代办申请提交数目',
    `cx`               int COMMENT '撤销数目',
    `qy`               int COMMENT '启用数目',
    `zkcg`             int COMMENT '制卡成功',
    `zksb`             int COMMENT '制卡失败',
    `khsb`             int COMMENT '开户失败',
    `zpshsb`           int COMMENT '照片审核失败',
    `zx`               int COMMENT '注销',
    `dwjbrtj`          int COMMENT '单位经办人提交',
    `date_year`        int COMMENT '年份 如2024',
    `date_month`       int COMMENT '月份 01-12',
    `date_week`        int COMMENT '周 1~7',
    `date_day`         int COMMENT '01-31',
    `date_hour`        int COMMENT '时  00-23',
    `date_point`       int COMMENT '分 00,05,10,15,20,25,30,35,40,45,50,55\r\n向后包含（00-05)等于00、(05-10)等于05、(55-00)等于55\r\n例: 45< x  <= 50',
    `active`           int(1) COMMENT '是否激活',
    `create_time`      datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`      datetime default current_timestamp on update current_timestamp comment '更新时间戳'
    -- PRIMARY KEY (`id`) USING BTREE,
    -- KEY `channel_code_date` (`channel_code`,`date_year`,`date_month`,`date_day`) USING BTREE COMMENT '渠道码 时间',
    -- KEY `date_branch_code` (`channel_code`,`date_total`) USING BTREE COMMENT '渠道码 时间'
) ENGINE = OLAP
unique key(`date_total`,`channel_code`)
COMMENT '渠道码按天统计表'
PARTITION BY RANGE (`date_total`)
(

)
DISTRIBUTED BY HASH(`date_total`) BUCKETS 10
PROPERTIES (
    "dynamic_partition.enable" = "true",
    "dynamic_partition.create_history_partition"="true",
    "dynamic_partition.history_partition_num"="1",
    "dynamic_partition.prefix" = "p",
    "dynamic_partition.end" = "3",
    "dynamic_partition.time_unit" = "day",
    "replication_num" = "3"
);

show partitions from dwd.dwd_channel_code_count_1d;
```

### 1.2.2 导入历史数据

1.查看表的分区情况

`show partitions from dwd.dwd_channel_code_count_1d;`

可以看到类似如下的分区信息：

p20241125  
p20241126  
p20241127  
p20241128  
p20241129

2.手动创建一个分区用于存储历史数据
```SQL
-- 临时禁用自动分区
ALTER TABLE dwd.dwd_channel_code_count_1d SET ("dynamic_partition.enable" = "false");
-- 添加一个分区用于存储历史数据
ALTER TABLE dwd.dwd_channel_code_count_1d ADD PARTITION p20241124 VALUES LESS THAN ("2024-11-25");
-- 重新开启自动分区
ALTER TABLE dwd.dwd_channel_code_count_1d SET ("dynamic_partition.enable" = "true");
-- 查看分区
show partitions from dwd.dwd_channel_code_count_1d;

```

``

3.插入历史数据

```sql
insert into dwd.dwd_channel_code_count_1d (
    date_total,
    channel_code,
    bank_name,
    bank_no,
    bank_branch_code,
    bank_branch_name,
    employee_code,
    employee_number,
    employee_name,
    scfw,
    fw,
    dxzc,
    wxzc,
    smrz,
    dwsqtj,
    grsqtj,
    dbsqtj,
    cx,
    qy,
    zkcg,
    zksb,
    khsb,
    zpshsb,
    zx,
    dwjbrtj,
    date_year,
    date_month,
    date_week,
    date_day,
    date_hour,
    date_point,
    active
)
select 
    date(date_total),
    channel_code,
    bank_name,
    bank_no,
    bank_branch_code,
    bank_branch_name,
    employee_code,
    employee_number,
    employee_name,
    scfw,
    fw,
    dxzc,
    wxzc,
    smrz,
    dwsqtj,
    grsqtj,
    dbsqtj,
    cx,
    qy,
    zkcg,
    zksb,
    khsb,
    zpshsb,
    zx,
    dwjbrtj,
    date_year,
    date_month,
    date_week,
    date_day,
    0 as date_hour,
    0 as date_point,
    active
from jdbc_hmsk_sjzt.bjcard_makeuse.dwd_channel_code_count_1d;
```
### 1.2.3 定时任务

```SQL
DROP JOB if exists where jobName='dwd_channel_code_count_1d';
CREATE JOB dwd_channel_code_count_1d
        -- quantity { WEEK | DAY | HOUR | MINUTE }
        ON SCHEDULE EVERY 1 DAY
        STARTS '2024-01-01 05:00:00'
DO
insert into dwd.dwd_channel_code_count_1d(
    date_total,
    channel_code,
    bank_name,
    bank_no,
    bank_branch_code,
    bank_branch_name,
    employee_code,
    employee_number,
    employee_name,
    scfw,
    fw,
    dxzc,
    wxzc,
    smrz,
    dwsqtj,
    grsqtj,
    dbsqtj,
    cx,
    qy,
    zkcg,
    zksb,
    khsb,
    zpshsb,
    zx,
    dwjbrtj,
    date_year,
    date_month,
    date_week,
    date_day,
    date_hour,
    date_point,
    active
)
SELECT
    DATE_SUB(CURDATE(), INTERVAL 1 DAY) date_total,
    a.channel_code,
    a.bank_no,
    a.bank_name,
    a.bank_branch_code,
    a.bank_branch_name,
    a.employee_code,
    a.employee_number,
    a.employee_name,
    -- 下面的指标统计各个渠道码的action_type
    COALESCE(scfw, 0)    AS scfw,
    COALESCE(fw, 0)      AS fw,
    COALESCE(dxzc, 0)    AS dxzc,
    COALESCE(wxzc, 0)    AS wxzc,
    COALESCE(smrz, 0)    AS smrz,
    COALESCE(dwsqtj, 0)  AS dwsqtj,
    COALESCE(grsqtj, 0)  AS grsqtj,
    COALESCE(dbsqtj, 0)  AS dbsqtj,
    -- 下面的指标统计各个渠道码对应的人卡状态发生变更的次数
    COALESCE(qy, 0)      AS qy,
    COALESCE(zx, 0)      AS zx,
    COALESCE(cx, 0)      AS cx,
    COALESCE(khsb, 0)    AS khsb,
    COALESCE(zksb, 0)    AS zksb,
    COALESCE(zkcg, 0)    AS zkcg,
    COALESCE(zpshsb, 0)  AS zpshsb,
    COALESCE(dwjbrtj, 0) AS dwjbrtj,
    -- 以下的年、月份、当前月的第几周、几号、小时、分钟 在查询过程中尽量不要使用
    -- date_total代表的是汇总的数据的日期 直接从date_total进行过滤处理
    -- 昨天的年数
    year(DATE_SUB(CURDATE(), INTERVAL 1 DAY)) date_year,
    -- 昨天的月份
    month(DATE_SUB(CURDATE(), INTERVAL 1 DAY)) date_month,
    -- select weekday('2024-11-25'); -- 0
    -- select weekday('2024-11-26'); -- 1
    -- select weekday('2024-11-27'); -- 2
    -- select weekday('2024-11-28'); -- 3
    -- select weekday('2024-11-29'); -- 4
    -- select weekday('2024-11-30'); -- 5
    -- select weekday('2024-12-01'); -- 6
    -- case when WEEKDAY(DATE_SUB(CURDATE(), INTERVAL 1 DAY)) = 0 then 7
    --      when WEEKDAY(DATE_SUB(CURDATE(), INTERVAL 1 DAY)) = 1 then 1
    --      when WEEKDAY(DATE_SUB(CURDATE(), INTERVAL 1 DAY)) = 2 then 2
    --      when WEEKDAY(DATE_SUB(CURDATE(), INTERVAL 1 DAY)) = 3 then 3
    --      when WEEKDAY(DATE_SUB(CURDATE(), INTERVAL 1 DAY)) = 4 then 4
    --      when WEEKDAY(DATE_SUB(CURDATE(), INTERVAL 1 DAY)) = 5 then 5
    --      when WEEKDAY(DATE_SUB(CURDATE(), INTERVAL 1 DAY)) = 6 then 6
    -- end date_week,
    -- WEEKDAY(DATE_SUB(CURDATE(), INTERVAL 1 DAY)) date_week,
    -- 昨天是当前月的第几周
    CEIL((DAYOFMONTH(CURDATE() - INTERVAL 1 DAY) + WEEKDAY(DATE_FORMAT(CURDATE(), '%Y-%m-01'))) / 7) AS date_week
    -- 昨天是几号
    DAY(DATE_SUB(CURDATE(), INTERVAL 1 DAY)) date_day,
    -- 由于CURDATE()取的是Date类型 小时和分钟都是0
    hour(DATE_SUB(CURDATE(), INTERVAL 1 DAY)) date_hour,
    minute(DATE_SUB(CURDATE(), INTERVAL 1 DAY)) date_point,
    1 active
from (select * from ods.ods_sjzt_channel where active = 1) a
left join 
-- 渠道码的统计指标：渠道码 + 统计指标 
-- 渠道码唯一
(
    -- 临时表统计各种操作的次数
    with temp as (
        SELECT 
            channel_code, 
            action_type, 
            COUNT(1) as count
        FROM ods.ods_sjzt_channel_code_trace
        -- 只统计昨天的动作
        WHERE date(create_time = date(DATE_SUB(CURDATE(), INTERVAL 1 DAY))
        GROUP BY channel_code, action_type
    )
    -- 行转列 指标汇总
    SELECT channel_code,
        IFNULL(MAX(CASE WHEN action_type = 1 THEN count END), 0)  AS scfw,
        IFNULL(MAX(CASE WHEN action_type = 2 THEN count END), 0)  AS fw,
        IFNULL(MAX(CASE WHEN action_type = 3 THEN count END), 0)  AS dxzc,
        IFNULL(MAX(CASE WHEN action_type = 4 THEN count END), 0)  AS wxzc,
        IFNULL(MAX(CASE WHEN action_type = 5 THEN count END), 0)  AS smrz,
        IFNULL(MAX(CASE WHEN action_type = 6 THEN count END), 0)  AS dwsqtj,
        IFNULL(MAX(CASE WHEN action_type = 7 THEN count END), 0)  AS grsqtj,
        IFNULL(MAX(CASE WHEN action_type = 8 THEN count END), 0)  AS dbsqtj
    FROM temp
    GROUP BY channel_code
) c on c.channel_code = a.channel_code
left join (
    with temp as (
        -- 获取人与渠道码的关系 关系由最后由最后进行申请提交的渠道码决定
        SELECT
            a.channel_code,
            a.user_calc_id,
            row_number() over (partition by a.user_calc_id order by a.create_time desc) as r
        FROM ods.ods_sjzt_channel_code_trace a
        -- 6：单位申请提交 7：个人申请提交 8：代办申请提交
        WHERE action_type IN (6, 7, 8)
    ),
    temp1 as (
        -- 增量状态轨迹表增量变化的人的卡状态数据
        -- temp1是为了后面统计各种卡状态的数据
        -- 卡状态变更对应着渠道码的统计发生变化，获取发生卡状态的人对应的渠道码
        SELECT
            trace.channel_code,
            trace.user_calc_id,
            cz05.AAC018
        FROM temp trace
        JOIN ods.ods_sjzt_csk_ac01 ac01 ON trace.user_calc_id = ac01.userCalcId
        JOIN ods.ods_sjzt_csk_cc02 cc02 ON ac01.ID = cc02.AC01_ID
        JOIN ods.ods_sjzt_csk_cz05 cz05 ON cc02.ID = cz05.CC02_ID
        WHERE trace.r = 1
        AND (
                cz05.AAC018 IN ( 1, 9, 22, 30, 70, 75, 115, 130) or (cz05.AAC018 = 5 and cc02.ACA016 = 2)
            )
        and date(cz05.create_time) = date(DATE_SUB(CURDATE(), INTERVAL 1 DAY))
    ),
    temp2 as (
        -- 统计不同渠道码下不同状态的数量
        select
            channel_code,
            case AAC018
                when 1 then 10
                when 9 then 15
                when 22 then 9
                when 30 then 13
                when 70 then 12
                when 75 then 11
                when 115 then 14
                when 130 then 14
                when 5 then 16
                else 0
            end as action_type,
            count(1) as count
        from temp1
        group by channel_code,
        case AAC018
            when 1 then 10
            when 9 then 15
            when 22 then 9
            when 30 then 13
            when 70 then 12
            when 75 then 11
            when 115 then 14
            when 130 then 14
            when 5 then 16
            else 0
        end
        )
    SELECT
        channel_code,
        IFNULL(MAX(CASE WHEN action_type = 10 THEN count END), 0) AS qy,
        IFNULL(MAX(CASE WHEN action_type = 15 THEN count END), 0) AS zx,
        IFNULL(MAX(CASE WHEN action_type = 9 THEN count END), 0)  AS cx,
        IFNULL(MAX(CASE WHEN action_type = 13 THEN count END), 0) AS khsb,
        IFNULL(MAX(CASE WHEN action_type = 12 THEN count END), 0) AS zksb,
        IFNULL(MAX(CASE WHEN action_type = 11 THEN count END), 0) AS zkcg,
        IFNULL(MAX(CASE WHEN action_type = 14 THEN count END), 0) AS zpshsb,
        IFNULL(MAX(CASE WHEN action_type = 16 THEN count END), 0) AS dwjbrtj
    FROM temp2
    GROUP BY channel_code
) b on b.channel_code = a.channel_code
```

[//]: # (#### 1.1.2.x xxxx)

[//]: # ()

[//]: # (##### 1.1.2.x.1 建表)

[//]: # ()

[//]: # (##### 1.1.2.x.2 创建全量同步JOB)

[//]: # ()

[//]: # (##### 1.1.2.x.3 创建增量同步JOB)