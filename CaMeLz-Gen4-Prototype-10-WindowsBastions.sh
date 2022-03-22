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
## Windows Bastions ###################################################################################################
#######################################################################################################################

## Global Management Windows Bastion ##################################################################################
profile=$management_profile

# Create WindowsBastion Security Group
global_management_wb_sg_id=$(aws ec2 create-security-group --group-name Management-WindowsBastion-InstanceSecurityGroup \
                                                           --description Management-WindowsBastion-InstanceSecurityGroup \
                                                           --vpc-id $global_management_vpc_id \
                                                           --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Management-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                           --query 'GroupId' \
                                                           --profile $profile --region us-east-1 --output text)
echo "global_management_wb_sg_id=$global_management_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $global_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

# Create WindowsBastion EIP
global_management_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                                     --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Management-WindowsBastion-EIPA},{Key=Hostname,Value=cmlue1mwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                     --query 'AllocationId' \
                                                     --profile $profile --region us-east-1 --output text)
echo "global_management_wb_eipa=$global_management_wb_eipa"

global_management_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $global_management_wb_eipa \
                                                                      --query 'Addresses[0].PublicIp' \
                                                                      --profile $profile --region us-east-1 --output text)
echo "global_management_wb_instancea_public_ip=$global_management_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/global-management-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1mwb01a.$global_management_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_management_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$global_management_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue1mwb01a.$global_management_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_management_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text
echo "global_management_wb_instancea_hostname=cmlue1mwb01a.$global_management_public_domain"
echo "global_management_wb_instancea_hostname_alias=wba.$global_management_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/global-management-wba-user-data-$$.ps1
sed -e "s/@hostname@/cmlue1mwb01a/g" \
    -e "s/@administrator_password_parameter@/Management-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Management-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Management-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Management-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

global_management_wb_instancea_id=$(aws ec2 run-instances --image-id $global_win2016_ami_id \
                                                          --instance-type t3a.medium \
                                                          --iam-instance-profile Name=ManagedInstance \
                                                          --key-name administrator \
                                                          --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_management_wb_sg_id],SubnetId=$global_management_public_subneta_id \
                                                          --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Management-WindowsBastion-InstanceA},{Key=Hostname,Value=cmlue1mwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                          --user-data file://$tmpfile \
                                                          --client-token $(date +%s) \
                                                          --query 'Instances[0].InstanceId' \
                                                          --profile $profile --region us-east-1 --output text)
echo "global_management_wb_instancea_id=$global_management_wb_instancea_id"

global_management_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $global_management_wb_instancea_id \
                                                                       --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                       --profile $profile --region us-east-1 --output text)
echo "global_management_wb_instancea_private_ip=$global_management_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/global-management-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1mwb01a.$global_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_management_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$global_management_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue1mwb01a.$global_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text

aws ec2 associate-address --instance-id $global_management_wb_instancea_id --allocation-id $global_management_wb_eipa \
                          --profile $profile --region us-east-1 --output text


## Global Core Windows Bastion ########################################################################################
profile=$core_profile

# Create WindowsBastion Security Group
global_core_wb_sg_id=$(aws ec2 create-security-group --group-name Core-WindowsBastion-InstanceSecurityGroup \
                                                     --description Core-WindowsBastion-InstanceSecurityGroup \
                                                     --vpc-id $global_core_vpc_id \
                                                     --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Core-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                     --query 'GroupId' \
                                                     --profile $profile --region us-east-1 --output text)
echo "global_core_wb_sg_id=$global_core_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $global_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

# Create WindowsBastion EIP
global_core_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                               --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Core-WindowsBastion-EIPA},{Key=Hostname,Value=cmlue1cwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                               --query 'AllocationId' \
                                               --profile $profile --region us-east-1 --output text)
echo "global_core_wb_eipa=$global_core_wb_eipa"

global_core_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $global_core_wb_eipa \
                                                                --query 'Addresses[0].PublicIp' \
                                                                --profile $profile --region us-east-1 --output text)
echo "global_core_wb_instancea_public_ip=$global_core_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/global-core-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1cwb01a.$global_core_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_core_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$global_core_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue1cwb01a.$global_core_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_core_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text
echo "global_core_wb_instancea_hostname=cmlue1cwb01a.$global_core_public_domain"
echo "global_core_wb_instancea_hostname_alias=wba.$global_core_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/global-core-wba-user-data-$$.ps1
sed -e "s/@hostname@/cmlue1cwb01a/g" \
    -e "s/@administrator_password_parameter@/Core-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Core-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Core-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Core-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

global_core_wb_instancea_id=$(aws ec2 run-instances --image-id $global_win2016_ami_id \
                                                    --instance-type t3a.medium \
                                                    --iam-instance-profile Name=ManagedInstance \
                                                    --key-name administrator \
                                                    --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Core-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_core_wb_sg_id],SubnetId=$global_core_public_subneta_id \
                                                    --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Core-WindowsBastion-InstanceA},{Key=Hostname,Value=cmlue1cwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                    --user-data file://$tmpfile \
                                                    --client-token $(date +%s) \
                                                    --query 'Instances[0].InstanceId' \
                                                    --profile $profile --region us-east-1 --output text)
echo "global_core_wb_instancea_id=$global_core_wb_instancea_id"

global_core_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $global_core_wb_instancea_id \
                                                                 --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                 --profile $profile --region us-east-1 --output text)
echo "global_core_wb_instancea_private_ip=$global_core_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/global-core-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1cwb01a.$global_core_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_core_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$global_core_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue1cwb01a.$global_core_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_core_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text

aws ec2 associate-address --instance-id $global_core_wb_instancea_id --allocation-id $global_core_wb_eipa \
                          --profile $profile --region us-east-1 --output text


## Global Log Windows Bastion #########################################################################################
profile=$log_profile

# Create WindowsBastion Security Group
global_log_wb_sg_id=$(aws ec2 create-security-group --group-name Log-WindowsBastion-InstanceSecurityGroup \
                                                    --description Log-WindowsBastion-InstanceSecurityGroup \
                                                    --vpc-id $global_log_vpc_id \
                                                    --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Log-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                    --query 'GroupId' \
                                                    --profile $profile --region us-east-1 --output text)
echo "global_log_wb_sg_id=$global_log_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $global_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

# Create WindowsBastion EIP
global_log_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                              --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Log-WindowsBastion-EIPA},{Key=Hostname,Value=cmlue1lwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                              --query 'AllocationId' \
                                              --profile $profile --region us-east-1 --output text)
echo "global_log_wb_eipa=$global_log_wb_eipa"

global_log_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $global_log_wb_eipa \
                                                               --query 'Addresses[0].PublicIp' \
                                                               --profile $profile --region us-east-1 --output text)
