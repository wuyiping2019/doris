FROM centos:7.6.1810

RUN curl -o /etc/yum.repos.d/CentOS-Base.repo \
    http://mirrors.aliyun.com/repo/Centos-7.repo && \
    yum install -y epel-release net-tools firewalld ntpd && \
    yum clean all

# 安装常用工具
RUN yum install -y \
    wget \
    vim \
    tar \
    gzip \
    && yum clean all

WORKDIR /opt