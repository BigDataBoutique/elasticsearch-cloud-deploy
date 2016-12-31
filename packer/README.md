You need to have a "packer" IAM Role defined.

```bash
aws iam create-role --role-name packer --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole",
    "Sid": ""
  }
}'
```

Response will look something like this:

```json
{
    "Role": {
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": {
                "Action": "sts:AssumeRole",
                "Effect": "Allow",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                }
            }
        },
        "RoleId": "AROAJ7Q2L7NZJHZBB6JKY",
        "CreateDate": "2016-12-16T13:22:47.254Z",
        "RoleName": "packer",
        "Path": "/",
        "Arn": "arn:aws:iam::611111111117:role/packer"
    }
}
```

```bash
aws iam create-instance-profile --instance-profile-name packer
aws iam add-role-to-instance-profile  --instance-profile-name packer --role-name packer

```

Getting the latest Ubuntu image on AWS (depending on region):

```bash
curl http://cloud-images.ubuntu.com/locator/ec2/releasesTable | grep us-east-1 | grep xenial | grep hvm:ebs  | grep amd64| awk -F "[<>]" '{print $3}'
```

Then run it via

```bash
packer build -var-file=variables.json elasticsearch-node.packer.json
export ES5_AMI=$
packer build -var-file=variables.json kibana-node.packer.json
```