echo "global_log_wb_instancea_public_ip=$global_log_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/global-log-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1lwb01a.$global_log_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_log_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$global_log_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue1lwb01a.$global_log_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_log_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text
echo "global_log_wb_instancea_hostname=cmlue1lwb01a.$global_log_public_domain"
echo "global_log_wb_instancea_hostname_alias=wba.$global_log_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/global-log-wba-user-data-$$.ps1
sed -e "s/@hostname@/cmlue1lwb01a/g" \
    -e "s/@administrator_password_parameter@/Log-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Log-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Log-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Log-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

global_log_wb_instancea_id=$(aws ec2 run-instances --image-id $global_win2016_ami_id \
                                                   --instance-type t3a.medium \
                                                   --iam-instance-profile Name=ManagedInstance \
                                                   --key-name administrator \
                                                   --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Log-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_log_wb_sg_id],SubnetId=$global_log_public_subneta_id \
                                                   --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Log-WindowsBastion-InstanceA},{Key=Hostname,Value=cmlue1lwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                   --user-data file://$tmpfile \
                                                   --client-token $(date +%s) \
                                                   --query 'Instances[0].InstanceId' \
                                                   --profile $profile --region us-east-1 --output text)
echo "global_log_wb_instancea_id=$global_log_wb_instancea_id"

global_log_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $global_log_wb_instancea_id \
                                                                --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                --profile $profile --region us-east-1 --output text)
echo "global_log_wb_instancea_private_ip=$global_log_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/global-log-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1lwb01a.$global_log_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_log_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$global_log_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue1lwb01a.$global_log_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_log_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text

aws ec2 associate-address --instance-id $global_log_wb_instancea_id --allocation-id $global_log_wb_eipa \
                          --profile $profile --region us-east-1 --output text


## Ohio Management Windows Bastion ####################################################################################
profile=$management_profile

# Create WindowsBastion Security Group
ohio_management_wb_sg_id=$(aws ec2 create-security-group --group-name Management-WindowsBastion-InstanceSecurityGroup \
                                                         --description Management-WindowsBastion-InstanceSecurityGroup \
                                                         --vpc-id $ohio_management_vpc_id \
                                                         --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Management-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                         --query 'GroupId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "ohio_management_wb_sg_id=$ohio_management_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ohio_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create WindowsBastion EIP
ohio_management_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                                   --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Management-WindowsBastion-EIPA},{Key=Hostname,Value=cmlue2mwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                   --query 'AllocationId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "ohio_management_wb_eipa=$ohio_management_wb_eipa"

ohio_management_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $ohio_management_wb_eipa \
                                                                    --query 'Addresses[0].PublicIp' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_management_wb_instancea_public_ip=$ohio_management_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/ohio-management-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2mwb01a.$ohio_management_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_management_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$ohio_management_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue2mwb01a.$ohio_management_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_management_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "ohio_management_wb_instancea_hostname=cmlue2mwb01a.$ohio_management_public_domain"
echo "ohio_management_wb_instancea_hostname_alias=wba.$ohio_management_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/ohio-management-wba-user-data-$$.ps1
sed -e "s/@hostname@/cmlue2mwb01a/g" \
    -e "s/@administrator_password_parameter@/Management-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Management-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Management-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Management-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

ohio_management_wb_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                        --instance-type t3a.medium \
                                                        --iam-instance-profile Name=ManagedInstance \
                                                        --key-name administrator \
                                                        --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_management_wb_sg_id],SubnetId=$ohio_management_public_subneta_id \
                                                        --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Management-WindowsBastion-InstanceA},{Key=Hostname,Value=cmlue2mwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --user-data file://$tmpfile \
                                                        --client-token $(date +%s) \
                                                        --query 'Instances[0].InstanceId' \
                                                        --profile $profile --region us-east-2 --output text)
echo "ohio_management_wb_instancea_id=$ohio_management_wb_instancea_id"

ohio_management_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_management_wb_instancea_id \
                                                                     --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_management_wb_instancea_private_ip=$ohio_management_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/ohio-management-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2mwb01a.$ohio_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_management_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$ohio_management_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue2mwb01a.$ohio_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $ohio_management_wb_instancea_id --allocation-id $ohio_management_wb_eipa \
                          --profile $profile --region us-east-2 --output text


## Ohio Core Windows Bastion ##########################################################################################
profile=$core_profile

# Create WindowsBastion Security Group
ohio_core_wb_sg_id=$(aws ec2 create-security-group --group-name Core-WindowsBastion-InstanceSecurityGroup \
                                                   --description Core-WindowsBastion-InstanceSecurityGroup \
                                                   --vpc-id $ohio_core_vpc_id \
                                                   --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Core-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "ohio_core_wb_sg_id=$ohio_core_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ohio_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create WindowsBastion EIP
ohio_core_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                             --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Core-WindowsBastion-EIPA},{Key=Hostname,Value=cmlue2cwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                             --query 'AllocationId' \
                                             --profile $profile --region us-east-2 --output text)
echo "ohio_core_wb_eipa=$ohio_core_wb_eipa"

ohio_core_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $ohio_core_wb_eipa \
                                                              --query 'Addresses[0].PublicIp' \
                                                              --profile $profile --region us-east-2 --output text)
echo "ohio_core_wb_instancea_public_ip=$ohio_core_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/ohio-core-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2cwb01a.$ohio_core_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_core_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$ohio_core_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue2cwb01a.$ohio_core_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_core_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "ohio_core_wb_instancea_hostname=cmlue2cwb01a.$ohio_core_public_domain"
echo "ohio_core_wb_instancea_hostname_alias=wba.$ohio_core_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/ohio-core-wba-user-data-$$.ps1
sed -e "s/@hostname@/cmlue2cwb01a/g" \
    -e "s/@administrator_password_parameter@/Core-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Core-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Core-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Core-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

ohio_core_wb_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                  --instance-type t3a.medium \
                                                  --iam-instance-profile Name=ManagedInstance \
                                                  --key-name administrator \
                                                  --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Core-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_core_wb_sg_id],SubnetId=$ohio_core_public_subneta_id \
                                                  --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Core-WindowsBastion-InstanceA},{Key=Hostname,Value=cmlue2cwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --user-data file://$tmpfile \
                                                  --client-token $(date +%s) \
                                                  --query 'Instances[0].InstanceId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "ohio_core_wb_instancea_id=$ohio_core_wb_instancea_id"

ohio_core_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_core_wb_instancea_id \
                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                               --profile $profile --region us-east-2 --output text)
echo "ohio_core_wb_instancea_private_ip=$ohio_core_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/ohio-core-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2cwb01a.$ohio_core_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_core_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$ohio_core_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue2cwb01a.$ohio_core_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_core_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $ohio_core_wb_instancea_id --allocation-id $ohio_core_wb_eipa \
                          --profile $profile --region us-east-2 --output text


## Ohio Log Windows Bastion ###########################################################################################
profile=$log_profile

