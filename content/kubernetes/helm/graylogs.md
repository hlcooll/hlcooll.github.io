---
title: "Graylogs"
date: 2020-10-16T10:12:53+08:00
draft: true

---

### mongodb

```
#  Warning  FailedCreate      30s (x14 over 71s)  statefulset-controller  create Pod mongodb-replicaset-1602575807-0 in StatefulSet mongodb-replicaset-1602575807 failed error: Pod "mongodb-replicaset-1602575807-0" is invalid: spec.containers[0].startupProbe.successThreshold: Invalid value: 2: must be 1

helm fetch  stable/mongodb-replicaset
kubectl create namespace mongodb

helm install mongodb-replicaset   --namespace "graylog" -n "mongodb" stable/mongodb-replicaset  --set persistentVolume.storageClass="nfs-client"  --set startupProbe.successThreshold="1"


```
```
WARNING: This chart is deprecated
NAME: mongodb-replicaset
LAST DEPLOYED: Fri Oct 16 10:17:48 2020
NAMESPACE: mongodb
STATUS: deployed
REVISION: 1
NOTES:
*******************
****DEPRECATED*****
*******************
*
* This chart is deprecated and no longer maintained.
*
* It is recommended to use the Bitnami maintained MongoDB chart
* (https://github.com/bitnami/charts/tree/master/bitnami/mongodb)
* which has a similar feature set.


1. After the statefulset is created completely, one can check which instance is primary by running:

    $ for ((i = 0; i < 3; ++i)); do kubectl exec --namespace mongodb mongodb-replicaset-$i -- sh -c 'mongo --eval="printjson(rs.isMaster())"'; done

2. One can insert a key into the primary instance of the mongodb replica set by running the following:
    MASTER_POD_NAME must be replaced with the name of the master found from the previous step.

    $ kubectl exec --namespace mongodb MASTER_POD_NAME -- mongo --eval="printjson(db.test.insert({key1: 'value1'}))"

3. One can fetch the keys stored in the primary or any of the slave nodes in the following manner.
    POD_NAME must be replaced by the name of the pod being queried.

    $ kubectl exec --namespace mongodb POD_NAME -- mongo --eval="rs.slaveOk(); db.test.find().forEach(printjson)"

```

### graylog create
```
#GRAYLOG_HTTP_EXTERNAL_URI  html重定向路径
      containers:
        - name: graylog-master
          image: graylog/graylog:3.3
          env:
          - name: TZ
            value: "Asia/Shanghai"
          - name: GRAYLOG_PASSWORD_SECRET
            value: "somepasswordpepper"
          - name: GRAYLOG_ROOT_PASSWORD_SHA2
            value: "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918"
          - name: GRAYLOG_MONGODB_URI
            #value: "mongodb://mongo-mongodb:27017/graylog"
            value: "mongodb://mongodb-replicaset-0.mongodb-replicaset.mongodb.svc.cluster.local:27017,mongodb-replicaset-1.mongodb-replicaset.mongodb.svc.cluster.local:27017,mongodb-replicaset-2.mongodb-replicaset.mongodb.svc.cluster.local:27017/graylog?replicaSet=rs0"
          - name: GRAYLOG_ROOT_TIMEZONE
            value: "PRC"
          - name: GRAYLOG_IS_MASTER
            value: "true"
          - name: GRAYLOG_ELASTICSEARCH_HOSTS
            value: "http://elasticsearch-0.elasticsearch.default.svc.cluster.local:9200, http://elasticsearch-1.elasticsearch.default.svc.cluster.local:9200, http://elasticsearch-2.elasticsearch.default.svc.cluster.local:9200"
          - name: GRAYLOG_WEB_ENDPOINT_URI
            value: "http://81.68.84.91:31300/api"
          - name: GRAYLOG_REST_LISTEN_URI
            value: "http://graylog.hlcooll.top/api/"
          - name: GRAYLOG_WEB_LISTEN_URI
            value: "http://graylog.hlcooll.top/"
          - name: GRAYLOG_HTTP_EXTERNAL_URI
            value: "http://graylog.hlcooll.top/"
          - name: GRAYLOG_REST_TRANSPORT_URI
            value: "http://graylog-master:9000/api/"
          - name: GRAYLOG_SERVER_JAVA_OPTS
            value: "-Xms1g -Xmx1g -XX:NewRatio=1 -XX:MaxMetaspaceSize=256m -server -XX:+ResizeTLAB -XX:+UseConcMarkSweepGC -XX:+CMSConcurrentMTEnabled -XX:+CMSClassUnloadingEnabled -XX:+UseParNewGC -XX:-OmitStackTraceInFastThrow"

```

{{- $image := resources.Get “images/niko-photos-tGTVxeOr_Rs-unsplash.jpg” -}}
