---
title: "Helm"
date: 2020-10-15T18:03:52+08:00
draft: true

---

#安装Helm3
```
#下载：
wget https://get.helm.sh/helm-v3.3.1-linux-amd64.tar.gz

curl -L -o helm-v3.2.4-linux-amd64.tar.gz https://file.choerodon.com.cn/kubernetes-helm/v3.2.4/helm-v3.2.4-linux-amd64.tar.gz

#官方安装文档
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh

解压压缩包（以linux-amd64为例）
tar -zxvf helm-v3.2.4-linux-amd64.tar.gz

将文件移动到PATH目录中（以linux-amd64为例）

sudo mv linux-amd64/helm /usr/bin/helm

chmod a+x /usr/bin/helm
#验证部署
执行命令，出现以下信息即部署成功。
helm version

#配置仓库
helm repo add aliyun https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts

```