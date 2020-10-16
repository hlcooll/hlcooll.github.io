---
title: "Nfs Sc"
date: 2020-10-15T18:02:24+08:00
draft: true

---

https://github.com/kubernetes-retired/external-storage/tree/master/nfs-client


#创建nfs-sc
helm install stable/nfs-client-provisioner --set nfs.server=172.17.16.14 --set nfs.path=/data/u01/prod