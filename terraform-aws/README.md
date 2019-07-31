# AWS deployment

## Create the AMIs with Packer

Go to the packer folder and see the README there. Once you have the AMI IDs, return here and continue with the next steps.

## Create key-pair

```bash
aws ec2 create-key-pair --key-name elasticsearch --query 'KeyMaterial' --output text > elasticsearch.pem
```

## VPC

Create a VPC, or use existing. You will need the VPC ID we will use the available subnets within it. 

## Configurations

Edit `variables.tf` to specify the following:

* `aws_region` - the region where to launch the cluster in.
* `availability_zones` - at least 2 availability zones in that region.
* `es_cluster` - the name of the Elasticsearch cluster to launch.
* `key_name` - the name of the key to use - that key needs to be handy so you can access the machines if needed.
* `vpc_id` - the ID of the VPC to launch the cluster in.

The rest of the configurations are mostly around cluster topology and  machine types and sizes.

### Cluster topology

Two modes of deployment are supported:

* A recommended configuration, with dedicated master-eligible nodes, data nodes, and client nodes. This is a production-ready and best-practice configuration. See more details in the [official documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html). 
* Single node mode - mostly useful for experimentation

At this point we consider the role `ingest` as unanimous with `data`, so all data nodes are also ingest nodes.

The default mode is the single-node mode. To change it to the recommended configuration, edit `variables.tf` and set number of master nodes to 3, data nodes to at least 2, and client nodes to at least 1.

All nodes with the `client` role will be attached to an ELB, so access to all client nodes can be done via the DNS it exposes.

### Cluster bootstrap
Deploying a cluster in non single-node mode requires [bootstrapping the cluster](https://www.elastic.co/guide/en/elasticsearch/reference/master/modules-discovery-bootstrap-cluster.html).  
We do this automatically, by spinning up a special bootstrap node, and terminating it once finished. This only happens once, first time you deploy the cluster. State information on whether cluster is bootstrapped or not is kept in a local file `cluster_bootstrap_state` which is used on later `terraform apply` runs.    
After the bootstrap node has terminated, you can start using the cluster.

### Security groups

By default we create two security groups - one for the internal cluster nodes (data and master), and one for the client nodes. Your applications need to be in the latter only, and communicate with the cluster via the client nodes only.

If you prefer using a security group of your own, you can add it to `additional_security_groups` in variables.tf.

## Launch the cluster with Terraform

On first usage, you will need to execute `terraform init` to initialize the terraform providers used.

To deploy the cluster, or apply any changes to an existing cluster deployed using this project, run:

```bash
terraform plan
terraform apply
```

When terraform is done, you should see a lot of output ending with something like this:

```
Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

clients_dns = internal-es-test-client-lb-963348710.eu-central-1.elb.amazonaws.com
```

Note `clients_dns` - that's your entry point to the cluster.

### Look around

The client nodes are the ones exposed to external networks. They provide Kibana, Kopf and direct Elasticsearch access. Client nodes are accessible via their public IPs (depending on your security group / VPC settings) and the DNS of the ELB they are attached to (see above).

Client nodes listen on port 8080 and are password protected. Access is managed by nginx which is expecting a username and password pair. Default ones are exampleuser/changeme. You can change those defaults by editing [this file](https://github.com/synhershko/elasticsearch-cloud-deploy/blob/master/packer/install-nginx.sh) and running Packer again.

On client nodes you will find:

* Kibana access is direct on port 8080 (http://host:8080)
* [Cerebro](https://github.com/lmenezes/cerebro) (a cluster management UI) is available on http://host:8080/cerebro/
* For direct Elasticsearch access, go to host:8080/es/

You can pull the list of instances by their state and role using aws-cli:

```bash
aws ec2 describe-instances --filters Name=instance-state-name,Values=running
aws ec2 describe-instances --filters Name=instance-state-name,Values=running,Name=tag:Role,Values=client
```

To login to one of the instances:

```bash
ssh -i elasticsearch.pem ubuntu@{public IP / DNS of the instance}
```

### Changing cluster size after deployment

Terraform is smart enough to make the least amount of changes possible and resize resources when possible instead of destroying them.
 
When you want to change the cluster configuration (e.g. add more client nodes, data nodes, resize disk or instances, etc) just edit variables.tf and run `terraform plan` followed by `terraform apply`.