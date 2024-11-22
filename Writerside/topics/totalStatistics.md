# 累计统计数据

## 1.1 原理

借助`/bi/doQuery/{name}`接口可配置动态执行SQL的能力，将累计统计的查询逻辑配置到`sql_search_config`表中。

## 1.2 配置的SQL

将`sql_search_config`表的name字段配置为`api_totalStatistics`，`sql_type`字段配置为`MYBATIS_TEMPLATE`，`return_type`字段配置为
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
    <!-- 处理flag的不同值 -->
    <choose>
        <when test="flag == '1'">
            AND date_year = #{now.year}
            AND date_month = #{now.monthValue}
            AND date_day = #{now.minusDays(1).dayOfMonth}
        </when>
        <when test="flag == '2'">
            AND date_year = #{now.year}
            AND date_month = #{now.monthValue}
            AND date_week = #{now[WeekFields.ISO.weekOfMonth]}
        </when>
        <when test="flag == '3'">
            AND date_year = #{now.year}
            AND date_month = #{now.monthValue}
        </when>
        <when test="flag == '4'">
            AND date_year = #{now.year}
        </when>
        <otherwise>
            <!-- 默认不加限制条件，查询全部 -->
        </otherwise>
    </choose>
        <!-- 根据bankBranchNoList进行过滤 -->
        <if test="bankBranchNoList != null and bankBranchNoList.size() > 0">
            AND bank_branch_code IN
            <foreach item="item" collection="bankBranchNoList" open="(" separator="," close=")">
                #{item}
            </foreach>
        </if>
</where>
```

## 1.3 接口描述

### 1.3.1 请求方式

- 方法：POST
- URL：`/bi/doQuery/api_totalStatistics`
- Content-Type：`application/json`

### 1.3.2 请求参数

| 参数名              | 类型           | 必填 | 默认值   | 描述                            |
|------------------|--------------|----|-------|-------------------------------|
| flag             | String       | 是  | 无     | 范围标识 全部-0 昨日-1 当周-2 当月-3 当年-4 |
| bankBranchNoList | String       | 是  | 无     | 银行网点列表 用户可所属多个部门网点            |

### 1.3.3 响应说明

| 字段      | 类型                 | 描述              |
|---------|--------------------|-----------------|
| code    | int                | 响应编码，200成功，其他失败 |
| message | String             | 响应消息            |
| data    | Map<String,Object> | 具体的统计数据         |

## 1.4 示例

POST http://localhost:9641/bi/doQuery/api_totalStatistics
Content-Type: application/json

```JSON
{
  "flag": "4",
  "bankBranchNoList": [
    "403-11012571"
  ]
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