# Create WindowsBastion Security Group
ohio_log_wb_sg_id=$(aws ec2 create-security-group --group-name Log-WindowsBastion-InstanceSecurityGroup \
                                                  --description Log-WindowsBastion-InstanceSecurityGroup \
                                                  --vpc-id $ohio_log_vpc_id \
                                                  --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Log-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --query 'GroupId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "ohio_log_wb_sg_id=$ohio_log_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ohio_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create WindowsBastion EIP
ohio_log_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                            --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Log-WindowsBastion-EIPA},{Key=Hostname,Value=cmlue2lwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                            --query 'AllocationId' \
                                            --profile $profile --region us-east-2 --output text)
echo "ohio_log_wb_eipa=$ohio_log_wb_eipa"

ohio_log_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $ohio_log_wb_eipa \
                                                             --query 'Addresses[0].PublicIp' \
                                                             --profile $profile --region us-east-2 --output text)
echo "ohio_log_wb_instancea_public_ip=$ohio_log_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/ohio-log-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2lwb01a.$ohio_log_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_log_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$ohio_log_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue2lwb01a.$ohio_log_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_log_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "ohio_log_wb_instancea_hostname=cmlue2lwb01a.$ohio_log_public_domain"
echo "ohio_log_wb_instancea_hostname_alias=wba.$ohio_log_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/ohio-log-wba-user-data-$$.ps1
sed -e "s/@hostname@/cmlue2lwb01a/g" \
    -e "s/@administrator_password_parameter@/Log-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Log-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Log-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Log-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

ohio_log_wb_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                 --instance-type t3a.medium \
                                                 --iam-instance-profile Name=ManagedInstance \
                                                 --key-name administrator \
                                                 --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Log-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_log_wb_sg_id],SubnetId=$ohio_log_public_subneta_id \
                                                 --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Log-WindowsBastion-InstanceA},{Key=Hostname,Value=cmlue2lwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                 --user-data file://$tmpfile \
                                                 --client-token $(date +%s) \
                                                 --query 'Instances[0].InstanceId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "ohio_log_wb_instancea_id=$ohio_log_wb_instancea_id"

ohio_log_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_log_wb_instancea_id \
                                                              --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                              --profile $profile --region us-east-2 --output text)
echo "ohio_log_wb_instancea_private_ip=$ohio_log_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/ohio-log-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2lwb01a.$ohio_log_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_log_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$ohio_log_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlue2lwb01a.$ohio_log_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_log_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $ohio_log_wb_instancea_id --allocation-id $ohio_log_wb_eipa \
                          --profile $profile --region us-east-2 --output text


## Alfa Ohio Production Windows Bastion ###############################################################################
profile=$production_profile

# Create WindowsBastion Security Group
alfa_ohio_production_wb_sg_id=$(aws ec2 create-security-group --group-name Alfa-Production-WindowsBastion-InstanceSecurityGroup \
                                                              --description Alfa-Production-WindowsBastion-InstanceSecurityGroup \
                                                              --vpc-id $alfa_ohio_production_vpc_id \
                                                              --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Production-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                              --query 'GroupId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_wb_sg_id=$alfa_ohio_production_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create WindowsBastion EIP
alfa_ohio_production_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                                        --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Production-WindowsBastion-EIPA},{Key=Hostname,Value=alfue2pwb01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                        --query 'AllocationId' \
                                                        --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_wb_eipa=$alfa_ohio_production_wb_eipa"

alfa_ohio_production_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_ohio_production_wb_eipa \
                                                                         --query 'Addresses[0].PublicIp' \
                                                                         --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_wb_instancea_public_ip=$alfa_ohio_production_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/alfa-ohio-production-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2pwb01a.$alfa_ohio_production_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_production_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$alfa_ohio_production_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alfue2pwb01a.$alfa_ohio_production_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_production_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_ohio_production_wb_instancea_hostname=alfue1pwb01a.$alfa_ohio_production_public_domain"
echo "alfa_ohio_production_wb_instancea_hostname_alias=wba.$alfa_ohio_production_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/alfa-ohio-production-wba-user-data-$$.ps1
sed -e "s/@hostname@/alfue1pwb01a/g" \
    -e "s/@administrator_password_parameter@/Alfa-Production-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Alfa-Production-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Alfa-Production-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Alfa-Production-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

alfa_ohio_production_wb_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                             --instance-type t3a.medium \
                                                             --iam-instance-profile Name=ManagedInstance \
                                                             --key-name administrator \
                                                             --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Production-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_production_wb_sg_id],SubnetId=$alfa_ohio_production_public_subneta_id \
                                                             --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Production-WindowsBastion-InstanceA},{Key=Hostname,Value=alfue2pwb01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                             --user-data file://$tmpfile \
                                                             --client-token $(date +%s) \
                                                             --query 'Instances[0].InstanceId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_wb_instancea_id=$alfa_ohio_production_wb_instancea_id"

alfa_ohio_production_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_production_wb_instancea_id \
                                                                          --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                          --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_wb_instancea_private_ip=$alfa_ohio_production_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/alfa-ohio-production-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2pwb01a.$alfa_ohio_production_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_production_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$alfa_ohio_production_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alfue2pwb01a.$alfa_ohio_production_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_production_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $alfa_ohio_production_wb_instancea_id --allocation-id $alfa_ohio_production_wb_eipa \
                          --profile $profile --region us-east-2 --output text


## Testing Windows Bastion ############################################################################################
profile=$testing_profile

# Create WindowsBastion Security Group
alfa_ohio_testing_wb_sg_id=$(aws ec2 create-security-group --group-name Alfa-Testing-WindowsBastion-InstanceSecurityGroup \
                                                           --description Alfa-Testing-WindowsBastion-InstanceSecurityGroup \
                                                           --vpc-id $alfa_ohio_testing_vpc_id \
                                                           --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Testing-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                           --query 'GroupId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_wb_sg_id=$alfa_ohio_testing_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create WindowsBastion EIP
alfa_ohio_testing_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                                     --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Testing-WindowsBastion-EIPA},{Key=Hostname,Value=alfue2twb01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                     --query 'AllocationId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_wb_eipa=$alfa_ohio_testing_wb_eipa"

alfa_ohio_testing_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_ohio_testing_wb_eipa \
                                                                      --query 'Addresses[0].PublicIp' \
                                                                      --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_wb_instancea_public_ip=$alfa_ohio_testing_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/alfa-ohio-testing-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2twb01a.$alfa_ohio_testing_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_testing_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$alfa_ohio_testing_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alfue2twb01a.$alfa_ohio_testing_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_testing_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_ohio_testing_wb_instancea_hostname=alfue2twb01a.$alfa_ohio_testing_public_domain"
echo "alfa_ohio_testing_wb_instancea_hostname_alias=wba.$alfa_ohio_testing_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/alfa-ohio-testing-wba-user-data-$$.ps1
sed -e "s/@hostname@/alfue2twb01a/g" \
    -e "s/@administrator_password_parameter@/Alfa-Testing-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Alfa-Testing-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Alfa-Testing-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Alfa-Testing-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

alfa_ohio_testing_wb_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                          --instance-type t3a.medium \
                                                          --iam-instance-profile Name=ManagedInstance \
                                                          --key-name administrator \
                                                          --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Testing-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_testing_wb_sg_id],SubnetId=$alfa_ohio_testing_public_subneta_id \
                                                          --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Testing-WindowsBastion-InstanceA},{Key=Hostname,Value=alfue2twb01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                          --user-data file://$tmpfile \
                                                          --client-token $(date +%s) \
                                                          --query 'Instances[0].InstanceId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_wb_instancea_id=$alfa_ohio_testing_wb_instancea_id"

alfa_ohio_testing_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_testing_wb_instancea_id \
                                                                       --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                       --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_wb_instancea_private_ip=$alfa_ohio_testing_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/alfa-ohio-testing-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2twb01a.$alfa_ohio_testing_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_testing_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$alfa_ohio_testing_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alfue2twb01a.$alfa_ohio_testing_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_testing_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $alfa_ohio_testing_wb_instancea_id --allocation-id $alfa_ohio_testing_wb_eipa \
                          --profile $profile --region us-east-2 --output text


## Alfa Ohio Development Windows Bastion ##############################################################################
profile=$development_profile

# Create WindowsBastion Security Group
alfa_ohio_development_wb_sg_id=$(aws ec2 create-security-group --group-name Alfa-Development-WindowsBastion-InstanceSecurityGroup \
                                                               --description Alfa-Development-WindowsBastion-InstanceSecurityGroup \
                                                               --vpc-id $alfa_ohio_development_vpc_id \
                                                               --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Development-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Development},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --query 'GroupId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_wb_sg_id=$alfa_ohio_development_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create WindowsBastion EIP
alfa_ohio_development_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                                         --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Development-WindowsBastion-EIPA},{Key=Hostname,Value=alfue2dwb01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Development},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                         --query 'AllocationId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_wb_eipa=$alfa_ohio_development_wb_eipa"

