---
title: "Api外部访问"
date: 2020-10-21T15:37:34+08:00
draft: true

---


##### 网络监听
```
kubectl proxy --address='81.68.84.91'  --accept-hosts='^*$' --port=8001 
启动kubectl proxy，使用网卡IP，从其他机器访问， --accept-hosts='^*$' 表示接受所有源IP,否则会显示不被授权
curl  https://81.68.84.91:8001/api

```
## 2.直接访问api
##### 2.1获取集群名称和api地址   
```
kubectl config view -o jsonpath='{"Cluster name\tServer\n"}{range .clusters[*]}{.name}{"\t"}{.cluster.server}{"\n"}{end}'
export CLUSTER_NAME="kubernetes"
APISERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")
```

#### 2.2serviceaccount创建访问ssl权限secret token
````````
kubectl create sa test

kubectl create clusterrolebinding sa-test-cluster-admin --clusterrole='cluster-admin' --serviceaccount=default:test

TOKEN=$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='test')].data.token}"|base64 -d)
````````

```` 使用token访问api
curl --header "Authorization: Bearer $TOKEN" --insecure  -X GET $APISERVER/api/v1/namespaces/test/pods?limit=1
curl --header "Authorization: Bearer $TOKEN" --insecure  -X GET $APISERVER/api/v1/namespaces/default/pods?limit=1
curl --header "Authorization: Bearer $TOKEN" --insecure  -X GET $APISERVER/api/v1/namespaces/kube-system/pods?limit=1
https://81.68.84.91:6443/apis/apps/v1/
````

#### 2.3.使用useraccount来访问

创建user panmeng的证书
```
openssl genrsa -out panmeng.key 2048
openssl req -new -key panmeng.key -out panmeng.csr -subj "/CN=panmeng"
openssl x509 -req -in panmeng.csr -out panmeng.crt -sha1 -CA ca.crt -CAkey ca.key  -CAcreateserial -days 3650
```
创建角色getpods，创建角色绑定user panmeng和role getpods
```
kubectl create role getpods --verb=get --verb=list --resource=pods
kubectl create rolebinding panmeng-getpods --role=getpods --user=panmeng --namespace=default
```
验证访问是否正常
```
curl --cert /etc/kubernetes/pki/panmeng.crt   -X GET $APISERVER/api/v1/namespaces/default/pods?limit=1 --key /etc/kubernetes/pki/panmeng.key  --insecure
```

验证用户panmeng不具备访问namespace kube-system的权限
```
curl --cert /etc/kubernetes/pki/panmeng.crt   -X GET $APISERVER/api/v1/namespaces/kube-system/pods?limit=1 --key /etc/kubernetes/pki/panmeng.key  --insecure
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {
    
  },
  "status": "Failure",
  "message": "pods is forbidden: User \"panmeng\" cannot list resource \"pods\" in API group \"\" in the namespace \"kube-system\"",
  "reason": "Forbidden",
  "details": {
    "kind": "pods"
  },
  "code": 403
}
```

## 3.常用api资源
以下为常用资源的URL路径，将/apis/GROUP/VERSION/替换为/api/v1/,则表示基础API组
```
/apis/GROUP/VERSION/RESOURCETYPE
/apis/GROUP/VERSION/RESOURCETYPE/NAME
/apis/GROUP/VERSION/namespaces/NAMESPACE/RESOURCETYPE
/apis/GROUP/VERSION/namespaces/NAMESPACE/RESOURCETYPE/NAME
/apis/GROUP/VERSION/RESOURCETYPE/NAME/SUBRESOURCE
/apis/GROUP/VERSION/namespaces/NAMESPACE/RESOURCETYPE/NAME/SUBRESOURCE
```

查看扩展api里的资源deployments
```
curl  http://127.0.0.1:8001/apis/extensions/v1beta1/namespaces/kube-system/deployments
```

查看基础api里的资源pods
```
curl  http://127.0.0.1:8001/api/v1/namespaces/kube-system/pods/
```

#### 3.1.使用watch持续监控资源的变化
```
curl  http://127.0.0.1:8001/api/v1/namespaces/test/pods
"resourceVersion": "2563046"
curl  http://127.0.0.1:8001/api/v1/namespaces/test/pods?watch=1&resourceVersion=2563046
```

#### 3.2.查看前n个资源
```
curl  http://127.0.0.1:8001/api/v1/namespaces/kube-system/pods?limit=1
"continue": "eyJ2IjoibWV0YS5rOHMuaW8vdjEiLCJydiI6MjU2NDk2Mywic3RhcnQiOiJjYWxpY28tbm9kZS1jejZrOVx1MDAwMCJ9"
```
使用continue token查看下n个资源
```
curl  'http://127.0.0.1:8001/api/v1/namespaces/kube-system/pods?limit=1&continue=eyJ2IjoibWV0YS5rOHMuaW8vdjEiLCJydiI6MjU3MTYxMSwic3RhcnQiOiJjYWxpY28ta3ViZS1jb250cm9sbGVycy01Y2JjY2NjODg1LWt2bGRyXHUwMDAwIn0'
```

## 4.资源的类型
```
资源分类：Workloads，Discovery & LB ，Config & Storage，Cluster，Metadata
资源对象：Resource ObjectMeta，ResourceSpec，ResourceStatus
资源操作：create，update（replace&patch），read（get&list&watch），delete,rollback,read/write scale,read/write status

```

## 5.Workloads的操作
以pod为例，介绍workloads apis，以下为pod的yaml文件
```
apiVersion: v1
kind: Pod
metadata:
  name: pod-example
spec:
  containers:
  - name: ubuntu
    image: ubuntu:trusty
    command: ["echo"]
    args: ["Hello World"]
```

#### 5.1. 创建pod

```
POST /api/v1/namespaces/{namespace}/pods
```
查看当前pods
```
kubectl -n kube-system get pods
```

使用api创建pod
```
curl --request POST http://127.0.0.1:8001/api/v1/namespaces/test/pods -s -w "状态码是:%{http_code}\n" -o /dev/null -H 'Content-Type: application/yaml' --data 
'apiVersion: v1
kind: Pod
metadata:
  name: pod-example
spec:
  containers:
  - name: ubuntu
    image: ubuntu:trusty
    command: ["echo"]
    args: ["Hello World"]'

状态码是:201
```
查看当前pods
```
kubectl -n test get pods
```

#### 5.2.删除pod

```
DELETE /api/v1/namespaces/{namespace}/pods/{name}
```
查看当前pods
```
kubectl get pods -n test --show-labels
```
删除pod pod-example
```
curl --request DELETE http://127.0.0.1:8001/api/v1/namespaces/test/pods/pod-example -o /dev/null  -s -w "状态码是:%{http_code}\n" 

状态码是:200
```

查看当前pods
```
kubectl get pods -n test --show-labels
```









``` 参考资料
https://www.jianshu.com/p/0a5976ce1ce4
```