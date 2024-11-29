# 元数据

## 1.1 ods_sjzt_channel_code_trace

```SQL
CREATE TABLE `ods_sjzt_channel_code_trace` (
  `id` bigint NULL,
  `channel_code` varchar(1000) NULL COMMENT '渠道整体编码字段',
  `uid` bigint NULL COMMENT '用户id',
  `uname` varchar(1000) NULL COMMENT '用户姓名',
  `id_type` varchar(600) NULL COMMENT '证件类型',
  `id_no` varchar(1000) NULL COMMENT '证件号码(加密)',
  `user_calc_id` varchar(1000) NULL COMMENT '三要素摘要',
  `phone` varchar(1000) NULL COMMENT '手机号(加密)',
  `usci` varchar(1000) NULL COMMENT '企业信用代码',
  `bank_no` varchar(1000) NULL COMMENT '银行编码',
  `bank_branch_code` varchar(1000) NULL COMMENT '银行网点编码',
  `bank_agree_flag` varchar(20) NULL COMMENT '是否同意某银行协议标识(0:不同意 1:同意)',
  `sync_flag` varchar(20) NULL COMMENT '同步标识 0-未同步 1-已同步',
  `action_type` varchar(100) NULL COMMENT '事件类型  第一次扫码进入1 访问2 短信验证码注册3  微信手机号注册4  实名认证5 单位申请提交6 个人申请提交7 代办申请提交8 撤销9 启用10 制卡成功 11 制卡失败 12开户失败 13照片审核失败 14 注销 15',
  `active` int NULL COMMENT '是否激活 0-未激活(删除)1-激活(正常)',
  `create_time` datetime NULL COMMENT '创建时间',
  `sync_timestamp` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间戳'
) ENGINE=OLAP
UNIQUE KEY(`id`)
COMMENT '埋点-事件记录表'
DISTRIBUTED BY HASH(`id`) BUCKETS 10
PROPERTIES (
"replication_allocation" = "tag.location.default: 3",
"min_load_replica_num" = "-1",
"is_being_synced" = "false",
"storage_medium" = "hdd",
"storage_format" = "V2",
"inverted_index_storage_format" = "V1",
"enable_unique_key_merge_on_write" = "true",
"light_schema_change" = "true",
"disable_auto_compaction" = "false",
"enable_single_replica_compaction" = "false",
"group_commit_interval_ms" = "10000",
"group_commit_data_bytes" = "134217728",
"enable_mow_light_delete" = "false"
);
```

## 1.2 ods_sjzt_channel

```SQL
CREATE TABLE `ods_sjzt_channel` (
  `id` bigint NULL COMMENT '自增主键',
  `region_id` bigint NULL COMMENT '分区ID',
  `channel_code` varchar(100) NULL COMMENT '渠道编码',
  `channel_type` int NULL COMMENT '内部码 1 外部码 2',
  `bank_no` varchar(1000) NULL COMMENT '银行编码',
  `bank_name` varchar(1000) NULL COMMENT '银行名称',
  `bank_branch_code` varchar(1000) NULL COMMENT '分行、网点编码',
  `bank_branch_name` varchar(1000) NULL COMMENT '分行、网点名称',
  `employee_code` varchar(1000) NULL COMMENT '员工编码',
  `employee_number` varchar(1000) NULL COMMENT '员工工号',
  `employee_name` varchar(1000) NULL COMMENT '员工名称',
  `file_id` varchar(1000) NULL COMMENT '文件id',
  `logo_img_url` varchar(1000) NULL COMMENT '个性化Logo上传地址',
  `status` int NULL COMMENT '状态 0-下架 1-上架',
  `remark` varchar(1000) NULL COMMENT '备注',
  `active` int NULL COMMENT '是否激活',
  `create_time` datetime NULL COMMENT '创建时间',
  `sync_timestamp` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间戳'
) ENGINE=OLAP
UNIQUE KEY(`id`)
COMMENT '渠道码'
DISTRIBUTED BY HASH(`id`) BUCKETS 10
PROPERTIES (
"replication_allocation" = "tag.location.default: 3",
"min_load_replica_num" = "-1",
"is_being_synced" = "false",
"storage_medium" = "hdd",
"storage_format" = "V2",
"inverted_index_storage_format" = "V1",
"enable_unique_key_merge_on_write" = "true",
"light_schema_change" = "true",
"disable_auto_compaction" = "false",
"enable_single_replica_compaction" = "false",
"group_commit_interval_ms" = "10000",
"group_commit_data_bytes" = "134217728",
"enable_mow_light_delete" = "false"
);
```

