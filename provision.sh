#!/bin/bash

MASTER_IP=$1
POD_NETWORK=$2

if [ $# -eq 3 ]
then
  MASTER_or_NODE=$3
fi 
if [ $# -eq 1 ]
then
  MASTER_or_NODE=$1
fi

ECHO ()
{
	IN_RED="\e[0;33m"
	END="\e[0m"
	echo -e "$IN_RED $* $END"
}

#####echo exiting for test;exit


if [ $MASTER_or_NODE == "master" ]
then
ECHO Starting provisioning of the kubernetes master node...
ECHO Using control-plane/api-server IP=$MASTER_IP and pod network=$POD_NETWORK
else
ECHO Starting provisioning of the worker node: `hostname`
fi

ECHO Wait while updating system. This may take upto 2+ minutes...
yum update -y -q

ECHO Setting up docker repo for installing containerd...
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

ECHO Disabling selinux...
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

ECHO Disabling swap...
swapoff -a
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

ECHO Disabling firewall...
systemctl disable firewalld
systemctl stop firewalld

ECHO Setting up k8s repos to install k8s...
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF

ECHO Setting up network bridge sysctl params...
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

ECHO Loading network bridge kernel mods...
cat <<EOF > /etc/modules-load.d/k8s-mods.conf
overlay
br_netfilter
EOF
systemctl start systemd-modules-load.service
sysctl --system
echo 1 > /proc/sys/net/ipv4/ip_forward

# install/use and start containerd instead of docker, post Mar 2024
ECHO Installing containerd.io...
yum install -y -q containerd.io 
containerd config default > /etc/containerd/config.toml
systemctl start containerd

ECHO Installing kubernetes components and enabling kubelet...
yum install -y -q kubelet kubeadm kubectl
systemctl enable kubelet.service

if [ $MASTER_or_NODE == "master" ]
then
systemctl start kubelet.service

ECHO Pulling kubernetes images...
kubeadm config images pull
if [ $? -eq 0 ]
then
  ECHO Resetting kubeadm if needed...
  [ -d /etc/kubernetes/manifests -a -s /etc/kubernetes/manifests/kube-apiserver.yaml ] && kubeadm reset -f
  ECHO Starting kubeadm...
  kubeadm init --apiserver-advertise-address $MASTER_IP --pod-network-cidr $POD_NETWORK 
  if [ $? -eq 0 ]
  then
      if [ -f /etc/kubernetes/admin.conf ]
      then
	grep 'export KUBECONFIG' /root/.bashrc
	[ $? -ne 0 ] && echo export KUBECONFIG=/etc/kubernetes/admin.conf >>/root/.bashrc
	export KUBECONFIG=/etc/kubernetes/admin.conf
	ECHO "========================================================="
	ECHO Note the kudeadm join command above! Use it to join worker nodes.
	ECHO "=========================================================\n"
	ECHO Now installing weavenet: A CNI based Pod network Addon...
	sleep 5
	kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
	if [ $? -eq 0 ]
	then
		ECHO Success!!. Please follow instructions above to join any number of nodes manually if intended
	else	ECHO Cluster config completed but could not install Addon using kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml ... Please check for alternatives to weave like calico or flannel.
	fi
      else
        ECHO Check for errors above to see if cluster master node is fully created or not!
      fi
  else
      ECHO Failed... Please check errors above.
  fi
else
  ECHO Image pull error. Check config files and apiserver IP...
fi
else
  ECHO Node `hostname`: Setup success!!. Run the join command above as user root to add node to cluster. Use root to kubectl get nodes.
fi
