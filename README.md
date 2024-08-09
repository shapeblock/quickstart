# quickstart

Terraform scripts to setup Shapeblock in a Kubernetes cluster.

# Prerequisites
- a new Linux server, with at least 2GB RAM and 30GB disk space.
- Terraform >= 1.0
- k3sup(https://github.com/alexellis/k3sup)

# Installation

1. Install k3s in the Linux machine using the following command:

```sh
$ k3sup install --host <your-server-public-ip> \
        --user root \
        --cluster \
        --local-path kubeconfig \
        --context default \
        --ssh-key <ssh-key--with-full-path> \
        --k3s-extra-args "--disable traefik"
```
This will install a single node cluster and download the kuberconfig file.

2. Copy over the `terraform.tfvars.sample` to `terraform.tfvars`. Make sure to customize this file to suit your needs.

3. Initiate terraform.

```sh
$ terraform init
```

4. Do a terraform apply.

```sh
$ terraform apply
```

This will show details on how to connect to shapeblock server after a successful run.

