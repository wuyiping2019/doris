# 渠道码统计

有关渠道码统计的接口都是针对dwd_channel_code_count_1d汇总表进进行查询操作的，dwd_channel_code_count_1d表的生成逻辑是由xxljob进行每天调度获取的统计结果表。

## 1.分页查询统计数据

@Deprecated V1:[分页查询统计数据](listStatistics.md)

将V1版本的接口迁移到V2中：

V2:[BI数据查询 name = "api_listStatistics"](bi_data_search.md#1-bi-doquery-name)

在[sql_search_config](metadata.md#)表中配置name = 'api_listStatistics'的sql查询逻辑。

### 1.1 name字段配置

api_listStatistics

### 1.2 sql_type字段配置

MYBATIS_TEMPLATE

### 1.3 sql字段配置

```sql
SELECT *
FROM dwd_channel_code_count_1d
WHERE date_total BETWEEN #{startTime} AND #{endTime}
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
```

## 2.维度统计数据

## 3.累计统计数据

版本V1:/api/totalStatistics 接口描述请查询&nbsp;&nbsp;[接口详情](totalStatistics.md)

将V1版本的接口迁移到V2中：

版本V2:/bi/doQuery/api_totalStatistics 接口描述请查询&nbsp;&nbsp;[接口详情](totalStatistics.md)

## 4.折线图

## 5.按部门统计

## 6.渠道码关联制卡进度查询

## 8.员工排名