## 1.3 ods_sjzt_csk_ac01

```SQL
CREATE TABLE `ods_sjzt_csk_ac01` (
  `ID` int NOT NULL COMMENT '序号',
  `userCalcId` varchar(1000) NULL,
  `AAC001` varchar(100) NULL COMMENT '个人编号',
  `AAC002` varchar(500) NULL COMMENT '证件号码',
  `AAC003` varchar(1000) NULL COMMENT '姓名',
  `AAC004` varchar(10) NULL COMMENT '性别',
  `AAC005` varchar(20) NULL COMMENT '民族',
  `AAC006` date NULL COMMENT '出生日期',
  `AAC008` varchar(100) NULL COMMENT '人员参保状态',
  `AAC009` varchar(200) NULL COMMENT '户口性质',
  `AAC010` varchar(1000) NULL COMMENT '户口所在地',
  `AAC031` varchar(100) NULL COMMENT '个人缴费状态',
  `AAE005` varchar(1000) NULL COMMENT '联系电话',
  `AAE006` text NULL COMMENT '通讯地址(常住所在地地址)',
  `AAE007` varchar(60) NULL COMMENT '邮政编码',
  `AAE015` varchar(1000) NULL COMMENT '电子信箱',
  `AAC161` varchar(100) NULL COMMENT '国籍  默认CHN',
  `AAB301_ID` varchar(120) NULL COMMENT '所属区域',
  `AAC058` varchar(20) NULL COMMENT '证件类型',
  `ACC009` varchar(500) NULL COMMENT '证件有效期起始日期',
  `ACC010` varchar(500) NULL COMMENT '证件有效期终止日期',
  `CREATE_BY` varchar(1000) NULL COMMENT '创建人',
  `CREATE_DATE` datetime NULL COMMENT '创建时间',
  `UPDATE_BY` varchar(1000) NULL COMMENT '操作员',
  `UPDATE_DATE` datetime NULL COMMENT '操作时间',
  `DEL_FLAG` varchar(10) NULL COMMENT '删除标记',
  `REMARKS` varchar(1000) NULL COMMENT '备注',
  `occupation` varchar(320) NULL COMMENT '职业',
  `addreesPer` text NULL COMMENT '户籍地址',
  `tel` varchar(1000) NULL COMMENT '固定电话不能同时为空',
  `AAB301` varchar(150) NULL COMMENT '常住区域编码',
  `AAC007` varchar(500) NULL COMMENT '社会保障号码',
  `PASSWORD` varchar(1000) NULL COMMENT '服务密码',
  `sync_timestamp` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间戳'
) ENGINE=OLAP
UNIQUE KEY(`ID`)
COMMENT '个人基本信息同步表'
DISTRIBUTED BY HASH(`ID`) BUCKETS 10
PROPERTIES (
"replication_allocation" = "tag.location.default: 3",
"min_load_replica_num" = "-1",
"is_being_synced" = "false",
"storage_medium" = "hdd",
"storage_format" = "V2",
"inverted_index_storage_format" = "V1",
"enable_unique_key_merge_on_write" = "true",
"light_schema_change" = "true",
"disable_auto_compaction" = "false",
"enable_single_replica_compaction" = "false",
"group_commit_interval_ms" = "10000",
"group_commit_data_bytes" = "134217728",
"enable_mow_light_delete" = "false"
);
```

## 1.4 ods_sjzt_csk_cc02

