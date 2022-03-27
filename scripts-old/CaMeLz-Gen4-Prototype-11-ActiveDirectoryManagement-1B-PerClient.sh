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
## Active Directory Management Instances - PerClient Model ############################################################
#######################################################################################################################

## Alfa Global Management Active Directory Management Instance ########################################################
profile=$management_profile

# Create Active Directory Management Instance Security Group
alfa_global_management_adm_sg_id=$(aws ec2 create-security-group --group-name Alfa-Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                                 --description Alfa-Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                                 --vpc-id $global_management_vpc_id \
                                                                 --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Management-ActiveDirectoryManagement-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                 --query 'GroupId' \
                                                                 --profile $profile --region us-east-1 --output text)
echo "alfa_global_management_adm_sg_id=$alfa_global_management_adm_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_global_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_global_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,UserIdGroupPairs=[{GroupId=$global_management_wb_sg_id,Description=\"Management-WindowsBastion-InstanceSecurityGroup (RDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_global_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
# - Note: We do not allow routing from the client's VPNs, and they are not allowed to manage their own DirectoryService

# Create Active Directory Management Instance
tmpfile=$tmpdir/alfa-global-management-adm-user-data-$$.ps1
sed -e "s/@hostname@/alfue1madm01a/g" \
    -e "s/@administrator_password_parameter@/Management-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Alfa-Management-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Alfa-Management-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Alfa-Management-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-adm-user-data.ps1 > $tmpfile

alfa_global_management_adm_instancea_id=$(aws ec2 run-instances --image-id $global_win2016_ami_id \
                                                                --instance-type t3a.medium \
                                                                --iam-instance-profile Name=ManagedInstance \
                                                                --key-name administrator \
                                                                --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-ActiveDirectoryManagement-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_global_management_adm_sg_id],SubnetId=$global_management_directory_subneta_id \
                                                                --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Management-ActiveDirectoryManagement-InstanceA},{Key=Hostname,Value=alfue1madm01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                --user-data file://$tmpfile \
                                                                --client-token $(date +%s) \
                                                                --query 'Instances[0].InstanceId' \
                                                                --profile $profile --region us-east-1 --output text)
echo "alfa_global_management_adm_instancea_id=$alfa_global_management_adm_instancea_id"

alfa_global_management_adm_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_global_management_adm_instancea_id \
                                                                             --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                             --profile $profile --region us-east-1 --output text)
echo "alfa_global_management_adm_instancea_private_ip=$alfa_global_management_adm_instancea_private_ip"

# Create Active Directory Management-Instance Private Domain Name
tmpfile=$tmpdir/alfa-global-management-adma-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue1madm01a.$global_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_global_management_adm_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfadma.$global_management_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alfue1madm01a.$global_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text
echo "alfa_global_management_adm_instancea_hostname=alfue1madm01a.$global_management_public_domain"
echo "alfa_global_management_adm_instancea_hostname_alias=alfadma.$global_management_public_domain"


## Alfa Ohio Management Active Directory Management Instance ##########################################################
profile=$management_profile

