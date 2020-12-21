
```
"apiVersion": "v1",
    "items": [
        {
            "apiVersion": "v1",
            "kind": "Node",
            "metadata": {
                "annotations": {
                    "kubeadm.alpha.kubernetes.io/cri-socket": "/var/run/dockershim.sock",
                    "node.alpha.kubernetes.io/ttl": "0",
                    "volumes.kubernetes.io/controller-managed-attach-detach": "true"
                },
                "creationTimestamp": "2020-12-16T03:28:34Z",
                "labels": {
                    "beta.kubernetes.io/arch": "amd64",
                    "beta.kubernetes.io/os": "linux",
                    "kubernetes.io/arch": "amd64",
                    "kubernetes.io/hostname": "docker-desktop",
                    "kubernetes.io/os": "linux",
                    "node-role.kubernetes.io/master": ""
                },
                "managedFields": [
                    {
                        "apiVersion": "v1",
                        "fieldsType": "FieldsV1", 
```


curl -o vpc-admission-webhook-deployment.yaml https://s3.us-west-2.amazonaws.com/amazon-eks/manifests/us-east-1/vpc-admission-webhook/latest/vpc-admission-webhook-deployment.yaml;
curl -o Setup-VPCAdmissionWebhook.ps1 https://s3.us-west-2.amazonaws.com/amazon-eks/manifests/us-east-1/vpc-admission-webhook/latest/Setup-VPCAdmissionWebhook.ps1;
curl -o webhook-create-signed-cert.ps1 https://s3.us-west-2.amazonaws.com/amazon-eks/manifests/us-east-1/vpc-admission-webhook/latest/webhook-create-signed-cert.ps1;
curl -o webhook-patch-ca-bundle.ps1 https://s3.us-west-2.amazonaws.com/amazon-eks/manifests/us-east-1/vpc-admission-webhook/latest/webhook-patch-ca-bundle.ps1;


curl -o webhook-create-signed-cert.sh https://s3.us-west-2.amazonaws.com/amazon-eks/manifests/us-east-1/vpc-admission-webhook/latest/webhook-create-signed-cert.sh
curl -o webhook-patch-ca-bundle.sh https://s3.us-west-2.amazonaws.com/amazon-eks/manifests/us-east-1/vpc-admission-webhook/latest/webhook-patch-ca-bundle.sh
curl -o vpc-admission-webhook-deployment.yaml https://s3.us-west-2.amazonaws.com/amazon-eks/manifests/us-east-1/vpc-admission-webhook/latest/vpc-admission-webhook-deployment.yaml