```SQL
CREATE TABLE `ods_sjzt_csk_cc02` (
  `ID` int NULL COMMENT '个人申领ID',
  `AC01_ID` int NULL COMMENT '个人基本信息ID',
  `AAB001` varchar(200) NULL COMMENT '单位编号',
  `AAB004` varchar(500) NULL COMMENT '单位名称',
  `ACA014` varchar(20) NULL COMMENT '申领渠道：1柜面渠道  2.自助申请  3.网上申请 4.银行线上渠道 5:银行线下渠道',
  `ACA017` varchar(10) NULL COMMENT '制卡类型：1:新开户、2 :补卡，3:换卡，4:同号换卡',
  `ACA016` varchar(10) NULL COMMENT '申领类型 1个人，2单位',
  `ACA015` varchar(20) NULL COMMENT '制卡方式（1.即时制卡 2.工厂制卡）',
  `AAC019` varchar(200) NULL COMMENT '金融状态',
  `AAC018` int NULL COMMENT '制卡流程状态（以card_status表aac018状态为准）',
  `AAZ500` varchar(100) NULL COMMENT '民生卡卡号',
  `AAE010` varchar(500) NULL COMMENT '银行卡号',
  `AAE010A` varchar(500) NULL COMMENT '金融账号',
  `AAE008` varchar(200) NULL COMMENT '银行编码',
  `AAE009` varchar(200) NULL COMMENT '网点编码',
  `AAB301` varchar(150) NULL COMMENT '所属区域',
  `ACC044` varchar(200) NULL COMMENT '未成年人标识 0否1是',
  `AAE165` varchar(1000) NULL COMMENT '开户失败的原因',
  `BATCH` varchar(500) NULL COMMENT '打包批次',
  `BATCH_NO` varchar(640) NULL COMMENT '制卡批次(未用到)',
  `SERVICE_NO` varchar(640) NULL COMMENT '办事编号',
  `personstatus` varchar(20) NULL COMMENT '11在职 21退休',
  `personcategory` varchar(10) NULL COMMENT '1为单位参保2为个人',
  `insurance` varchar(1000) NULL COMMENT '参保险种',
  `card_validity` varchar(200) NULL COMMENT '社保卡有效期',
  `upload_status` varchar(10) NULL COMMENT '上传标识',
  `CREATE_BY` varchar(500) NULL COMMENT '创建人',
  `CREATE_DATE` datetime NULL COMMENT '创建时间',
  `UPDATE_BY` varchar(500) NULL COMMENT '更新人',
  `UPDATE_DATE` datetime NULL COMMENT '更新时间',
  `REMARKS` varchar(1000) NULL COMMENT '备注',
  `DEL_FLAG` varchar(10) NULL COMMENT '删除标识',
  `department` varchar(640) NULL COMMENT '所在部门',
  `emsName` varchar(320) NULL COMMENT 'ems 联系人',
  `emsPhone` varchar(320) NULL COMMENT 'ems 联系电话',
  `emsCode` varchar(320) NULL COMMENT 'ems 邮编',
  `emAddress` varchar(1000) NULL COMMENT 'ems 联系地址',
  `bhyyType` int NULL COMMENT '补换卡原因',
  `reason` int NULL COMMENT '挂失原因编号',
  `serialNumber` varchar(640) NULL COMMENT '行内提交交易流水号(对应个人领卡接口的业务单据号)',
  `platformSeqId` varchar(500) NULL COMMENT '外部平台流水号',
  `AAE001` varchar(1000) NULL COMMENT '制卡失败原因',
  `pbatchNum` varchar(1000) NULL COMMENT '外部平台批次',
  `ACA018` varchar(100) NULL COMMENT '领卡方式：1个人网点领卡，2银行邮寄，3单位代领',
  `AAB005` varchar(500) NULL COMMENT '单位经办人证件号码',
  `CNL001` varchar(200) NULL COMMENT '申领提交渠道号',
  `personId` varchar(1000) NULL COMMENT '持卡库部级人员id',
  `confirmFlag` varchar(10) NULL COMMENT '制卡失败确认标识(0:未确认 1:已确认)',
  `lockFlag` varchar(10) NULL COMMENT '锁定标识(0:未锁定 1:已锁定)',
  `confirmSource` varchar(100) NULL COMMENT '申领信息确认渠道(网上申领渠道有此值)',
  `workPermitNumber` varchar(500) NULL COMMENT '来华外国人工作许可证号码',
  `sync_timestamp` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间戳'
) ENGINE=OLAP
UNIQUE KEY(`ID`)
DISTRIBUTED BY HASH(`ID`) BUCKETS 10
PROPERTIES (
"replication_allocation" = "tag.location.default: 3",
"min_load_replica_num" = "-1",
"is_being_synced" = "false",
"storage_medium" = "hdd",
"storage_format" = "V2",
"inverted_index_storage_format" = "V1",
"enable_unique_key_merge_on_write" = "true",
"light_schema_change" = "true",
"disable_auto_compaction" = "false",
"enable_single_replica_compaction" = "false",
"group_commit_interval_ms" = "10000",
"group_commit_data_bytes" = "134217728",
"enable_mow_light_delete" = "false"
);
```