# Create Active Directory Management Instance Security Group
alfa_ohio_management_adm_sg_id=$(aws ec2 create-security-group --group-name Alfa-Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                               --description Alfa-Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                               --vpc-id $ohio_management_vpc_id \
                                                               --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Management-ActiveDirectoryManagement-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --query 'GroupId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_management_adm_sg_id=$alfa_ohio_management_adm_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,UserIdGroupPairs=[{GroupId=$ohio_management_wb_sg_id,Description=\"Management-WindowsBastion-InstanceSecurityGroup (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
# - Note: We do not allow routing from the client's VPNs, and they are not allowed to manage their own DirectoryService

# Create Active Directory Management Instance
tmpfile=$tmpdir/alfa-ohio-management-adm-user-data-$$.ps1
sed -e "s/@hostname@/alfue2madm01a/g" \
    -e "s/@administrator_password_parameter@/Management-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Alfa-Management-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Alfa-Management-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Alfa-Management-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-adm-user-data.ps1 > $tmpfile

alfa_ohio_management_adm_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                              --instance-type t3a.medium \
                                                              --iam-instance-profile Name=ManagedInstance \
                                                              --key-name administrator \
                                                              --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-ActiveDirectoryManagement-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_management_adm_sg_id],SubnetId=$ohio_management_directory_subneta_id \
                                                              --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Management-ActiveDirectoryManagement-InstanceA},{Key=Hostname,Value=alfue2madm01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                              --user-data file://$tmpfile \
                                                              --client-token $(date +%s) \
                                                              --query 'Instances[0].InstanceId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_management_adm_instancea_id=$alfa_ohio_management_adm_instancea_id"

alfa_ohio_management_adm_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_management_adm_instancea_id \
                                                                           --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_management_adm_instancea_private_ip=$alfa_ohio_management_adm_instancea_private_ip"

# Create ActiveDirectoryManagement-Instance Private Domain Name
tmpfile=$tmpdir/alfa-ohio-management-adm-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2madm01a.$ohio_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_management_adm_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfadma.$ohio_management_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alfue2madm01a.$ohio_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_ohio_management_adm_instancea_hostname=alfue2madm01a.$alfa_ohio_management_public_domain"
echo "alfa_ohio_management_adm_instancea_hostname_alias=alfadma.$alfa_ohio_management_public_domain"


## Zulu Ohio Management Active Directory Management Instance ##########################################################
profile=$management_profile

# Create Active Directory Management Instance Security Group
zulu_ohio_management_adm_sg_id=$(aws ec2 create-security-group --group-name Zulu-Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                               --description Zulu-Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                               --vpc-id $ohio_management_vpc_id \
                                                               --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Management-ActiveDirectoryManagement-InstanceSecurityGroup},{Key=Company,Value=Zulu},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --query 'GroupId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_management_adm_sg_id=$zulu_ohio_management_adm_sg_id"

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,UserIdGroupPairs=[{GroupId=$ohio_management_wb_sg_id,Description=\"Management-WindowsBastion-InstanceSecurityGroup (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create Active Directory Management Instance
tmpfile=$tmpdir/zulu-ohio-management-adm-user-data-$$.ps1
sed -e "s/@hostname@/zulue2madm01a/g" \
    -e "s/@administrator_password_parameter@/Management-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Zulu-Management-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Zulu-Management-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Zulu-Management-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-adm-user-data.ps1 > $tmpfile

zulu_ohio_management_adm_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                              --instance-type t3a.medium \
                                                              --iam-instance-profile Name=ManagedInstance \
                                                              --key-name administrator \
                                                              --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-ActiveDirectoryManagement-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_ohio_management_adm_sg_id],SubnetId=$ohio_management_directory_subneta_id \
                                                              --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Management-ActiveDirectoryManagement-InstanceA},{Key=Hostname,Value=zulue2madm01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                              --user-data file://$tmpfile \
                                                              --client-token $(date +%s) \
                                                              --query 'Instances[0].InstanceId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_management_adm_instancea_id=$zulu_ohio_management_adm_instancea_id"

zulu_ohio_management_adm_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_ohio_management_adm_instancea_id \
                                                                           --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_management_adm_instancea_private_ip=$zulu_ohio_management_adm_instancea_private_ip"

# Create ActiveDirectoryManagement-Instance Private Domain Name
tmpfile=$tmpdir/zulu-ohio-management-adm-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zulue2madm01a.$ohio_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_ohio_management_adm_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zuladma.$ohio_management_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "zulue2madm01a.$ohio_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "zulu_ohio_management_adm_instancea_hostname=zulue2madm01a.$zulu_ohio_management_public_domain"
echo "zulu_ohio_management_adm_instancea_hostname_alias=zuladma.$zulu_ohio_management_public_domain"


## Alfa Ireland Management Active Directory Management Instance #######################################################
profile=$management_profile

# Create Active Directory Management Instance Security Group
alfa_ireland_management_adm_sg_id=$(aws ec2 create-security-group --group-name Alfa-Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                                  --description Alfa-Management-ActiveDirectoryManagement-InstanceSecurityGroup \
                                                                  --vpc-id $ireland_management_vpc_id \
                                                                  --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Management-ActiveDirectoryManagement-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                  --query 'GroupId' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_management_adm_sg_id=$alfa_ireland_management_adm_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,UserIdGroupPairs=[{GroupId=$ireland_management_wb_sg_id,Description=\"Management-WindowsBastion-InstanceSecurityGroup (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_management_adm_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create Active Directory Management Instance
tmpfile=$tmpdir/alfa-ireland-management-adm-user-data-$$.ps1
sed -e "s/@hostname@/alfew1madm01a/g" \
    -e "s/@administrator_password_parameter@/Management-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Alfa-Management-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Alfa-Management-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Alfa-Management-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-adm-user-data.ps1 > $tmpfile

alfa_ireland_management_adm_instancea_id=$(aws ec2 run-instances --image-id $ireland_win2016_ami_id \
                                                                 --instance-type t3a.medium \
                                                                 --iam-instance-profile Name=ManagedInstance \
                                                                 --key-name administrator \
                                                                 --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-ActiveDirectoryManagement-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ireland_management_adm_sg_id],SubnetId=$ireland_management_directory_subneta_id \
                                                                 --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Management-ActiveDirectoryManagement-InstanceA},{Key=Hostname,Value=alfew1madm01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Management},{Key=Utility,Value=ActiveDirectoryManagement},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                 --user-data file://$tmpfile \
                                                                 --client-token $(date +%s) \
                                                                 --query 'Instances[0].InstanceId' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_management_adm_instancea_id=$alfa_ireland_management_adm_instancea_id"

alfa_ireland_management_adm_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ireland_management_adm_instancea_id \
                                                                              --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                              --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_management_adm_instancea_private_ip=$alfa_ireland_management_adm_instancea_private_ip"

# Create ActiveDirectoryManagement-Instance Private Domain Name
tmpfile=$tmpdir/alfa-ireland-management-adma-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfew1madm01a.$ireland_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ireland_management_adm_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfadma.$ireland_management_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alfew1madm01a.$ireland_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "alfa_ireland_management_adm_instancea_hostname=alfew1madm01a.$ireland_management_public_domain"
echo "alfa_ireland_management_adm_instancea_hostname_alias=alfadma.$ireland_management_public_domain"
