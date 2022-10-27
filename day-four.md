# **Day Four: Kubernetes Ecosystem**

## *Expose a service using Ingress*

**1. Install Ingress-NGINX**
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.4.0/deploy/static/provider/cloud/deploy.yaml
```
**2. Verify installation**
```
kubectl -n ingress-nginx get all
```
*Output*
```
NAME                                            READY   STATUS      RESTARTS    AGE
pod/ingress-nginx-controller-xxxxxxxx-xxxxxx    1/1     Running     0           13m
```
**3. Start tunnel**
Open the other terminal and type the following:
```
minikube tunnel
```
**4. Verify service**
```
kubectl -n ingress-nginx get service
```
*Output*
```
NAME                        TYPE            CLUSTER-IP      EXTERNAL-IP         PORT(S) …
ingress-nginx-controller    LoadBalancer    10.111.217.87   127.0.0.1           80:31….
```
**4. Change the type of the kubenetes-bootcamp service**
```
kubectl edit service kubernetes-bootcamp
(생략)
  sessionAffinity: None
  type: ClusterIP                    << NodePort -> ClusterIP
```
**5. Create an Ingress**
```
kubectl create ingress bootcamp \
--class nginx \
--rule="apps.test/bootcamp=kubernetes-bootcamp:8080"
```
**6. Verify the ingress**
```
kubectl get ingress
```
*Output*
```
NAME        CLASS       HOSTS         ADDRESS         PORTS     AGE
bootcamp    nginx       apps.test     192.168.49.2    80        23s…
```
**7. Send a request through ingress-NGINX**
```
curl -H "Host:apps.test" http://localhost/bootcamp
```
*Output*
```
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-xxx…… | v=1
```

## *Enable monitoring and alerting*

**1. Get helm repository info**
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```
**2. Check default values**
```
helm show values prometheus-community/kube-prometheus-stack 
```
**3. Install kube-prometheus-stack using helm**
```
helm install prometheus prometheus-community/kube-prometheus-stack  \
--namespace monitoring 
--create-namespace 
```
**4. Verify installation**
```
kubectl -n monitoring get all
```
**5. Expose Prometheus UI and Grafana using ingress**
```
# For Prometheus
kubectl -n monitoring create ingress prometheus --class nginx \
--rule="prometheus.test/*=prometheus-kube-prometheus-prometheus:9090"

# For Grafana
kubectl -n monitoring create ingress grafana --class nginx 
--rule="grafana.test/*=prometheus-grafana:3000"
```

> Paths containing the leading character '*' are considered pathType=Prefix

**6. Verify ingress**
```
kubectl -n monitoring get all
```
*Output*
```
NAME            CLASS	HOSTS	        ADDRESS         PORTS   AGE
grafana         nginx	grafana.test	127.0.0.1       80      21s
prometheus      nginx   prometheus.test	127.0.0.1       80      27s
```
**7. Connection Test**
* Prometheus
  ```
  curl -H "Host:prometheus.test" http://localhost
  ```
  *Output*
  ```
  <a href="/graph">Found</a>.
  ```
* Grafana
  ```
  curl -H "Host:grafana.test" http://localhost
  ```
  *Output*
  ```
  <a href="/login">Found</a>.
  ```
**8. Modify Windows host file**
Add the following lines:
```
127.0.0.1 prometheus.test
127.0.0.1 grafana.test
```
**9. Exploring Prometheus and Grafana**  
Use the default grafana user:password of admin:prom-operator

## *Securing a service*

**1. Install cert-manager with kubectl**
```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.0/cert-manager.yaml
```
**2. Verify installation**
```
kubectl -n cert-manager get all
```
**3. Create certificate as a root CA**
* Generate the root key
  ```
  openssl genrsa -out "root-ca.key" 4096
  ```
* Generate CSR
  ```
  openssl req -new -key "root-ca.key" -out "root-ca.csr" \
  -sha256 \
  -subj '/CN=test'
  ```
* Configure Root CA
  ```
  vi root-ca.cnf
  [root_ca]
  basicConstraints = critical,CA:TRUE,pathlen:1
  keyUsage = critical, nonRepudiation, cRLSign, keyCertSign
  subjectKeyIdentifier=hash
  ```
* Self-sign the root certificate
  ```
  openssl x509 -req -days 3650 -in "root-ca.csr" -signkey "root-ca.key" \
  -sha256 -out "root-ca.crt" \
  -extfile "root-ca.cnf" \
  -extensions root_ca
  ```
* Verify Root CA certificate
  ```
  openssl x509 -in root-ca.crt -noout -text
  ```
**4. Create a Secret with Root CA certificate**
```
kubectl create secret tls root-ca \
--cert=root-ca.crt \
--key=root-ca.key
```
**5. Create a ClusterIssuer for self-signed certificates**
```
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
spec:
  ca:
    secretName: root-ca
EOF
```