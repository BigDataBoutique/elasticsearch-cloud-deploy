# AWS deployment

## Create the AMIs with Packer

Go to the packer folder and see the README there. Once you have the AMI IDs, return here and continue with the next steps.

## Create key-pair

```bash
aws ec2 create-key-pair --key-name elasticsearch --query 'KeyMaterial' --output text > elasticsearch.pem
```

## Region and availability zones

Specify the region to operate on, and at least 2 availability zones in that region.

You can find the availability zones available to you by running:

```
aws ec2 describe-availability-zones
```

(first make sure awscli is installed and configured correctly to your account and default region)

## VPC

Create a VPC, or use existing. You will need the VPC ID and private subnets IDs. 

## Configurations

Edit `variables.tf` to specify the following:

* `aws_region` - the region where to launch the cluster in
* `availability_zones` - at least 2 availability zones in that region
* `key_name` - the name of the key to use - that key needs to be handy so you can access the machines if needed
* `vpc_id` - the ID of the VPC to launch the cluster in
* `vpc_subnets` - the private subnet IDs within the VPC

The rest of the configurations are mostly around machine types and sizes. Unless you are interested in the single-node mode, make sure you set number of master nodes to 3, data nodes to at least 2, and client nodes to at least 1.

## Security groups

By default this will create two securiy groups - one for the cluster, and one for the client nodes. Your applications need to be in the latter.

If you prefer using a security group of your own, you can add it to `additional_security_groups` in variables.tf.

## Launch the cluster with Terraform

```bash
terraform plan
terraform apply
```

### Look around

You can pull the list of instances by their state and role using aws-cli:

```bash
aws ec2 describe-instances --filters Name=instance-state-name,Values=running
aws ec2 describe-instances --filters Name=instance-state-name,Values=running,Name=tag:Role,Values=client
```

To login to one of the instances:

```bash
ssh -i elasticsearch.pem ubuntu@{public IP / DNS of the instance}
```