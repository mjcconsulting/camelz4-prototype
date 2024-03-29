#!/usr/bin/env bash
#
# This is part of a set of scripts to setup a realistic CaMeLz Prototype which uses multiple Accounts, VPCs and
# Transit Gateway to connect them all
#
# You will need to sign up for the "Cisco Cloud Services Router (CSR) 1000V - BYOL for Maximum Performance" Marketplace AMI
# in the Management Account (or the account where you will run simulated customer on-prem locations).
#
# Using words which correspond to the NATO Phonetic Alphabet for simulated company examples (i.e. Alfa, Bravo, Charlie, ..., Zulu)
#
# Good links:
# - https://james-rankin.com/articles/management-of-start-menu-and-tiles-on-windows-10-and-server-2016-part-1/
# - https://www.tenforums.com/tutorials/105001-set-default-start-layout-users-windows-10-a.html
# - https://support.royalapps.com/support/solutions/articles/17000027838-deploy-and-register-royal-ts-on-multiple-computers
# - https://aws.amazon.com/blogs/compute/optimizing-joining-windows-server-instances-to-a-domain-with-powershell-in-aws-cloudformation/
# - https://aws.amazon.com/blogs/security/how-to-configure-your-ec2-instances-to-automatically-join-a-microsoft-active-directory-domain/
# - https://aws.amazon.com/blogs/security/how-to-connect-your-on-premises-active-directory-to-aws-using-ad-connector/
#

echo "This script has not been tested to run non-interactively. It has no error handling, re-try or restart logic."
echo "You must paste the commands in this script one by one into a terminal, and manually handle errors and re-try."
exit 1

echo "#######################################################################################################################"
echo "## STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP     ##"
echo "#######################################################################################################################"
echo "## All prior scripts in the run order must be run before you run this script                                        ##"
echo "#######################################################################################################################"

#######################################################################################################################
## Active Directory Management Instances - OneGlobal (Shared) Model ###################################################
#######################################################################################################################

## Global Management Active Directory Management Instance #############################################################
profile=$management_profile

# Create Active Directory Management Instance Security Group
global_management_adm_sg_id=$(aws ec2 create-security-group --group-name Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                            --description Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                            --vpc-id $global_management_vpc_id \
                                                            --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Management-ActiveDirectoryManagement-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                            --query 'GroupId' \
                                                            --profile $profile --region us-east-1 --output text)
echo "global_management_adm_sg_id=$global_management_adm_sg_id"

aws ec2 authorize-security-group-ingress --group-id $global_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,UserIdGroupPairs=[{GroupId=$global_management_wb_sg_id,Description=\"Management-WindowsBastion-InstanceSecurityGroup (RDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

# Create Active Directory Management Instance
tmpfile=$tmpdir/global-management-adm-user-data-$$.ps1
sed -e "s/@hostname@/cmlue1madm01a/g" \
    -e "s/@administrator_password_parameter@/Management-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Management-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Management-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Management-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-adm-user-data.ps1 > $tmpfile

global_management_adm_instancea_id=$(aws ec2 run-instances --image-id $global_win2016_ami_id \
                                                           --instance-type t3a.medium \
                                                           --iam-instance-profile Name=ManagedInstance \
                                                           --key-name administrator \
                                                           --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-ActiveDirectoryManagement-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_management_adm_sg_id],SubnetId=$global_management_directory_subneta_id \
                                                           --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Management-ActiveDirectoryManagement-InstanceA},{Key=Hostname,Value=cmlue1madm01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                           --user-data file://$tmpfile \
                                                           --client-token $(date +%s) \
                                                           --query 'Instances[0].InstanceId' \
                                                           --profile $profile --region us-east-1 --output text)
echo "global_management_adm_instancea_id=$global_management_adm_instancea_id"

global_management_adm_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $global_management_adm_instancea_id \
                                                                        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                        --profile $profile --region us-east-1 --output text)
echo "global_management_adm_instancea_private_ip=$global_management_adm_instancea_private_ip"

# Create Active Directory Management-Instance Private Domain Name
tmpfile=$tmpdir/global-management-adma-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1madm01a.$global_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_management_adm_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "adma.$global_management_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue1madm01a.$global_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text
echo "global_management_adm_instancea_hostname=cmlue1madm01a.$global_management_public_domain"
echo "global_management_adm_instancea_hostname_alias=adma.$global_management_public_domain"


## Ohio Management Active Directory Management Instance ###############################################################
profile=$management_profile

