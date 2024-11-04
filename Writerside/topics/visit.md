# 访问

## 1.通过Web UI访问

FE启动后，可以通过任意FE节点的http://[IP]:[http_port]，默认http_port=8030。

## 2.通过MySQL客户端访问

指定IP和query_port,默认query_port=9030。

```shell
mysql -uroot -h[IP] -P[query_port] -p
```

## 3.补充

安装完doris后，默认root用户的密码是空字符串

```shell
# 使用root登录后 重置密码 
SET PASSWORD = PASSWORD('User123$');
```
