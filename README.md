# k8s-webhook
Sample webhook project using controller runtime


kubebuilder init --domain deven01.webhooks.io --skip-go-version-check

kubebuilder create api --group core --version v1 --kind Pod --resource=false --controller=false

kubebuilder create webhook --group core --version v1 --kind Pod --programmatic-validation --defaulting

https://kubebuilder.io/reference/webhook-for-core-types.html


go run main.go -metrics-bind-address :8084 -health-probe-bind-address :8087 -kubeconfig /home/devendra/work/src/bitbucket.org/scalock/kube-enforcer/deployment/aqua-kube-deployment1/cluster1.yaml