## 1.5 ods_sjzt_card_status

```SQL
CREATE TABLE `ods_sjzt_card_status` (
  `ID` int NULL COMMENT '序号',
  `cc02_id` int NULL,
  `aac002` varchar(500) NULL COMMENT '身份证号码',
  `aac003` varchar(1000) NULL COMMENT '姓名',
  `aac018` int NULL COMMENT '制卡流程状态',
  `aac019` int NULL COMMENT '金融状态',
  `modify_flag` varchar(10) NULL COMMENT '修改标记 0未修改 1已修改',
  `aaz502` int NULL COMMENT '0封存 1正常，2挂失，3应用锁定 4临时挂失 6:特殊制卡数据作废 9注销',
  `card_type` varchar(10) NULL COMMENT '类型',
  `AAZ161` varchar(500) NULL COMMENT '发卡日期',
  `AAZ162` varchar(500) NULL COMMENT '卡片有效期',
  `AAZ163` varchar(10) NULL COMMENT '自动解挂标识（1:自动解挂 2:不自动解挂）',
  `AAZ164` varchar(500) NULL COMMENT '金融自动解挂时间',
  `AAZ165` varchar(500) NULL COMMENT '民生自动解挂时间',
  `AAC042` varchar(500) NULL COMMENT '代办人证件号码',
  `AAC044` varchar(1000) NULL COMMENT '代办人姓名',
  `AAC043` varchar(100) NULL COMMENT '代办人证件类型',
  `AAE165` varchar(1000) NULL COMMENT '开户失败原因',
  `AAE200` varchar(100) NULL COMMENT '挂失原因编码',
  `AAE001` varchar(1000) NULL COMMENT '制卡失败原因',
  `AAE300` varchar(100) NULL COMMENT '补换卡原因编码',
  `AAE400` varchar(1000) NULL COMMENT '销户原因',
  `AAE500` varchar(10) NULL COMMENT '卡回收标志',
  `ckkStatus` varchar(10) NULL COMMENT '持卡库当前卡状态',
  `CREATE_BY` varchar(500) NULL COMMENT '创建者',
  `CREATE_DATE` datetime NULL COMMENT '创建时间',
  `UPDATE_BY` varchar(500) NULL COMMENT '更新者',
  `UPDATE_DATE` datetime NULL COMMENT '更新时间',
  `REMARKS` varchar(500) NULL COMMENT '备注',
  `DEL_FLAG` varchar(10) NULL COMMENT '删除标记',
  `sync_timestamp` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次同步时间',
  `update_timestamp` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间戳'
) ENGINE=OLAP
UNIQUE KEY(`ID`)
COMMENT '个人基本信息同步表'
DISTRIBUTED BY HASH(`ID`) BUCKETS 10
PROPERTIES (
"replication_allocation" = "tag.location.default: 3",
"min_load_replica_num" = "-1",
"is_being_synced" = "false",
"storage_medium" = "hdd",
"storage_format" = "V2",
"inverted_index_storage_format" = "V1",
"enable_unique_key_merge_on_write" = "true",
"light_schema_change" = "true",
"disable_auto_compaction" = "false",
"enable_single_replica_compaction" = "false",
"group_commit_interval_ms" = "10000",
"group_commit_data_bytes" = "134217728",
"enable_mow_light_delete" = "false"
);
```