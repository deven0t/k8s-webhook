#!/bin/bash

mkdir k8s-webhook
cd k8s-webhook

openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -days 100000 -out ca.crt -subj "/CN=admission_ca"

cat >tls.conf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ alt_names ]
DNS.1 = k8s-webhook.k8s-webhook.svc
DNS.2 = k8s-webhook.k8s-webhook.svc.cluster.local
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names
EOF

openssl genrsa -out tls.key 2048
openssl req -new -key tls.key -out tls.csr -subj "/CN=k8s-webhook.k8s-webhook-system.svc" -config tls.conf
openssl x509 -req -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tls.crt -days 100000 -extensions v3_req -extfile tls.conf

kubectl create ns k8s-webhook

# Create secret containing TLS certs.
kubectl create secret generic \
k8s-webhook-server-cert \
--from-file tls.key \
--from-file tls.crt \
-n k8s-webhook

# Create validating webhook configuration.
cat <<EOF > validatingwebhookconfig.yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: validating-deven01-k8s-webhook
  namespace: k8s-webhook
webhooks:
  - name: deven01.webhooks.io
    failurePolicy: Ignore
    admissionReviewVersions: ["v1", "v1beta1"]
    timeoutSeconds: 5
    sideEffects: None
    rules:
      - operations: ["CREATE", "UPDATE"]
        apiGroups: ["*"]
        apiVersions: ["*"]
        resources: ["pods"]
    clientConfig:
      caBundle: $(cat ca.crt | base64 | tr -d '\n')
      service:
        namespace: k8s-webhook
        name: k8s-webhook
        path: "/validate"
EOF
kubectl apply -f validatingwebhookconfig.yaml

cat <<EOF > mutatingwebhookconfig.yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: mutating-deven01-k8s-webhook
  namespace: k8s-webhook
webhooks:
  - name: deven01.webhooks.io
    failurePolicy: Ignore
    admissionReviewVersions: ["v1", "v1beta1"]
    timeoutSeconds: 5
    sideEffects: None
    clientConfig:
      service:
        name: k8s-webhook
        namespace: k8s-webhook
        path: "/mutate"
      caBundle: $(cat ca.crt | base64 | tr -d '\n')
    rules:
      - operations: ["CREATE", "UPDATE"]
        apiGroups: ["*"]
        apiVersions: ["v1"]
        resources: ["pods"]
EOF
kubectl apply -f mutatingwebhookconfig.yaml

cat <<EOF > k8s-webhook.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: k8s-webhook
  namespace: k8s-webhook
spec:
  ports:
    - port: 443
      targetPort: 9443
  selector:
    control-plane: k8s-webhook
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-webhook
  namespace: k8s-webhook
  labels:
    control-plane: k8s-webhook
spec:
  selector:
    matchLabels:
      control-plane: k8s-webhook
  template:
    metadata:
      labels:
        control-plane: k8s-webhook
    spec:
      containers:
      - name: manager
        image: turkardg/k8s-webhook:0.1.0-rc1
        ports:
        - containerPort: 9443
          name: k8s-webhook
          protocol: TCP
        volumeMounts:
        - mountPath: /tmp/k8s-webhook-server/serving-certs
          name: cert
          readOnly: true
      volumes:
      - name: cert
        secret:
          defaultMode: 420
          secretName: k8s-webhook-server-cert

EOF
kubectl create -f k8s-webhook.yaml

echo -e "\e[32mDeven0t k8s-webhook is successfully deployed!\e[0m"
