# Deploy Elasticsearch on the cloud easily

This repository contains a set of tools and scripts to deploy an Elasticsearch cluster on the cloud, using best-practices and state of the art tooling.

***Note:*** This branch supports Elasticsearch 7.x only. For other Elasticsearch versions see [elasticsearch-5.x](https://github.com/BigDataBoutique/elasticsearch-cloud-deploy/tree/elasticsearch-5.x) and [elasticsearch-6.x](https://github.com/BigDataBoutique/elasticsearch-cloud-deploy/tree/elasticsearch-6.x) branches.

You need to use the latest version of Terraform and Packer for all features to work correctly.

Features:

* Deployment of data and master nodes as separate nodes
* Client node with Kibana, Cerebro, Grafana and authenticated Elasticsearch access
* DNS and load-balancing access to client nodes
* Sealed from external access, only accessible via password-protected external facing client nodes
* AWS deployment support (under `terraform-aws`)
* Azure deployment (under `terraform-azure`)
* Google Cloud Platform deployment (coming soon)

## Usage

Clone this repo to work locally. You might want to fork it in case you need to apply some additional configurations or commit changes to the variables file.

Create images with Packer (see `packer` folder in this repo), and then go into the terraform folder and run `terraform plan`. See README files in each respective folder. 

## tfstate

Once you run `terraform apply` on any of the terraform folders in this repo, a file `terraform.tfstate` will be created. This file contains the mapping between your cloud elements to the terraform configuration. Make sure to keep this file safe.
  
See [this guide](https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa#.fbb2nalw6) for a discussion on tfstate management and locking between team members.