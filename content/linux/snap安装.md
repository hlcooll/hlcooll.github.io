---
title: "Snap安装"
date: 2020-10-19T16:52:16+08:00
draft: true

---

### centos7安装snap
```
#添加epel存储库并安装copr yum插件开始安装
sudo yum install epel-release
sudo yum install yum-plugin-copr
#添加仓库
sudo yum copr enable ngompa/snapcore-el7
#安装
sudo yum -y install snapd

sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap

snap --help
```

### centos8安装snap
```
#添加EPEL存储库
sudo dnf -y install https://dl.Fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
#
sudo dnf -y upgrade

sudo dnf -y install snapd

sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap

snap --help
```