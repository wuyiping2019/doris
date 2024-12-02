# api_employeeRanking

查询指定银行或一个班或多个网点下的员工前20名提交卡申请次数的员工信息。

## 1.1 入参
```JSON
{
  "startTime": {
    "type": "String",
    "desc": "开始时间，格式为 yyyy-MM-ddTHH:mm:ss",
    "required": false
  },
  "endTime": {
    "type": "String",
    "desc": "结束时间，格式为 yyyy-MM-ddTHH:mm:ss",
    "required": false
  },
  "bankNo": {
    "type": "String",
    "desc": "银行编码，不能为空",
    "required": true
  },
  "bankBranchList": {
    "type": "List<String>",
    "desc": "银行网点编码集合，不能为空",
    "required": true
  }
}

```
## 1.2 响应
```JSON
{
  "code": {
    "type": "Integer",
    "desc": "响应状态码，200 表示成功，其他值表示错误"
  },
  "message": {
    "type": "String",
    "desc": "响应结果描述，例如操作成功或错误提示"
  },
  "data": {
    "type": "List<Object>",
    "desc": "业务数据列表，每个对象表示一个员工记录",
    "items": {
      "bankBranchCode": {
        "type": "String",
        "desc": "银行网点代码"
      },
      "bankBranchName": {
        "type": "String",
        "desc": "银行网点名称"
      },
      "employeeCode": {
        "type": "String",
        "desc": "员工代码，用于唯一标识员工记录"
      },
      "employeeNumber": {
        "type": "String",
        "desc": "员工工号"
      },
      "employeeName": {
        "type": "String",
        "desc": "员工姓名"
      },
      "sqtj": {
        "type": "Integer",
        "desc": "申请提交次数"
      }
    }
  }
}
```

## 1.3 SQL逻辑

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