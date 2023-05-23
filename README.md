# label-studio-deployments
A simple terraform + packer configuration to deploy [Label
Studio](https://labelstud.io/) to a single machine with a custom subdomain.

## User Guide

### Requirements
1. [Google Cloud CLI](https://cloud.google.com/sdk/docs/install-sdk).
2. [Application Default
   Credentials](https://cloud.google.com/sdk/gcloud/reference/auth/application-default).
3. A domain name where you have configured its name servers to a [Cloud DNS
   zone](https://cloud.google.com/dns/docs/tutorials/create-domain-tutorial).
4. [`terraform`](https://developer.hashicorp.com/terraform/downloads) and
   [`packer`](https://developer.hashicorp.com/packer/downloads).
5. `make` (probably comes with your distro).
6. Any public ssh key in `~/.ssh` that matches `id_*.pub` (and its private counterpart).
6. [optional] docker + docker compose if you want to try locally.

### Steps to deploy
First you need to define some configurations. You need to set a username and
password for the default account in Label Studio, and provide your project in
GCP and a Cloud DNS zone to create the final subdomain.

```terraform
# image/packer.auto.pkrvars.hcl
label_studio_username = <your username> # must be an email like person@domain.tld
label_studio_password = <your password>
```

```terraform
# infra/terraform.tfvars
project   = <you gcp project>
dns_zone  = <cloud dns zone from point 3. in requirements>
subdomain = <the name you chose for the subdomain> # optional, defaults to "labelstudio"
```
For convenience, you can see your default project with `gcloud config get-value
project` and your dns zones with `gcloud dns managed-zones list`.

Next, run the following
```console
$ make init
$ make
```

Done! This has created a machine image and deployed it to a compute engine
instance. The url of the instace is
```console
$ echo https://$(terraform -chdir=infra output -raw label_studio_domain)
```
where you can login using the username and password that you configured in
`image/packer.auto.pkrvars.hcl`.

For simple management you can ssh to it via the command
```console
$ ssh $(terraform -chdir=infra output -raw ssh_connect)
```

### Clean Up
Run
```console
$ make clean
```

This will destroy the cloud infrastructure (only what was created, you dns zone
is left intact), and remove the images created, so that they don't incur in
storage charges.


## Warning
This project uses [Let's Encrypt](https://letsencrypt.org) for SSL
certificates. Each time a new machine image is created by Packer a new
certificate is requested, and so you must be wary of the [rate
limits](https://letsencrypt.org/docs/rate-limits/) of let's encrypt. In
practice, this means you shouldn't run `make` more than 50 times a week using
the same Cloud DNS zone and subdomain.

To simplifly turning off and back on the deployed machine (without running
`make` and building a new image each time) i've provided two simple commands
`make terminated` and `make running` which _should_ be equivalent to
terminating and turning back on the compute instance via de GCP Console.