# Create Active Directory Management Instance Security Group
ohio_management_adm_sg_id=$(aws ec2 create-security-group --group-name Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                          --description Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                          --vpc-id $ohio_management_vpc_id \
                                                          --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Management-ActiveDirectoryManagement-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                          --query 'GroupId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "ohio_management_adm_sg_id=$ohio_management_adm_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ohio_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,UserIdGroupPairs=[{GroupId=$ohio_management_wb_sg_id,Description=\"Management-WindowsBastion-InstanceSecurityGroup (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create Active Directory Management Instance
tmpfile=$tmpdir/ohio-management-adm-user-data-$$.ps1
sed -e "s/@hostname@/cmlue2madm01a/g" \
    -e "s/@administrator_password_parameter@/Management-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Management-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Management-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Management-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-adm-user-data.ps1 > $tmpfile

ohio_management_adm_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                         --instance-type t3a.medium \
                                                         --iam-instance-profile Name=ManagedInstance \
                                                         --key-name administrator \
                                                         --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-ActiveDirectoryManagement-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_management_adm_sg_id],SubnetId=$ohio_management_directory_subneta_id \
                                                         --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Management-ActiveDirectoryManagement-InstanceA},{Key=Hostname,Value=cmlue2madm01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                         --user-data file://$tmpfile \
                                                         --client-token $(date +%s) \
                                                         --query 'Instances[0].InstanceId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "ohio_management_adm_instancea_id=$ohio_management_adm_instancea_id"

ohio_management_adm_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_management_adm_instancea_id \
                                                                      --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                      --profile $profile --region us-east-2 --output text)
echo "ohio_management_adm_instancea_private_ip=$ohio_management_adm_instancea_private_ip"

# Create ActiveDirectoryManagement-Instance Private Domain Name
tmpfile=$tmpdir/ohio-management-adm-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2madm01a.$ohio_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_management_adm_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "adma.$ohio_management_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue2madm01a.$ohio_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "ohio_management_adm_instancea_hostname=cmlue2madm01a.$ohio_management_public_domain"
echo "ohio_management_adm_instancea_hostname_alias=adma.$ohio_management_public_domain"


## Ireland Management Active Directory Management Instance ############################################################
profile=$management_profile

# Create Active Directory Management Instance Security Group
ireland_management_adm_sg_id=$(aws ec2 create-security-group --group-name Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                             --description Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                             --vpc-id $ireland_management_vpc_id \
                                                             --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Management-ActiveDirectoryManagement-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                             --query 'GroupId' \
                                                             --profile $profile --region eu-west-1 --output text)
echo "ireland_management_adm_sg_id=$ireland_management_adm_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ireland_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,UserIdGroupPairs=[{GroupId=$ireland_management_wb_sg_id,Description=\"Management-WindowsBastion-InstanceSecurityGroup (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create Active Directory Management Instance
tmpfile=$tmpdir/ireland-management-adm-user-data-$$.ps1
sed -e "s/@hostname@/cmlew1madm01a/g" \
    -e "s/@administrator_password_parameter@/Management-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Management-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Management-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Management-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-adm-user-data.ps1 > $tmpfile

ireland_management_adm_instancea_id=$(aws ec2 run-instances --image-id $ireland_win2016_ami_id \
                                                            --instance-type t3a.medium \
                                                            --iam-instance-profile Name=ManagedInstance \
                                                            --key-name administrator \
                                                            --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-ActiveDirectoryManagement-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ireland_management_adm_sg_id],SubnetId=$ireland_management_directory_subneta_id \
                                                            --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Management-ActiveDirectoryManagement-InstanceA},{Key=Hostname,Value=cmlew1madm01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                            --user-data file://$tmpfile \
                                                            --client-token $(date +%s) \
                                                            --query 'Instances[0].InstanceId' \
                                                            --profile $profile --region eu-west-1 --output text)
echo "ireland_management_adm_instancea_id=$ireland_management_adm_instancea_id"

ireland_management_adm_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ireland_management_adm_instancea_id \
                                                                         --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_management_adm_instancea_private_ip=$ireland_management_adm_instancea_private_ip"

# Create ActiveDirectoryManagement-Instance Private Domain Name
tmpfile=$tmpdir/ireland-management-adma-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1madm01a.$ireland_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_management_adm_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "adma.$ireland_management_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlew1madm01a.$ireland_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "ireland_management_adm_instancea_hostname=cmlew1madm01a.$ireland_management_public_domain"
echo "ireland_management_adm_instancea_hostname_alias=adma.$ireland_management_public_domain"
