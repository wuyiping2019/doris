# ODS

ODS层用于汇总来自各个其他数据源的数据。

## 1.卡管(bjcard_makeuse)

同步卡管的数据分为实时同步和增量同步。

实时同步借助canal-server--->canal-adapter->jdbc->doris。

增量同步借助doris jdbc catalog--->doris

详情查看&nbsp;&nbsp;[**卡管**](bjcard_makeuse.md)