<show-structure depth="2"/>

# 分页查询统计数据

该接口实现对dwd_channel_code_count_1d的分页查询。

**[dwd_channel_code_count_1d元数据导航](metadata.md#1-dwd-channel-code-count-1d)**

## 1.代码SQL逻辑

```sql
SELECT *
FROM dwd_channel_code_count1d
WHERE date_total BETWEEN #{start} AND #{end}
  <if test="channelCodeList != null and channelCodeList.size > 0">
    AND channel_code IN
    <foreach collection="channelCodeList" item="item" open="(" separator="," close=")">
        #{item}
    </foreach>
  </if>
  <if test="bankNoList != null and bankNoList.size > 0">
    AND bank_no IN
    <foreach collection="bankNoList" item="item" open="(" separator="," close=")">
        #{item}
    </foreach>
  </if>
  <if test="bankBranchNoList != null and bankBranchNoList.size > 0">
    AND bank_branch_code IN
    <foreach collection="bankBranchNoList" item="item" open="(" separator="," close=")">
        #{item}
    </foreach>
  </if>
  <if test="employeeCodeList != null and employeeCodeList.size > 0">
    AND employee_code IN
    <foreach collection="employeeCodeList" item="item" open="(" separator="," close=")">
        #{item}
    </foreach>
  </if>
  <if test="employeeNumberList != null and employeeNumberList.size > 0">
    AND employee_number IN
    <foreach collection="employeeNumberList" item="item" open="(" separator="," close=")">
        #{item}
    </foreach>
  </if>
  <if test="bankBranchName != null and bankBranchName != ''">
    AND bank_branch_name LIKE CONCAT('%', #{bankBranchName}, '%')
  </if>
  <if test="employeeName != null and employeeName != ''">
    AND employee_name LIKE CONCAT('%', #{employeeName}, '%')
  </if>
ORDER BY date_total <if test="isAsc">ASC</if><if test="!isAsc">DESC</if>
LIMIT #{offset}, #{pageSize};
```

具体SQL逻辑如下：

```sql
SELECT *
FROM dwd_channel_code_count_1d
WHERE date_total BETWEEN '2024-11-01 00:00:00' AND '2024-11-10 23:59:59'
  AND channel_code IN ('C001', 'C002')
  AND bank_branch_code IN ('B001')
  AND employee_number IN ('E001', 'E002')
  AND bank_branch_name LIKE '%Branch1%'
ORDER BY date_total ASC
LIMIT 0, 10;
```

## 2.接口

### 2.1 接口描述

### 2.2 请求方式

- 方法：POST
- URL：`/api/listStatistics`
- Content-Type：`application/json`

### 2.3 请求参数

| 参数名                | 类型           | 必填 | 默认值   | 描述      |
|--------------------|--------------|----|-------|---------|
| startTime          | String       | 是  | 无     | 统计开始时间  |
| endTime            | String       | 是  | 无     | 统计结束时间  |
| channelCodeList    | List<String> | 否  | false | 渠道码     |
| bankNoList         | List<String> | 否  | false | 银行编码    |
| bankBranchNoList   | List<String> | 否  | false | 分行、网点编码 |
| employeeCodeList   | List<String> | 否  | false | 员工编码    |
| employeeNumberList | List<String> | 否  | false | 员工工号    |
| bankBranchName     | String       | 否  | false | 分行、网点名称 |
| employeeName       | String       | 否  | false | 员工名称    |
| pageNumber         | int          | 否  | false | 页码      |
| pageSize           | int          | 否  | false | 分页大小    |

示例请求

```json
{
  "startTime": "2024-11-01 00:00:00",
  "endTime": "2024-11-10 23:59:59",
  "channelCodeList": [],
  "bankNoList": [
    "BN1"
  ],
  "bankBranchNoList": [],
  "employeeCodeList": [],
  "employeeNumberList": [],
  "bankBranchName": "",
  "employeeName": "",
  "pageNumber": 1,
  "pageSize": 100
}
```

### **2.4. 响应说明**

定义接口的响应格式，包括字段说明和可能的状态码。

**响应参数**

| 参数名             | 类型                   | 描述    |
|-----------------|----------------------|-------|
| code            | int                  | 响应状态码 |
| message         | int                  | 响应描述  |
| data            | Map<Map<String,Map>> | 数据    |
| data.list       | List<Map>            | 数据列表  |
| data.pagination | Map                  | 分页数据  |

**示例响应**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "list": [
      {
        "id": "6434",
        "channelCode": "1815197225643798530-1",
        "bankName": "北京农商银行",
        "bankBranchCode": "402-001170",
        "bankBranchName": "北京农商银行永外支行",
        "scfw": 0,
        "fw": 0,
        "dxzc": 0,
        "wxzc": 0,
        "smrz": 0,
        "dwsqtj": 0,
        "grsqtj": 0,
        "dbsqtj": 0,
        "cx": 0,
        "qy": 0,
        "zkcg": 0,
        "zksb": 0,
        "khsb": 0,
        "zpshsb": 0,
        "zx": 0,
        "dateYear": 2024,
        "dateMonth": 11,
        "dateWeek": 1,
        "dateDay": 10,
        "dateHour": 23,
        "datePoint": 59,
        "dateTotal": "2024-11-10"
      }
    ],
    "pagination": {
      "total": "310",
      "pageSize": 1,
      "current": 10
    }
  }
}
```

#### **2.5. 错误示例**

提供可能的错误响应及其原因。


