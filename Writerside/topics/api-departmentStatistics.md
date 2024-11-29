# api_departmentStatistics

## 1.1 SQL逻辑
```SQL
SELECT 
    channel_code AS channelCode,
    bank_name AS bankName,
    bank_no AS bankNo,
    bank_branch_code AS bankBranchCode,
    bank_branch_name AS bankBranchName,
    employee_code AS employeeCode,
    employee_name AS employeeName,
    SUM(scfw) AS scfw,
    SUM(fw) AS fw,
    SUM(dxzc) AS dxzc,
    SUM(wxzc) AS wxzc,
    SUM(smrz) AS smrz,
    SUM(dwsqtj) AS dwsqtj,
    SUM(grsqtj) AS grsqtj,
    SUM(dbsqtj) AS dbsqtj,
    SUM(cx) AS cx,
    SUM(qy) AS qy,
    SUM(zkcg) AS zkcg,
    SUM(zksb) AS zksb,
    SUM(khsb) AS khsb,
    SUM(zpshsb) AS zpshsb,
    SUM(dwjbrtj) AS dwjbrtj,
    SUM(zx) AS zx
FROM dwd.dwd_channel_code_count_1d
WHERE 1=1
<foreach collection="departmentList" item="department" separator="OR" open="AND (" close=")">
    channel_code IN
        <foreach collection="department" item="channelCode" open="(" separator="," close=")">
            #{channelCode}
        </foreach>
</foreach>
<if test="flag == '1'">
    AND date_year = YEAR(CURDATE())
    AND date_month = MONTH(CURDATE())
    AND date_week = WEEK(CURDATE()) - WEEK(DATE_SUB(CURDATE(), INTERVAL DAY(CURDATE()) - 1 DAY)) + 1;
</if>
<if test="flag == '2'">
    AND date_year = YEAR(CURDATE())
    AND date_month = MONTH(CURDATE())
</if>
<if test="flag == '3'">
    AND date_year = YEAR(CURDATE())
</if>
GROUP BY channel_code, bank_name, bank_no, bank_branch_code, bank_branch_name, employee_code, employee_name
```