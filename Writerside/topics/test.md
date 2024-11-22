# msk-operation-data-center

## 1.data-center-service

### 1.SqlSearchController

接口地址`/bi/doQuery/{name}`:  
入参：  
1.路径参数name
2.分页参数，body application/json pageNum、pageSize 可选

逻辑根据name参数查询数据库中`sql_search_config`配置表中的`sql`字段配置的SQL，根据配置的SQL进行查询并自动进行分页返回。

