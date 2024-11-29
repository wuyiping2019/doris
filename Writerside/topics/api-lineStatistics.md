# api_lineStatistics

## 1.1 SQL逻辑

```SQL
SELECT
    date_year AS dateYear, -- 年
    date_month AS dateMonth, -- 月
    date_week AS dateWeek, -- 周 一个月的第几周
    date_day AS dateDay, -- 日
    date_total AS dateTotal, -- 日期
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
    -- 时间条件: 最近一个月
    date_total between  CURDATE() - INTERVAL 1 MONTH AND CURDATE()
    -- 筛选银行网点编码
    <if test="bankBranchNoList != null and bankBranchNoList.size() > 0">
        AND bank_branch_code IN
        <foreach collection="bankBranchNoList" item="item" open="(" close=")" separator=",">
            #{item}
        </foreach>
    </if>
</where>
GROUP BY date_year,date_month,date_week,date_day,date_total
order by date_total
```