---
title: "HUGO"
date: 2020-09-15T14:37:56+08:00
draft: true

---

# Hugo 能做什么
    通过 Hugo 你可以快速搭建你的静态网站，比如博客系统、文档介绍、公司主页、产品介绍等等。相对于其他静态网站生成器来说，Hugo 具备如下特点：
    极快的页面编译生成速度。（ ~1 ms 每页面）
    完全跨平台支持，可以运行在  Mac OS X,  Linux,  Windows, 以及更多!
    安装方便 Installation
    本地调试 Usage 时通过 LiveReload 自动即时刷新页面。
    完全的皮肤支持。
    可以部署在任何的支持 HTTP 的服务器上。

# Hugo 官方下载地址
```
https://github.com/gohugoio/hugo/releases
```

# Hugo 官网资料
```
#doc
https://gohugo.io/getting-started/installing/
#主题
https://themes.gohugo.io/
```

# Hugo 命令
```
查看版本
hugo version

```

# Hugo 创建
```
hugo new site hlcooll
```

# Hugo 安装主题
```
# 主题地址https://themes.gohugo.io/hyde/
cd themes/
git clone https://github.com/spf13/hyde.git

```

# 修改config.toml
```
baseURL = "https://hlcooll.github.io/"
languageCode = "en-us"
#HTML的title标题
title = "hlcooll"
#主题
theme = "hyde"
#侧边栏菜单
[Menus]
  main = [
      {Name = "Github", URL = "https://github.com/hlcooll"},  
  ]

[params]
  description = "blog"
  #配色主题
  themeColor = "theme-base-0d"
  #反向布局
  layoutReverse = true
  #启用由Disqus提供的评论系统来发布帖子
  disqusShortname = "spf13"
  #谷歌分析跟踪代码 https://analytics.google.com/
  googleAnalytics = "UA-180227187-1"

```

# Sticky sidebar content
```
<!-- Default sidebar -->
<div class="sidebar">
  <div class="container sidebar-sticky">
    ...
  </div>
</div>

<!-- Modified sidebar -->
<div class="sidebar">
  <div class="container">
    ...
  </div>
</div>

```

# Hugo 启动服务
```
hugo server --theme=hyde --port 1314 --buildDrafts
hugo server -t hyde --port 1333 --buildDrafts
hugo server --theme=hyde --buildDrafts --watch
```

# Hugo 生成静态文件
```
// baseurl 需要修改为自己的page地址,hyde当前使用的hugo主题！生成静态文件public
hugo --theme=hyde --buildDrafts --baseUrl="https://hlcooll.github.io/public/"
```

# Hugo 上传github
```
#Github pages 
https://pages.github.com/


```


