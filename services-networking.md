# Services & Networking (20%)

## Understand host networking configuration on the cluster nodes

Doc: https://kubernetes.io/docs/concepts/cluster-administration/networking/

## Understand connectivity between Pods

Doc: https://kubernetes.io/docs/concepts/cluster-administration/networking/

## Understand ClusterIP, NodePort, LoadBalancer service types and endpoints

Doc: https://kubernetes.io/docs/concepts/services-networking/service/

Questions:
- Create a deployment with the latest nginx image and two replicas.
- Expose it's port 80 through a service of type NodePort.
- Show all elements, including the endpoints.
- Get the nginx index page through the NodePort.

<details><summary>Solution</summary>
<p>

```bash
kubectl create deployment nginx --image=nginx:latest
kubectl scale deployment nginx --replicas=2
kubectl expose deployment nginx --port=80 --target-port=80 --type=NodePort
kubectl describe svc nginx
Name:                     nginx
Namespace:                default
Labels:                   app=nginx
Annotations:              <none>
Selector:                 app=nginx
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.104.222.43
IPs:                      10.104.222.43
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  32740/TCP
Endpoints:                10.244.1.27:80,10.244.2.26:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>

kubectl get pods -l app=nginx -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP            NODE         NOMINATED NODE   READINESS GATES
nginx-55649fd747-6xvlq   1/1     Running   0          35s   10.244.2.26   k8s-node-2   <none>           <none>
nginx-55649fd747-vnbjz   1/1     Running   0          35s   10.244.1.27   k8s-node-1   <none>           <none>

# We are getting the page through IP address of the controlplane node and the port allocated by the NodePort service
curl http://172.16.1.11:32740
...
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
...

```

</p>
</details>


### Deploy and configure network load balancer

Doc: https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/

Questions:
- Do the same exercice as in the previous section but use a Load Balancer service type rather than a NodePort.

