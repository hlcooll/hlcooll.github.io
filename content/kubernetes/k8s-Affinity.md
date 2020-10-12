---
title: "K8s Affinity"
date: 2020-10-12T11:15:57+08:00
draft: true

---


# k8s学习笔记-调度之Affinity
```
Kubernetes中的调度策略可以大致分为两种

一种是全局的调度策略，要在启动调度器时配置，包括kubernetes调度器自带的各种predicates和priorities算法，具体可以参看上一篇文章；

另一种是运行时调度策略，包括nodeAffinity（主机亲和性），podAffinity（POD亲和性）以及podAntiAffinity（POD反亲和性）。

nodeAffinity 主要解决POD要部署在哪些主机，以及POD不能部署在哪些主机上的问题，处理的是POD和主机之间的关系。

podAffinity 主要解决POD可以和哪些POD部署在同一个拓扑域中的问题（拓扑域用主机标签实现，可以是单个主机，也可以是多个主机组成的cluster、zone等。）

podAntiAffinity主要解决POD不能和哪些POD部署在同一个拓扑域中的问题。它们处理的是Kubernetes集群内部POD和POD之间的关系。

三种亲和性和反亲和性策略的比较如下表所示：

策略名称	匹配目标	支持的操作符	支持拓扑域	设计目标
nodeAffinity	主机标签	In，NotIn，Exists，DoesNotExist，Gt，Lt	不支持	决定Pod可以部署在哪些主机上
podAffinity	Pod标签	In，NotIn，Exists，DoesNotExist	支持	决定Pod可以和哪些Pod部署在同一拓扑域
PodAntiAffinity	Pod标签	In，NotIn，Exists，DoesNotExist	支持	决定Pod不可以和哪些Pod部署在同一拓扑域

亲和性：应用A与应用B两个应用频繁交互，所以有必要利用亲和性让两个应用的尽可能的靠近，甚至在一个node上，以减少因网络通信而带来的性能损耗。

反亲和性：当应用的采用多副本部署时，有必要采用反亲和性让各个应用实例打散分布在各个node上，以提高HA。

主要介绍kubernetes的中调度算法中的Node affinity和Pod affinity用法

实际上是对前文提到的优选策略中的NodeAffinityPriority策略和InterPodAffinityPriority策略的具体应用。

kubectl explain pods.spec.affinity 

亲和性策略（Affinity）能够提供比NodeSelector或者Taints更灵活丰富的调度方式，例如：

丰富的匹配表达式（In, NotIn, Exists, DoesNotExist. Gt, and Lt）
软约束和硬约束（Required/Preferred）
以节点上的其他Pod作为参照物进行调度计算
亲和性策略分为NodeAffinityPriority策略和InterPodAffinityPriority策略。

先回顾一下之前的节点选择器

节点选择器： nodeSelector nodeName
创建一个Pod 节点选择器标签
nodeSelector:
   disktype: ssd

默认节点没这个标签：所以会调度失败

[root@k8s-master schedule]# kubectl get node --show-labels|egrep disktype
[root@k8s-master schedule]# kubectl get pods
NAME          READY      STATUS      RESTARTS  AGE
pod-demo        0/1        Pending           0          11s
[root@k8s-master schedule]# kubectl describe pod pod-demo
Warning FailedScheduling 28s (x2 over 28s) default-scheduler 0/3 nodes are available: 3 node(s) didn't match node selector.

给一个节点打上标签：
[root@k8s-master schedule]# kubectl label nodes k8s-node2 disktype=ssd
node/k8s-node2 labeled

[root@k8s-master schedule]# kubectl get node --show-labels|egrep disktype
k8s-node2 Ready <none> 63d v1.14.1 beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,disktype=ssd,kubernetes.io/arch=amd64,kubernetes.io/hostname=k8s-node2,kubernetes.io/os=linux

[root@k8s-master schedule]# kubectl get pods -o wide
NAME          READY          STATUS         RESTARTS AGE     IP             NODE            NOMINATED NODE  READINESS GATES
pod-demo       1/1               Running             0          45s  10.244.1.14   k8s-node2                 <none>              <none>

Node affinity（节点亲和性）

kubectl explain pods.spec.affinity.nodeAffinity 

据官方说法未来NodeSeletor策略会被废弃，由NodeAffinityPriority策略中requiredDuringSchedulingIgnoredDuringExecution替代。

NodeAffinityPriority策略和NodeSelector一样，通过Node节点的Label标签进行匹配，匹配的表达式有：In, NotIn, Exists, DoesNotExist. Gt, and Lt。

定义节点亲和性规则有2种：硬亲和性（require）和软亲和性（preferred）

硬亲和性：requiredDuringSchedulingIgnoredDuringExecution
软亲和性：preferredDuringSchedulingIgnoredDuringExecution

硬亲和性：实现的是强制性规则，是Pod调度时必须满足的规则，否则Pod对象的状态会一直是Pending
软亲和性：实现的是一种柔性调度限制，在Pod调度时可以尽量满足其规则，在无法满足规则时，可以调度到一个不匹配规则的节点之上。
需要注意的是preferred和required后半段字符串IgnoredDuringExecution表示：

在Pod资源基于节点亲和性规则调度到某个节点之后，如果节点的标签发生了改变，调度器不会讲Pod对象从该节点上移除，因为该规则仅对新建的Pod对象有效。

硬亲和性

kubectl explain pods.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution

apiVersion: v1
kind: Pod
metadata:
    name: nodeaffinity-required 
spec:

   containers:
  -  name: myapp
      image: ikubernetes/myapp:v1
   affinity:
     nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          -  matchExpressions:
         #   -  {key: zone,operator: In,values: ["ssd","hard"]}    

              -  key: disktype
                 operator: In
                 values:
                 -  ssd

                 -  hard

[root@k8s-master schedule]# kubectl get pod -o wide
NAME                        READY         STATUS              RESTARTS      AGE      IP               NODE             NOMINATED NODE    READINESS GATES
pod-affinity-required     1/1               Running                  0               7s    10.244.1.16     k8s-node2              <none>                   <none>

发现和上面定义的节点选择器效果一样，未来是要取代节点选择器的。

注意：

nodeSelectorTerms可以定义多条约束，只需满足其中一条。
    matchExpressions可以定义多条约束，必须满足全部约束。

如下配置清单，必须存在满足标签zone=foo和ssd=true的节点才能够调度成功
affinity:
   nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
         nodeSelectorTerms:
         -  matchExpressions:
             -  {key: zone, operator: In, values: ["foo"]}
             -  {key: ssd, operator: Exists, values: []} #增加一个规则

[root@k8s-master ~]# kubectl get pods pod-affinity-required
NAME                           READY       STATUS     RESTARTS    AGE
pod-affinity-required       0/1            Pending          0             16s
[root@k8s-master ~]# kubectl label node k8s-node1 ssd=true

[root@k8s-master ~]# kubectl get pods  pod-affinity-required 
NAME                             READY         STATUS       RESTARTS AGE
 pod-affinity-required         1/1              Running           0          2m

软亲和性
kubectl explain pods.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution

affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    -  weight:  60
        preference:
          matchExpressions:
          -  {key: zone, operator: In, values: ["foo"]}
    -  weight:  30
        preference:
          matchExpressions:
          -  {key: ssd, operator: Exists, values: []}

总结：
同时指定nodeSelector and nodeAffinity，pod必须都满足
nodeAffinity有多个nodeSelectorTerms ，pod只需满足一个
nodeSelectorTerms多个matchExpressions ，pod必须都满足
由于IgnoredDuringExecution，所以改变labels不会影响已经运行pod
总的来说，node亲和性与nodeSelector类似，是它的扩展，节点是否配置合乎需求的标签，或者Pod对象定义合理的标签选择器，这样才能够基于标签选择出期望的目标节点

Pod affinity（Pod 亲和性）

kubectl explain pods.spec.affinity.podAffinity

在出于高效通信的需求，有时需要将一些Pod调度到相近甚至是同一区域位置（比如同一节点、机房、区域）等等，比如业务的前端Pod和后端Pod，

此时这些Pod对象之间的关系可以叫做亲和性。同时出于安全性的考虑，也会把一些Pod之间进行隔离，此时这些Pod对象之间的关系叫做反亲和性。

调度器把第一个Pod放到任意位置，然后和该Pod有亲和或反亲和关系的Pod根据该动态完成位置编排，这就是Pod亲和性和反亲和性调度的作用。

Pod的亲和性定义也存在硬亲和性和软亲和性的区别，其约束的意义和节点亲和性类似。

requiredDuringSchedulingIgnoredDuringExecution， 硬约束，一定要满足，Pod的亲和性调度必须要满足后续定义的约束条件。
preferredDuringSchedulingIgnoredDuringExecution，软约束，不一定满足，Pod的亲和性调度会尽量满足后续定义的约束条件。

Pod的亲和性调度要求各相关的Pod对象运行在同一位置，而反亲和性则要求它们不能运行在同一位置。这里的位置实际上取决于节点的位置拓扑，拓扑的方式不同，Pod是否在同一位置的判定结果也会有所不同。

如果基于各个节点的kubernetes.io/hostname标签作为评判标准，那么会根据节点的hostname去判定是否在同一位置区域。

根据节点上正在运行的pod的标签来调度，而非node的标签，要求对节点和Pod两个条件进行匹配，其规则为：如果在具有标签X的Node上运行了一个或多个符合条件Y的Pod，那么Pod应该运行在此Node上，

如果是互斥，则拒绝运行在此Node上。 也就是说根据某个已存在的pod，来决定要不要和此pod在一个Node上，在一起就需要设置亲和性，不和它在一起就设置互斥性。

Pod亲和性调度请使用：podAffinity，非亲和性调度请使用：podAntiAffinity。

InterPodAffinityPriority策略有podAffinity和podAntiAffinity两种配置方式。

InterPodAffinityPriority是干嘛的呢？简单来说，就说根据Node上运行的Pod的Label来进行调度匹配的规则，匹配的表达式有：In, NotIn, Exists, DoesNotExist，通过该策略，可以更灵活地对Pod进行调度。

例如：将多实例的Pod分散到不通的Node、尽量调度A-Pod到有B-Pod运行的Node节点上等等。另外与Node-affinity不同的是：该策略是依据Pod的Label进行调度，所以会受到namespace约束。

硬亲和性
通过Kubernetes内置节点标签中的key来进行声明，这个key的名字为topologyKey，用来表达节点所属的拓朴结构之下。

pod的亲和性表达方式与Node亲和性是一样的表达方式。

kubectl explain pods.spec.affinity.podAffinity.requiredDuringSchedulingIgnoredDuringExecution

参数配置说明：

kubectl -get nodes --show-labels

  kubernetes内置标签：

        ○ kubernetes.io/hostname

        ○ failure-domain.beta.kubernetes.io/zone

        ○ failure-domain.beta.kubernetes.io/region

        ○ beta.kubernetes.io/instance-type

        ○ beta.kubernetes.io/os

        ○ beta.kubernetes.io/arch

topologyKey:

对于亲和性和软反亲和性，不允许空topologyKey;
对于硬反亲和性，LimitPodHardAntiAffinityTopology控制器用于限制topologyKey只能是kubernetes.io/hostname;
对于软反亲和性，空topologyKey被解读成kubernetes.io/hostname, failure-domain.beta.kubernetes.io/zone and failure-domain.beta.kubernetes.io/region的组合；
kubernetes.io/hostname标签是Kubernetes集群节点的内建标签，它的值为当前节点的主机名，对于各个节点来说都是不同的
1:创建参照Pod



#查看调度到哪个Node之上：
kubectl get pod -o wide
NAME READY STATUS RESTARTS AGE IP NODE
pod-flag 1/1 Running 0 4m 10.244.1.16 k8s-node1

2:创建一个pod的硬亲和性



# 因为pod是属于某个命名空间的，所以设置符合条件的目标Pod时，还可以指定哪个命名空间或全部命名空间里的Pod，
# namespace的定义与labelSelector同级，如果不指定命名空间，则与此处创建的pod在一个namespace之中
kubectl get pod -o wide
NAME READY STATUS RESTARTS AGE IP NODE
with-pod-affinity 1/1 Running 0 11s 10.244.1.16 k8s-node1
pod-flag 1/1 Running 0 1h 10.244.1.17 k8s-node1
的确是在同一个Node上。
如果在创建时，pod状态一直处于Pending状态，很有可能是因为找不到满足条件的Node
基于单一节点的Pod亲和性相对来说使用的情况会比较少，通常使用的是基于同一地区、区域、机架等拓扑位置约束。

比如部署应用程序（myapp）和数据库（db）服务相关的Pod时，这两种Pod应该部署在同一区域上，可以加速通信的速度

3:创建一个pod的反硬亲和性

kubectl explain pods.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution



kubectl get pod -o wide
NAME READY STATUS RESTARTS AGE IP NODE
pod-flag 1/1 Running 0 1h 10.244.1.16 k8s-node1
with-pod-affinity 1/1 Running 0 1h 10.244.1.17 k8s-node1
with-pod-antiffinity 1/1 Running 0 1m 10.244.2.11 k8s-node2
#可以看到与参照pod不在同一个node之上,达到了互斥的作用

实例：

1.借助反硬特性我们可以部署3个redis实例，并且为了提升HA，部署在不同的节点：

apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
spec:
  selector:
    matchLabels:
      app: store
  replicas: 3
  template:
    metadata:
      labels:
        app: store
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - store
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: redis-server
        image: redis:3.2-alpine
2：部署三个web实例，为了提升HA，都不在一个node；并且为了方便与redis交互，尽量与redis在同一个node（硬特性和反硬特性的结合应用）。

apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
spec:
  selector:
    matchLabels:
      app: web-store
  replicas: 3
  template:
    metadata:
      labels:
        app: web-store
    spec:
      affinity:
        podAntiAffinity: #反亲和性
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web-store
            topologyKey: "kubernetes.io/hostname"
        podAffinity: #亲和性
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - store
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: web-app
        image: nginx:1.12-alpine
软亲和性
kubectl explain pods.spec.affinity.podAffinity.preferredDuringSchedulingIgnoredDuringExecution



上述的清单配置当中，pod的软亲和调度需要将Pod调度到标签为app=cache并在区域zone当中，或者调度到app=db标签节点上的，但是我们的节点上并没有类似的标签，

所以调度器会根据软亲和调度进行随机调度到k8s-node1节点之上。如下：

[root@k8s-master ~]# kubectl get pods -o wide |grep myapp-with-preferred-pod-affinity

myapp-with-preferred-pod-affinity-5c44649f58-cwgcd 1/1 Running 0 1m 10.244.1.40 k8s-node01

myapp-with-preferred-pod-affinity-5c44649f58-hdk8q 1/1 Running 0 1m 10.244.1.42 k8s-node01

myapp-with-preferred-pod-affinity-5c44649f58-kg7cx 1/1 Running 0 1m 10.244.1.41 k8s-node01

pod的反软亲和度：

kubectl explain pods.spec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution

podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: security
              operator: In
              values:
              - S2
          topologyKey: kubernetes.io/hostname
如果该节点已经运行着具有“security=S2”标签的pod，将不会优先调度到该节点。
如果topologyKey是failure-domain.beta.kubernetes.io/zone，该pod也不会被优先调度到具有“security=S2”标签的节点所在的zone
 
实例：

使用该配置模板创建三个pod，可以发现pod依旧分配到了不同的节点上。当创建第四个pod时，第四个pod能够被顺利创建

说明preferredDuringScheduling在podAntiAnffinity下也是不严格匹配规则，如果是硬约束，会有一个处于 Pending 

对称性
考虑一个场景，两个应用S1和S2。现在严格要求S1 pod不能与S2 pod运行在一个node，
如果仅设置S1的hard反亲和性是不够的，必须同时给S2设置对应的hard反亲和性。
即调度S1 pod时，考虑node没有S2 pod，同时需要在调度S2 pod时，考虑node上没有S1 pod。考虑下面两种情况：
1.先调度S2，后调度S1，可以满足反亲和性，
2.先调度S1，后调度S2，违反S1的反亲和性规则，因为S2没有反亲和性规则，所以在schedule-time可以与S1调度在一个拓扑下。
这就是对称性，即S1设置了与S2相关的hard反亲和性规则，就必须对称地给S2设置与S1相关的hard反亲和性规则，以达到调度预期。



反亲和性（soft/hard）具备对称性，上面已经举过例子了
hard亲和性不具备对称性，例如期望test1、test2亲和，那么调度test2的时候没有必要node上一定要有test1，但是有一个隐含规则，node上有test1更好
soft亲和性具备对称性，不是很理解，遗留

总结：
1.Pod间的亲和性和反亲和性需要大量的处理，需要消耗大量计算资源，会增加调度时间,这会显着减慢大型集群中的调度。 我们不建议在大于几百个节点的群集中使用它们。

2.Pod反亲和性要求Node一致地标记,集群中的每个节点必须具有匹配topologyKey的标签,Pod反亲和性需要制定topologyKey如果某些或所有节点缺少指定的topologyKey标签，则可能导致意外行为。

3.在反亲和性中，空的selector表示不与任何pod亲和。

4.由于hard规则在预选阶段处理，所以如果只有一个node满足hard亲和性，但是这个node又不满足其他预选判断，比如资源不足，那么就无法调度。所以何时用hard，何时用soft需要根据业务考量。

5.如果所有node上都没有符合亲和性规则的target pod，那么pod调度可以忽略亲和性

6.如果labelSelector和topologyKey同级，还可以定义namespaces列表，表示匹配哪些namespace里面的pod，默认情况下，会匹配定义的pod所在的namespace，如果定义了这个字段，但是它的值为空，则匹配所有的namespaces。

7.所有关联requiredDuringSchedulingIgnoredDuringExecution的matchExpressions全都满足之后，系统才能将pod调度到某个node上。


```