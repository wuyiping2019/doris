# api_cardProcess
## 1.1 入参
```json
{
  "startTime": {
    "required": false,
    "type": "String",
    "desc": "开始时间"
  },
  "endTime":{
    "required": false,
    "type": "String",
    "desc": "结束时间"
  },
  "cardStatus": {
    "required": false,
    "type": "Integer",
    "desc": "制卡状态 申领7-5 单位经办人提交8 申请撤销9-22 制卡成功11-75 制卡失败12-70 开户失败13-30 照片审核失败14-115 130"
  },
  "channelCodeList": {
    "required": false,
    "type": "List<String>",
    "desc": "渠道码集合"
  },
  "bankBranchList": {
    "required": false,
    "type": "List<String>",
    "desc": "银行网点集合"
  },
  "pageNumber": {
    "required": false,
    "type": "Integer",
    "desc": "页数",
    "default": 1
  },
  "pageSize": {
    "required": false,
    "type": "Integer",
    "desc": "条数",
    "default": 20
  },
  "employeeName": {
    "required": false,
    "type": "String",
    "desc": "员工姓名 模糊搜索"
  },
  "employeeNumber": {
    "required": false,
    "type": "String",
    "desc": "员工工号"
  }
  
}
```
## 1.2 SQL逻辑
```SQL
WITH temp AS (
    SELECT
        -- d和e表是ods_sjzt_channel_code_trace和ods_sjzt_channel的channel_code关联
        -- d和e的字段不会存在空字段
        -- d和e的表left join卡管的状态表 通过人、网点和申领方式进行关联
        -- kg的字段可能为空 数据未到达卡管

        -- d和e通过channel_code关联 ods_sjzt_channel中channel_code唯一
        -- d和e的关联结果与卡管卡状态关联，存在关联不到和多对多的关联的情况
        d.*,
        e.bank_branch_code AS bankBranchCode,
        e.bank_branch_name AS bankBranchName,
        e.employee_code AS employeeCode,
        e.employee_number AS employeeNumber,
        e.employee_name AS employeeName,
        kg.aaz502 AS cardStatus,
        kg.UPDATE_DATE AS cardUpdateTime,
        kg.c_create_date AS cardCreateTime,
        kg.applyType,
        kg.aac018 as dataStatus,
        ROW_NUMBER() OVER (PARTITION BY d.user_calc_id, d.bank_branch_code ORDER BY d.create_time DESC, kg.b_create_date DESC ) AS r1
    -- 人与渠道码埋点操作轨迹
    FROM ods.ods_sjzt_channel_code_trace d
    -- 关联渠道信息
    LEFT JOIN ods.ods_sjzt_channel e ON e.channel_code = d.channel_code
    LEFT JOIN (
    -- 关联人的最新状态
    SELECT
        a.id AS aid,
        a.userCalcId,
        b.id AS bid,
        b.AAE009,
        -- 申领类型 1个人，2单位
        b.ACA016 AS applyType,
        b.create_date as b_create_date,
        c.id AS cid,
        c.aac018,
        c.aaz502,
        c.UPDATE_DATE,
        c.CREATE_DATE as c_create_date
    FROM ods.ods_sjzt_csk_ac01 a, ods.ods_sjzt_csk_cc02 b, ods.ods_sjzt_card_status c
    WHERE a.id = b.AC01_ID AND c.cc02_id = b.id
    ) kg ON
        -- 关联关系 同一个人、网点
        kg.userCalcId = d.user_calc_id
        AND kg.AAE009 = d.bank_branch_code COLLATE utf8mb4_general_ci
        AND ( CASE WHEN d.action_type = '6' THEN '2' ELSE '1' END ) = kg.applyType
        AND ( CASE WHEN d.action_type = '6' THEN d.create_time ELSE kg.b_create_date END ) &lt;= ifnull(kg.b_create_date, d.create_time )
    WHERE 1 = 1
    -- "6", "单位申领"
    -- "7", "个人申领"
    -- "8", "代办申领"
    AND d.action_type IN ( 6,7,8 )
    <if test="channelCodeList != null and channelCodeList.size() > 0">
        AND d.channel_code IN
        <foreach item="item" index="index" collection="channelCodeList" open="(" separator="," close=")">
            #{item}
        </foreach>
    </if>
    <if test="bankBranchList != null and bankBranchList.size() > 0">
        AND d.bank_branch_code IN
        <foreach item="item" index="index" collection="bankBranchList" open="(" separator="," close=")">
            #{item}
        </foreach>
    </if>
    AND d.create_time BETWEEN
            <if test="startTime != null">
                #{startTime}
            </if>
            <if test="startTime == null">
                '2024-01-01'
            </if>
            and
            <if test="endTime != null">
                #{endTime}
            </if>
            <if test="endTime == null">
                curdate()
            </if>
    <if test="employeeName!= null and ''!= employeeName">
        AND e.employee_name LIKE CONCAT('%', #{employeeName}, '%')
    </if>
    <if test="employeeNumber!= null and ''!= employeeNumber">
        AND e.employee_number = #{employeeNumber}
    </if>
)
SELECT
    a.id,
    a.channel_code as channelCode,
    a.uid,
    a.uname,
    a.id_type as idType,
    a.id_no as idNo,
    a.user_calc_id as userCalcId,
    a.phone,
    a.usci,
    a.bank_no as bankNo,
    a.bank_agree_flag as bankAgreeFlag,
    a.sync_flag as syncFlag,
    a.action_type as actionType,
    a.active as active,
    a.create_time as createTime,
    a.bankBranchCode,
    a.bankBranchName,
    a.employeeCode,
    a.employeeName,
    a.employeeNumber,
    a.cardStatus, -- 来源卡管可能为空 来源卡管的aaz502
    a.cardCreateTime, -- 来源卡管可能为空
    ifNULL(a.cardUpdateTime,ifnull(a.cardCreateTime, a.create_time)) as cardUpdateTime, -- 来源卡管可能为空
    case
        -- applyType 1 个人/待办申请 2 单位申请
        when a.applyType = 1 then '个人/待办申请'
        when a.applyType = 2 then '单位申请'
        -- action_type单位申请提交6 个人申请提交7 代办申请提交8
        when a.applyType is null and a.action_type = 6 then '单位申请'
        when a.applyType is null and a.action_type = 7 then '个人/待办申请'
        when a.applyType is null and a.action_type = 8 then '个人/待办申请'
        else '未知'
    end applyType, -- applyType可能为空 来源卡管的ACA016
    ifnull(a.dataStatus, '-1') as dataStatus -- 来源卡管可能为空
FROM temp a
WHERE r1 = 1
<if test="cardStatus!= null and ''!= cardStatus and cardStatus == -1">
    -- 待单位提交
    -- 1.数据还没有到卡管
    -- 2.小程序的action_type = 6
    and a.dataStatus is null and a.action_type = 6
</if>
<if test="cardStatus!= null and ''!= cardStatus and cardStatus == 7">
    -- 申领完成 5
    and a.dataStatus = 5
</if>
<if test="cardStatus!= null and ''!= cardStatus and cardStatus == 8">
    -- 申领完成5 applyType2单位申请
    -- 表达的含义 单位申领完成
    and a.dataStatus = 5 AND a.applyType = 2
</if>
<if test="cardStatus!= null and ''!= cardStatus and cardStatus == 9">
    -- 已撤销22
    and a.dataStatus = 22
</if>
<if test="cardStatus!= null and ''!= cardStatus and cardStatus == 11">
    -- 制卡成功75
    and a.dataStatus = 75
</if>
<if test="cardStatus!= null and ''!= cardStatus and cardStatus == 12">
    -- 制卡失败70
    and a.dataStatus = 70
</if>
<if test="cardStatus!= null and ''!= cardStatus and cardStatus == 13">
    -- 开户失败30
    and a.dataStatus = 30
</if>
<if test="cardStatus!= null and ''!= cardStatus and cardStatus == 14">
    -- 证照审核失败115 证照复核失败130
    and a.dataStatus in (115,130)
</if>
<if test="applyType == 0">
    1=1
</if>
<!-- 0 全部 1个人/待办申请 2 单位申请  -->
<if test="applyType == 1">
    and (a.applyType = 1 or (a.applyType is null and a.action_type in (7,8)))
</if>
<if test="applyType == 2">
    and (a.applyType = 2 or (a.applyType is null and a.action_type in = 6))
</if>

order by a.id DESC
```