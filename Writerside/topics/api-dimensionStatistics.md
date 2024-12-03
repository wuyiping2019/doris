# api_dimensionStatistics
## 1.1 入参
```JSON
{
  "year": {
    "type": "Integer",
    "desc": "年份，默认为 0 表示不限制年份",
    "required": false
  },
  "month": {
    "type": "Integer",
    "desc": "月份，默认为 0 表示不限制月份",
    "required": false
  },
  "week": {
    "type": "Integer",
    "desc": "周次，默认为 0 表示不限制周次",
    "required": false
  },
  "day": {
    "type": "Integer",
    "desc": "天数，默认为 0 表示不限制具体日期",
    "required": false
  },
  "bankNo": {
    "type": "String",
    "desc": "银行编码，用于指定银行的过滤条件",
    "required": false
  },
  "bankBranchNo": {
    "type": "String",
    "desc": "银行网点编码，用于指定银行网点的过滤条件",
    "required": false
  },
  "employeeCode": {
    "type": "String",
    "desc": "员工编码，用于唯一标识员工",
    "required": false
  },
  "employeeNumber": {
    "type": "String",
    "desc": "员工工号，用于唯一标识员工的工号",
    "required": false
  },
  "channelCode": {
    "type": "String",
    "desc": "渠道码，用于指定渠道的过滤条件",
    "required": false
  }
}

```
## 1.2 响应
```JSON

```
## 1.3 SQL逻辑
```SQL
SELECT
    <!-- 首次访问数目 -->
    ifnull(SUM(scfw),0) AS scfw,
    <!-- 访问数目 -->
    ifnull(SUM(fw),0) AS fw,
    <!-- 短信验证码注册数目 -->
    ifnull(SUM(dxzc),0) AS dxzc,
    <!-- 微信手机号注册数目 -->
    ifnull(SUM(wxzc),0) AS wxzc,
    <!-- 实名认证数目 -->
    ifnull(SUM(smrz),0) AS smrz,
    <!-- 单位申请提交数目 -->
    ifnull(SUM(dwsqtj),0) AS dwsqtj,
    <!-- 个人申请提交数目 -->
    ifnull(SUM(grsqtj),0) AS grsqtj,
    <!-- 代办申请提交数目 -->
    ifnull(SUM(dbsqtj),0) AS dbsqtj,
    <!-- 撤销数目 -->
    ifnull(SUM(cx),0) AS cx,
    <!-- 启用数目 -->
    ifnull(SUM(qy),0) AS qy,
    <!-- 制卡成功数目 -->
    ifnull(SUM(zkcg),0) AS zkcg,
    <!-- 制卡失败数目 -->
    ifnull(SUM(zksb),0) AS zksb,
    <!-- 开户失败数目 -->
    ifnull(SUM(khsb),0) AS khsb,
    <!-- 照片审核失败数目 -->
    ifnull(SUM(zpshsb),0) AS zpshsb,
    <!-- 销户数目 -->
    ifnull(SUM(zx),0) AS zx
FROM dwd.dwd_channel_code_count_1d
<where>
     1=1
    <if test="year != null and  year != 0">
        -- 查询指定年
        AND year(date_total) = #{year}
    </if>
    <if test="month != null and month != 0">
        -- 查询指定月份
        AND month(date_total) = #{month}
    </if>
    <if test="week != null and week != 0">
        -- 查询指定周 一个月份所在的第几周
        AND weekday(date_total) + 1 = #{week}
    </if>
    <if test="day != null and day != 0">
        -- 查询几号
        AND day(date_total) = #{day}
    </if>
    <if test="channelCode != null and channelCode != ''">
        -- 查询指定渠道
        AND channel_code = #{channelCode}
    </if>
    <if test="bankNo != null and bankNo != ''">
        -- 查询指定银行
        AND bank_no = #{bankNo}
    </if>
    <if test="bankBranchNo != null and bankBranchNo != ''">
        -- 查询指定支行
        AND bank_branch_code = #{bankBranchNo}
    </if>
    <if test="employeeCode != null and employeeCode != ''">
        -- 查询指定员工
        AND employee_code = #{employeeCode}
    </if>
    <if test="employeeNumber != null and employeeNumber != ''">
        -- 查询指定工号
        AND employee_number = #{employeeNumber}
    </if>
</where>
```