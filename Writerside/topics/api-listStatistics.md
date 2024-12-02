# api_listStatistics
## 1.1 入参
```JSON
{
  "startTime": {
    "required": true,
    "type": "String",
    "desc": "开始时间，不能为空，格式为 yyyy-MM-dd"
  },
  "endTime": {
    "required": true,
    "type": "String",
    "desc": "结束时间，不能为空，格式为 yyyy-MM-dd"
  },
  "bankNoList": {
    "required": false,
    "type": "List<String>",
    "desc": "银行编码集合，用于过滤银行数据"
  },
  "bankBranchNoList": {
    "required": false,
    "type": "List<String>",
    "desc": "银行网点编码集合，用于过滤具体网点数据"
  },
  "employeeCodeList": {
    "required": false,
    "type": "List<String>",
    "desc": "员工编码集合，用于指定特定员工的操作"
  },
  "channelCodeList": {
    "required": false,
    "type": "List<String>",
    "desc": "渠道码集合，用于过滤特定渠道数据"
  },
  "bankBranchName": {
    "required": false,
    "type": "String",
    "desc": "银行网点名称，用于模糊查询网点信息"
  },
  "employeeName": {
    "required": false,
    "type": "String",
    "desc": "员工名称，用于模糊查询员工信息"
  },
  "employeeNumber": {
    "required": false,
    "type": "String",
    "desc": "员工工号，用于精准查询员工信息"
  },
  "channelCodeStatus": {
    "required": false,
    "type": "Integer",
    "desc": "渠道码状态，0 表示下架，1 表示上架，2 表示删除"
  },
  "pageNumber": {
    "required": false,
    "type": "Integer",
    "desc": "分页页码，默认值为 1"
  },
  "pageSize": {
    "required": false,
    "type": "Integer",
    "desc": "分页条数，默认值为 20"
  }
}
```
## 1.2 响应
```JSON
{
  "code": {
    "type": "Integer",
    "desc": "响应状态码，200 表示成功，其他值表示失败"
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
        "desc": "业务记录列表",
        "items": {
          "dwsqtj": {
            "type": "Integer",
            "desc": "单位申请提交数量"
          },
          "grsqtj": {
            "type": "Integer",
            "desc": "个人申请提交数量"
          },
          "bankBranchName": {
            "type": "String",
            "desc": "银行网点名称"
          },
          "dateDay": {
            "type": "Integer",
            "desc": "日期中的日（天）"
          },
          "bankName": {
            "type": "String",
            "desc": "银行名称"
          },
          "employeeCode": {
            "type": "String",
            "desc": "员工代码，唯一标识"
          },
          "employeeNumber": {
            "type": "String",
            "desc": "员工工号"
          },
          "fw": {
            "type": "Integer",
            "desc": "访问次数"
          },
          "dxzc": {
            "type": "Integer",
            "desc": "短信注册数量"
          },
          "scfw": {
            "type": "Integer",
            "desc": "首次访问数目"
          },
          "zpshsb": {
            "type": "Integer",
            "desc": "照片审核失败数量"
          },
          "dateYear": {
            "type": "Integer",
            "desc": "日期中的年份"
          },
          "smrz": {
            "type": "Integer",
            "desc": "实名认证数目"
          },
          "datePoint": {
            "type": "Integer",
            "desc": "日期中的点（时间点）"
          },
          "bankNo": {
            "type": "String",
            "desc": "银行编号"
          },
          "dateMonth": {
            "type": "Integer",
            "desc": "日期中的月份"
          },
          "khsb": {
            "type": "Integer",
            "desc": "开户失败数量"
          },
          "dateWeek": {
            "type": "Integer",
            "desc": "星期"
          },
          "channelCode": {
            "type": "String",
            "desc": "渠道代码"
          },
          "employeeName": {
            "type": "String",
            "desc": "员工姓名"
          },
          "dateHour": {
            "type": "Integer",
            "desc": "日期中的小时"
          },
          "qy": {
            "type": "Integer",
            "desc": "启用"
          },
          "updateTime": {
            "type": "String",
            "desc": "更新时间，格式为 yyyy-MM-dd HH:mm:ss"
          },
          "zkcg": {
            "type": "Integer",
            "desc": "制卡成功数量"
          },
          "dbsqtj": {
            "type": "Integer",
            "desc": "代办申请提交数目"
          },
          "cx": {
            "type": "Integer",
            "desc": "撤销数量"
          },
          "createTime": {
            "type": "String",
            "desc": "创建时间，格式为 yyyy-MM-dd HH:mm:ss"
          },
          "bankBranchNo": {
            "type": "String",
            "desc": "银行网点编号"
          },
          "zksb": {
            "type": "Integer",
            "desc": "制卡失败数量"
          },
          "dateTotal": {
            "type": "String",
            "desc": "完整日期，格式为 yyyy-MM-dd"
          },
          "wxzc": {
            "type": "Integer",
            "desc": "微信注册数量"
          },
          "zx": {
            "type": "Integer",
            "desc": "注销数量"
          },
          "dwjbrtj": {
            "type": "Integer",
            "desc": "单位经办人提交"
          }
        }
      },
      "pagination": {
        "type": "Object",
        "desc": "分页信息",
        "properties": {
          "total": {
            "type": "Integer",
            "desc": "符合条件的记录总数"
          },
          "pageSize": {
            "type": "Integer",
            "desc": "每页显示的记录数量"
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
    <!-- 首次访问数目 -->
    ifnull(a.scfw,0) as scfw,
    <!-- 访问数目 -->
    ifnull(a.fw,0) as fw,
    <!-- 短信验证码注册数目 -->
    ifnull(a.dxzc,0) as dxzc,
    <!-- 微信手机号注册数目 -->
    ifnull(a.wxzc,0) as wxzc,
    <!-- 实名认证数目 -->
    ifnull(a.smrz,0) as smrz,
    <!-- 单位申请提交数目 -->
    ifnull(a.dwsqtj,0) as dwsqtj,
    <!-- 个人申请提交数目 -->
    ifnull(a.grsqtj,0) as grsqtj,
    <!-- 代办申请提交数目 -->
    ifnull(a.dbsqtj,0) as dbsqtj,
    <!-- 撤销数目 -->
    ifnull(a.cx,0) as cx,
    <!-- 启用数目 -->
    ifnull(a.qy,0) as qy,
    <!-- 制卡成功 -->
    ifnull(a.zkcg,0) as zkcg,
    <!-- 制卡失败 -->
    ifnull(a.zksb,0) as zksb,
    <!-- 开户成功 -->
    ifnull(a.khsb,0) as khsb,
    <!-- 照片审核失败 -->
    ifnull(a.zpshsb,0) as zpshsb,
    <!-- 注销 -->
    ifnull(a.zx,0) as zx,
    <!-- 单位经办人提交 -->
    ifnull(a.dwjbrtj,0) as dwjbrtj,
    year(a.date_total) as dateYear,
    month(a.date_total) as dateMonth,
    weekday(a.date_total) + 1 as dateWeek,
    day(a.date_total) as dateDay,
    0 as dateHour,
    0 as datePoint,
    <!-- 是否激活 -->
    a.create_time as createTime,
    a.update_time as updateTime
FROM dwd.dwd_channel_code_count_1d a
left join ods.ods_sjzt_channel b
on a.channel_code = b.channel_code
WHERE date_total BETWEEN date(#{startTime}) AND date(#{endTime})
<!-- 渠道编号 -->
<if test="channelCodeList != null and channelCodeList.size > 0">
  AND a.channel_code IN
  <foreach collection="channelCodeList" item="item" open="(" separator="," close=")">
      #{item}
  </foreach>
</if>
<!-- 银行编码 -->
<if test="bankNoList != null and bankNoList.size > 0">
  AND a.bank_no IN
  <foreach collection="bankNoList" item="item" open="(" separator="," close=")">
      #{item}
  </foreach>
</if>
<!-- 网点编码 -->
<if test="bankBranchNoList != null and bankBranchNoList.size > 0">
  AND a.bank_branch_code IN
  <foreach collection="bankBranchNoList" item="item" open="(" separator="," close=")">
      #{item}
  </foreach>
</if>
<!-- 员工编码 -->
<if test="employeeCodeList != null and employeeCodeList.size > 0">
  AND a.employee_code IN
  <foreach collection="employeeCodeList" item="item" open="(" separator="," close=")">
      #{item}
  </foreach>
</if>
<!-- 员工工号 -->
<if test="employeeNumberList != null and employeeNumberList.size > 0">
  AND a.employee_number IN
  <foreach collection="employeeNumberList" item="item" open="(" separator="," close=")">
      #{item}
  </foreach>
</if>
<!-- 网点名称 -->
<if test="bankBranchName != null and bankBranchName != ''">
  AND a.bank_branch_name LIKE CONCAT('%', #{bankBranchName}, '%')
</if>
<!-- 员工姓名 -->
<if test="employeeName != null and employeeName != ''">
  AND a.employee_name LIKE CONCAT('%', #{employeeName}, '%')
</if>
<!-- 渠道码状态 0-下架 1-上架 2-删除 -->
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