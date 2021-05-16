# k8s-webhook
Sample webhook project using controller runtime


kubebuilder init --domain deven01.webhooks.io --skip-go-version-check

kubebuilder create api --group core --version v1 --kind Pod --resource=false --controller=false

kubebuilder create webhook --group core --version v1 --kind Pod --programmatic-validation --defaulting

https://kubebuilder.io/reference/webhook-for-core-types.html