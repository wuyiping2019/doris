# api_lineStatistics

## 1.1 入参
```JSON
{
  "bankBranchNoList": {
    "required": true,
    "type": "List<String>",
    "desc": "银行网点列表 用户可所属多个部门网点"
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
    "desc": "日期统计数据列表，每项表示一天的统计数据",
    "items": {
      "dwsqtj": {
        "type": "Integer",
        "desc": "单位申请提交数量"
      },
      "grsqtj": {
        "type": "Integer",
        "desc": "个人申请提交数量"
      },
      "dateDay": {
        "type": "Integer",
        "desc": "日期中的天数部分"
      },
      "qy": {
        "type": "Integer",
        "desc": "启用"
      },
      "zkcg": {
        "type": "Integer",
        "desc": "制卡成功数量"
      },
      "dbsqtj": {
        "type": "Integer",
        "desc": "代办申请提交数目"
      },
      "fw": {
        "type": "Integer",
        "desc": "访问数目"
      },
      "dxzc": {
        "type": "Integer",
        "desc": "短信验证码注册数目"
      },
      "scfw": {
        "type": "Integer",
        "desc": "首次访问数目"
      },
      "cx": {
        "type": "Integer",
        "desc": "撤销数目"
      },
      "zpshsb": {
        "type": "Integer",
        "desc": "照片审核失败"
      },
      "dateYear": {
        "type": "Integer",
        "desc": "年份"
      },
      "smrz": {
        "type": "Integer",
        "desc": "实名认证数目"
      },
      "dateMonth": {
        "type": "Integer",
        "desc": "月份"
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
      "dateWeek": {
        "type": "Integer",
        "desc": "星期几（1 表示星期一，依此类推）"
      },
      "khsb": {
        "type": "Integer",
        "desc": "开户失败数量"
      },
      "zx": {
        "type": "Integer",
        "desc": "注销数量"
      }
    }
  }
}

```
## 1.3 SQL逻辑

```SQL
SELECT
    <!-- 年 -->
    year(date_total) AS dateYear,
    <!-- 月 -->
    month(date_total) AS dateMonth,
    <!-- 周 -->
    case weekday(date_total)
        when 1 then 1
        when 2 then 2
        when 3 then 3
        when 4 then 4
        when 5 then 5
        when 6 then 6
        when 0 then 7
    end AS dateWeek,
    <!-- 日 -->
    day(date_total) AS dateDay,
    <!-- 具体日期 -->
    date_total AS dateTotal,
    <!-- 首次访问数目 -->
    SUM(scfw) AS scfw,
    <!-- 访问次数 -->
    SUM(fw) AS fw,
    <!-- 短信验证码注册数目 -->
    SUM(dxzc) AS dxzc,
    <!-- 微信手机号注册数目 -->
    SUM(wxzc) AS wxzc,
    <!-- 实名认证数目 -->
    SUM(smrz) AS smrz,
    <!-- 单位申请提交数目 -->
    SUM(dwsqtj) AS dwsqtj,
    <!-- 个人申请提交数目 -->
    SUM(grsqtj) AS grsqtj,
    <!-- 代办申请提交数目 -->
    SUM(dbsqtj) AS dbsqtj,
    <!-- 撤销数目 -->
    SUM(cx) AS cx,
    <!-- 启用数目 -->
    SUM(qy) AS qy,
    <!-- 制卡成功 -->
    SUM(zkcg) AS zkcg,
    <!-- 制卡失败 -->
    SUM(zksb) AS zksb,
    <!-- 开户失败 -->
    SUM(khsb) AS khsb,
    <!-- 照片审核失败 -->
    SUM(zpshsb) AS zpshsb,
    <!-- 注销 -->
    SUM(zx) AS zx
FROM dwd.dwd_channel_code_count_1d
<where>
    <!-- 时间条件: 最近一个月 -->
    date_total between CURDATE() - INTERVAL 1 MONTH AND CURDATE()
    <!-- 筛选银行网点编码 -->
    <if test="bankBranchNoList != null and bankBranchNoList.size() > 0">
        AND bank_branch_code IN
        <foreach collection="bankBranchNoList" item="item" open="(" close=")" separator=",">
            #{item}
        </foreach>
    </if>
     <if test="bankBranchNoList == null or bankBranchNoList.size() == 0">
       AND 1=0
     </if>
</where>
GROUP BY date_total
order by date_total
```