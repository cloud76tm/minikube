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
kubectl -n cert-manager create secret tls root-ca \
--cert=root-ca.crt \
--key=root-ca.key
```
**5. Create a ClusterIssuer as CA Issuer**
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
**6. Modify the ingress**
```
kubectl edit ingress bootcamp
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:                                              <<< Add
    cert-manager.io/cluster-issuer: root-ca                 <<< Add
    nginx.ingress.kubernetes.io/backend-protocol: HTTP      <<< Add
  creationTimestamp: "2022-10-20T01:30:11Z"
  generation: 2
  name: bootcamp
  namespace: default
  resourceVersion: "85051"
  uid: 2c29ea14-77aa-483a-b5b1-6b141b49fd92
spec:
  ingressClassName: nginx
  rules:
  - host: apps.test
    http:
      paths:
      - backend:
          service:
            name: kubernetes-bootcamp
            port:
              number: 8080
        path: /bootcamp
        pathType: Exact
  tls:                                                      <<< Add
  - hosts:                                                  <<< Add
    - apps.test                                             <<< Add
    secretName: bootcamp-cert                               <<< Add
status:
  loadBalancer:
    ingress:
    - ip: 127.0.0.1
```
**7. Verify certificate creation**
```
kubectl get secret
```
*Output*
```
NAME                  TYPE     DATA   AGE
bootcamp-cert-mqc64   Opaque   1      10m
```
**8. Start minikube tunnel**  
Open the other Ubuntu terminal. Type the following:
```
minikube tunnel
```
**9. Test access**
```
curl -H "Host: apps.test" https://localhost --insecure -vvv
```
*Output*
```
*   Trying 127.0.0.1:443...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  start date: Oct 27 09:04:34 2022 GMT
*  expire date: Oct 27 09:04:34 2023 GMT
*  issuer: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x5602e1d8e8c0)
> GET /bootcamp HTTP/2
> Host:apps.test
> user-agent: curl/7.68.0
> accept: */*
>
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
< HTTP/2 200
< date: Thu, 27 Oct 2022 09:24:14 GMT
< content-type: text/plain
< strict-transport-security: max-age=15724800; includeSubDomains
<
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-75c5d958ff-l7tjg | v=1
* Connection #0 to host localhost left intact
```