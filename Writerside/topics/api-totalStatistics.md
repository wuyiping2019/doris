# api_totalStatistics

## 1.1 SQL逻辑
```SQL
SELECT
    ifnull(SUM(scfw),0) AS scfw, -- 首次访问数目
    ifnull(SUM(fw),0) AS fw, -- 访问数目
    ifnull(SUM(dxzc),0) AS dxzc, -- 短信验证码注册数目
    ifnull(SUM(wxzc),0) AS wxzc, -- 微信手机号注册数目
    ifnull(SUM(smrz),0) AS smrz, -- 实名认证数目
    ifnull(SUM(dwsqtj),0) AS dwsqtj, -- 单位申请提交数目
    ifnull(SUM(grsqtj),0) AS grsqtj, -- 个人申请提交数目
    ifnull(SUM(dbsqtj),0) AS dbsqtj, -- 代办申请提交数目
    ifnull(SUM(cx),0) AS cx, -- 撤销数目
    ifnull(SUM(qy),0) AS qy, -- 启用数目
    ifnull(SUM(zkcg),0) AS zkcg, -- 制卡成功
    ifnull(SUM(zksb),0) AS zksb, -- 制卡失败
    ifnull(SUM(khsb),0) AS khsb, -- 开户失败
    ifnull(SUM(zpshsb),0) AS zpshsb, -- 照片审核失败
    ifnull(SUM(zx),0) AS zx -- 注销
FROM dwd.dwd_channel_code_count_1d
<where>
    <choose>
        <when test="flag.trim() == '1'.toString()">
            date_total BETWEEN curdate_sub(1, 'day') AND curdate_sub(1, 'day')
        </when>
        <when test="flag.trim() == '2'.toString()">
            date_total BETWEEN
                CASE
                    WHEN WEEKDAY(CURDATE()) = 0 THEN DATE_SUB(CURDATE(), INTERVAL 0 DAY)
                    WHEN WEEKDAY(CURDATE()) = 1 THEN DATE_SUB(CURDATE(), INTERVAL 1 DAY)
                    WHEN WEEKDAY(CURDATE()) = 2 THEN DATE_SUB(CURDATE(), INTERVAL 2 DAY)
                    WHEN WEEKDAY(CURDATE()) = 3 THEN DATE_SUB(CURDATE(), INTERVAL 3 DAY)
                    WHEN WEEKDAY(CURDATE()) = 4 THEN DATE_SUB(CURDATE(), INTERVAL 4 DAY)
                    WHEN WEEKDAY(CURDATE()) = 5 THEN DATE_SUB(CURDATE(), INTERVAL 5 DAY)
                    WHEN WEEKDAY(CURDATE()) = 6 THEN DATE_SUB(CURDATE(), INTERVAL 6 DAY)
                END
                AND CURDATE()
        </when>
        <when test="flag.trim() == '3'.toString()">
            date_total BETWEEN DATE_FORMAT(CURDATE(), '%Y-%m-01') AND CURDATE()
        </when>
        <when test="flag.trim() == '4'.toString()">
            date_year BETWEEN DATE_FORMAT(CURDATE(), '%Y-01-01') AND CURDATE()
        </when>
        <otherwise>
            1 = 0
        </otherwise>
    </choose>
    <if test="bankBranchNoList != null and bankBranchNoList.size() > 0">
        AND bank_branch_code IN
        <foreach item="item" collection="bankBranchNoList" open="(" separator="," close=")">
            #{item}
        </foreach>
    </if>
    <if test="bankBranchNoList == null or bankBranchNoList.size() == 0">
        AND 1 = 0
    </if>
</where>
```