alfa_ohio_development_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_ohio_development_wb_eipa \
                                                                          --query 'Addresses[0].PublicIp' \
                                                                          --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_wb_instancea_public_ip=$alfa_ohio_development_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/alfa-ohio-development-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2dwb01a.$alfa_ohio_development_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_development_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$alfa_ohio_development_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alfue2dwb01a.$alfa_ohio_development_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_development_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_ohio_development_wb_instancea_hostname=alfue2dwb01a.$alfa_ohio_development_public_domain"
echo "alfa_ohio_development_wb_instancea_hostname_alias=wba.$alfa_ohio_development_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/alfa-ohio-development-wba-user-data-$$.ps1
sed -e "s/@hostname@/alfue2dwb01a/g" \
    -e "s/@administrator_password_parameter@/Alfa-Development-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Alfa-Development-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Alfa-Development-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Alfa-Development-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

alfa_ohio_development_wb_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                              --instance-type t3a.medium \
                                                              --iam-instance-profile Name=ManagedInstance \
                                                              --key-name administrator \
                                                              --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Development-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_development_wb_sg_id],SubnetId=$alfa_ohio_development_public_subneta_id \
                                                              --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Development-WindowsBastion-InstanceA},{Key=Hostname,Value=alfue2dwb01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Development},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                              --user-data file://$tmpfile \
                                                              --client-token $(date +%s) \
                                                              --query 'Instances[0].InstanceId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_wb_instancea_id=$alfa_ohio_development_wb_instancea_id"

alfa_ohio_development_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_development_wb_instancea_id \
                                                                           --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_wb_instancea_private_ip=$alfa_ohio_development_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/alfa-ohio-development-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2dwb01a.$alfa_ohio_development_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_development_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$alfa_ohio_development_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alfue2dwb01a.$alfa_ohio_development_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_development_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $alfa_ohio_development_wb_instancea_id --allocation-id $alfa_ohio_development_wb_eipa \
                          --profile $profile --region us-east-2 --output text


## Zulu Ohio Production Windows Bastion ###############################################################################
profile=$production_profile

# Create WindowsBastion Security Group
zulu_ohio_production_wb_sg_id=$(aws ec2 create-security-group --group-name Zulu-Production-WindowsBastion-InstanceSecurityGroup \
                                                              --description Zulu-Production-WindowsBastion-InstanceSecurityGroup \
                                                              --vpc-id $zulu_ohio_production_vpc_id \
                                                              --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Production-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                              --query 'GroupId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_wb_sg_id=$zulu_ohio_production_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"DataCenter-Zulu-Dallas (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"DataCenter-Zulu-Dallas (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create WindowsBastion EIP
zulu_ohio_production_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                                        --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Zulu-Production-WindowsBastion-EIPA},{Key=Hostname,Value=zulue2pwb01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                        --query 'AllocationId' \
                                                        --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_wb_eipa=$zulu_ohio_production_wb_eipa"

zulu_ohio_production_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $zulu_ohio_production_wb_eipa \
                                                                         --query 'Addresses[0].PublicIp' \
                                                                         --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_wb_instancea_public_ip=$zulu_ohio_production_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/zulu-ohio-production-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zulue2pwb01a.$zulu_ohio_production_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_ohio_production_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$zulu_ohio_production_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "zulue2pwb01a.$zulu_ohio_production_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_ohio_production_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "zulu_ohio_production_wb_instancea_hostname=zulue2pwb01a.$zulu_ohio_production_public_domain"
echo "zulu_ohio_production_wb_instancea_hostname_alias=wba.$zulu_ohio_production_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/zulu-ohio-production-wba-user-data-$$.ps1
sed -e "s/@hostname@/zulue2pwb01a/g" \
    -e "s/@administrator_password_parameter@/Zulu-Production-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Zulu-Production-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Zulu-Production-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Zulu-Production-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

zulu_ohio_production_wb_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                             --instance-type t3a.medium \
                                                             --iam-instance-profile Name=ManagedInstance \
                                                             --key-name administrator \
                                                             --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Zulu-Production-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_ohio_production_wb_sg_id],SubnetId=$zulu_ohio_production_public_subneta_id \
                                                             --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Production-WindowsBastion-InstanceA},{Key=Hostname,Value=zulue2pwb01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                             --user-data file://$tmpfile \
                                                             --client-token $(date +%s) \
                                                             --query 'Instances[0].InstanceId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_wb_instancea_id=$zulu_ohio_production_wb_instancea_id"

zulu_ohio_production_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_ohio_production_wb_instancea_id \
                                                                          --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                          --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_wb_instancea_private_ip=$zulu_ohio_production_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/zulu-ohio-production-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zulue2pwb01a.$zulu_ohio_production_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_ohio_production_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$zulu_ohio_production_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "zulue2pwb01a.$zulu_ohio_production_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_ohio_production_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $zulu_ohio_production_wb_instancea_id --allocation-id $zulu_ohio_production_wb_eipa \
                          --profile $profile --region us-east-2 --output text


## Zulu Ohio Development Windows Bastion ##############################################################################
profile=$development_profile

# Create WindowsBastion Security Group
zulu_ohio_development_wb_sg_id=$(aws ec2 create-security-group --group-name Zulu-Development-WindowsBastion-InstanceSecurityGroup \
                                                               --description Zulu-Development-WindowsBastion-InstanceSecurityGroup \
                                                               --vpc-id $zulu_ohio_development_vpc_id \
                                                               --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Development-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=Zulu},{Key=Environment,Value=Development},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --query 'GroupId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_wb_sg_id=$zulu_ohio_development_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"DataCenter-Zulu-Dallas (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"DataCenter-Zulu-Dallas (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create WindowsBastion EIP
zulu_ohio_development_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                                         --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Zulu-Development-WindowsBastion-EIPA},{Key=Hostname,Value=zulue2dwb01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Development},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                         --query 'AllocationId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_wb_eipa=$zulu_ohio_development_wb_eipa"

