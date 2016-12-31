## AWS deployment

### Create the AMIs with Packer

Go to the packer folder and see the README there. Once you have the AMI IDs, return here and continue the steps.

### Create key-pair

```bash
aws ec2 create-key-pair --key-name elasticsearch --query 'KeyMaterial' --output text > elasticsearch.pem
```

### Configurations



### Launch the cluster with Terraform

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

logs
cluster health