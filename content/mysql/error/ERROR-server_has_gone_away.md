---
title: "ERROR Server_has_gone_away"
date: 2020-10-16T16:52:40+08:00
draft: true

---

## MySQL server has gone away 问题的解决方法

mysql出现ERROR : (2006, 'MySQL server has gone away') 的问题意思就是指client和MySQL server之间的链接断开了。
造成这样的原因一般是sql操作的时间过长，或者是传送的数据太大(例如使用insert ... values的语句过长， 这种情况可以通过修改max_allowed_packed的配置参数来避免，也可以在程序中将数据分批插入)。
产生这个问题的原因有很多，总结下网上的分析：
### 原因一. MySQL 服务宕了 
判断是否属于这个原因的方法很简单，进入mysql控制台，查看mysql的运行时长

```
mysql> show global status like 'uptime';
 +---------------+---------+
 | Variable_name | Value   |
 +---------------+---------+
 | Uptime        | 3414707 |
 +---------------+---------+
```

1 row in set或者查看MySQL的报错日志，看看有没有重启的信息
如果uptime数值很大，表明mysql服务运行了很久了。说明最近服务没有重启过。
如果日志没有相关信息，也表名mysql服务最近没有重启过，可以继续检查下面几项内容。
### 原因二. mysql连接超时 
即某个mysql长连接很久没有新的请求发起，达到了server端的timeout，被server强行关闭。
 此后再通过这个connection发起查询的时候，就会报错server has gone away
（大部分PHP脚本就是属于此类）
```
mysql> show global variables like '%timeout';
 +----------------------------+----------+
 | Variable_name              | Value    |
 +----------------------------+----------+
 | connect_timeout            | 10       |
 | delayed_insert_timeout     | 300      |
 | innodb_lock_wait_timeout   | 50       |
 | innodb_rollback_on_timeout | OFF      |
 | interactive_timeout        | 28800    |
 | lock_wait_timeout          | 31536000 |
 | net_read_timeout           | 30       |
 | net_write_timeout          | 60       |
 | slave_net_timeout          | 3600     |
 | wait_timeout               | 28800    |
 +----------------------------+----------+
 10 rows in set
```

wait_timeout 是28800秒，即mysql链接在无操作28800秒后被自动关闭

### 原因三. mysql请求链接进程被主动kill 
这种情况和原因二相似，只是一个是人为一个是MYSQL自己的动作

```
mysql> show global status like 'com_kill';
 +---------------+-------+
 | Variable_name | Value |
 +---------------+-------+
 | Com_kill      | 21    |
 +---------------+-------+
 1 row in set
```

### 原因四. Your SQL statement was too large.
当查询的结果集超过 max_allowed_packet 也会出现这样的报错。定位方法是打出相关报错的语句。
用select * into outfile 的方式导出到文件，查看文件大小是否超过 max_allowed_packet ，如果超过则需要调整参数，或者优化语句。

```
mysql> show global variables like 'max_allowed_packet';
 +--------------------+---------+
 | Variable_name      | Value   |
 +--------------------+---------+
 | max_allowed_packet | 1048576 |
 +--------------------+---------+
 1 row in set (0.00 sec)
 ```
修改参数：

```
mysql> set global max_allowed_packet=1024*1024*16;
 mysql> show global variables like 'max_allowed_packet';
 +--------------------+----------+
 | Variable_name      | Value    |
 +--------------------+----------+
 | max_allowed_packet | 16777216 |
 +--------------------+----------+
 1 row in set (0.00 sec)
```

## MySQL "Got an Error Reading Communication Packet" Errors

前言： 本文是对Muhammad Irfan的这篇博客MySQL "Got an Error Reading Communication Packet" Errors的翻译,如有翻译不对或不好的地方，敬请指出，大家一起学习进步。尊重原创和翻译劳动成果，转载时请注明出处。谢谢！

 

 

英文原文地址：https://www.percona.com/blog/2016/05/16/mysql-got-an-error-reading-communication-packet-errors/

 

 

翻译原文地址：http://www.cnblogs.com/kerrycode/p/9075214.html

 

 

 

在这篇博客中，我们来讨论一下引起MySQL出现”Got an error reading communication packet”错误的可能原因，以及如何解决这个错误。

 

在Percona的托管服务中，我们经常收到客户关于通信故障错误的问题—客户面临间歇性的”Got an error reading communication packet”错误，我认为这个话题值得写一篇博客，所以我们在这里讨论这个错误出现的可能原因，以及如何解决这个问题。我希望这些能够帮助读者如何调查和解决这个问题。

 

首先，当通信故障错误出现时，MySQL的状态变量Aborted_clients和Aborted_connects的计数会增加。这两个状态变量描述了由于客户端没有正确关闭连接而导致中断的连接数以及那些尝试登录MySQL失败的连接数量（分别）。两个错误出现的可能原因很多（请参考官方文档关于Aborted_clients increments or Aborted_connects increments 章节）。

 

在系统变量log_warnings > 1的情况下，MySQL会将这些信息写入错误日志（如下所示）：

 

[Warning] Aborted connection 305628 to db: 'db' user: 'dbuser' host: 'hostname' (Got an error reading communication packets)

[Warning] Aborted connection 305627 to db: 'db' user: 'dbuser' host: 'hostname' (Got an error reading communication packets)

 

 

在下面这些情况下， MySQL会增加Aborted_clients状态变量的计数，这可能意味着：

 

o    客户端已经成功连接，但是异常终止了（可能与未正确关闭连接有关系）

