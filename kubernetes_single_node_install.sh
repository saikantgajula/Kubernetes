#Autho:- saikant.gajula@hpe.com
#Purpose:- Install singe node kdf cluster
#How to install a single node.

kubernetes_prereq ()
{
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

yum install wget firewalld -y

systemctl restart firewalld && systemctl enable firewalld

firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --reload

#Disable Swap

swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#create kubernetes repo

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

#Clean yum cache
yum clean all
}

install_kubernetes_rpm ()
{

#Install Kubernetes and Docker packages
yum install kubeadm kubelet docker -y

#Enable and Start Services

systemctl restart docker && systemctl enable docker;systemctl  restart kubelet && systemctl enable kubelet


modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
}

initialize_cluster ()
{
#Initialize cluster
kubeadm init |tee -a ~/kube.init.log.$$
#Create kube config

#Delete if any existing kube config
rm -rf $HOME/.kube

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
}

install_weave_network ()
{
#Install Cluster network

export kubever=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"
}

verify_cluster_install_untaint_master ()
{
#Verify Cluster is functional
kubectl get nodes
# Verify node is up.
kubectl get nodes
kubectl get pods -A
# Untaint master node so that we can schedule pod on it.

kubectl taint nodes --all node-role.kubernetes.io/master-
}

install_dashboard ()
{
#Install dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.3/aio/deploy/recommended.yaml
kubectl create serviceaccount dashboard-admin-sa
kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa
#Save the token for future login in dashboard.
kubectl describe secret `kubectl get secrets |grep dashboard-admin|awk '{print $1}'`
kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]'

#This is kubernetes dashboard URL. Use token which was copied earlier to login .(kubectl describe secret `kubectl get secrets |grep dashboard-admin|awk '{print $1}'`) .

PORT=`kubectl -n kubernetes-dashboard get services|grep kubernetes-dashboard |awk '{print $(NF-1)}'|awk -F: '{print $2}'|tr -d /TCP`
echo "https://`hostname -I | awk '{print $1}'`:$PORT"
}


uninstall_kubernetes ()
{
#How to uninstall:-

kubectl drain `hostname` --delete-local-data --force --ignore-daemonsets
echo "y" |kubeadm reset
sudo rm -rf ~/.kube
}

#Install script starts here

kubernetes_prereq
install_kubernetes_rpm
initialize_cluster
install_weave_network
verify_cluster_install_untaint_master
install_dashboard
#uninstall_kubernetes
