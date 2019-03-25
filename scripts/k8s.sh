#!/bin/bash -eux

# using socat to port forward in helm tiller
# install  kmod and ceph-common for rook
yum install -y wget curl conntrack-tools vim net-tools telnet tcpdump bind-utils socat ntp kmod ceph-common dos2unix

# enable ntp to sync time
echo 'sync time'
systemctl start ntpd
systemctl enable ntpd
echo 'disable selinux'
setenforce 0
sed -i 's/=enforcing/=disabled/g' /etc/selinux/config

echo 'enable iptable kernel parameter'
cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_forward=1
EOF
sysctl -p

echo 'disable swap'
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

#create group if not exists
egrep "^docker" /etc/group >& /dev/null
if [ $? -ne 0 ]
then
  groupadd docker
fi

usermod -aG docker vagrant
rm -rf ~/.docker/
yum install -y docker.x86_64
# To fix docker exec error, downgrade docker version, see https://github.com/openshift/origin/issues/21590
yum downgrade -y docker-1.13.1-75.git8633870.el7.centos.x86_64 docker-client-1.13.1-75.git8633870.el7.centos.x86_64 docker-common-1.13.1-75.git8633870.el7.centos.x86_64

yum install -y etcd
systemctl daemon-reload
systemctl disable etcd

echo 'install flannel...'
yum install -y flannel
systemctl daemon-reload
systemctl disable flanneld

echo 'enable docker'
systemctl daemon-reload
systemctl start docker
docker pull docker.io/coredns/coredns:1.2.0
docker pull docker.io/jimmysong/kubernetes-dashboard-amd64:v1.8.3
docker pull docker.io/jimmysong/pause-amd64:3.0
docker pull docker.io/traefik:latest
systemctl stop docker
systemctl disable docker
