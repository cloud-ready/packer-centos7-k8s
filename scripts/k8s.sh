#!/bin/bash -eux

# Fix centos warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
# see: https://gist.github.com/ibrahimlawal/bfec7092cb64d46d8f9d1fd2c0c3d9c8
touch /etc/environment
echo 'LANG=en_US.utf-8' | tee -a /etc/environment
echo 'LC_ALL=en_US.utf-8' | tee -a /etc/environment


if [[ ! -d /usr/local/bin ]]; then mkdir -p /usr/local/bin; chmod 755 /usr/local/bin; fi
echo 'export PATH="${PATH}:/usr/local/bin"' > /etc/profile.d/path.sh


# CentOS 7 restore the old naming convention (change network interface names from enp* To eth*)
# Disable consistent network device naming in RHEL7 see: https://access.redhat.com/discussions/916973
# see: https://www.thegeekdiary.com/centos-rhel-7-how-to-use-the-old-ethx-style-network-interfaces-names/
# Note that the biosdevname package is not installed by default, so unless it gets installed, you don't need to add biosdevname=0 as a kernel argument.
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules

function edit_grub() {
    local conf_file="$1"

    if [[ -f ${conf_file} ]]; then
        if [[ -z $(cat ${conf_file} | grep GRUB_CMDLINE_LINUX) ]]; then
            touch ${conf_file}
            echo 'GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"' | tee -a ${conf_file}
        else
            GRUB_CMDLINE_LINUX="$(cat ${conf_file} | grep GRUB_CMDLINE_LINUX | head -n1 | sed -r 's#^GRUB_CMDLINE_LINUX="(.*)"#\1#')"
            GRUB_CMDLINE_LINUX="${GRUB_CMDLINE_LINUX} net.ifnames=0 biosdevname=0"
            sed -i "s#GRUB_CMDLINE_LINUX=.*#GRUB_CMDLINE_LINUX=\"${GRUB_CMDLINE_LINUX}\"#" ${conf_file}
        fi
    else
        echo 'GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"' | tee ${conf_file}
    fi
}

edit_grub "/etc/sysconfig/grub"
edit_grub "/etc/default/grub"
grub2-mkconfig -o /boot/grub2/grub.cfg
if [[ -d /boot/efi/EFI/redhat ]]; then grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg; fi

echo 'nmcli connection show'
nmcli connection show
#echo 'nmcli connection modify enp0s3 connection.interface-name eth0'
#nmcli connection modify enp0s3 connection.interface-name eth0
#nmcli connection show


# using socat to port forward in helm tiller
# install  kmod and ceph-common for rook
yum install -y epel-release
yum install -y bash-completion jq
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
if [[ $? -ne 0 ]]
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
