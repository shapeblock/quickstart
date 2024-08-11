# DigitalOcean Shapeblock quickstart

Terraform scripts to setup Shapeblock in DigitalOcean. A two-node K3s Kubernetes cluster will be created from two droplets running Ubuntu 24.04. Both droplets will be accessible over SSH using the SSH key `private-key`.

# Prerequisites
- a DigitalOcean API token with permissions to CRUD ssh keys and droplets.
- Terraform >= 1.0
- A domain name(optional)

# Installation

1. Copy over the `terraform.tfvars.sample` to `terraform.tfvars`. Make sure to customize this file to suit your needs.

2. Configure DigitalOcean token for terraform.

```sh
$ export DIGITALOCEAN_TOKEN=dop_v1_xxxx
```

3. Initiate terraform.

```sh
$ terraform init
```

4. Do a terraform apply.

```sh
$ terraform apply
```

This will show details on how to connect to shapeblock server after a successful run.

Here's how the output of a successful run looks like:

```sh
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

instructions = <<EOT
Shapeblock has been successfully installed.

Here are the next steps:
1. If you've added a domain, please go to your DNS provider and add the following DNS entries:
    A record - test1.example.com 1.2.3.4
    CNAME - *.test1.example.com test1.example.com
2. You can access the Shapeblock API using the sb-cli command. The latest version can be downloaded here: https://github.com/shapeblock/sb-cli/releases/latest
3. You can login to Shapeblock using sb-cli with the following credentials:
    server: https://sb.example.com
    username: admin
    password: xu4TVCvzloySWhW3
For more details, check the docs: https://docs.shapeblock.com/

EOT
```