zulu_ohio_development_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $zulu_ohio_development_wb_eipa \
                                                                          --query 'Addresses[0].PublicIp' \
                                                                          --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_wb_instancea_public_ip=$zulu_ohio_development_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/alfa-ohio-development-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zulue2dwb01a.$zulu_ohio_development_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_ohio_development_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$zulu_ohio_development_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "zulue2dwb01a.$zulu_ohio_development_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_ohio_development_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "zulu_ohio_development_wb_instancea_hostname=zulue2dwb01a.$zulu_ohio_development_public_domain"
echo "zulu_ohio_development_wb_instancea_hostname_alias=wba.$zulu_ohio_development_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/zulu-ohio-development-wba-user-data-$$.ps1
sed -e "s/@hostname@/zulue2dwb01a/g" \
    -e "s/@administrator_password_parameter@/Zulu-Development-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Zulu-Development-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Zulu-Development-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Zulu-Development-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

zulu_ohio_development_wb_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                              --instance-type t3a.medium \
                                                              --iam-instance-profile Name=ManagedInstance \
                                                              --key-name administrator \
                                                              --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Zulu-Development-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_ohio_development_wb_sg_id],SubnetId=$zulu_ohio_development_public_subneta_id \
                                                              --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Development-WindowsBastion-InstanceA},{Key=Hostname,Value=zulue2dwb01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Development},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                              --user-data file://$tmpfile \
                                                              --client-token $(date +%s) \
                                                              --query 'Instances[0].InstanceId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_wb_instancea_id=$zulu_ohio_development_wb_instancea_id"

zulu_ohio_development_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_ohio_development_wb_instancea_id \
                                                                           --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_wb_instancea_private_ip=$zulu_ohio_development_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/alfa-ohio-development-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zulue2dwb01a.$zulu_ohio_development_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_ohio_development_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$zulu_ohio_development_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "zulue2dwb01a.$zulu_ohio_development_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_ohio_development_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $zulu_ohio_development_wb_instancea_id --allocation-id $zulu_ohio_development_wb_eipa \
                          --profile $profile --region us-east-2 --output text


## Ireland Management Windows Bastion #################################################################################
profile=$management_profile

# Create WindowsBastion Security Group
ireland_management_wb_sg_id=$(aws ec2 create-security-group --group-name Management-WindowsBastion-InstanceSecurityGroup \
                                                            --description Management-WindowsBastion-InstanceSecurityGroup \
                                                            --vpc-id $ireland_management_vpc_id \
                                                            --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Management-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                            --query 'GroupId' \
                                                            --profile $profile --region eu-west-1 --output text)
echo "ireland_management_wb_sg_id=$ireland_management_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ireland_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_management_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create WindowsBastion EIP
ireland_management_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                                      --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Management-WindowsBastion-EIPA},{Key=Hostname,Value=cmlew1mwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                      --query 'AllocationId' \
                                                      --profile $profile --region eu-west-1 --output text)
echo "ireland_management_wb_eipa=$ireland_management_wb_eipa"

ireland_management_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $ireland_management_wb_eipa \
                                                                       --query 'Addresses[0].PublicIp' \
                                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_management_wb_instancea_public_ip=$ireland_management_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/ireland-management-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1mwb01a.$ireland_management_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_management_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$ireland_management_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlew1mwb01a.$ireland_management_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_management_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "ireland_management_wb_instancea_hostname=cmlew1mwb01a.$ireland_management_public_domain"
echo "ireland_management_wb_instancea_hostname_alias=wba.$ireland_management_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/ireland-management-wba-user-data-$$.ps1
sed -e "s/@hostname@/cmlew1mwb01a/g" \
    -e "s/@administrator_password_parameter@/Management-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Management-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Management-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Management-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

ireland_management_wb_instancea_id=$(aws ec2 run-instances --image-id $ireland_win2016_ami_id \
                                                           --instance-type t3a.medium \
                                                           --iam-instance-profile Name=ManagedInstance \
                                                           --key-name administrator \
                                                           --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ireland_management_wb_sg_id],SubnetId=$ireland_management_public_subneta_id \
                                                           --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Management-WindowsBastion-InstanceA},{Key=Hostname,Value=cmlew1mwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                           --user-data file://$tmpfile \
                                                           --client-token $(date +%s) \
                                                           --query 'Instances[0].InstanceId' \
                                                           --profile $profile --region eu-west-1 --output text)
echo "ireland_management_wb_instancea_id=$ireland_management_wb_instancea_id"

ireland_management_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ireland_management_wb_instancea_id \
                                                                        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_management_wb_instancea_private_ip=$ireland_management_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/ireland-management-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1mwb01a.$ireland_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_management_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$ireland_management_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlew1mwb01a.$ireland_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text

aws ec2 associate-address --instance-id $ireland_management_wb_instancea_id --allocation-id $ireland_management_wb_eipa \
                          --profile $profile --region eu-west-1 --output text


## Ireland Core Windows Bastion #######################################################################################
profile=$core_profile

# Create WindowsBastion Security Group
ireland_core_wb_sg_id=$(aws ec2 create-security-group --group-name Core-WindowsBastion-InstanceSecurityGroup \
                                                      --description Core-WindowsBastion-InstanceSecurityGroup \
                                                      --vpc-id $ireland_core_vpc_id \
                                                      --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Core-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                      --query 'GroupId' \
                                                      --profile $profile --region eu-west-1 --output text)
echo "ireland_core_wb_sg_id=$ireland_core_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ireland_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_core_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create WindowsBastion EIP
ireland_core_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                                --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Core-WindowsBastion-EIPA},{Key=Hostname,Value=cmlew1cwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                --query 'AllocationId' \
                                                --profile $profile --region eu-west-1 --output text)
echo "ireland_core_wb_eipa=$ireland_core_wb_eipa"

ireland_core_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $ireland_core_wb_eipa \
                                                                 --query 'Addresses[0].PublicIp' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "ireland_core_wb_instancea_public_ip=$ireland_core_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/ireland-core-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1cwb01a.$ireland_core_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_core_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$ireland_core_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlew1cwb01a.$ireland_core_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_core_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "ireland_core_wb_instancea_hostname=cmlew1cwb01a.$ireland_core_public_domain"
