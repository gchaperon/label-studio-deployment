.PHONY: all init build deploy terminated running clean

all: build deploy

init:
	packer init image
	terraform -chdir=infra init

build:
	packer build \
		-var certificate_email=$$(gcloud auth list --filter='status:ACTIVE' --format 'value(account)') \
		-var domain_name=$$(echo 'var.subdomain' | terraform -chdir=infra console | tr -d '"').$$(echo 'var.dns_zone' | terraform -chdir=infra console | xargs gcloud dns managed-zones describe | awk -F': ' '{if ($$1=="dnsName") print substr($$2, 1, length($$2)-1)}') \
		-var project=$$(echo 'var.project' | terraform -chdir=infra console | tr -d '"') \
		image

deploy:
	terraform -chdir=infra apply -auto-approve

terminated:
	terraform -chdir=infra apply -auto-approve -var 'instance_status=TERMINATED'

running:
	terraform -chdir=infra apply -auto-approve -var 'instance_status=RUNNING'

clean:
	terraform -chdir=infra destroy -auto-approve
	gcloud compute images list --filter 'family=labelstudio' --format 'value(name)' | xargs -r gcloud compute images delete