Hint: If you are not running your cluster on a cloud providing a load balancer service, you can use [MetalLB](https://metallb.universe.tf/installation/)

<details><summary>Solution</summary>
<p>

```bash
# We will deploy MetalLB first to provide Load Balancer service type
## You have to enable strict ARP mode
kubectl edit configmap -n kube-system kube-proxy

## And set
...
mode: "ipvs"
ipvs:
  strictARP: true
...

## Download and install MetalLB
mkdir metallb
cd metallb
wget https://raw.githubusercontent.com/metallb/metallb/v0.13.3/config/manifests/metallb-native.yaml

# We are giving MetalLB an IP range from our cluster infra to allocate from
cat << EOF > metallb-config.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.16.1.101-172.16.1.150

---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: advert
  namespace: metallb-system
EOF

# Apply the manifests
kubectl apply -f metallb-native.yaml
kubectl apply -f metallb-config.yaml

# Now we create the deployment with a Load Balancer service type
kubectl create deployment nginx-lb --image=nginx:latest
kubectl scale deployment nginx-lb --replicas=2
kubectl expose deployment nginx-lb --port=80 --target-port=80 --type=LoadBalancer
kubectl describe svc nginx-lb
Name:                     nginx-lb
Namespace:                default
Labels:                   app=nginx-lb
Annotations:              <none>
Selector:                 app=nginx-lb
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.104.174.166
IPs:                      10.104.174.166
LoadBalancer Ingress:     172.16.1.101
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31264/TCP
Endpoints:                10.244.1.17:80,10.244.2.17:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason        Age   From                Message
  ----    ------        ----  ----                -------
  Normal  IPAllocated   27s   metallb-controller  Assigned IP ["172.16.1.101"]
  Normal  nodeAssigned  27s   metallb-speaker     announcing from node "k8s-node-1" with protocol "layer2"

# We are getting the page through the IP address allocated by MetalLB from the pool we provided
curl http://172.16.1.101:80
...
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
...
 
```

</p>
</details>

## Know how to use Ingress controllers and Ingress resources

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/

Questions:
- Keep the previous deployment of nginx and add a new deployment using the image `bitnami/apache` with two replicas.
- Expose its port 8080 through a service and query it.
- Deploy nginx ingress controller
- Create an ingress service that redirects /nginx to the nginx service and /apache to the apache service.

<details><summary>Solution</summary>
<p>

```bash
kubectl create deployment apache-lb --image=bitnami/apache:latest
kubectl scale deployment apache-lb --replicas=2
kubectl expose deployment apache-lb --port=8080 --target-port=8080 --type=LoadBalancer # Replace by NodePort if you don't have a LoadBalancer provider
kubectl describe svc apache-lb
Name:                     apache-lb
Namespace:                default
Labels:                   app=apache-lb
Annotations:              <none>
Selector:                 app=apache-lb
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.101.245.9
IPs:                      10.101.245.9
LoadBalancer Ingress:     172.16.1.101
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  30174/TCP
Endpoints:                10.244.1.32:8080,10.244.2.35:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason        Age              From                Message
  ----    ------        ----             ----                -------
  Normal  IPAllocated   4s               metallb-controller  Assigned IP "172.16.1.101"
  Normal  nodeAssigned  3s (x2 over 3s)  metallb-speaker     announcing from node "k8s-node-1"

curl http://172.16.1.101:8080
<html><body><h1>It works!</h1></body></html>
```

web-ingress.yaml:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: nginx-or-apache.com
    http:
      paths:
      - pathType: Prefix
        path: /nginx
        backend:
          service:
            name: nginx-lb
            port:
              number: 80
      - pathType: Prefix
        path: /apache
        backend:
          service:
            name: apache-lb
            port:
              number: 8080
```

Deploy nginx ingress controller:
```bash
# If using metallb or cloud deployment
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.1/deploy/static/provider/cloud/deploy.yaml
# If using NodePort
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.1/deploy/static/provider/baremetal/deploy.yaml

kubectl -n ingress-nginx get svc
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.102.124.243   172.16.1.102   80:30249/TCP,443:31876/TCP   13s
ingress-nginx-controller-admission   ClusterIP      10.98.20.7       <none>         443/TCP                      13s
```

Deploy web-ingress.yaml:
```bash
Name:             web-ingress
Labels:           <none>
Namespace:        default
Address:          172.16.1.102
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host                 Path  Backends
  ----                 ----  --------
  nginx-or-apache.com  
                       /nginx    nginx-lb:80 (10.244.1.17:80,10.244.2.17:80)
                       /apache   apache-lb:8080 (10.244.1.20:8080,10.244.2.19:8080)
Annotations:           <none>
Events:
  Type    Reason  Age                From                      Message
  ----    ------  ----               ----                      -------
  Normal  Sync    23s (x2 over 61s)  nginx-ingress-controller  Scheduled for sync
```

</p>
</details>

## Know how to configure and use CoreDNS

Doc: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
Doc: https://kubernetes.io/docs/tasks/administer-cluster/coredns/

Questions:
- Create a busybox pod and resolve the nginx and apache services created earlier from within the pod.

<details><summary>Solution</summary>
<p>

```bash
kubectl run busybox --image=busybox --rm -it --restart=Never -- sh
If you don't see a command prompt, try pressing enter.
# nslookup apache-lb
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	apache-lb.default.svc.cluster.local
Address: 10.101.245.9

# nslookup nginx-lb
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	nginx-lb.default.svc.cluster.local
Address: 10.108.72.239

```

</p>
</details>

## Choose an appropriate container network interface plugin

<details><summary>Solution</summary>
<p>

Docs:
- https://kubernetes.io/docs/concepts/cluster-administration/networking/
- https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network

We installed flannel in [Provision underlying infrastructure to deploy a Kubernetes cluster](https://github.com/alijahnas/CKA-practice-exercises/blob/CKA-v1.23/cluster-architecture-installation-configuration.md#create-a-cluster-with-kubeadm)

</p>
</details>