echo "ireland_core_wb_instancea_hostname_alias=wba.$ireland_core_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/ireland-core-wba-user-data-$$.ps1
sed -e "s/@hostname@/cmlew1cwb01a/g" \
    -e "s/@administrator_password_parameter@/Core-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Core-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Core-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Core-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

ireland_core_wb_instancea_id=$(aws ec2 run-instances --image-id $ireland_win2016_ami_id \
                                                     --instance-type t3a.medium \
                                                     --iam-instance-profile Name=ManagedInstance \
                                                     --key-name administrator \
                                                     --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Core-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ireland_core_wb_sg_id],SubnetId=$ireland_core_public_subneta_id \
                                                     --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Core-WindowsBastion-InstanceA},{Key=Hostname,Value=cmlew1cwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                     --user-data file://$tmpfile \
                                                     --client-token $(date +%s) \
                                                     --query 'Instances[0].InstanceId' \
                                                     --profile $profile --region eu-west-1 --output text)
echo "ireland_core_wb_instancea_id=$ireland_core_wb_instancea_id"

ireland_core_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ireland_core_wb_instancea_id \
                                                                  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "ireland_core_wb_instancea_private_ip=$ireland_core_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/ireland-core-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1cwb01a.$ireland_core_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_core_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$ireland_core_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlew1cwb01a.$ireland_core_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_core_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text

aws ec2 associate-address --instance-id $ireland_core_wb_instancea_id --allocation-id $ireland_core_wb_eipa \
                          --profile $profile --region eu-west-1 --output text


## Ireland Log Windows Bastion ########################################################################################
profile=$log_profile

# Create WindowsBastion Security Group
ireland_log_wb_sg_id=$(aws ec2 create-security-group --group-name Log-WindowsBastion-InstanceSecurityGroup \
                                                     --description Log-WindowsBastion-InstanceSecurityGroup \
                                                     --vpc-id $ireland_log_vpc_id \
                                                     --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Log-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                     --query 'GroupId' \
                                                     --profile $profile --region eu-west-1 --output text)
echo "ireland_log_wb_sg_id=$ireland_log_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ireland_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_log_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create WindowsBastion EIP
ireland_log_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                               --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Log-WindowsBastion-EIPA},{Key=Hostname,Value=cmlew1lwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                               --query 'AllocationId' \
                                               --profile $profile --region eu-west-1 --output text)
echo "ireland_log_wb_eipa=$ireland_log_wb_eipa"

ireland_log_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $ireland_log_wb_eipa \
                                                                --query 'Addresses[0].PublicIp' \
                                                                --profile $profile --region eu-west-1 --output text)
echo "ireland_log_wb_instancea_public_ip=$ireland_log_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/ireland-log-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1lwb01a.$ireland_log_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_log_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$ireland_log_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlew1lwb01a.$ireland_log_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_log_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "ireland_log_wb_instancea_hostname=cmlew1lwb01a.$ireland_log_public_domain"
echo "ireland_log_wb_instancea_hostname_alias=wba.$ireland_log_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/ireland-log-wba-user-data-$$.ps1
sed -e "s/@hostname@/cmlew1lwb01a/g" \
    -e "s/@administrator_password_parameter@/Log-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Log-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Log-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Log-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

ireland_log_wb_instancea_id=$(aws ec2 run-instances --image-id $ireland_win2016_ami_id \
                                                    --instance-type t3a.medium \
                                                    --iam-instance-profile Name=ManagedInstance \
                                                    --key-name administrator \
                                                    --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Log-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ireland_log_wb_sg_id],SubnetId=$ireland_log_public_subneta_id \
                                                    --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Log-WindowsBastion-InstanceA},{Key=Hostname,Value=cmlew1lwb01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                    --user-data file://$tmpfile \
                                                    --client-token $(date +%s) \
                                                    --query 'Instances[0].InstanceId' \
                                                    --profile $profile --region eu-west-1 --output text)
echo "ireland_log_wb_instancea_id=$ireland_log_wb_instancea_id"

ireland_log_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ireland_log_wb_instancea_id \
                                                                 --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "ireland_log_wb_instancea_private_ip=$ireland_log_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/ireland-log-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1lwb01a.$ireland_log_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_log_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$ireland_log_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlew1lwb01a.$ireland_log_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_log_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text

aws ec2 associate-address --instance-id $ireland_log_wb_instancea_id --allocation-id $ireland_log_wb_eipa \
                          --profile $profile --region eu-west-1 --output text


## Alfa Ireland Recovery Windows Bastion ##############################################################################
profile=$recovery_profile

# Create WindowsBastion Security Group
alfa_ireland_recovery_wb_sg_id=$(aws ec2 create-security-group --group-name Alfa-Recovery-WindowsBastion-InstanceSecurityGroup \
                                                               --description Alfa-Recovery-WindowsBastion-InstanceSecurityGroup \
                                                               --vpc-id $alfa_ireland_recovery_vpc_id \
                                                               --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Recovery-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --query 'GroupId' \
                                                               --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_wb_sg_id=$alfa_ireland_recovery_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create WindowsBastion EIP
alfa_ireland_recovery_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                                         --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Recovery-WindowsBastion-EIPA},{Key=Hostname,Value=alfew1rwb01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                         --query 'AllocationId' \
                                                         --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_wb_eipa=$alfa_ireland_recovery_wb_eipa"

alfa_ireland_recovery_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_ireland_recovery_wb_eipa \
                                                                          --query 'Addresses[0].PublicIp' \
                                                                          --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_wb_instancea_public_ip=$alfa_ireland_recovery_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/alfa-ireland-recovery-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfew1rwb01a.$alfa_ireland_recovery_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ireland_recovery_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$alfa_ireland_recovery_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alfew1rwb01a.$alfa_ireland_recovery_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ireland_recovery_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "alfa_ireland_recovery_wb_instancea_hostname=alfew1rwb01a.$alfa_ireland_recovery_public_domain"
echo "alfa_ireland_recovery_wb_instancea_hostname_alias=wba.$alfa_ireland_recovery_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/alfa-ireland-recovery-wba-user-data-$$.ps1
sed -e "s/@hostname@/alfew1rwb01a/g" \
    -e "s/@administrator_password_parameter@/Alfa-Recovery-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@/Alfa-Recovery-Directory-Domain/g" \
    -e "s/@directory_domainjoin_user_parameter@/Alfa-Recovery-Directory-DomainJoin-User/g" \
    -e "s/@directory_domainjoin_password_parameter@/Alfa-Recovery-Directory-DomainJoin-Password/g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

alfa_ireland_recovery_wb_instancea_id=$(aws ec2 run-instances --image-id $ireland_win2016_ami_id \
                                                              --instance-type t3a.medium \
                                                              --iam-instance-profile Name=ManagedInstance \
                                                              --key-name administrator \
                                                              --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Recovery-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ireland_recovery_wb_sg_id],SubnetId=$alfa_ireland_recovery_public_subneta_id \
                                                              --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Recovery-WindowsBastion-InstanceA},{Key=Hostname,Value=alfew1rwb01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                              --user-data file://$tmpfile \
                                                              --client-token $(date +%s) \
                                                              --query 'Instances[0].InstanceId' \
                                                              --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_wb_instancea_id=$alfa_ireland_recovery_wb_instancea_id"

alfa_ireland_recovery_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ireland_recovery_wb_instancea_id \
                                                                           --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                           --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_wb_instancea_private_ip=$alfa_ireland_recovery_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/alfa-ireland-recovery-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfew1rwb01a.$alfa_ireland_recovery_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ireland_recovery_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$alfa_ireland_recovery_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alfew1rwb01a.$alfa_ireland_recovery_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ireland_recovery_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text

aws ec2 associate-address --instance-id $alfa_ireland_recovery_wb_instancea_id --allocation-id $alfa_ireland_recovery_wb_eipa \
                          --profile $profile --region eu-west-1 --output text


## Alfa LosAngeles Windows Bastion ####################################################################################
profile=$management_profile

# Create WindowsBastion Security Group
alfa_lax_wb_sg_id=$(aws ec2 create-security-group --group-name Alfa-LosAngeles-WindowsBastion-InstanceSecurityGroup \
                                                  --description Alfa-LosAngeles-WindowsBastion-InstanceSecurityGroup \
                                                  --vpc-id $alfa_lax_vpc_id \
                                                  --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-LosAngeles-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Location,Value=LosAngeles},{Key=Environment,Value=Network},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --query 'GroupId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_lax_wb_sg_id=$alfa_lax_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_lax_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_lax_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_lax_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_lax_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create WindowsBastion EIP
alfa_lax_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                            --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-LosAngeles-WindowsBastion-EIPA},{Key=Hostname,Value=alflaxnwb01a},{Key=Company,Value=Alfa},{Key=Location,Value=LosAngeles},{Key=Environment,Value=Network},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                            --query 'AllocationId' \
                                            --profile $profile --region us-east-2 --output text)
