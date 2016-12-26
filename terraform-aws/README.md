## AWS deployment

### Create IAM roles for Packer

```shell
aws iam create-role --role-name=packer --assume-role-policy-document '{
                                                                                 "Version": "2012-10-17",
                                                                                 "Statement": [
                                                                                     {
                                                                                         "Action": "sts:AssumeRole",
                                                                                         "Principal": {
                                                                                             "Service": "ec2.amazonaws.com"
                                                                                         },
                                                                                         "Effect": "Allow",
                                                                                         "Sid": ""
                                                                                     }
                                                                                 ]
                                                                             }'
aws iam create-instance-profile --instance-profile-name=packer
aws iam add-role-to-instance-profile --instance-profile-name=packer --role-name=packer
```

### Create the AMI with Packer

From `./packer`, do `packer build elasticsearch-node.packer.json` and wait.

When Packer is done, take the ami and update variables.tf

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