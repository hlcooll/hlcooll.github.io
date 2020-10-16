---
title: "Ingress Tls"
date: 2020-10-15T17:31:29+08:00
draft: true

---

```
kubectl -n kubernetes-dashboard create secret tls hl-https --cert=hlcooll.crt --key=hlcooll.key 
```

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kubernetes-dashboard
spec:
  tls:
  - hosts:
    - dashboard.hlcool.top
    secretName: https
  rules:
    - host: sslexample.foo.com
      http:
        paths:
        - path: /
          backend:
            serviceName: kubernetes-dashboard
            servicePort: 80
```