echo "alfa_lax_wb_eipa=$alfa_lax_wb_eipa"

alfa_lax_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_lax_wb_eipa \
                                                             --query 'Addresses[0].PublicIp' \
                                                             --profile $profile --region us-east-2 --output text)
echo "alfa_lax_wb_instancea_public_ip=$alfa_lax_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/alfa-lax-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alflaxnwb01a.$alfa_lax_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_lax_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$alfa_lax_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alflaxnwb01a.$alfa_lax_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_lax_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_lax_wb_instancea_hostname=alflaxnwb01a.$alfa_lax_public_domain"
echo "alfa_lax_wb_instancea_hostname_alias=wba.$alfa_lax_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/alfa-lax-wba-user-data-$$.ps1
sed -e "s/@hostname@/alflaxnwb01a/g" \
    -e "s/@administrator_password_parameter@/Alfa-LosAngeles-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@//g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

alfa_lax_wb_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                 --instance-type t3a.medium \
                                                 --iam-instance-profile Name=ManagedInstance \
                                                 --key-name administrator \
                                                 --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-LosAngeles-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_lax_wb_sg_id],SubnetId=$alfa_lax_public_subneta_id \
                                                 --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-LosAngeles-WindowsBastion-InstanceA},{Key=Hostname,Value=alflaxnwb01a},{Key=Company,Value=Alfa},{Key=Location,Value=LosAngeles},{Key=Environment,Value=Network},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                 --user-data file://$tmpfile \
                                                 --client-token $(date +%s) \
                                                 --query 'Instances[0].InstanceId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_lax_wb_instancea_id=$alfa_lax_wb_instancea_id"

alfa_lax_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_lax_wb_instancea_id \
                                                              --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_lax_wb_instancea_private_ip=$alfa_lax_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/alfa-lax-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alflaxnwb01a.$alfa_lax_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_lax_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$alfa_lax_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alflaxnwb01a.$alfa_lax_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_lax_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $alfa_lax_wb_instancea_id --allocation-id $alfa_lax_wb_eipa \
                          --profile $profile --region us-east-2 --output text


## Alfa Miami Windows Bastion #########################################################################################
profile=$management_profile

# Create WindowsBastion Security Group
alfa_mia_wb_sg_id=$(aws ec2 create-security-group --group-name Alfa-Miami-WindowsBastion-InstanceSecurityGroup \
                                                  --description Alfa-Miami-WindowsBastion-InstanceSecurityGroup \
                                                  --vpc-id $alfa_mia_vpc_id \
                                                  --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Miami-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Location,Value=Miami},{Key=Environment,Value=Network},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --query 'GroupId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_mia_wb_sg_id=$alfa_mia_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_mia_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_mia_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_mia_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_mia_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create WindowsBastion EIP
alfa_mia_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                            --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Miami-WindowsBastion-EIPA},{Key=Hostname,Value=alfmianwb01a},{Key=Company,Value=Alfa},{Key=Location,Value=Miami},{Key=Environment,Value=Network},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                            --query 'AllocationId' \
                                            --profile $profile --region us-east-2 --output text)
echo "alfa_mia_wb_eipa=$alfa_mia_wb_eipa"

alfa_mia_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_mia_wb_eipa \
                                                             --query 'Addresses[0].PublicIp' \
                                                             --profile $profile --region us-east-2 --output text)
echo "alfa_mia_wb_instancea_public_ip=$alfa_mia_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/alfa-mia-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfmianwb01a.$alfa_mia_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_mia_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$alfa_mia_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alfmianwb01a.$alfa_mia_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_mia_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_mia_wb_instancea_hostname=alfmianwb01a.$alfa_mia_public_domain"
echo "alfa_mia_wb_instancea_hostname_alias=wba.$alfa_mia_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/alfa-mia-wba-user-data-$$.ps1
sed -e "s/@hostname@/alfmianwb01a/g" \
    -e "s/@administrator_password_parameter@/Alfa-Miami-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@//g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

alfa_mia_wb_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                 --instance-type t3a.medium \
                                                 --iam-instance-profile Name=ManagedInstance \
                                                 --key-name administrator \
                                                 --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Miami-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_mia_wb_sg_id],SubnetId=$alfa_mia_public_subneta_id \
                                                 --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Miami-WindowsBastion-InstanceA},{Key=Hostname,Value=alfmianwb01a},{Key=Company,Value=Alfa},{Key=Location,Value=Miami},{Key=Environment,Value=Network},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                 --user-data file://$tmpfile \
                                                 --client-token $(date +%s) \
                                                 --query 'Instances[0].InstanceId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_mia_wb_instancea_id=$alfa_mia_wb_instancea_id"

alfa_mia_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_mia_wb_instancea_id \
                                                              --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_mia_wb_instancea_private_ip=$alfa_mia_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/alfa-mia-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfmianwb01a.$alfa_mia_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_mia_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$alfa_mia_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "alfmianwb01a.$alfa_mia_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_mia_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $alfa_mia_wb_instancea_id --allocation-id $alfa_mia_wb_eipa \
                          --profile $profile --region us-east-2 --output text


