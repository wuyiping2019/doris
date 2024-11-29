# api_dimensionStatistics

## 1.1 SQL逻辑
```SQL
SELECT
    SUM(scfw) AS scfw, -- 首次访问数目
    SUM(fw) AS fw, -- 访问数目
    SUM(dxzc) AS dxzc, -- 短信验证码注册数目
    SUM(wxzc) AS wxzc, -- 微信手机号注册数目
    SUM(smrz) AS smrz, -- 实名认证数目
    SUM(dwsqtj) AS dwsqtj, -- 单位申请提交数目
    SUM(grsqtj) AS grsqtj, -- 个人申请提交数目
    SUM(dbsqtj) AS dbsqtj, -- 代办申请提交数目
    SUM(cx) AS cx, -- 撤销数目
    SUM(qy) AS qy, -- 启用数目
    SUM(zkcg) AS zkcg, -- 制卡成功
    SUM(zksb) AS zksb, -- 制卡失败
    SUM(khsb) AS khsb, -- 开户失败
    SUM(zpshsb) AS zpshsb, -- 照片审核失败
    SUM(zx) AS zx -- 注销
FROM dwd.dwd_channel_code_count_1d
<where>
     1=1
    <if test="year != null and  year != 0">
        -- 查询指定年
        AND date_year = #{year}
    </if>
    <if test="month != null and month != 0">
        -- 查询指定月份
        AND date_month = #{month}
    </if>
    <if test="week != null and week != 0">
        -- 查询指定周 一个月份所在的第几周
        AND date_week = #{week}
    </if>
    <if test="day != null and day != 0">
        -- 查询几号
        AND date_day = #{day}
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