o    客户端休眠时间超过了系统变量wait_timeout或interactive_timeout的定义值（最终导致连接休眠的时间超过系统变量wait_timeout的值，然后被MySQL强行关闭）

o    客户端异常中断或查询超出了max_allowed_packet值。

 

上面不是一个包括了全部可能原因的列表，现在，我们来聊聊如何识别导致这个问题的原因以及如何解决这个。

 

我们如何识别导致此问题的原因，以及如何解决、修复这个问题呢？

 

 

老实来说，连接中断错误不容易诊断，但根据我的经验，大部分时候它跟网络/防火墙问题有关，我们通常在Percona Toolkit脚本的帮助下来调查这些问题。例如pt-summary / pt-mysql-summary / pt-stalk 这些脚本的输出信息非常有帮助。

 

其中的一些可能原因：

 

在MySQL内部，大量的MySQL连接处于休眠状态并休眠了数百秒是应用程序在完成工作后没有关闭连接的症状之一，它们依靠wait_tiemout系统变量来关闭连接。 我强烈建议修改应用程序逻辑，在操作结束后正确关闭连接。

 

检查并确保max_allowed_packet的值足够大，并且客户端没有收到“packet Too large”这种消息，这种情况会导致连接中断而无法正常关闭连接。

 

另外一种可能性是TIME_WAIT， 我注意到了许多来自netstat的TIME_WAIT通知，所以我建议在应用程序端管理好连接并关闭连接。

 

确保事务正确的提交（begin 和 commit），以便一旦应用程序完成后，它保持干净状态。

 

你应该确保客户端应用程序不会终止连接。 例如，如果PHP将选项max_execution_time设置成5秒，则增加connection_timeout将无济于事， 因为PHP将终止该脚本。其它编程语言和环境可能有类似的安全选项。

 

引起连接延迟的另外一个原因是DNS问题，检查是否启用了跳过名称解析，以及主机是否针对其IP地址而不是其主键名进行身份验证。

 

找出应用程序错误行为的一种方法在代码中增加一些日志记录，以便将应用程序的操作与MySQL连接标识信息一起保存。这样你可以将它与错误行中的连接号关联起来。启用PerConna审计日志插件(Audit log plugin)，记录连接和查询活动，并在你遇到连接中断时检查Percona Audit Log Plugin的日志，以确定哪个查询是罪魁祸首。如果你由于某种原因不能使用Audit插件，你可以考虑使用MySQL的查询日志，尽管在负荷较高的服务器可能有风险， 你也应该启用查询日志至少几分钟。虽然它给服务器带来了沉重的负担，由于错误往往会经常发生，所以你应该能够在日志变得过大前收集到所需的数据，我建议使用启用查询日志并使用tail -f来查看查询日志，当你在查询日志中看到下一个告警出现时，就禁用查询日志。

 

 

一旦你从中断的连接中找到一些查询语句后，在应用程序中找到使用这些查询的相关应用程序部分。

 

 

尝试增加MySQL的系统变量net_read_timeout 和 net_write_timeout 的值，看看是否会减少错误的数量，net_read_timeout是很少出现的异常，除非你的网络环境实在是太糟糕了，尝试调整这些值，因为在大多数情况下，会生成一个查询并将其作为单个数据包发送到服务器，并且应用程序无法切换到执行其他操作，而将服务器保留作为部分接收的查询。我们的首席执行官Peter Zaitsev关于这个话题有一篇非常详细的博客文章。

 

 

中断连接的出现是因为连接未正确关闭。除非服务器和客户端直接存在网络问题（例如，服务器是半双工，客户端是全双工），否则服务器不会导致连接中断，所以引起问题的是网络，而不是服务器，在任何情况下，这些问题应该显示为网络接口上的错误，为了更加确定，请在MySQL服务器上使用ifconfig -a命令输出相关信息。以检查是否有错误。

 

解决这个问题的另外一个方法是通过tcpdump工具，你可以参考这篇博客，了解如何追踪连接中断的来源，查找潜在的网络问题、超时和与 MySQL 相关的资源问题。

 

我发现这篇博客对解释如何在繁忙的主机上使用tcpdump非常有用，它为跟踪导致中止连接的TCP交换序列提供了帮助，这可以帮助您找出连接断开的原因。

 

对于网络问题，使用ping命令计算mysqld所在的服务器与应用程序发出请求的机器之间的往返时间（RTT），从客户端向服务器发送大文件（1GB或更大），使用tcpdump观察进程，然后检查传输过程中是否发生错误。重复这个测试。我也从我的同事Marco Tusa那里找到了这个有用的方法：  检查网络连接的有效方法。

 

对于网络问题，使用ping来计算mysqld所在的机器与应用程序发出请求的机器之间的往返时间（RTT）。向客户机和服务器机器发送大文件（1GB或更多），使用tcpdump观察进程，然后检查传输过程中是否发生错误。重复这个测试几次。我也从我的同事Marco Tusa那里找到了这个有用的方法：检查网络连接的有效方法。

 

我能想到的另一个想法是在每N秒后捕获一次netstat -s输出和一个时间戳（例如，10秒钟，这样您就可以将BEFORE和AFTER中断连接错误的netstat -s输出与MySQL错误日志相关联） 。通过中断连接错误的时间戳，您可以将它与根据netstat时间戳记捕获的netstat示例进行共同关联，并观察在netstat -s的TcpExt部分下增加了哪些错误计数器。

 

除此之外，还应该检查位于客户端和服务器之间的网络基础架构，从代理（proxies），负载平衡器和防火墙那些可能导致问题的方面入手。