## Zulu Dallas Windows Bastion ########################################################################################
profile=$management_profile

# Create WindowsBastion Security Group
zulu_dfw_wb_sg_id=$(aws ec2 create-security-group --group-name Zulu-Dallas-WindowsBastion-InstanceSecurityGroup \
                                                  --description Zulu-Dallas-WindowsBastion-InstanceSecurityGroup \
                                                  --vpc-id $zulu_dfw_vpc_id \
                                                  --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Dallas-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --query 'GroupId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_wb_sg_id=$zulu_dfw_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create WindowsBastion EIP
zulu_dfw_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                            --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Zulu-Dallas-WindowsBastion-EIPA},{Key=Hostname,Value=zuldfwnwb01a},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                            --query 'AllocationId' \
                                            --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_wb_eipa=$zulu_dfw_wb_eipa"

zulu_dfw_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $zulu_dfw_wb_eipa \
                                                             --query 'Addresses[0].PublicIp' \
                                                             --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_wb_instancea_public_ip=$zulu_dfw_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/zulu-dfw-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zuldfwnwb01a.$zulu_dfw_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_dfw_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$zulu_dfw_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "zuldfwnwb01a.$zulu_dfw_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_dfw_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "zulu_dfw_wb_instancea_hostname=zuldfwnwb01a.$zulu_dfw_public_domain"
echo "zulu_dfw_wb_instancea_hostname_alias=wba.$zulu_dfw_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/zulu-dfw-wba-user-data-$$.ps1
sed -e "s/@hostname@/zuldfwnwb01a/g" \
    -e "s/@administrator_password_parameter@/Zulu-Dallas-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@//g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

zulu_dfw_wb_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                 --instance-type t3a.medium \
                                                 --iam-instance-profile Name=ManagedInstance \
                                                 --key-name administrator \
                                                 --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Zulu-Dallas-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_dfw_wb_sg_id],SubnetId=$zulu_dfw_public_subneta_id \
                                                 --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Dallas-WindowsBastion-InstanceA},{Key=Hostname,Value=zuldfwnwb01a},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                 --user-data file://$tmpfile \
                                                 --client-token $(date +%s) \
                                                 --query 'Instances[0].InstanceId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_wb_instancea_id=$zulu_dfw_wb_instancea_id"

zulu_dfw_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_dfw_wb_instancea_id \
                                                              --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                              --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_wb_instancea_private_ip=$zulu_dfw_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/zulu-dfw-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zuldfwnwb01a.$zulu_dfw_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_dfw_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$zulu_dfw_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "zuldfwnwb01a.$zulu_dfw_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_dfw_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $zulu_dfw_wb_instancea_id --allocation-id $zulu_dfw_wb_eipa \
                          --profile $profile --region us-east-2 --output text


## CaMeLz SantaBarbara Windows Bastion ###################################################################################
profile=$management_profile

# Create WindowsBastion Security Group
cml_sba_wb_sg_id=$(aws ec2 create-security-group --group-name CaMeLz-SantaBarbara-WindowsBastion-InstanceSecurityGroup \
                                                 --description CaMeLz-SantaBarbara-WindowsBastion-InstanceSecurityGroup \
                                                 --vpc-id $cml_sba_vpc_id \
                                                 --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=CaMeLz-SantaBarbara-WindowsBastion-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Location,Value=SantaBarbara},{Key=Environment,Value=Network},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                 --query 'GroupId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "cml_sba_wb_sg_id=$cml_sba_wb_sg_id"

aws ec2 authorize-security-group-ingress --group-id $cml_sba_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $cml_sba_wb_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $cml_sba_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $cml_sba_wb_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (RDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create WindowsBastion EIP
cml_sba_wb_eipa=$(aws ec2 allocate-address --domain vpc \
                                           --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=CaMeLz-SantaBarbara-WindowsBastion-EIPA},{Key=Hostname,Value=cmlsbanwb01a},{Key=Company,Value=CaMeLz},{Key=Location,Value=SantaBarbara},{Key=Environment,Value=Network},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                           --query 'AllocationId' \
                                           --profile $profile --region us-east-2 --output text)
echo "cml_sba_wb_eipa=$cml_sba_wb_eipa"

cml_sba_wb_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $cml_sba_wb_eipa \
                                                            --query 'Addresses[0].PublicIp' \
                                                            --profile $profile --region us-east-2 --output text)
echo "cml_sba_wb_instancea_public_ip=$cml_sba_wb_instancea_public_ip"

# Create WindowsBastion Public Domain Name
tmpfile=$tmpdir/cml-sba-wba-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlsbanwb01a.$cml_sba_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$cml_sba_wb_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$cml_sba_public_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlsbanwb01a.$cml_sba_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $cml_sba_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "cml_sba_wb_instancea_hostname=cmlsbanwb01a.$cml_sba_public_domain"
echo "cml_sba_wb_instancea_hostname_alias=wba.$cml_sba_public_domain"

# Create WindowsBastion Instance
tmpfile=$tmpdir/cml-sba-wba-user-data-$$.ps1
sed -e "s/@hostname@/cmlsbanwb01a/g" \
    -e "s/@administrator_password_parameter@/CaMeLz-SantaBarbara-Administrator-Password/g" \
    -e "s/@directory_domain_parameter@//g" \
    $templatesdir/windows-wb-user-data.ps1 > $tmpfile

cml_sba_wb_instancea_id=$(aws ec2 run-instances --image-id $ohio_win2016_ami_id \
                                                --instance-type t3a.medium \
                                                --iam-instance-profile Name=ManagedInstance \
                                                --key-name administrator \
                                                --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=CaMeLz-SantaBarbara-WindowsBastion-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$cml_sba_wb_sg_id],SubnetId=$cml_sba_public_subneta_id \
                                                --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=CaMeLz-SantaBarbara-WindowsBastion-InstanceA},{Key=Hostname,Value=cmlsbanwb01a},{Key=Company,Value=CaMeLz},{Key=Location,Value=SantaBarbara},{Key=Utility,Value=WindowsBastion},{Key=Project,Value=CaMeLz-POC-4}] \
                                                --user-data file://$tmpfile \
                                                --client-token $(date +%s) \
                                                --query 'Instances[0].InstanceId' \
                                                --profile $profile --region us-east-2 --output text)
echo "cml_sba_wb_instancea_id=$cml_sba_wb_instancea_id"

cml_sba_wb_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $cml_sba_wb_instancea_id \
                                                             --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                             --profile $profile --region us-east-2 --output text)
echo "cml_sba_wb_instancea_private_ip=$cml_sba_wb_instancea_private_ip"

# Create WindowsBastion Private Domain Name
tmpfile=$tmpdir/cml-sba-wba-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlsbanwb01a.$cml_sba_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$cml_sba_wb_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "wba.$cml_sba_private_domain",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "cmlsbanwb01a.$cml_sba_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $cml_sba_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $cml_sba_wb_instancea_id --allocation-id $cml_sba_wb_eipa \
                          --profile $profile --region us-east-2 --output text
