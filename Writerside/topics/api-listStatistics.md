# api_listStatistics

## 1.2 SQL逻辑

```SQL
SELECT
    a.date_total as dateTotal,
    a.channel_code as channelCode,
    a.bank_name as bankName,
    a.bank_no as bankNo,
    a.bank_branch_code as bankBranchNo,
    a.bank_branch_name as bankBranchName,
    ifnull(a.employee_code,b.employee_code) as employeeCode,
    ifnull(a.employee_number,b.employee_number) as employeeNumber,
    ifnull(a.employee_name,b.employee_name) as employeeName,
    a.scfw, -- 首次访问数目
    a.fw, -- 访问数目
    a.dxzc, -- 短信验证码注册数目
    a.wxzc, -- 微信手机号注册数目
    a.smrz, -- 实名认证数目
    a.dwsqtj, -- 单位申请提交数目
    a.grsqtj, -- 个人申请提交数目
    a.dbsqtj, -- 代办申请提交数目
    a.cx, -- 撤销数目
    a.qy, -- 启用数目
    a.zkcg, -- 制卡成功
    a.zksb, -- 制卡失败
    a.khsb, -- 开户失败
    a.zpshsb, -- 照片审核失败
    a.zx, -- 注销
    a.dwjbrtj, -- 单位经办人提交
    a.date_year as dateYear,
    a.date_month as dateMonth,
    a.date_week as dateWeek,
    a.date_day as dateDay,
    a.date_hour as dateHour,
    a.date_point as datePoint,
    a.active, -- 是否激活
    a.create_time as createTime,
    a.update_time as updateTime
FROM dwd.dwd_channel_code_count_1d a
left join ods.ods_sjzt_channel b
on a.channel_code = b.channel_code
WHERE date_total BETWEEN date(#{startTime}) AND date(#{endTime})
-- 渠道编号
<if test="channelCodeList != null and channelCodeList.size > 0">
  AND a.channel_code IN
  <foreach collection="channelCodeList" item="item" open="(" separator="," close=")">
      #{item}
  </foreach>
</if>
-- 银行编码
<if test="bankNoList != null and bankNoList.size > 0">
  AND a.bank_no IN
  <foreach collection="bankNoList" item="item" open="(" separator="," close=")">
      #{item}
  </foreach>
</if>
-- 网点编码
<if test="bankBranchNoList != null and bankBranchNoList.size > 0">
  AND a.bank_branch_code IN
  <foreach collection="bankBranchNoList" item="item" open="(" separator="," close=")">
      #{item}
  </foreach>
</if>
-- 员工编码
<if test="employeeCodeList != null and employeeCodeList.size > 0">
  AND a.employee_code IN
  <foreach collection="employeeCodeList" item="item" open="(" separator="," close=")">
      #{item}
  </foreach>
</if>
-- 员工工号
<if test="employeeNumberList != null and employeeNumberList.size > 0">
  AND a.employee_number IN
  <foreach collection="employeeNumberList" item="item" open="(" separator="," close=")">
      #{item}
  </foreach>
</if>
-- 网点名称
<if test="bankBranchName != null and bankBranchName != ''">
  AND a.bank_branch_name LIKE CONCAT('%', #{bankBranchName}, '%')
</if>
-- 员工姓名
<if test="employeeName != null and employeeName != ''">
  AND a.employee_name LIKE CONCAT('%', #{employeeName}, '%')
</if>
-- 渠道码状态 0-下架 1-上架 2-删除
<if test="channelCodeStatus != null and channelCodeStatus == 2">
  AND b.active = 0
</if>
<if test="channelCodeStatus != null and channelCodeStatus != 2">
  AND b.status = #{channelCodeStatus}
</if>
ORDER BY date_total
<if test="isAsc != null and isAsc">
    ASC
</if>
<if test="isAsc == null or !isAsc">
    DESC
</if>,
ifnull(a.employee_number,b.employee_number)
<if test="isAsc != null and isAsc">
    ASC
</if>
<if test="isAsc == null or !isAsc">
    DESC
</if>
```