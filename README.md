# Deploy Elasticsearch on the cloud easily

## AWS

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

From `./packer`, do `packer build elasticsearch-node.packer.json` and wait..

When Packer is done, take the ami

### Create IAM roles for the Elasticsearch nodes

```shell
aws iam create-role --role-name=elasticsearch --assume-role-policy-document '{
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
aws iam create-instance-profile --instance-profile-name=elasticsearch
aws iam add-role-to-instance-profile --instance-profile-name=elasticsearch --role-name=elasticsearch
```

### Configurations

### Launch the cluster with Terraform