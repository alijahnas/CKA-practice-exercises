# Networking (11%)

## Understand the networking configuration of the cluster nodes

Doc: https://kubernetes.io/docs/concepts/cluster-administration/networking/

## Understand Pod networking concepts

Doc: https://kubernetes.io/docs/concepts/cluster-administration/networking/

## Understand service networking

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
IP:                       10.96.36.225
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  30811/TCP
Endpoints:                10.244.1.25:80,10.244.1.26:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>

kubectl get pods -l app=nginx -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP            NODE           NOMINATED NODE   READINESS GATES
nginx-674ff86d-9s9z6   1/1     Running   0          10m   10.244.1.25   k8s-worker-1   <none>           <none>
nginx-674ff86d-p52qm   1/1     Running   0          10m   10.244.1.26   k8s-worker-1   <none>           <none>

# We are getting the page through IP address of the master node and the port allocated by the NodePort service
curl http://172.16.1.11:30811
...
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
...

```

</p>
</details>


## Deploy and configure network load balancer

Doc: https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/

Questions:
- Do the same exercice as in the previous section but use a Load Balancer service type rather than a NodePort.

Hint: If you are not running your cluster on a cloud providing a load balancer service, you can use [MetalLB](https://metallb.universe.tf/installation/)

<details><summary>Solution</summary>
<p>

```bash
# We will deploy MetalLB first to provide Load Balancer service type
mkdir metallb
cd metallb
wget https://raw.githubusercontent.com/google/metallb/v0.9.3/manifests/namespace.yaml
wget https://raw.githubusercontent.com/google/metallb/v0.9.3/manifests/metallb.yaml

# We are giving MetalLB an IP range from our cluster infra to allocate from
cat << EOF > metallb-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol:
      addresses:
      - 172.16.1.101-172.16.1.150
EOF

# Apply the manifests
kubectl apply -f namespace.yaml
kubectl apply -f metallb-config.yml
kubectl apply -f metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

# Now we create the deployment with a Load Balancer service type
kubectl create deployment nginx --image=nginx:latest
kubectl scale deployment nginx --replicas=2
kubectl expose deployment nginx --port=80 --target-port=80 --type=LoadBalancer
kubectl describe svc nginx
Name:                     nginx
Namespace:                default
Labels:                   app=nginx
Annotations:              <none>
Selector:                 app=nginx
Type:                     LoadBalancer
IP:                       10.99.146.85
LoadBalancer Ingress:     172.16.1.101
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  32402/TCP
Endpoints:                10.244.1.25:80,10.244.1.26:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason        Age   From                Message
  ----    ------        ----  ----                -------
  Normal  IPAllocated   3s    metallb-controller  Assigned IP "172.16.1.101"
  Normal  nodeAssigned  3s    metallb-speaker     announcing from node "k8s-worker-1"

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


## Know how to use Ingress rules

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/

Questions:
- Keep the previous deployment of nginx and add a new deployment using the image `bitnami/apache` with two replicas.
- Expose its port 8080 through a service and query it.
- Create an ingress service that redirects /nginx to the nginx service and /apache to the apache service.

<details><summary>Solution</summary>
<p>

```bash
kubectl create deployment apache --image=bitnami/apache:latest
kubectl scale deployment apache --replicas=2
kubectl expose deployment apache --port=8080 --target-port=8080 --type=LoadBalancer # Replace by NodePort if you don't have a LoadBalancer provider
kubectl describe svc apache
Name:                     apache
Namespace:                default
Labels:                   app=apache
Annotations:              <none>
Selector:                 app=apache
Type:                     LoadBalancer
IP:                       10.101.123.225
LoadBalancer Ingress:     172.16.1.102
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  31041/TCP
Endpoints:                10.244.1.28:8080,10.244.2.68:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason        Age    From                Message
  ----    ------        ----   ----                -------
  Normal  IPAllocated   5m55s  metallb-controller  Assigned IP "172.16.1.102"
  Normal  nodeAssigned  5m55s  metallb-speaker     announcing from node "k8s-worker-2"

curl http://172.16.1.102:8080
<html><body><h1>It works!</h1></body></html>
```

web-ingress.yml:
```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: nginx-or-apache.com
    http:
      paths:
      - path: /nginx
        backend:
          serviceName: nginx
          servicePort: 80
      - path: /apache
        backend:
          serviceName: apache
          servicePort: 8080

```

```bash
# Install the nginx ingress controller if necessary then create the ingress
kubectl apply -f web-ingress.yml
kubectl describe ingress web-ingress

```

</p>
</details>

## Know how to configure and use the cluster DNS

Doc: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

Questions:
- Create a busybox pod and resolve the nginx and apache services created earlier from within the pod.

<details><summary>Solution</summary>
<p>

```bash
kubectl run busybox --image=busybox --rm -it --restart=Never -- sh
If you don't see a command prompt, try pressing enter.
# nslookup apache
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	apache.default.svc.cluster.local
Address: 10.105.144.161

# nslookup nginx
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	nginx.default.svc.cluster.local
Address: 10.99.146.85

```

</p>
</details>


## Understand CNI

Doc: https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/
