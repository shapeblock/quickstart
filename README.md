# Quickstart examples for Shapeblock

Quickly stand up an HA-style installation of Rancher by SUSE products on your infrastructure provider of choice.

Intended for experimentation/evaluation ONLY.

**You will be responsible for any and all infrastructure costs incurred by these resources.** As a result, this repository minimizes costs by standing up the minimum required resources for a given provider.

## Cloud quickstart

Cloud quickstarts to install Shapeblock are provided for:

- [**DigitalOcean** (`do`)](./do)
- AWS(Coming soon)
- Hetzner Cloud(Coming soon)
- Linode(Coming soon)

**You will be responsible for any and all infrastructure costs incurred by these resources.**

## Requirements - Cloud

- Terraform >=1.0.0
- Credentials for the cloud provider used for the quickstart

### Using cloud quickstarts

To begin with any quickstart, perform the following steps:

1. Clone or download this repository to a local folder
2. Choose a cloud provider and navigate into the provider's folder
3. Copy or rename `terraform.tfvars.sample` to `terraform.tfvars` and fill in all required variables
4. Run `terraform init`
5. Run `terraform apply`

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

For more details on each cloud provider, refer to the documentation in their respective folders.

## Remove

When you're finished exploring the Rancher server, use terraform to tear down all resources in the quickstart.

**NOTE: Any resources not provisioned by the quickstart are not guaranteed to be destroyed when tearing down the quickstart.**
Make sure you tear down any resources you provisioned manually before running the destroy command.

Run `terraform destroy -auto-approve` to remove all resources without prompting for confirmation.
