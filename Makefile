.PHONY: all build deploy clean

all: build deploy

build:
	packer build \
		-var certificate_email=$$(gcloud auth list --filter='status:ACTIVE' --format 'value(account)') \
		-var domain_name=labelstudio.$$(echo 'var.dns_zone' | terraform console | xargs gcloud dns managed-zones describe | awk -F': ' '{if ($$1=="dnsName") print substr($$2, 1, length($$2)-1)}') \
		.

deploy:
	terraform apply -auto-approve

clean:
	terraform destroy -auto-approve
	gcloud compute images list --filter 'family=labelstudio' --format 'value(name)' | xargs gcloud compute images delete
