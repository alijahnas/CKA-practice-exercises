# Installation, Configuration & Validation (12%)

## Design a Kubernetes cluster

<details><summary>Solution</summary>
<p>

We will use a three node cluster, with one master node and two worker nodes.

Three Libvirt/KVM nodes (or any cloud provider you are using):
- k8s-master: 2 vCPUs, 4GB RAM, 40GB Disk, 172.16.1.11/24
- k8s-worker-1: 2 vCPUs, 2GB RAM, 40GB Disk, 172.16.1.21/24
- k8s-worker-2: 2 vCPUs, 2GB RAM, 40GB Disk, 172.16.1.22/24

OS description:

```bash
$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 18.04.4 LTS
Release:	18.04
Codename:	bionic
```

</p>
</details>

## Install Kubernetes masters and nodes

<details><summary>Solution</summary>
<p>

If you don't have cluster nodes yet, check the terraform deployment from below: [Provision underlying infrastructure to deploy a Kubernetes cluster](https://github.com/alijahnas/CKA-practice-exercises/blob/master/installation-configuration-validation.md#provision-underlying-infrastructure-to-deploy-a-kubernetes-cluster)

Installation from [scratch](https://github.com/kelseyhightower/kubernetes-the-hard-way/) is too time consuming. We will be using KubeADM (v1.17) to install the Kubernetes cluster.

### Install container runtime

<details><summary>Solution</summary>
<p>

Doc: https://kubernetes.io/docs/setup/production-environment/container-runtimes/

Do this on all three nodes:

```bash
# Install Docker CE
## Set up the repository:
### Install packages to allow apt to use a repository over HTTPS
sudo apt-get update && sudo apt-get install -y \
  apt-transport-https ca-certificates curl software-properties-common gnupg2

### Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

### Add Docker apt repository.
sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

## Install Docker CE.
sudo apt-get update && sudo apt-get install -y \
  containerd.io=1.2.10-3 \
  docker-ce=5:19.03.4~3-0~ubuntu-$(lsb_release -cs) \
  docker-ce-cli=5:19.03.4~3-0~ubuntu-$(lsb_release -cs)

# Setup daemon.
cat << EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
sudo systemctl daemon-reload
sudo systemctl restart docker
```

</p>
</details>

### Install kubeadm, kubelet and kubectl

<details><summary>Solution</summary>
<p>

Doc: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

Do this on all three nodes:

```bash
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet=1.17.4-00 kubeadm=1.17.4-00 kubectl=1.17.4-00
sudo apt-mark hold kubelet kubeadm kubectl
```

</p>
</details>

### Create a cluster with KubeADM

<details><summary>Solution</summary>
<p>

Doc: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

On master node:
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

Run the output of the init command on worker nodes:
```bash
sudo kubeadm join 172.16.1.11:6443 --token h8vno9.7eroqaei7v1isdpn \
    --discovery-token-ca-cert-hash sha256:44f1def2a041f116bc024f7e57cdc0cdcc8d8f36f0b942bdd27c7f864f645407
```

On master node again:
```bash
# Configure kubectl access
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Deploy Flannel as a network plugin
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml

```

</p>
</details>

### Check that your nodes are running and ready

<details><summary>Solution</summary>
<p>

```bash
kubectl get nodes
NAME           STATUS   ROLES    AGE     VERSION
k8s-master     Ready    master   11m     v1.17.4
k8s-worker-1   Ready    <none>   3m12s   v1.17.4
k8s-worker-2   Ready    <none>   3m10s   v1.17.4
```

</p>
</details>

</p>
</details>

## Configure secure cluster communications

<details><summary>Solution</summary>
<p>

Doc: https://kubernetes.io/docs/tasks/administer-cluster/securing-a-cluster/

KubeADM already manages TLS certificate creation for the cluster. Check how to do it the hard way through `cfssl`: https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md

</p>
</details>

## Configure a Highly-Available Kubernetes cluster

<details><summary>Solution</summary>
<p>

Doc: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/

</p>
</details>

## Know where to get the Kubernetes release binaries

<details><summary>Solution</summary>
<p>

Doc: https://kubernetes.io/docs/setup/release/notes/

```bash
wget https://dl.k8s.io/v1.18.0/kubernetes.tar.gz
tar xzvf kubernetes.tar.gz
cd kubernetes/
cluster/get-kube-binaries.sh
tar xzvf server/kubernetes-server-linux-amd64.tar.gz
ls kubernetes/server/bin/
# You will find: kube-apiserver, kube-controller-manager, kube-scheduler, kube-proxy, kubelet, kubeadm, kubectl, ...
```

</p>
</details>

## Provision underlying infrastructure to deploy a Kubernetes cluster

<details><summary>Solution</summary>
<p>

You can use any cloud provider (AWS, Azure, GCP, OpenStack, etc.) and multiple tools to provision nodes for your Kubernetes cluster.

Here is an example where we use a local libvirt/KVM baremetal node with terraform (v0.12.20) to provision a three node cluster as described in [Design a Kubernetes cluster](https://github.com/alijahnas/CKA-practice-exercises/blob/master/installation-configuration-validation.md#design-a-kubernetes-cluster) above.

```bash
mkdir terraform
cd terraform
wget https://raw.githubusercontent.com/alijahnas/CKA-practice-exercises/master/terraform/cluster-infra.tf
terraform plan
terraform apply
```

</p>
</details>

## Choose a network solution

<details><summary>Solution</summary>
<p>

Docs:
- https://kubernetes.io/docs/concepts/cluster-administration/networking/
- https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network

</p>
</details>

## Install and use kubeadm to install, configure, and manage Kubernetes clusters

<details><summary>Solution</summary>
<p>

Check section "Install Kubernetes masters and nodes" above.

</p>
</details>
