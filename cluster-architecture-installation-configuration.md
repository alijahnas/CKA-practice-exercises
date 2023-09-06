# Cluster Architecture, Installation & Configuration (25%)

## Manage role-based access control (RBAC)

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

## Use KubeADM to install a basic cluster

<details><summary>Solution</summary>
<p>

If you don't have cluster nodes yet, check the terraform deployment from below: [Provision underlying infrastructure to deploy a Kubernetes cluster](https://github.com/alijahnas/CKA-practice-exercises/blob/CKA-v1.27/cluster-architecture-installation-configuration.md#provision-underlying-infrastructure-to-deploy-a-kubernetes-cluster)

Installation from [scratch](https://github.com/kelseyhightower/kubernetes-the-hard-way/) is too time consuming. We will be using KubeADM (v1.27) to install the Kubernetes cluster.

### Install container runtime

<details><summary>Solution</summary>
<p>

Doc: https://kubernetes.io/docs/setup/production-environment/container-runtimes/

Do this on all three nodes (here is the path to the script https://github.com/alijahnas/CKA-practice-exercises/blob/CKA-v1.27/containerd-install.sh):

```bash
# containerd preinstall configuration
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Install containerd
## Set up the repository
### Install packages to allow apt to use a repository over HTTPS
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

## Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

## Add Docker apt repository.
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

## Install packages
sudo apt-get update
sudo apt-get install -y containerd.io

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
```

</p>
</details>

### Install kubeadm, kubelet and kubectl

<details><summary>Solution</summary>
<p>

Doc: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

Do this on all three nodes:

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet=1.27.5-1.1 kubeadm=1.27.5-1.1 kubectl=1.27.5-1.1
sudo apt-mark hold kubelet kubeadm kubectl
```

</p>
</details>

### Create a cluster with KubeADM

<details><summary>Solution</summary>
<p>

Doc: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

Make sure the nodes have different hostnames.

On controlplane node:
```bash
sudo kubeadm init --kubernetes-version=1.27.5 --pod-network-cidr=10.244.0.0/16
```

Run the output of the init command on the other nodes:
```bash
sudo kubeadm join 172.16.1.11:6443 --token h8vno9.7eroqaei7v1isdpn \
    --discovery-token-ca-cert-hash sha256:44f1def2a041f116bc024f7e57cdc0cdcc8d8f36f0b942bdd27c7f864f645407
```

On controlplane node again:
```bash
# Configure kubectl access
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Deploy Flannel as a network plugin
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

</p>
</details>

### Check that your nodes are running and ready

<details><summary>Solution</summary>
<p>

```bash
kubectl get nodes
NAME               STATUS   ROLES           AGE     VERSION
k8s-controlplane   Ready    control-plane   3m29s   v1.27.5
k8s-node-1         Ready    <none>          114s    v1.27.5
k8s-node-2         Ready    <none>          77s     v1.27.5
```

</p>
</details>

</p>
</details>

## Perform a version upgrade on a Kubernetes cluster using KubeADM

<details><summary>Solution</summary>
<p>

Doc: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

After installing Kubernetes v1.27 here: [install](https://github.com/alijahnas/CKA-practice-exercises/blob/CKA-v1.27/cluster-architecture-installation-configuration.md#use-kubeadm-to-install-a-basic-cluster)

We will now upgrade the cluster to v1.28.

On controlplane node:

```bash
# Add 1.28 repository
sudo sh -c 'echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" >> /etc/apt/sources.list.d/kubernetes.list'

# Upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update && sudo apt-get install -y kubeadm=1.28.1-1.1
sudo apt-mark hold kubeadm

# Upgrade controlplane node
kubectl drain k8s-controlplane --ignore-daemonsets
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.28.1

# Update Flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Upgrade kubelet and kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update && sudo apt-get install -y kubelet=1.28.1-1.1 kubectl=1.28.1-1.1
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Make controlplane node reschedulable
kubectl uncordon k8s-controlplane
```

On worker nodes:

```bash
# Add 1.28 repository
sudo sh -c 'echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" >> /etc/apt/sources.list.d/kubernetes.list'

# Upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update && sudo apt-get install -y kubeadm=1.28.1-1.1
sudo apt-mark hold kubeadm

# Upgrade the other node
kubectl drain k8s-node-1 --ignore-daemonsets
sudo kubeadm upgrade node

# Upgrade kubelet and kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update && sudo apt-get install -y kubelet=1.28.1-1.1 kubectl=1.28.1-1.1
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Make worker node reschedulable
kubectl uncordon k8s-node-1
```

Verify that the nodes are upgraded to v1.28.1:

```bash
kubectl get nodes
NAME               STATUS                     ROLES           AGE   VERSION
k8s-controlplane   Ready                      control-plane   15m   v1.28.1
k8s-node-1         Ready,SchedulingDisabled   <none>          13m   v1.28.1
k8s-node-2         Ready,SchedulingDisabled   <none>          13m   v1.28.1
```

</p>
</details>

### Facilitate operating system upgrades

<details><summary>Solution</summary>
<p>

When having a one controlplane node in you cluster, you cannot upgrade the OS system (with reboot) without loosing temporarily access to your cluster.

Here we will upgrade our worker nodes:

```bash
# Hold kubernetes from upgrading
sudo apt-mark hold kubeadm kubelet kubectl

# Upgrade node
kubectl drain k8s-node-1 --ignore-daemonsets
sudo apt update && sudo apt upgrade -y # Be careful about container runtime (e.g., docker) upgrade.

# Reboot node if necessary
sudo reboot

# Make worker node reschedulable
kubectl uncordon k8s-node-1
```

</p>
</details>

## Provision underlying infrastructure to deploy a Kubernetes cluster

<details><summary>Solution</summary>
<p>

You can use any cloud provider (AWS, Azure, GCP, OpenStack, etc.) and multiple tools to provision nodes for your Kubernetes cluster.

We will deploy a three node cluster, with one control plane node and two worker nodes.

Three Libvirt/KVM nodes (or any cloud provider you are using):
- k8s-controlplane: 2 vCPUs, 4GB RAM, 40GB Disk, 172.16.1.11/24
- k8s-node-1: 2 vCPUs, 2GB RAM, 40GB Disk, 172.16.1.21/24
- k8s-node-2: 2 vCPUs, 2GB RAM, 40GB Disk, 172.16.1.22/24

OS description:

```bash
$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.3 LTS
Release:	22.04
Codename:	jammy
```

We will use a local libvirt/KVM baremetal node with terraform (v1.2.5) to provision the three node cluster described above.

```bash
mkdir terraform
cd terraform
wget https://raw.githubusercontent.com/alijahnas/CKA-practice-exercises/CKA-v1.27/terraform/cluster-infra.tf
terraform init
terraform plan
terraform apply
```

</p>
</details>

## Implement etcd backup and restore

<details><summary>Solution</summary>
<p>

### Backup etcd cluster

<details><summary>Solution</summary>
<p>

Doc: https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster

Check the version of your etcd cluster depending on how you installed it.

```bash
kubectl exec -it -n kube-system etcd-k8s-controlplane -- etcd --version
etcd Version: 3.5.3
Git SHA: 0452feec7
Go Version: go1.16.15
Go OS/Arch: linux/amd64
```

```bash
# Download etcd client
wget https://github.com/etcd-io/etcd/releases/download/v3.5.3/etcd-v3.5.3-linux-amd64.tar.gz
tar xzvf etcd-v3.5.3-linux-amd64.tar.gz
sudo mv etcd-v3.5.3-linux-amd64/etcdctl /usr/local/bin
sudo mv etcd-v3.5.3-linux-amd64/etcdutl /usr/local/bin

# save etcd snapshot
sudo etcdctl snapshot save --endpoints 172.16.1.11:2379 snapshot.db --cacert /etc/kubernetes/pki/etcd/server.crt --cert /etc/kubernetes/pki/etcd/ca.crt --key /etc/kubernetes/pki/etcd/ca.key

# View the snapshot
sudo etcdutl --write-out=table snapshot status snapshot.db 
+---------+----------+------------+------------+
|  HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+---------+----------+------------+------------+
| 74116f1 |     2616 |       2639 |     4.5 MB |
+---------+----------+------------+------------+
```

</p>
</details>

### Restore an etcd cluster from a snapshot

<details><summary>Solution</summary>
<p>

Doc: https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster

</p>
</details>

</p>
</details>
