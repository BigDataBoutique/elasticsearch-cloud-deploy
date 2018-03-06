# Elasticsearch and Kibana machine images

This Packer configuration will generate Ubuntu images with Elasticsearch, Kibana and other important tools for deploying and managing Elasticsearch clusters on the cloud.

The output of running Packer here would be two machine images, as below:

* elasticsearch node image, containing latest Elasticsearch installed (latest version 5.x) and configured with best-practices.
* kibana node image, based on the elasticsearch node image, and with Kibana (5.x, latest), nginx with basic proxy and authentication setip, and Kopf.

## On Amazon Web Services (AWS)

Using the AWS builder will create the two images and store them as AMIs.

As a convention the Packer builders will use a dedicated IAM roles, which you will need to have present.

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

Follow up by execting the following

```bash
aws iam create-instance-profile --instance-profile-name packer
aws iam add-role-to-instance-profile  --instance-profile-name packer --role-name packer

```

## On Microsoft Azure

Before running Packer for the first time you will need to do a one-time initial setup.

Use PowerShell, and login to AzureRm. See here for more details: https://docs.microsoft.com/en-us/powershell/azure/authenticate-azureps. Once logged in, take note of the subscription and tenant IDs which will be printed out. Alternatively, you can retrieve them by running `Get-AzureRmSubscription` once logged-in.

```Powershell
$rgName = "packer-elasticsearch-images"
$location = "East US"
New-AzureRmResourceGroup -Name $rgName -Location $location
$Password = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | sort {Get-Random})[0..8] -join ''
"Password: " + $Password
$sp = New-AzureRmADServicePrincipal -DisplayName "Azure Packer IKF" -Password $Password
New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $sp.ApplicationId
$sp.ApplicationId
```

Note the resource group name, location, password, sp.ApplicationId as used in the script and emitted as output and update `variables.json`.

To learn more about using Packer on Azure see https://docs.microsoft.com/en-us/azure/virtual-machines/windows/build-image-with-packer

Similarly, using the Azure CLI is going to look something like below:

```bash
export rgName=packer-elasticsearch-images
az group create -n ${rgName} -l eastus

az ad sp create-for-rbac --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"
# outputs client_id, client_secret and tenant_id
az account show --query "{ subscription_id: id }"
# outputs subscription_id
```

## Google Cloud Platform

gcloud and retrieving the account.json file

## Building

Building the AMIs is done using the following commands:

```bash
packer build -only=amazon-ebs -var-file=variables.json elasticsearch6-node.packer.json
packer build -only=amazon-ebs -var-file=variables.json kibana6-node.packer.json
```

Replace the `-only` parameter to `azure-arm` to build images for Azure instead of AWS.