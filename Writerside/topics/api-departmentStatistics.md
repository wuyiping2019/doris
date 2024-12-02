# api_departmentStatistics
## 1.1 入参
```JSON
{
  "flag": {
    "required": true,
    "type": "String",
    "desc": "范围标识，用于指定统计范围",
    "validValues": [
      "0", "全部",
      "1", "本周",
      "2", "本月",
      "3", "本年"
    ]
  },
  "departmentList": {
    "required": true,
    "type": "List<List<String>>",
    "desc": "部门列表，外层为多个部门，每个部门包含多个渠道码"
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
    "type": "Object",
    "desc": "业务数据",
    "properties": {
      "list": {
        "type": "List<Object>",
        "desc": "记录列表",
        "items": {
          "dwsqtj": {
            "type": "String",
            "desc": "单位申请提交数目"
          },
          "grsqtj": {
            "type": "String",
            "desc": "个人申请提交数目"
          },
          "employeeName": {
            "type": "String",
            "desc": "员工姓名"
          },
          "bankBranchCode": {
            "type": "String",
            "desc": "银行网点代码"
          },
          "bankBranchName": {
            "type": "String",
            "desc": "银行网点名称"
          },
          "qy": {
            "type": "String",
            "desc": "启用数目"
          },
          "bankName": {
            "type": "String",
            "desc": "银行名称"
          },
          "zkcg": {
            "type": "String",
            "desc": "制卡成功"
          },
          "dbsqtj": {
            "type": "String",
            "desc": "代办申请提交数目"
          },
          "employeeCode": {
            "type": "String",
            "desc": "员工代码，唯一标识"
          },
          "fw": {
            "type": "String",
            "desc": "访问数目"
          },
          "dxzc": {
            "type": "String",
            "desc": "短信验证码注册数目"
          },
          "scfw": {
            "type": "String",
            "desc": "首次访问数目"
          },
          "cx": {
            "type": "String",
            "desc": "撤销数量"
          },
          "zpshsb": {
            "type": "String",
            "desc": "照片审核失败"
          },
          "smrz": {
            "type": "String",
            "desc": "实名认证数目"
          },
          "bankNo": {
            "type": "String",
            "desc": "银行编号"
          },
          "zksb": {
            "type": "String",
            "desc": "制卡失败数量"
          },
          "wxzc": {
            "type": "String",
            "desc": "微信手机号注册数目"
          },
          "khsb": {
            "type": "String",
            "desc": "开户失败数量"
          },
          "dwjbrtj": {
            "type": "String",
            "desc": "单位经办人提交"
          },
          "zx": {
            "type": "String",
            "desc": "注销数量"
          },
          "channelCode": {
            "type": "String",
            "desc": "渠道代码"
          }
        }
      },
      "pagination": {
        "type": "Object",
        "desc": "分页信息",
        "properties": {
          "total": {
            "type": "String",
            "desc": "符合条件的记录总数"
          },
          "pageSize": {
            "type": "Integer",
            "desc": "每页记录数"
          },
          "current": {
            "type": "Integer",
            "desc": "当前页码"
          }
        }
      }
    }
  }
}

```
## 1.3 SQL逻辑
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