# Cluster Maintenance (11%)

## Understand Kubernetes Cluster upgrade process

<details><summary>Solution</summary>
<p>

Doc: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

After installing Kubernetes v1.17 here: [install](https://github.com/alijahnas/CKA-practice-exercises/blob/master/installation-configuration-validation.md#install-kubernetes-masters-and-nodes)

We will now upgrade the cluster to v1.18.

On master node:

```bash
# Upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update && sudo apt-get install -y kubeadm=1.18.0-00
sudo apt-mark hold kubeadm

# Upgrade master node
kubectl drain k8s-master --ignore-daemonsets
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.18.0

# Update Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml

# Make master node reschedulable
kubectl uncordon k8s-master

# Upgrade kubelet and kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update && sudo apt-get install -y kubelet=1.18.0-00 kubectl=1.18.0-00
sudo apt-mark hold kubelet kubectl
sudo systemctl restart kubelet
```

On worker nodes:

```bash
# Upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update && sudo apt-get install -y kubeadm=1.18.0-00
sudo apt-mark hold kubeadm

# Upgrade worker node
kubectl drain k8s-worker-1 --ignore-daemonsets # On master node, or on worker node if you have proper config
sudo kubeadm upgrade node

# Upgrade kubelet and kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update && sudo apt-get install -y kubelet=1.18.0-00 kubectl=1.18.0-00
sudo apt-mark hold kubelet kubectl
sudo systemctl restart kubelet

# Make worker node reschedulable
kubectl uncordon k8s-worker-1 # On master node, or on worker node if you have proper config
```

Verify that the nodes are upgraded to v1.18:

```bash
kubectl get nodes
$NAME           STATUS   ROLES    AGE    VERSION
k8s-master     Ready    master   172m   v1.18.0
k8s-worker-1   Ready    <none>   164m   v1.18.0
k8s-worker-2   Ready    <none>   164m   v1.18.0
```

</p>
</details>

## Facilitate operating system upgrades

<details><summary>Solution</summary>
<p>

When having a one master node in you cluster, you cannot upgrade the OS system (with reboot) without loosing temporarily access to your cluster.

Here we will upgrade our worker nodes:

```bash
# Hold kubernetes from upgrading
sudo apt-mark hold kubeadm kubelet kubectl

# Upgrade node
kubectl drain k8s-worker-1 --ignore-daemonsets # On master node, or on worker node if you have proper config
sudo apt update && sudo apt upgrade -y # Be careful about container runtime (e.g., docker) upgrade.

# Reboot node if necessary
sudo reboot

# Make worker node reschedulable
kubectl uncordon k8s-worker-1 # On master node, or on worker node if you have proper config
```

</p>
</details>

## Implement backup and restore methodologies

<details><summary>Solution</summary>
<p>

### Backup etcd cluster

<details><summary>Solution</summary>
<p>

Check the version of your etcd cluster depending on how you installed it.

```bash
kubectl exec -it -n kube-system etcd-k8s-master -- etcd --version
etcd Version: 3.4.3
Git SHA: 3cf2f69b5
Go Version: go1.12.12
Go OS/Arch: linux/amd64
```

```bash
# Download etcd client
wget https://github.com/etcd-io/etcd/releases/download/v3.4.3/etcd-v3.4.3-linux-amd64.tar.gz
tar xzvf etcd-v3.4.3-linux-amd64.tar.gz
sudo mv etcd-v3.4.3-linux-amd64/etcdctl /usr/local/bin

# save etcd snapshot
sudo ETCDCTL_API=3 etcdctl snapshot save --endpoints=172.16.1.11:2379 snapshot.db --cacert /etc/kubernetes/pki/etcd/server.crt --cert /etc/kubernetes/pki/etcd/ca.crt --key /etc/kubernetes/pki/etcd/ca.key

# View the snapshot
ETCDCTL_API=3 sudo etcdctl --write-out=table snapshot status snapshot.db 
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| b72a6b6e |    34871 |       1430 |     3.3 MB |
+----------+----------+------------+------------+

```

</p>
</details>

### Restore an etcd cluster from a snapshot

<details><summary>Solution</summary>
<p>

Doc: https://github.com/etcd-io/etcd/blob/master/Documentation/op-guide/recovery.md#restoring-a-cluster

</p>
</details>

</p>
</details>
