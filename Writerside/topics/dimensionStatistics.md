# 维度统计数据

## 1.1 原理

借助`/bi/doQuery/{name}`接口可配置动态执行SQL的能力，将累计统计的查询逻辑配置到`sql_search_config`表中。

## 1.2 配置的SQL

将`sql_search_config`表的name字段配置为`api_dimensionStatistics`，`sql_type`字段配置为`MYBATIS_TEMPLATE`，`return_type`
字段配置为
`ONE`。

```SQL
SELECT
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
    SUM(zx) AS zx
FROM dwd_channel_code_count_1d
<where>
    <if test="year != 0">
        AND date_year = #{year}
    </if>
    <if test="month != 0">
        AND date_month = #{month}
    </if>
    <if test="week != 0">
        AND date_week = #{week}
    </if>
    <if test="day != 0">
        AND date_day = #{day}
    </if>
    <if test="channelCode != null and channelCode != ''">
        AND channel_code = #{channelCode}
    </if>
    <if test="bankNo != null and bankNo != ''">
        AND bank_no = #{bankNo}
    </if>
    <if test="bankBranchNo != null and bankBranchNo != ''">
        AND bank_branch_code = #{bankBranchNo}
    </if>
    <if test="employeeCode != null and employeeCode != ''">
        AND employee_code = #{employeeCode}
    </if>
    <if test="employeeNumber != null and employeeNumber != ''">
        AND employee_number = #{employeeNumber}
    </if>
</where>
```

## 1.3 接口描述

### 1.3.1 请求方式

- 方法：POST
- URL：`/bi/doQuery/api_dimensionStatistics`
- Content-Type：`application/json`

### 1.3.2 请求参数

| 参数名            | 类型      | 必填 | 默认值 | 描述     |
|----------------|---------|----|-----|--------|
| year           | Integer | 否  | 0   | 年      |
| month          | Integer | 否  | 0   | 月      |
| week           | Integer | 否  | 0   | 周      |
| day            | Integer | 否  | 0   | 天      |
| bankNo         | Integer | 是  | -   | 银行编码   |
| bankBranchNo   | Integer | 是  | -   | 银行网点编码 |
| employeeCode   | Integer | 是  | -   | 员工编码   |
| employeeNumber | Integer | 是  | -   | 员工工号   |
| channelCode    | Integer | 是  | -   | 渠道码    |

### 1.3.3 响应说明

| 字段      | 类型                      | 描述              |
|---------|-------------------------|-----------------|
| code    | int                     | 响应编码，200成功，其他失败 |
| message | String                  | 响应消息            |
| data    | Map<String,Object> | 具体的统计数据         |

## 1.4 示例

POST http://localhost:9641/bi/doQuery/api_dimensionStatistics
Content-Type: application/json

```JSON
{
  year
  month
  week
  day
  bankNo
  bankBranchNo
  employeeCode
  employeeNumber
  channelCode
}
```

```JSON
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "dwsqtj": 0,
    "grsqtj": 500,
    "qy": 0,
    "zkcg": 0,
    "dbsqtj": 0,
    "fw": 0,
    "dxzc": 0,
    "scfw": 0,
    "cx": 0,
    "zpshsb": 0,
    "smrz": 0,
    "zksb": 0,
    "wxzc": 0,
    "khsb": 0,
    "zx": 0
  }
}
```
