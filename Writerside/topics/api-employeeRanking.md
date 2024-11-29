# api_employeeRanking

## 1.1 SQL逻辑

```SQL
with temp as (
    SELECT
        a.bank_branch_code as bankBranchCode, -- 银行网点编码
        a.bank_branch_name as bankBranchName, -- 银行网点名称
        ifnull(b.employee_code, ifnull(a.employee_code, '')) as employeeCode, -- 员工编码
        ifnull(b.employee_name,ifnull(a.employee_name, '')) as employeeName, -- 员工姓名
        ifnull(b.employee_number,ifnull(a.employee_number, '')) as employeeNumber, -- 员工工号
        SUM(a.dwsqtj) +  -- 单位申请提交数目
        SUM(a.grsqtj) + -- 个人申请提交数目
        SUM(a.dbsqtj)  -- 代办申请提交数目
            AS sqtj -- 申请提交数目
    FROM dwd.dwd_channel_code_count_1d a, ods.ods_sjzt_channel b
    where a.channel_code = b.channel_code
    <if test="bankNo != null">
        AND a.bank_no = #{bankNo}
    </if>
    <if test="bankBranchList != null and bankBranchList.size() > 0">
        AND a.bank_branch_code IN
        <foreach collection="bankBranchList" item="item" open="(" separator="," close=")">
            #{item}
        </foreach>
    </if>
    <if test="startTime != null">
        AND a.date_total BETWEEN date(#{startTime}) AND date(#{endTime})
    </if>
    <if test="startTime == null">
        AND a.date_total BETWEEN date(DATE_SUB(NOW(), INTERVAL 1 YEAR)) AND date(NOW())
    </if>
    AND ifnull(b.employee_number,ifnull(a.employee_number, '')) != ''
    group by
    a.bank_branch_code,
    a.bank_branch_name,
    ifnull(b.employee_code, ifnull(a.employee_code, '')),
    ifnull(b.employee_name,ifnull(a.employee_name, '')),
    ifnull(b.employee_number,ifnull(a.employee_number, ''))
    order by sqtj desc
    limit 20
)
select
    *
from temp

```