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

echo "This script has not been tested to run non-interactively. It has no error handling, re-try or restart logic."
echo "You must paste the commands in this script one by one into a terminal, and manually handle errors and re-try."
exit 1

echo "#######################################################################################################################"
echo "## STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP     ##"
echo "#######################################################################################################################"
echo "## All prior scripts in the run order must be run before you run this script                                        ##"
echo "#######################################################################################################################"

#######################################################################################################################
## Linux Test Instances ###############################################################################################
#######################################################################################################################

## Global Management Test Instances ###################################################################################
profile=$management_profile

# Create LinuxWebServer Security Group
global_management_lws_sg_id=$(aws ec2 create-security-group --group-name Management-LinuxWebServer-InstanceSecurityGroup \
                                                            --description Management-LinuxWebServer-InstanceSecurityGroup \
                                                            --vpc-id $global_management_vpc_id \
                                                            --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Management-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                            --query 'GroupId' \
                                                            --profile $profile --region us-east-1 --output text)
echo "global_management_lws_sg_id=$global_management_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text

# Create LinuxWebServer EIP
global_management_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                      --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Management-LinuxWebServer-EIPA},{Key=Hostname,Value=cmlue1mlws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                      --query 'AllocationId' \
                                                      --profile $profile --region us-east-1 --output text)
echo "global_management_lws_eipa=$global_management_lws_eipa"

global_management_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $global_management_lws_eipa \
                                                                       --query 'Addresses[0].PublicIp' \
                                                                       --profile $profile --region us-east-1 --output text)
echo "global_management_lws_instancea_public_ip=$global_management_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/global-management-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1mlws01a.$global_management_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_management_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$global_management_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue1mlws01a.$global_management_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_management_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text
echo "global_management_lws_instancea_hostname=cmlue1mlws01a.$global_management_public_domain"
echo "global_management_lws_instancea_hostname_alias=lwsa.$global_management_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/global-management-lwsa-user-data-$$.sh
sed -e "s/@hostname@/cmlue1mlws01a.$global_management_private_domain/g" \
    -e "s/@motd@/CaMeLz Global Management Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

global_management_lws_instancea_id=$(aws ec2 run-instances --image-id $global_amzn2_ami_id \
                                                           --instance-type t3a.nano \
                                                           --iam-instance-profile Name=ManagedInstance \
                                                           --key-name administrator \
                                                           --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_management_lws_sg_id],SubnetId=$global_management_web_subneta_id \
                                                           --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Management-LinuxWebServer-InstanceA},{Key=Hostname,Value=cmlue1mlws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                           --user-data file://$tmpfile \
                                                           --client-token $(date +%s) \
                                                           --query 'Instances[0].InstanceId' \
                                                           --profile $profile --region us-east-1 --output text)
echo "global_management_lws_instancea_id=$global_management_lws_instancea_id"

global_management_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $global_management_lws_instancea_id \
                                                                        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                        --profile $profile --region us-east-1 --output text)
echo "global_management_lws_instancea_private_ip=$global_management_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/global-management-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1mlws01a.$global_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_management_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$global_management_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue1mlws01a.$global_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text

aws ec2 associate-address --instance-id $global_management_lws_instancea_id --allocation-id $global_management_lws_eipa \
                          --profile $profile --region us-east-1 --output text

# Create LinuxApplicationServer Security Group
global_management_las_sg_id=$(aws ec2 create-security-group --group-name Management-LinuxApplicationServer-InstanceSecurityGroup \
                                                            --description Management-LinuxApplicationServer-InstanceSecurityGroup \
                                                            --vpc-id $global_management_vpc_id \
                                                            --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Management-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                            --query 'GroupId' \
                                                            --profile $profile --region us-east-1 --output text)
echo "global_management_las_sg_id=$global_management_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $global_management_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_management_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$global_management_lws_sg_id,Description=\"Management-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/global-management-lasa-user-data-$$.sh
sed -e "s/@hostname@/cmlue1mlas01a.$global_management_private_domain/g" \
    -e "s/@motd@/CaMeLz Global Management Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

global_management_las_instancea_id=$(aws ec2 run-instances --image-id $global_amzn2_ami_id \
                                                           --instance-type t3a.nano \
                                                           --iam-instance-profile Name=ManagedInstance \
                                                           --key-name administrator \
                                                           --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_management_las_sg_id],SubnetId=$global_management_application_subneta_id \
                                                           --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Management-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=cmlue1mlas01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                           --user-data file://$tmpfile \
                                                           --client-token $(date +%s) \
                                                           --query 'Instances[0].InstanceId' \
                                                           --profile $profile --region us-east-1 --output text)
echo "global_management_las_instancea_id=$global_management_las_instancea_id"

global_management_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $global_management_las_instancea_id \
                                                                        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                        --profile $profile --region us-east-1 --output text)
echo "global_management_las_instancea_private_ip=$global_management_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/global-management-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1mlas01a.$global_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_management_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$global_management_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue1mlas01a.$global_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text
echo "global_management_las_instancea_hostname=cmlue1mlas01a.$global_management_private_domain"
echo "global_management_las_instancea_hostname_alias=lasa.$global_management_private_domain"


## Global Core Test Instances #########################################################################################
profile=$core_profile

# Create LinuxWebServer Security Group
global_core_lws_sg_id=$(aws ec2 create-security-group --group-name Core-LinuxWebServer-InstanceSecurityGroup \
                                                      --description Core-LinuxWebServer-InstanceSecurityGroup \
                                                      --vpc-id $global_core_vpc_id \
                                                      --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Core-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                      --query 'GroupId' \
                                                      --profile $profile --region us-east-1 --output text)
echo "global_core_lws_sg_id=$global_core_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $global_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text

# Create LinuxWebServer EIP
global_core_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Core-LinuxWebServer-EIPA},{Key=Hostname,Value=cmlue1clws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                --query 'AllocationId' \
                                                --profile $profile --region us-east-1 --output text)
echo "global_core_lws_eipa=$global_core_lws_eipa"

global_core_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $global_core_lws_eipa \
                                                                 --query 'Addresses[0].PublicIp' \
                                                                 --profile $profile --region us-east-1 --output text)
echo "global_core_lws_instancea_public_ip=$global_core_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/global-core-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1clws01a.$global_core_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_core_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$global_core_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue1clws01a.$global_core_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_core_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text
echo "global_core_lws_instancea_hostname=cmlue1clws01a.$global_core_public_domain"
echo "global_core_lws_instancea_hostname_alias=lwsa.$global_core_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/global-core-lwsa-user-data-$$.sh
sed -e "s/@hostname@/cmlue1clws01a.$global_core_private_domain/g" \
    -e "s/@motd@/CaMeLz Global Core Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

global_core_lws_instancea_id=$(aws ec2 run-instances --image-id $global_amzn2_ami_id \
                                                     --instance-type t3a.nano \
                                                     --iam-instance-profile Name=ManagedInstance \
                                                     --key-name administrator \
                                                     --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Core-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_core_lws_sg_id],SubnetId=$global_core_web_subneta_id \
                                                     --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Core-LinuxWebServer-InstanceA},{Key=Hostname,Value=cmlue1clws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                     --user-data file://$tmpfile \
                                                     --client-token $(date +%s) \
                                                     --query 'Instances[0].InstanceId' \
                                                     --profile $profile --region us-east-1 --output text)
echo "global_core_lws_instancea_id=$global_core_lws_instancea_id"

global_core_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $global_core_lws_instancea_id \
                                                                  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                  --profile $profile --region us-east-1 --output text)
echo "global_core_lws_instancea_private_ip=$global_core_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/global-core-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1clws01a.$global_core_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_core_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$global_core_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue1clws01a.$global_core_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_core_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text

aws ec2 associate-address --instance-id $global_core_lws_instancea_id --allocation-id $global_core_lws_eipa \
                          --profile $profile --region us-east-1 --output text

# Create LinuxApplicationServer Security Group
global_core_las_sg_id=$(aws ec2 create-security-group --group-name Core-LinuxApplicationServer-InstanceSecurityGroup \
                                                      --description Core-LinuxApplicationServer-InstanceSecurityGroup \
                                                      --vpc-id $global_core_vpc_id \
                                                      --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Core-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                      --query 'GroupId' \
                                                      --profile $profile --region us-east-1 --output text)
echo "global_core_las_sg_id=$global_core_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $global_core_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_core_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$global_core_lws_sg_id,Description=\"Core-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_core_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/global-core-lasa-user-data-$$.sh
sed -e "s/@hostname@/cmlue1clas01a.$global_core_private_domain/g" \
    -e "s/@motd@/CaMeLz Global Core Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

global_core_las_instancea_id=$(aws ec2 run-instances --image-id $global_amzn2_ami_id \
                                                     --instance-type t3a.nano \
                                                     --iam-instance-profile Name=ManagedInstance \
                                                     --key-name administrator \
                                                     --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Core-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_core_las_sg_id],SubnetId=$global_core_application_subneta_id \
                                                     --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Core-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=cmlue1clas01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4] \
                                                     --user-data file://$tmpfile \
                                                     --client-token $(date +%s) \
                                                     --query 'Instances[0].InstanceId' \
                                                     --profile $profile --region us-east-1 --output text)
echo "global_core_las_instancea_id=$global_core_las_instancea_id"

global_core_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $global_core_las_instancea_id \
                                                                  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                  --profile $profile --region us-east-1 --output text)
echo "global_core_las_instancea_private_ip=$global_core_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/global-core-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1clas01a.$global_core_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_core_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$global_core_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue1clas01a.$global_core_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_core_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text
echo "global_core_las_instancea_hostname=cmlue1clas01a.$global_core_private_domain"
echo "global_core_las_instancea_hostname_alias=lasa.$global_core_private_domain"


## Global Log Test Instances ##########################################################################################
profile=$log_profile

# Create LinuxWebServer Security Group
global_log_lws_sg_id=$(aws ec2 create-security-group --group-name Log-LinuxWebServer-InstanceSecurityGroup \
                                                     --description Log-LinuxWebServer-InstanceSecurityGroup \
                                                     --vpc-id $global_log_vpc_id \
                                                     --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Log-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                     --query 'GroupId' \
                                                     --profile $profile --region us-east-1 --output text)
echo "global_log_lws_sg_id=$global_log_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $global_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text

# Create LinuxWebServer EIP
global_log_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                               --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Log-LinuxWebServer-EIPA},{Key=Hostname,Value=cmlue1llws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                               --query 'AllocationId' \
                                               --profile $profile --region us-east-1 --output text)
echo "global_log_lws_eipa=$global_log_lws_eipa"

global_log_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $global_log_lws_eipa \
                                                                --query 'Addresses[0].PublicIp' \
                                                                --profile $profile --region us-east-1 --output text)
echo "global_log_lws_instancea_public_ip=$global_log_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/global-log-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1llws01a.$global_log_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_log_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$global_log_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue1llws01a.$global_log_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_log_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text
echo "global_log_lws_instancea_hostname=cmlue1llws01a.$global_log_public_domain"
echo "global_log_lws_instancea_hostname_alias=lwsa.$global_log_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/global-log-lwsa-user-data-$$.sh
sed -e "s/@hostname@/cmlue1llws01a.$global_log_private_domain/g" \
    -e "s/@motd@/CaMeLz Global Log Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

global_log_lws_instancea_id=$(aws ec2 run-instances --image-id $global_amzn2_ami_id \
                                                    --instance-type t3a.nano \
                                                    --iam-instance-profile Name=ManagedInstance \
                                                    --key-name administrator \
                                                    --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Log-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_log_lws_sg_id],SubnetId=$global_log_web_subneta_id \
                                                    --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Log-LinuxWebServer-InstanceA},{Key=Hostname,Value=cmlue1llws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                    --user-data file://$tmpfile \
                                                    --client-token $(date +%s) \
                                                    --query 'Instances[0].InstanceId' \
                                                    --profile $profile --region us-east-1 --output text)
echo "global_log_lws_instancea_id=$global_log_lws_instancea_id"

global_log_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $global_log_lws_instancea_id \
                                                                 --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                 --profile $profile --region us-east-1 --output text)
echo "global_log_lws_instancea_private_ip=$global_log_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/global-log-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1llws01a.$global_log_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_log_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$global_log_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue1llws01a.$global_log_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_log_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text

aws ec2 associate-address --instance-id $global_log_lws_instancea_id --allocation-id $global_log_lws_eipa \
                          --profile $profile --region us-east-1 --output text

# Create LinuxApplicationServer Security Group
global_log_las_sg_id=$(aws ec2 create-security-group --group-name Log-LinuxApplicationServer-InstanceSecurityGroup \
                                                     --description Log-LinuxApplicationServer-InstanceSecurityGroup \
                                                     --vpc-id $global_log_vpc_id \
                                                     --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Log-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                            --query 'GroupId' \
                                                     --profile $profile --region us-east-1 --output text)
echo "global_log_las_sg_id=$global_log_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $global_log_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_log_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$global_log_lws_sg_id,Description=\"Log-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_log_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-1 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/global-log-lasa-user-data-$$.sh
sed -e "s/@hostname@/cmlue1llas01a.$global_log_private_domain/g" \
    -e "s/@motd@/CaMeLz Global Log Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

global_log_las_instancea_id=$(aws ec2 run-instances --image-id $global_amzn2_ami_id \
                                                    --instance-type t3a.nano \
                                                    --iam-instance-profile Name=ManagedInstance \
                                                    --key-name administrator \
                                                    --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Log-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_log_las_sg_id],SubnetId=$global_log_application_subneta_id \
                                                    --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Log-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=cmlue1llas01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                    --user-data file://$tmpfile \
                                                    --client-token $(date +%s) \
                                                    --query 'Instances[0].InstanceId' \
                                                    --profile $profile --region us-east-1 --output text)
echo "global_log_las_instancea_id=$global_log_las_instancea_id"

global_log_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $global_log_las_instancea_id \
                                                                 --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                 --profile $profile --region us-east-1 --output text)
echo "global_log_las_instancea_private_ip=$global_log_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/global-log-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue1llas01a.$global_log_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$global_log_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$global_log_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue1llas01a.$global_log_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $global_log_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-1 --output text
echo "global_log_las_instancea_hostname=cmlue1llas01a.$global_log_private_domain"
echo "global_log_las_instancea_hostname_alias=lasa.$global_log_private_domain"


## Ohio Management Test Instances #####################################################################################
profile=$management_profile

# Create LinuxWebServer Security Group
ohio_management_lws_sg_id=$(aws ec2 create-security-group --group-name Management-LinuxWebServer-InstanceSecurityGroup \
                                                          --description Management-LinuxWebServer-InstanceSecurityGroup \
                                                          --vpc-id $ohio_management_vpc_id \
                                                          --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Management-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                          --query 'GroupId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "ohio_management_lws_sg_id=$ohio_management_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ohio_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxWebServer EIP
ohio_management_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                    --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Management-LinuxWebServer-EIPA},{Key=Hostname,Value=cmlue2mlws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                    --query 'AllocationId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_management_lws_eipa=$ohio_management_lws_eipa"

ohio_management_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $ohio_management_lws_eipa \
                                                                     --query 'Addresses[0].PublicIp' \
                                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_management_lws_instancea_public_ip=$ohio_management_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/ohio-management-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2mlws01a.$ohio_management_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_management_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$ohio_management_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue2mlws01a.$ohio_management_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_management_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "ohio_management_lws_instancea_hostname=cmlue2mlws01a.$ohio_management_public_domain"
echo "ohio_management_lws_instancea_hostname_alias=lwsa.$ohio_management_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/ohio-management-lwsa-user-data-$$.sh
sed -e "s/@hostname@/cmlue2mlws01a.$ohio_management_private_domain/g" \
    -e "s/@motd@/CaMeLz Ohio Management Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

ohio_management_lws_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                         --instance-type t3a.nano \
                                                         --iam-instance-profile Name=ManagedInstance \
                                                         --key-name administrator \
                                                         --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_management_lws_sg_id],SubnetId=$ohio_management_web_subneta_id \
                                                         --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Management-LinuxWebServer-InstanceA},{Key=Hostname,Value=cmlue2mlws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                         --user-data file://$tmpfile \
                                                         --client-token $(date +%s) \
                                                         --query 'Instances[0].InstanceId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "ohio_management_lws_instancea_id=$ohio_management_lws_instancea_id"

ohio_management_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_management_lws_instancea_id \
                                                                      --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                      --profile $profile --region us-east-2 --output text)
echo "ohio_management_lws_instancea_private_ip=$ohio_management_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/ohio-management-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2mlws01a.$ohio_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_management_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$ohio_management_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue2mlws01a.$ohio_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $ohio_management_lws_instancea_id --allocation-id $ohio_management_lws_eipa \
                          --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Security Group
ohio_management_las_sg_id=$(aws ec2 create-security-group --group-name Management-LinuxApplicationServer-InstanceSecurityGroup \
                                                          --description Management-LinuxApplicationServer-InstanceSecurityGroup \
                                                          --vpc-id $ohio_management_vpc_id \
                                                          --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Management-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                          --query 'GroupId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "ohio_management_las_sg_id=$ohio_management_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ohio_management_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_management_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$ohio_management_lws_sg_id,Description=\"Management-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_management_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/ohio-management-lasa-user-data-$$.sh
sed -e "s/@hostname@/cmlue2mlas01a.$ohio_management_private_domain/g" \
    -e "s/@motd@/CaMeLz Ohio Management Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

ohio_management_las_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                         --instance-type t3a.nano \
                                                         --iam-instance-profile Name=ManagedInstance \
                                                         --key-name administrator \
                                                         --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_management_las_sg_id],SubnetId=$ohio_management_application_subneta_id \
                                                         --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Management-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=cmlue2mlas01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                         --user-data file://$tmpfile \
                                                         --client-token $(date +%s) \
                                                         --query 'Instances[0].InstanceId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "ohio_management_las_instancea_id=$ohio_management_las_instancea_id"

ohio_management_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_management_las_instancea_id \
                                                                      --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                      --profile $profile --region us-east-2 --output text)
echo "ohio_management_las_instancea_private_ip=$ohio_management_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/ohio-management-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2mlas01a.$ohio_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_management_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$ohio_management_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue2mlas01a.$ohio_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "ohio_management_las_instancea_hostname=cmlue2mlas01a.$ohio_management_private_domain"
echo "ohio_management_las_instancea_hostname_alias=lasa.$ohio_management_private_domain"


## Ohio Core Test Instances ###########################################################################################
profile=$core_profile

# Create LinuxWebServer Security Group
ohio_core_lws_sg_id=$(aws ec2 create-security-group --group-name Core-LinuxWebServer-InstanceSecurityGroup \
                                                    --description Core-LinuxWebServer-InstanceSecurityGroup \
                                                    --vpc-id $ohio_core_vpc_id \
                                                    --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Core-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                    --query 'GroupId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_core_lws_sg_id=$ohio_core_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ohio_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxWebServer EIP
ohio_core_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                              --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Core-LinuxWebServer-EIPA},{Key=Hostname,Value=cmlue2clws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                              --query 'AllocationId' \
                                              --profile $profile --region us-east-2 --output text)
echo "ohio_core_lws_eipa=$ohio_core_lws_eipa"

ohio_core_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $ohio_core_lws_eipa \
                                                               --query 'Addresses[0].PublicIp' \
                                                               --profile $profile --region us-east-2 --output text)
echo "ohio_core_lws_instancea_public_ip=$ohio_core_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/ohio-core-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2clws01a.$ohio_core_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_core_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$ohio_core_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue2clws01a.$ohio_core_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_core_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "ohio_core_lws_instancea_hostname=cmlue2clws01a.$ohio_core_public_domain"
echo "ohio_core_lws_instancea_hostname_alias=lwsa.$ohio_core_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/ohio-core-lwsa-user-data-$$.sh
sed -e "s/@hostname@/cmlue2clws01a.$ohio_core_private_domain/g" \
    -e "s/@motd@/CaMeLz Ohio Core Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

ohio_core_lws_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                   --instance-type t3a.nano \
                                                   --iam-instance-profile Name=ManagedInstance \
                                                   --key-name administrator \
                                                   --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Core-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_core_lws_sg_id],SubnetId=$ohio_core_web_subneta_id \
                                                   --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Core-LinuxWebServer-InstanceA},{Key=Hostname,Value=cmlue2clws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                   --user-data file://$tmpfile \
                                                   --client-token $(date +%s) \
                                                   --query 'Instances[0].InstanceId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "ohio_core_lws_instancea_id=$ohio_core_lws_instancea_id"

ohio_core_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_core_lws_instancea_id \
                                                                --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                --profile $profile --region us-east-2 --output text)
echo "ohio_core_lws_instancea_private_ip=$ohio_core_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/ohio-core-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2clws01a.$ohio_core_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_core_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$ohio_core_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue2clws01a.$ohio_core_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_core_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $ohio_core_lws_instancea_id --allocation-id $ohio_core_lws_eipa \
                          --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Security Group
ohio_core_las_sg_id=$(aws ec2 create-security-group --group-name Core-LinuxApplicationServer-InstanceSecurityGroup \
                                                    --description Core-LinuxApplicationServer-InstanceSecurityGroup \
                                                    --vpc-id $ohio_core_vpc_id \
                                                    --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Core-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                    --query 'GroupId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_core_las_sg_id=$ohio_core_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ohio_core_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_core_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$ohio_core_lws_sg_id,Description=\"Core-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_core_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/ohio-core-lasa-user-data-$$.sh
sed -e "s/@hostname@/cmlue2clas01a.$ohio_core_private_domain/g" \
    -e "s/@motd@/CaMeLz Ohio Core Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

ohio_core_las_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                   --instance-type t3a.nano \
                                                   --iam-instance-profile Name=ManagedInstance \
                                                   --key-name administrator \
                                                   --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Core-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_core_las_sg_id],SubnetId=$ohio_core_application_subneta_id \
                                                   --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Core-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=cmlue2clas01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                   --user-data file://$tmpfile \
                                                   --client-token $(date +%s) \
                                                   --query 'Instances[0].InstanceId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "ohio_core_las_instancea_id=$ohio_core_las_instancea_id"

ohio_core_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_core_las_instancea_id \
                                                                --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                --profile $profile --region us-east-2 --output text)
echo "ohio_core_las_instancea_private_ip=$ohio_core_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/ohio-core-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2clas01a.$ohio_core_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_core_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$ohio_core_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue2clas01a.$ohio_core_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_core_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "ohio_core_las_instancea_hostname=cmlue2clas01a.$ohio_core_private_domain"
echo "ohio_core_las_instancea_hostname_alias=lasa.$ohio_core_private_domain"


## Ohio Log Test Instances ############################################################################################
profile=$log_profile

# Create LinuxWebServer Security Group
ohio_log_lws_sg_id=$(aws ec2 create-security-group --group-name Log-LinuxWebServer-InstanceSecurityGroup \
                                                   --description Log-LinuxWebServer-InstanceSecurityGroup \
                                                   --vpc-id $ohio_log_vpc_id \
                                                   --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Log-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "ohio_log_lws_sg_id=$ohio_log_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ohio_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxWebServer EIP
ohio_log_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                             --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Log-LinuxWebServer-EIPA},{Key=Hostname,Value=cmlue2llws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                             --query 'AllocationId' \
                                             --profile $profile --region us-east-2 --output text)
echo "ohio_log_lws_eipa=$ohio_log_lws_eipa"

ohio_log_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $ohio_log_lws_eipa \
                                                              --query 'Addresses[0].PublicIp' \
                                                              --profile $profile --region us-east-2 --output text)
echo "ohio_log_lws_instancea_public_ip=$ohio_log_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/ohio-log-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2llws01a.$ohio_log_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_log_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$ohio_log_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue2llws01a.$ohio_log_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_log_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "ohio_log_lws_instancea_hostname=cmlue2llws01a.$ohio_log_public_domain"
echo "ohio_log_lws_instancea_hostname_alias=lwsa.$ohio_log_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/ohio-log-lwsa-user-data-$$.sh
sed -e "s/@hostname@/cmlue2llws01a.$ohio_log_private_domain/g" \
    -e "s/@motd@/CaMeLz Ohio Log Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

ohio_log_lws_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                  --instance-type t3a.nano \
                                                  --iam-instance-profile Name=ManagedInstance \
                                                  --key-name administrator \
                                                  --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Log-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_log_lws_sg_id],SubnetId=$ohio_log_web_subneta_id \
                                                  --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Log-LinuxWebServer-InstanceA},{Key=Hostname,Value=cmlue2llws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --user-data file://$tmpfile \
                                                  --client-token $(date +%s) \
                                                  --query 'Instances[0].InstanceId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "ohio_log_lws_instancea_id=$ohio_log_lws_instancea_id"

ohio_log_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_log_lws_instancea_id \
                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                               --profile $profile --region us-east-2 --output text)
echo "ohio_log_lws_instancea_private_ip=$ohio_log_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/ohio-log-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2llws01a.$ohio_log_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_log_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$ohio_log_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue2llws01a.$ohio_log_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_log_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $ohio_log_lws_instancea_id --allocation-id $ohio_log_lws_eipa \
                          --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Security Group
ohio_log_las_sg_id=$(aws ec2 create-security-group --group-name Log-LinuxApplicationServer-InstanceSecurityGroup \
                                                   --description Log-LinuxApplicationServer-InstanceSecurityGroup \
                                                   --vpc-id $ohio_log_vpc_id \
                                                   --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Log-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "ohio_log_las_sg_id=$ohio_log_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ohio_log_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_log_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$ohio_log_lws_sg_id,Description=\"Log-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_log_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/ohio-log-lasa-user-data-$$.sh
sed -e "s/@hostname@/cmlue2llas01a.$ohio_log_private_domain/g" \
    -e "s/@motd@/CaMeLz Ohio Log Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

ohio_log_las_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                  --instance-type t3a.nano \
                                                  --iam-instance-profile Name=ManagedInstance \
                                                  --key-name administrator \
                                                  --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Log-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_log_las_sg_id],SubnetId=$ohio_log_application_subneta_id \
                                                  --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Log-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=cmlue2llas01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --user-data file://$tmpfile \
                                                  --client-token $(date +%s) \
                                                  --query 'Instances[0].InstanceId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "ohio_log_las_instancea_id=$ohio_log_las_instancea_id"

ohio_log_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_log_las_instancea_id \
                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                               --profile $profile --region us-east-2 --output text)
echo "ohio_log_las_instancea_private_ip=$ohio_log_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/ohio-log-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlue2llas01a.$ohio_log_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ohio_log_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$ohio_log_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlue2llas01a.$ohio_log_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ohio_log_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "ohio_log_las_instancea_hostname=cmlue2llas01a.$ohio_log_private_domain"
echo "ohio_log_las_instancea_hostname_alias=lasa.$ohio_log_private_domain"


## Alfa Ohio Production Test Instances ################################################################################
profile=$production_profile

# Create LinuxWebServer Security Group
alfa_ohio_production_lws_sg_id=$(aws ec2 create-security-group --group-name Alfa-Production-LinuxWebServer-InstanceSecurityGroup \
                                                               --description Alfa-Production-LinuxWebServer-InstanceSecurityGroup \
                                                               --vpc-id $alfa_ohio_production_vpc_id \
                                                               --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Production-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --query 'GroupId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_lws_sg_id=$alfa_ohio_production_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxWebServer EIP
alfa_ohio_production_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                         --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Production-LinuxWebServer-EIPA},{Key=Hostname,Value=alfue2plws01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                         --query 'AllocationId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_lws_eipa=$alfa_ohio_production_lws_eipa"

alfa_ohio_production_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_ohio_production_lws_eipa \
                                                                          --query 'Addresses[0].PublicIp' \
                                                                          --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_lws_instancea_public_ip=$alfa_ohio_production_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/alfa-ohio-production-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2plws01a.$alfa_ohio_production_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_production_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$alfa_ohio_production_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfue2plws01a.$alfa_ohio_production_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_production_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_ohio_production_lws_instancea_hostname=alfue2plws01a.$alfa_ohio_production_public_domain"
echo "alfa_ohio_production_lws_instancea_hostname_alias=lwsa.$alfa_ohio_production_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/alfa-ohio-production-lwsa-user-data-$$.sh
sed -e "s/@hostname@/alfue2plws01a.$alfa_ohio_production_private_domain/g" \
    -e "s/@motd@/CaMeLz Alfa Ohio Production Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

alfa_ohio_production_lws_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                              --instance-type t3a.nano \
                                                              --iam-instance-profile Name=ManagedInstance \
                                                              --key-name administrator \
                                                              --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Production-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_production_lws_sg_id],SubnetId=$alfa_ohio_production_web_subneta_id \
                                                              --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Production-LinuxWebServer-InstanceA},{Key=Hostname,Value=alfue2plws01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                              --user-data file://$tmpfile \
                                                              --client-token $(date +%s) \
                                                              --query 'Instances[0].InstanceId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_lws_instancea_id=$alfa_ohio_production_lws_instancea_id"

alfa_ohio_production_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_production_lws_instancea_id \
                                                                           --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_lws_instancea_private_ip=$alfa_ohio_production_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/alfa-ohio-production-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2plws01a.$alfa_ohio_production_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_production_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$alfa_ohio_production_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfue2plws01a.$alfa_ohio_production_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_production_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $alfa_ohio_production_lws_instancea_id --allocation-id $alfa_ohio_production_lws_eipa \
                          --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Security Group
alfa_ohio_production_las_sg_id=$(aws ec2 create-security-group --group-name Alfa-Production-LinuxApplicationServer-InstanceSecurityGroup \
                                                               --description Alfa-Production-LinuxApplicationServer-InstanceSecurityGroup \
                                                               --vpc-id $alfa_ohio_production_vpc_id \
                                                               --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Production-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --query 'GroupId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_las_sg_id=$alfa_ohio_production_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text


aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$alfa_ohio_production_lws_sg_id,Description=\"Alfa-Production-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/alfa-ohio-production-lasa-user-data-$$.sh
sed -e "s/@hostname@/alfue2plas01a.$alfa_ohio_production_private_domain/g" \
    -e "s/@motd@/CaMeLz Alfa Ohio Production Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

alfa_ohio_production_las_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                              --instance-type t3a.nano \
                                                              --iam-instance-profile Name=ManagedInstance \
                                                              --key-name administrator \
                                                              --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Production-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_production_las_sg_id],SubnetId=$alfa_ohio_production_application_subneta_id \
                                                              --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Production-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=alfue2plas01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                              --user-data file://$tmpfile \
                                                              --client-token $(date +%s) \
                                                              --query 'Instances[0].InstanceId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_las_instancea_id=$alfa_ohio_production_las_instancea_id"

alfa_ohio_production_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_production_las_instancea_id \
                                                                           --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_las_instancea_private_ip=$alfa_ohio_production_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/alfa-ohio-production-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2plas01a.$alfa_ohio_production_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_production_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$alfa_ohio_production_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfue2plas01a.$alfa_ohio_production_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_production_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_ohio_production_las_instancea_hostname=alfue2plas01a.$alfa_ohio_production_private_domain"
echo "alfa_ohio_production_las_instancea_hostname_alias=lasa.$alfa_ohio_production_private_domain"


## Alfa Ohio Testing Test Instances ###################################################################################
profile=$testing_profile

# Create LinuxWebServer Security Group
alfa_ohio_testing_lws_sg_id=$(aws ec2 create-security-group --group-name Alfa-Testing-LinuxWebServer-InstanceSecurityGroup \
                                                            --description Alfa-Testing-LinuxWebServer-InstanceSecurityGroup \
                                                            --vpc-id $alfa_ohio_testing_vpc_id \
                                                            --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Testing-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --query 'GroupId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_lws_sg_id=$alfa_ohio_testing_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxWebServer EIP
alfa_ohio_testing_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                      --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Testing-LinuxWebServer-EIPA},{Key=Hostname,Value=alfue2tlws01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                      --query 'AllocationId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_lws_eipa=$alfa_ohio_testing_lws_eipa"

alfa_ohio_testing_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_ohio_testing_lws_eipa \
                                                                       --query 'Addresses[0].PublicIp' \
                                                                       --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_lws_instancea_public_ip=$alfa_ohio_testing_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/alfa-ohio-testing-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2tlws01a.$alfa_ohio_testing_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_testing_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$alfa_ohio_testing_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfue2tlws01a.$alfa_ohio_testing_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_testing_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_ohio_testing_lws_instancea_hostname=alfue2tlws01a.$alfa_ohio_testing_public_domain"
echo "alfa_ohio_testing_lws_instancea_hostname_alias=lwsa.$alfa_ohio_testing_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/alfa-ohio-testing-lwsa-user-data-$$.sh
sed -e "s/@hostname@/alfue2tlws01a.$alfa_ohio_testing_private_domain/g" \
    -e "s/@motd@/CaMeLz Alfa Ohio Testing Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

alfa_ohio_testing_lws_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                           --instance-type t3a.nano \
                                                           --iam-instance-profile Name=ManagedInstance \
                                                           --key-name administrator \
                                                           --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Testing-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_testing_lws_sg_id],SubnetId=$alfa_ohio_testing_web_subneta_id \
                                                           --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Testing-LinuxWebServer-InstanceA},{Key=Hostname,Value=alfue2tlws01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                           --user-data file://$tmpfile \
                                                           --client-token $(date +%s) \
                                                           --query 'Instances[0].InstanceId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_lws_instancea_id=$alfa_ohio_testing_lws_instancea_id"

alfa_ohio_testing_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_testing_lws_instancea_id \
                                                                        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                        --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_lws_instancea_private_ip=$alfa_ohio_testing_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/alfa-ohio-testing-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2tlws01a.$alfa_ohio_testing_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_testing_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$alfa_ohio_testing_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfue2tlws01a.$alfa_ohio_testing_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_testing_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $alfa_ohio_testing_lws_instancea_id --allocation-id $alfa_ohio_testing_lws_eipa \
                          --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Security Group
alfa_ohio_testing_las_sg_id=$(aws ec2 create-security-group --group-name Alfa-Testing-LinuxApplicationServer-InstanceSecurityGroup \
                                                            --description Alfa-Testing-LinuxApplicationServer-InstanceSecurityGroup \
                                                            --vpc-id $alfa_ohio_testing_vpc_id \
                                                            --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Testing-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                            --query 'GroupId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_las_sg_id=$alfa_ohio_testing_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text


aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$alfa_ohio_testing_lws_sg_id,Description=\"Alfa-Testing-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/alfa-ohio-testing-lasa-user-data-$$.sh
sed -e "s/@hostname@/alfue2tlas01a.$alfa_ohio_testing_private_domain/g" \
    -e "s/@motd@/CaMeLz Alfa Ohio Testing Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

alfa_ohio_testing_las_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                           --instance-type t3a.nano \
                                                           --iam-instance-profile Name=ManagedInstance \
                                                           --key-name administrator \
                                                           --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Testing-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_testing_las_sg_id],SubnetId=$alfa_ohio_testing_application_subneta_id \
                                                           --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Testing-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=alfue2tlas01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                           --user-data file://$tmpfile \
                                                           --client-token $(date +%s) \
                                                           --query 'Instances[0].InstanceId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_las_instancea_id=$alfa_ohio_testing_las_instancea_id"

alfa_ohio_testing_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_testing_las_instancea_id \
                                                                        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                        --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_las_instancea_private_ip=$alfa_ohio_testing_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/alfa-ohio-testing-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2tlas01a.$alfa_ohio_testing_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_testing_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$alfa_ohio_testing_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfue2tlas01a.$alfa_ohio_testing_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_testing_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_ohio_testing_las_instancea_hostname=alfue2tlas01a.$alfa_ohio_testing_private_domain"
echo "alfa_ohio_testing_las_instancea_hostname_alias=lasa.$alfa_ohio_testing_private_domain"


## Alfa Ohio Development Test Instances ###############################################################################
profile=$development_profile

# Create LinuxWebServer Security Group
alfa_ohio_development_lws_sg_id=$(aws ec2 create-security-group --group-name Alfa-Development-LinuxWebServer-InstanceSecurityGroup \
                                                                --description Alfa-Development-LinuxWebServer-InstanceSecurityGroup \
                                                                --vpc-id $alfa_ohio_development_vpc_id \
                                                                --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Development-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Development},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_lws_sg_id=$alfa_ohio_development_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxWebServer EIP
alfa_ohio_development_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                          --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Development-LinuxWebServer-EIPA},{Key=Hostname,Value=alfue2dlws01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Development},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                          --query 'AllocationId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_lws_eipa=$alfa_ohio_development_lws_eipa"

alfa_ohio_development_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_ohio_development_lws_eipa \
                                                                           --query 'Addresses[0].PublicIp' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_lws_instancea_public_ip=$alfa_ohio_development_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/alfa-ohio-development-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2dlws01a.$alfa_ohio_development_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_development_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$alfa_ohio_development_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfue2dlws01a.$alfa_ohio_development_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_development_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_ohio_development_lws_instancea_hostname=alfue2dlws01a.$alfa_ohio_development_public_domain"
echo "alfa_ohio_development_lws_instancea_hostname_alias=lwsa.$alfa_ohio_development_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/alfa-ohio-development-lwsa-user-data-$$.sh
sed -e "s/@hostname@/alfue2dlws01a.$alfa_ohio_development_private_domain/g" \
    -e "s/@motd@/CaMeLz Alfa Ohio Development Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

alfa_ohio_development_lws_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                               --instance-type t3a.nano \
                                                               --iam-instance-profile Name=ManagedInstance \
                                                               --key-name administrator \
                                                               --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Development-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_development_lws_sg_id],SubnetId=$alfa_ohio_development_web_subneta_id \
                                                               --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Development-LinuxWebServer-InstanceA},{Key=Hostname,Value=alfue2dlws01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Development},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --user-data file://$tmpfile \
                                                               --client-token $(date +%s) \
                                                               --query 'Instances[0].InstanceId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_lws_instancea_id=$alfa_ohio_development_lws_instancea_id"

alfa_ohio_development_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_development_lws_instancea_id \
                                                                            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_lws_instancea_private_ip=$alfa_ohio_development_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/alfa-ohio-development-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2dlws01a.$alfa_ohio_development_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_development_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$alfa_ohio_development_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfue2dlws01a.$alfa_ohio_development_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_development_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $alfa_ohio_development_lws_instancea_id --allocation-id $alfa_ohio_development_lws_eipa \
                          --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Security Group
alfa_ohio_development_las_sg_id=$(aws ec2 create-security-group --group-name Alfa-Development-LinuxApplicationServer-InstanceSecurityGroup \
                                                                --description Alfa-Development-LinuxApplicationServer-InstanceSecurityGroup \
                                                                --vpc-id $alfa_ohio_development_vpc_id \
                                                                --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Development-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Development},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_las_sg_id=$alfa_ohio_development_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text


aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$alfa_ohio_development_lws_sg_id,Description=\"Alfa-Development-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/alfa-ohio-development-lasa-user-data-$$.sh
sed -e "s/@hostname@/alfue2dlas01a.$alfa_ohio_development_private_domain/g" \
    -e "s/@motd@/CaMeLz Alfa Ohio Development Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

alfa_ohio_development_las_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                               --instance-type t3a.nano \
                                                               --iam-instance-profile Name=ManagedInstance \
                                                               --key-name administrator \
                                                               --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Development-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_development_las_sg_id],SubnetId=$alfa_ohio_development_application_subneta_id \
                                                               --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Development-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=alfue2dlas01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Development},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --user-data file://$tmpfile \
                                                               --client-token $(date +%s) \
                                                               --query 'Instances[0].InstanceId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_las_instancea_id=$alfa_ohio_development_las_instancea_id"

alfa_ohio_development_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_development_las_instancea_id \
                                                                            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_las_instancea_private_ip=$alfa_ohio_development_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/alfa-ohio-development-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfue2dlas01a.$alfa_ohio_development_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ohio_development_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$alfa_ohio_development_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfue2dlas01a.$alfa_ohio_development_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ohio_development_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_ohio_development_las_instancea_hostname=alfue2dlas01a.$alfa_ohio_development_private_domain"
echo "alfa_ohio_development_las_instancea_hostname_alias=lasa.$alfa_ohio_development_private_domain"


## Zulu Ohio Production Test Instances ################################################################################
profile=$production_profile

# Create LinuxWebServer Security Group
zulu_ohio_production_lws_sg_id=$(aws ec2 create-security-group --group-name Zulu-Production-LinuxWebServer-InstanceSecurityGroup \
                                                               --description Zulu-Production-LinuxWebServer-InstanceSecurityGroup \
                                                               --vpc-id $zulu_ohio_production_vpc_id \
                                                               --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Production-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --query 'GroupId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_lws_sg_id=$zulu_ohio_production_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"DataCenter-Zulu-Dallas (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"DataCenter-Zulu-Dallas (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxWebServer EIP
zulu_ohio_production_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                         --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Zulu-Production-LinuxWebServer-EIPA},{Key=Hostname,Value=zulue2plws01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                         --query 'AllocationId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_lws_eipa=$zulu_ohio_production_lws_eipa"

zulu_ohio_production_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $zulu_ohio_production_lws_eipa \
                                                                          --query 'Addresses[0].PublicIp' \
                                                                          --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_lws_instancea_public_ip=$zulu_ohio_production_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/zulu-ohio-production-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zulue2plws01a.$zulu_ohio_production_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_ohio_production_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$zulu_ohio_production_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "zulue2plws01a.$zulu_ohio_production_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_ohio_production_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "zulu_ohio_production_lws_instancea_hostname=zulue2plws01a.$zulu_ohio_production_public_domain"
echo "zulu_ohio_production_lws_instancea_hostname_alias=lwsa.$zulu_ohio_production_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/zulu-ohio-production-lwsa-user-data-$$.sh
sed -e "s/@hostname@/zulue2plws01a.$zulu_ohio_production_private_domain/g" \
    -e "s/@motd@/CaMeLz Zulu Ohio Production Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

zulu_ohio_production_lws_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                              --instance-type t3a.nano \
                                                              --iam-instance-profile Name=ManagedInstance \
                                                              --key-name administrator \
                                                              --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Zulu-Production-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_ohio_production_lws_sg_id],SubnetId=$zulu_ohio_production_web_subneta_id \
                                                              --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Production-LinuxWebServer-InstanceA},{Key=Hostname,Value=zulue2plws01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                              --user-data file://$tmpfile \
                                                              --client-token $(date +%s) \
                                                              --query 'Instances[0].InstanceId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_lws_instancea_id=$zulu_ohio_production_lws_instancea_id"

zulu_ohio_production_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_ohio_production_lws_instancea_id \
                                                                           --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_lws_instancea_private_ip=$zulu_ohio_production_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/zulu-ohio-production-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zulue2plws01a.$zulu_ohio_production_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_ohio_production_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$zulu_ohio_production_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "zulue2plws01a.$zulu_ohio_production_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_ohio_production_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $zulu_ohio_production_lws_instancea_id --allocation-id $zulu_ohio_production_lws_eipa \
                          --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Security Group
zulu_ohio_production_las_sg_id=$(aws ec2 create-security-group --group-name Zulu-Production-LinuxApplicationServer-InstanceSecurityGroup \
                                                               --description Zulu-Production-LinuxApplicationServer-InstanceSecurityGroup \
                                                               --vpc-id $zulu_ohio_production_vpc_id \
                                                               --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Production-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                            --query 'GroupId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_las_sg_id=$zulu_ohio_production_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$zulu_ohio_production_lws_sg_id,Description=\"Zulu-Production-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"DataCenter-Zulu-Dallas (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/zulu-ohio-production-lasa-user-data-$$.sh
sed -e "s/@hostname@/zulue2plas01a.$zulu_ohio_production_private_domain/g" \
    -e "s/@motd@/CaMeLz Zulu Ohio Production Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

zulu_ohio_production_las_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                              --instance-type t3a.nano \
                                                              --iam-instance-profile Name=ManagedInstance \
                                                              --key-name administrator \
                                                              --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Zulu-Production-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_ohio_production_las_sg_id],SubnetId=$zulu_ohio_production_application_subneta_id \
                                                              --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Production-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=zulue2plas01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                              --user-data file://$tmpfile \
                                                              --client-token $(date +%s) \
                                                              --query 'Instances[0].InstanceId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_las_instancea_id=$zulu_ohio_production_las_instancea_id"

zulu_ohio_production_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_ohio_production_las_instancea_id \
                                                                           --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_las_instancea_private_ip=$zulu_ohio_production_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/zulu-ohio-production-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zulue2plas01a.$zulu_ohio_production_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_ohio_production_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$zulu_ohio_production_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "zulue2plas01a.$zulu_ohio_production_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_ohio_production_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "zulu_ohio_production_las_instancea_hostname=zulue2plas01a.$zulu_ohio_production_private_domain"
echo "zulu_ohio_production_las_instancea_hostname_alias=lasa.$zulu_ohio_production_private_domain"


## Zulu Ohio Development Test Instances ###############################################################################
profile=$development_profile

# Create LinuxWebServer Security Group
zulu_ohio_development_lws_sg_id=$(aws ec2 create-security-group --group-name Zulu-Development-LinuxWebServer-InstanceSecurityGroup \
                                                                --description Zulu-Development-LinuxWebServer-InstanceSecurityGroup \
                                                                --vpc-id $zulu_ohio_development_vpc_id \
                                                                --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Development-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=Zulu},{Key=Environment,Value=Development},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_lws_sg_id=$zulu_ohio_development_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"DataCenter-Zulu-Dallas (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"DataCenter-Zulu-Dallas (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxWebServer EIP
zulu_ohio_development_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                          --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Zulu-Development-LinuxWebServer-EIPA},{Key=Hostname,Value=zulue2dlws01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Development},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                          --query 'AllocationId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_lws_eipa=$zulu_ohio_development_lws_eipa"

zulu_ohio_development_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $zulu_ohio_development_lws_eipa \
                                                                           --query 'Addresses[0].PublicIp' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_lws_instancea_public_ip=$zulu_ohio_development_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/zulu-ohio-development-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zulue2dlws01a.$zulu_ohio_development_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_ohio_development_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$zulu_ohio_development_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "zulue2dlws01a.$zulu_ohio_development_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_ohio_development_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "zulu_ohio_development_lws_instancea_hostname=zulue2dlws01a.$zulu_ohio_development_public_domain"
echo "zulu_ohio_development_lws_instancea_hostname_alias=lwsa.$zulu_ohio_development_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/zulu-ohio-development-lwsa-user-data-$$.sh
sed -e "s/@hostname@/zulue2dlws01a.$zulu_ohio_development_private_domain/g" \
    -e "s/@motd@/CaMeLz Zulu Ohio Development Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

zulu_ohio_development_lws_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                               --instance-type t3a.nano \
                                                               --iam-instance-profile Name=ManagedInstance \
                                                               --key-name administrator \
                                                               --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Zulu-Development-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_ohio_development_lws_sg_id],SubnetId=$zulu_ohio_development_web_subneta_id" \
                                                               --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Development-LinuxWebServer-InstanceA},{Key=Hostname,Value=zulue2dlws01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Development},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --user-data file://$tmpfile \
                                                               --client-token $(date +%s) \
                                                               --query 'Instances[0].InstanceId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_lws_instancea_id=$zulu_ohio_development_lws_instancea_id"

zulu_ohio_development_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_ohio_development_lws_instancea_id \
                                                                            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                            --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_lws_instancea_private_ip=$zulu_ohio_development_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/zulu-ohio-development-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zulue2dlws01a.$zulu_ohio_development_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_ohio_development_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$zulu_ohio_development_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "zulue2dlws01a.$zulu_ohio_development_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_ohio_development_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $zulu_ohio_development_lws_instancea_id --allocation-id $zulu_ohio_development_lws_eipa \
                          --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Security Group
zulu_ohio_development_las_sg_id=$(aws ec2 create-security-group --group-name Zulu-Development-LinuxApplicationServer-InstanceSecurityGroup \
                                                                --description Zulu-Development-LinuxApplicationServer-InstanceSecurityGroup \
                                                                --vpc-id $zulu_ohio_development_vpc_id \
                                                                --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Development-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=Zulu},{Key=Environment,Value=Development},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_las_sg_id=$zulu_ohio_development_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$zulu_ohio_development_lws_sg_id,Description=\"Zulu-Production-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"DataCenter-Zulu-Dallas (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/zulu-ohio-development-lasa-user-data-$$.sh
sed -e "s/@hostname@/zulue2dlas01a.$zulu_ohio_development_private_domain/g" \
    -e "s/@motd@/CaMeLz Zulu Ohio Development Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

zulu_ohio_development_las_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                               --instance-type t3a.nano \
                                                               --iam-instance-profile Name=ManagedInstance \
                                                               --key-name administrator \
                                                               --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Zulu-Development-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_ohio_development_las_sg_id],SubnetId=$zulu_ohio_development_application_subneta_id \
                                                               --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Development-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=zulue2dlas01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Development},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --user-data file://$tmpfile \
                                                               --client-token $(date +%s) \
                                                               --query 'Instances[0].InstanceId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_las_instancea_id=$zulu_ohio_development_las_instancea_id"

zulu_ohio_development_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_ohio_development_las_instancea_id \
                                                                            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                            --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_las_instancea_private_ip=$zulu_ohio_development_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/zulu-ohio-development-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zulue2dlas01a.$zulu_ohio_development_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_ohio_development_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$zulu_ohio_development_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "zulue2dlas01a.$zulu_ohio_development_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_ohio_development_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "zulu_ohio_development_las_instancea_hostname=zulue2dlas01a.$zulu_ohio_development_private_domain"
echo "zulu_ohio_development_las_instancea_hostname_alias=lasa.$zulu_ohio_development_private_domain"


## Ireland Management Test Instances ##################################################################################
profile=$management_profile

# Create LinuxWebServer Security Group
ireland_management_lws_sg_id=$(aws ec2 create-security-group --group-name Management-LinuxWebServer-InstanceSecurityGroup \
                                                             --description Management-LinuxWebServer-InstanceSecurityGroup \
                                                             --vpc-id $ireland_management_vpc_id \
                                                             --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Management-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                             --query 'GroupId' \
                                                             --profile $profile --region eu-west-1 --output text)
echo "ireland_management_lws_sg_id=$ireland_management_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ireland_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_management_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create LinuxWebServer EIP
ireland_management_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                       --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Management-LinuxWebServer-EIPA},{Key=Hostname,Value=cmluw1mlws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                       --query 'AllocationId' \
                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_management_lws_eipa=$ireland_management_lws_eipa"

ireland_management_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $ireland_management_lws_eipa \
                                                                        --query 'Addresses[0].PublicIp' \
                                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_management_lws_instancea_public_ip=$ireland_management_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/ireland-management-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1mlws01a.$ireland_management_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_management_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$ireland_management_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlew1mlws01a.$ireland_management_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_management_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "ireland_management_lws_instancea_hostname=cmlew1mlws01a.$ireland_management_public_domain"
echo "ireland_management_lws_instancea_hostname_alias=lwsa.$ireland_management_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/ireland-management-lwsa-user-data-$$.sh
sed -e "s/@hostname@/cmlew1mlws01a.$ireland_management_private_domain/g" \
    -e "s/@motd@/CaMeLz Ireland Management Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

ireland_management_lws_instancea_id=$(aws ec2 run-instances --image-id $ireland_amzn2_ami_id \
                                                            --instance-type t3a.nano \
                                                            --iam-instance-profile Name=ManagedInstance \
                                                            --key-name administrator \
                                                            --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ireland_management_lws_sg_id],SubnetId=$ireland_management_web_subneta_id \
                                                            --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Management-LinuxWebServer-InstanceA},{Key=Hostname,Value=cmlew1mlws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                            --user-data file://$tmpfile \
                                                            --client-token $(date +%s) \
                                                            --query 'Instances[0].InstanceId' \
                                                            --profile $profile --region eu-west-1 --output text)
echo "ireland_management_lws_instancea_id=$ireland_management_lws_instancea_id"

ireland_management_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ireland_management_lws_instancea_id \
                                                                         --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_management_lws_instancea_private_ip=$ireland_management_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/ireland-management-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1mlws01a.$ireland_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_management_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$ireland_management_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlew1mlws01a.$ireland_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text

aws ec2 associate-address --instance-id $ireland_management_lws_instancea_id --allocation-id $ireland_management_lws_eipa \
                          --profile $profile --region eu-west-1 --output text

# Create LinuxApplicationServer Security Group
ireland_management_las_sg_id=$(aws ec2 create-security-group --group-name Management-LinuxApplicationServer-InstanceSecurityGroup \
                                                             --description Management-LinuxApplicationServer-InstanceSecurityGroup \
                                                             --vpc-id $ireland_management_vpc_id \
                                                             --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Management-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                             --query 'GroupId' \
                                                             --profile $profile --region eu-west-1 --output text)
echo "ireland_management_las_sg_id=$ireland_management_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ireland_management_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_management_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$ireland_management_lws_sg_id,Description=\"Management-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_management_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/ireland-management-lasa-user-data-$$.sh
sed -e "s/@hostname@/cmlew1mlas01a.$ireland_management_private_domain/g" \
    -e "s/@motd@/CaMeLz Ireland Management Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

ireland_management_las_instancea_id=$(aws ec2 run-instances --image-id $ireland_amzn2_ami_id \
                                                            --instance-type t3a.nano \
                                                            --iam-instance-profile Name=ManagedInstance \
                                                            --key-name administrator \
                                                            --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ireland_management_las_sg_id],SubnetId=$ireland_management_application_subneta_id \
                                                            --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Management-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=cmlew1mlas01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                            --user-data file://$tmpfile \
                                                            --client-token $(date +%s) \
                                                            --query 'Instances[0].InstanceId' \
                                                            --profile $profile --region eu-west-1 --output text)
echo "ireland_management_las_instancea_id=$ireland_management_las_instancea_id"

ireland_management_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ireland_management_las_instancea_id \
                                                                         --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_management_las_instancea_private_ip=$ireland_management_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/ireland-management-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1mlas01a.$ireland_management_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_management_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$ireland_management_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlew1mlas01a.$ireland_management_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_management_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "ireland_management_las_instancea_hostname=cmlew1mlas01a.$ireland_management_private_domain"
echo "ireland_management_las_instancea_hostname_alias=lasa.$ireland_management_private_domain"


## Ireland Core Test Instances ########################################################################################
profile=$core_profile

# Create LinuxWebServer Security Group
ireland_core_lws_sg_id=$(aws ec2 create-security-group --group-name Core-LinuxWebServer-InstanceSecurityGroup \
                                                       --description Core-LinuxWebServer-InstanceSecurityGroup \
                                                       --vpc-id $ireland_core_vpc_id \
                                                       --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Core-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                       --query 'GroupId' \
                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_core_lws_sg_id=$ireland_core_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ireland_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_core_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create LinuxWebServer EIP
ireland_core_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                 --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Core-LinuxWebServer-EIPA},{Key=Hostname,Value=cmluw1clws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                 --query 'AllocationId' \
                                                 --profile $profile --region eu-west-1 --output text)
echo "ireland_core_lws_eipa=$ireland_core_lws_eipa"

ireland_core_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $ireland_core_lws_eipa \
                                                                  --query 'Addresses[0].PublicIp' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "ireland_core_lws_instancea_public_ip=$ireland_core_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/ireland-core-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1clws01a.$ireland_core_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_core_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$ireland_core_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlew1clws01a.$ireland_core_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_core_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "ireland_core_lws_instancea_hostname=cmlew1clws01a.$ireland_core_public_domain"
echo "ireland_core_lws_instancea_hostname_alias=lwsa.$ireland_core_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/ireland-core-lwsa-user-data-$$.sh
sed -e "s/@hostname@/cmlew1clws01a.$ireland_core_private_domain/g" \
    -e "s/@motd@/CaMeLz Ireland Core Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

ireland_core_lws_instancea_id=$(aws ec2 run-instances --image-id $ireland_amzn2_ami_id \
                                                      --instance-type t3a.nano \
                                                      --iam-instance-profile Name=ManagedInstance \
                                                      --key-name administrator \
                                                      --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Core-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ireland_core_lws_sg_id],SubnetId=$ireland_core_web_subneta_id \
                                                      --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Core-LinuxWebServer-InstanceA},{Key=Hostname,Value=cmlew1clws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                      --user-data file://$tmpfile \
                                                      --client-token $(date +%s) \
                                                      --query 'Instances[0].InstanceId' \
                                                      --profile $profile --region eu-west-1 --output text)
echo "ireland_core_lws_instancea_id=$ireland_core_lws_instancea_id"

ireland_core_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ireland_core_lws_instancea_id \
                                                                   --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                   --profile $profile --region eu-west-1 --output text)
echo "ireland_core_lws_instancea_private_ip=$ireland_core_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/ireland-management-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1clws01a.$ireland_core_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_core_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$ireland_core_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlew1clws01a.$ireland_core_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_core_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text

aws ec2 associate-address --instance-id $ireland_core_lws_instancea_id --allocation-id $ireland_core_lws_eipa \
                          --profile $profile --region eu-west-1 --output text

# Create LinuxApplicationServer Security Group
ireland_core_las_sg_id=$(aws ec2 create-security-group --group-name Core-LinuxApplicationServer-InstanceSecurityGroup \
                                                       --description Core-LinuxApplicationServer-InstanceSecurityGroup \
                                                       --vpc-id $ireland_core_vpc_id \
                                                       --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Core-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                       --query 'GroupId' \
                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_core_las_sg_id=$ireland_core_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ireland_core_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_core_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$ireland_core_lws_sg_id,Description=\"Core-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_core_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/ireland-core-lasa-user-data-$$.sh
sed -e "s/@hostname@/cmlew1clas01a.$ireland_core_private_domain/g" \
    -e "s/@motd@/CaMeLz Ireland Core Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

ireland_core_las_instancea_id=$(aws ec2 run-instances --image-id $ireland_amzn2_ami_id \
                                                      --instance-type t3a.nano \
                                                      --iam-instance-profile Name=ManagedInstance \
                                                      --key-name administrator \
                                                      --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Core-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ireland_core_las_sg_id],SubnetId=$ireland_core_application_subneta_id \
                                                      --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Core-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=cmlew1clas01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4},{Key=Note,] \
                                                      --user-data file://$tmpfile \
                                                      --client-token $(date +%s) \
                                                      --query 'Instances[0].InstanceId' \
                                                      --profile $profile --region eu-west-1 --output text)
echo "ireland_core_las_instancea_id=$ireland_core_las_instancea_id"

ireland_core_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ireland_core_las_instancea_id \
                                                                   --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                   --profile $profile --region eu-west-1 --output text)
echo "ireland_core_las_instancea_private_ip=$ireland_core_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/ireland-core-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1clas01a.$ireland_core_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_core_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$ireland_core_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlew1clas01a.$ireland_core_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_core_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "ireland_core_las_instancea_hostname=cmlew1clas01a.$ireland_core_private_domain"
echo "ireland_core_las_instancea_hostname_alias=lasa.$ireland_core_private_domain"


## Ireland Log Test Instances #########################################################################################
profile=$log_profile

# Create LinuxWebServer Security Group
ireland_log_lws_sg_id=$(aws ec2 create-security-group --group-name Log-LinuxWebServer-InstanceSecurityGroup \
                                                      --description Log-LinuxWebServer-InstanceSecurityGroup \
                                                      --vpc-id $ireland_log_vpc_id \
                                                      --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Log-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                      --query 'GroupId' \
                                                      --profile $profile --region eu-west-1 --output text)
echo "ireland_log_lws_sg_id=$ireland_log_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ireland_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_log_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create LinuxWebServer EIP
ireland_log_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Log-LinuxWebServer-EIPA},{Key=Hostname,Value=cmluw1llws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                --query 'AllocationId' \
                                                --profile $profile --region eu-west-1 --output text)
echo "ireland_log_lws_eipa=$ireland_log_lws_eipa"

ireland_log_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $ireland_log_lws_eipa \
                                                                 --query 'Addresses[0].PublicIp' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "ireland_log_lws_instancea_public_ip=$ireland_log_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/ireland-log-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1llws01a.$ireland_log_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_log_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$ireland_log_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlew1llws01a.$ireland_log_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_log_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "ireland_log_lws_instancea_hostname=cmlew1llws01a.$ireland_log_public_domain"
echo "ireland_log_lws_instancea_hostname_alias=lwsa.$ireland_log_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/ireland-log-lwsa-user-data-$$.sh
sed -e "s/@hostname@/cmlew1llws01a.$ireland_log_private_domain/g" \
    -e "s/@motd@/CaMeLz Ireland Log Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

ireland_log_lws_instancea_id=$(aws ec2 run-instances --image-id $ireland_amzn2_ami_id \
                                                     --instance-type t3a.nano \
                                                     --iam-instance-profile Name=ManagedInstance \
                                                     --key-name administrator \
                                                     --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Log-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ireland_log_lws_sg_id],SubnetId=$ireland_log_web_subneta_id \
                                                     --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Log-LinuxWebServer-InstanceA},{Key=Hostname,Value=cmlew1llws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                     --user-data file://$tmpfile \
                                                     --client-token $(date +%s) \
                                                     --query 'Instances[0].InstanceId' \
                                                     --profile $profile --region eu-west-1 --output text)
echo "ireland_log_lws_instancea_id=$ireland_log_lws_instancea_id"

ireland_log_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ireland_log_lws_instancea_id \
                                                                  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "ireland_log_lws_instancea_private_ip=$ireland_log_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/ireland-log-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1llws01a.$ireland_log_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_log_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$ireland_log_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlew1llws01a.$ireland_log_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_log_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text

aws ec2 associate-address --instance-id $ireland_log_lws_instancea_id --allocation-id $ireland_log_lws_eipa \
                          --profile $profile --region eu-west-1 --output text

# Create LinuxApplicationServer Security Group
ireland_log_las_sg_id=$(aws ec2 create-security-group --group-name Log-LinuxApplicationServer-InstanceSecurityGroup \
                                                      --description Log-LinuxApplicationServer-InstanceSecurityGroup \
                                                      --vpc-id $ireland_log_vpc_id \
                                                      --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Log-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                      --query 'GroupId' \
                                                      --profile $profile --region eu-west-1 --output text)
echo "ireland_log_las_sg_id=$ireland_log_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $ireland_log_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_log_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$ireland_log_lws_sg_id,Description=\"Log-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_log_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/ireland-log-lasa-user-data-$$.sh
sed -e "s/@hostname@/cmlew1llas01a.$ireland_log_private_domain/g" \
    -e "s/@motd@/CaMeLz Ireland Log Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

ireland_log_las_instancea_id=$(aws ec2 run-instances --image-id $ireland_amzn2_ami_id \
                                                     --instance-type t3a.nano \
                                                     --iam-instance-profile Name=ManagedInstance \
                                                     --key-name administrator \
                                                     --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Log-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ireland_log_las_sg_id],SubnetId=$ireland_log_application_subneta_id \
                                                     --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Log-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=cmlew1llas01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                     --user-data file://$tmpfile \
                                                     --client-token $(date +%s) \
                                                     --query 'Instances[0].InstanceId' \
                                                     --profile $profile --region eu-west-1 --output text)
echo "ireland_log_las_instancea_id=$ireland_log_las_instancea_id"

ireland_log_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ireland_log_las_instancea_id \
                                                                  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "ireland_log_las_instancea_private_ip=$ireland_log_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/ireland-log-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlew1llas01a.$ireland_log_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$ireland_log_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$ireland_log_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlew1llas01a.$ireland_log_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ireland_log_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "ireland_log_las_instancea_hostname=cmlew1llas01a.$ireland_log_private_domain"
echo "ireland_log_las_instancea_hostname_alias=lasa.$ireland_log_private_domain"


## Alfa Ireland Recovery Test Instances ###############################################################################
profile=$recovery_profile

# Create LinuxWebServer Security Group
alfa_ireland_recovery_lws_sg_id=$(aws ec2 create-security-group --group-name Alfa-Recovery-LinuxWebServer-InstanceSecurityGroup \
                                                                --description Alfa-Recovery-LinuxWebServer-InstanceSecurityGroup \
                                                                --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Recovery-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                --query 'GroupId' \
                                                                --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_lws_sg_id=$alfa_ireland_recovery_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create LinuxWebServer EIP
alfa_ireland_recovery_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                          --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Recovery-LinuxWebServer-EIPA},{Key=Hostname,Value=alfuw1rlws01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                          --query 'AllocationId' \
                                                          --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_lws_eipa=$alfa_ireland_recovery_lws_eipa"

alfa_ireland_recovery_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_ireland_recovery_lws_eipa \
                                                                           --query 'Addresses[0].PublicIp' \
                                                                           --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_lws_instancea_public_ip=$alfa_ireland_recovery_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/alfa-ireland-recovery-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfew1rlws01a.$alfa_ireland_recovery_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ireland_recovery_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$alfa_ireland_recovery_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfew1rlws01a.$alfa_ireland_recovery_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ireland_recovery_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "alfa_ireland_recovery_lws_instancea_hostname=alfew1rlws01a.$alfa_ireland_recovery_public_domain"
echo "alfa_ireland_recovery_lws_instancea_hostname_alias=lwsa.$alfa_ireland_recovery_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/alfa-ireland-recovery-lwsa-user-data-$$.sh
sed -e "s/@hostname@/alfew1rlws01a.$alfa_ireland_recovery_private_domain/g" \
    -e "s/@motd@/CaMeLz Alfa Ireland Recovery Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

alfa_ireland_recovery_lws_instancea_id=$(aws ec2 run-instances --image-id $ireland_amzn2_ami_id \
                                                               --instance-type t3a.nano \
                                                               --iam-instance-profile Name=ManagedInstance \
                                                               --key-name administrator \
                                                               --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Recovery-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ireland_recovery_lws_sg_id],SubnetId=$alfa_ireland_recovery_web_subneta_id \
                                                               --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Recovery-LinuxWebServer-InstanceA},{Key=Hostname,Value=alfew1rlws01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --user-data file://$tmpfile \
                                                               --client-token $(date +%s) \
                                                               --query 'Instances[0].InstanceId' \
                                                               --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_lws_instancea_id=$alfa_ireland_recovery_lws_instancea_id"

alfa_ireland_recovery_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ireland_recovery_lws_instancea_id \
                                                                            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                            --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_lws_instancea_private_ip=$alfa_ireland_recovery_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/alfa-ireland-recovery-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfew1rlws01a.$alfa_ireland_recovery_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ireland_recovery_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$alfa_ireland_recovery_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfew1rlws01a.$alfa_ireland_recovery_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ireland_recovery_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text

aws ec2 associate-address --instance-id $alfa_ireland_recovery_lws_instancea_id --allocation-id $alfa_ireland_recovery_lws_eipa \
                          --profile $profile --region eu-west-1 --output text

# Create LinuxApplicationServer Security Group
alfa_ireland_recovery_las_sg_id=$(aws ec2 create-security-group --group-name Alfa-Recovery-LinuxApplicationServer-InstanceSecurityGroup \
                                                                --description Alfa-Recovery-LinuxApplicationServer-InstanceSecurityGroup \
                                                                --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Recovery-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                --query 'GroupId' \
                                                                --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_las_sg_id=$alfa_ireland_recovery_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$alfa_ireland_recovery_lws_sg_id,Description=\"Alfa-Recovery-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"DataCenter-Alfa-LosAngeles (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"DataCenter-Alfa-Miami (SSH)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/alfa-ireland-recovery-lasa-user-data-$$.sh
sed -e "s/@hostname@/alfew1rlas01a.$alfa_ireland_recovery_private_domain/g" \
    -e "s/@motd@/CaMeLz Alfa Ireland Recovery Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

alfa_ireland_recovery_las_instancea_id=$(aws ec2 run-instances --image-id $ireland_amzn2_ami_id \
                                                               --instance-type t3a.nano \
                                                               --iam-instance-profile Name=ManagedInstance \
                                                               --key-name administrator \
                                                               --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Recovery-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ireland_recovery_las_sg_id],SubnetId=$alfa_ireland_recovery_application_subneta_id \
                                                               --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Recovery-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=alfew1rlas01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                               --user-data file://$tmpfile \
                                                               --client-token $(date +%s) \
                                                               --query 'Instances[0].InstanceId' \
                                                               --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_las_instancea_id=$alfa_ireland_recovery_las_instancea_id"

alfa_ireland_recovery_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ireland_recovery_las_instancea_id \
                                                                            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                            --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_las_instancea_private_ip=$alfa_ireland_recovery_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/alfa-ireland-recovery-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfew1rlas01a.$alfa_ireland_recovery_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_ireland_recovery_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$alfa_ireland_recovery_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfew1rlas01a.$alfa_ireland_recovery_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_ireland_recovery_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region eu-west-1 --output text
echo "alfa_ireland_recovery_las_instancea_hostname=alfew1rlas01a.$alfa_ireland_recovery_private_domain"
echo "alfa_ireland_recovery_las_instancea_hostname_alias=lasa.$alfa_ireland_recovery_private_domain"


## Alfa LosAngeles Test Instances #####################################################################################
profile=$management_profile

# Create LinuxWebServer Security Group
alfa_lax_lws_sg_id=$(aws ec2 create-security-group --group-name Alfa-LosAngeles-LinuxWebServer-InstanceSecurityGroup \
                                                   --description Alfa-LosAngeles-LinuxWebServer-InstanceSecurityGroup \
                                                   --vpc-id $alfa_lax_vpc_id \
                                                   --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-LosAngeles-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Location,Value=LosAngeles},{Key=Environment,Value=Network},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_lax_lws_sg_id=$alfa_lax_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_lax_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_lax_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_lax_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_lax_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxWebServer EIP
alfa_lax_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                             --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-LosAngeles-LinuxWebServer-EIPA},{Key=Hostname,Value=alflaxnlws01a},{Key=Company,Value=Alfa},{Key=Location,Value=LosAngeles},{Key=Environment,Value=Network},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                             --query 'AllocationId' \
                                             --profile $profile --region us-east-2 --output text)
echo "alfa_lax_lws_eipa=$alfa_lax_lws_eipa"

alfa_lax_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_lax_lws_eipa \
                                                              --query 'Addresses[0].PublicIp' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_lax_lws_instancea_public_ip=$alfa_lax_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/alfa-lax-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alflaxnlws01a.$alfa_lax_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_lax_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$alfa_lax_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alflaxnlws01a.$alfa_lax_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_lax_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_lax_lws_instancea_hostname=alflaxnlws01a.$alfa_lax_public_domain"
echo "alfa_lax_lws_instancea_hostname_alias=lwsa.$alfa_lax_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/alfa-lax-lwsa-user-data-$$.sh
sed -e "s/@hostname@/alflaxnlws01a.$alfa_lax_private_domain/g" \
    -e "s/@motd@/CaMeLz Alfa Los Angeles Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

alfa_lax_lws_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                  --instance-type t3a.nano \
                                                  --iam-instance-profile Name=ManagedInstance \
                                                  --key-name administrator \
                                                  --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-LosAngeles-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_lax_lws_sg_id],SubnetId=$alfa_lax_public_subneta_id \
                                                  --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-LosAngeles-LinuxWebServer-InstanceA},{Key=Hostname,Value=alflaxnlws01a},{Key=Company,Value=Alfa},{Key=Location,Value=LosAngeles},{Key=Environment,Value=Network},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --user-data file://$tmpfile \
                                                  --client-token $(date +%s) \
                                                  --query 'Instances[0].InstanceId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_lax_lws_instancea_id=$alfa_lax_lws_instancea_id"

alfa_lax_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_lax_lws_instancea_id \
                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_lax_lws_instancea_private_ip=$alfa_lax_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/alfa-lax-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alflaxnlws01a.$alfa_lax_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_lax_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$alfa_lax_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alflaxnlws01a.$alfa_lax_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_lax_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $alfa_lax_lws_instancea_id --allocation-id $alfa_lax_lws_eipa \
                          --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Security Group
alfa_lax_las_sg_id=$(aws ec2 create-security-group --group-name Alfa-LosAngeles-LinuxApplicationServer-InstanceSecurityGroup \
                                                   --description Alfa-LosAngeles-LinuxApplicationServer-InstanceSecurityGroup \
                                                   --vpc-id $alfa_lax_vpc_id \
                                                   --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-LosAngeles-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Location,Value=LosAngeles},{Key=Environment,Value=Network},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_lax_las_sg_id=$alfa_lax_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_lax_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_lax_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$alfa_lax_lws_sg_id,Description=\"Alfa-LosAngeles-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_lax_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/alfa-lax-lasa-user-data-$$.sh
sed -e "s/@hostname@/alflaxnlas01a.$alfa_lax_private_domain/g" \
    -e "s/@motd@/CaMeLz Alfa Los Angeles Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

alfa_lax_las_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                  --instance-type t3a.nano \
                                                  --iam-instance-profile Name=ManagedInstance \
                                                  --key-name administrator \
                                                  --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-LosAngeles-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_lax_las_sg_id],SubnetId=$alfa_lax_private_subneta_id \
                                                  --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-LosAngeles-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=alflaxnlas01a},{Key=Company,Value=Alfa},{Key=Location,Value=LosAngeles},{Key=Environment,Value=Network},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --user-data file://$tmpfile \
                                                  --client-token $(date +%s) \
                                                  --query 'Instances[0].InstanceId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_lax_las_instancea_id=$alfa_lax_las_instancea_id"

alfa_lax_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_lax_las_instancea_id \
                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_lax_las_instancea_private_ip=$alfa_lax_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/alfa-lax-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alflaxnlas01a.$alfa_lax_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_lax_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$alfa_lax_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alflaxnlas01a.$alfa_lax_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_lax_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_lax_las_instancea_hostname=alflaxnlas01a.$alfa_lax_private_domain"
echo "alfa_lax_las_instancea_hostname_alias=lasa.$alfa_lax_private_domain"


## Alfa Miami Test Instances ##########################################################################################
profile=$management_profile

# Create LinuxWebServer Security Group
alfa_mia_lws_sg_id=$(aws ec2 create-security-group --group-name Alfa-Miami-LinuxWebServer-InstanceSecurityGroup \
                                                   --description Alfa-Miami-LinuxWebServer-InstanceSecurityGroup \
                                                   --vpc-id $alfa_mia_vpc_id \
                                                   --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Miami-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Location,Value=Miami},{Key=Environment,Value=Network},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_mia_lws_sg_id=$alfa_mia_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_mia_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_mia_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_mia_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_mia_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxWebServer EIP
alfa_mia_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                             --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Miami-LinuxWebServer-EIPA},{Key=Hostname,Value=alfmianlws01a},{Key=Company,Value=Alfa},{Key=Location,Value=Miami},{Key=Environment,Value=Network},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                             --query 'AllocationId' \
                                             --profile $profile --region us-east-2 --output text)
echo "alfa_mia_lws_eipa=$alfa_mia_lws_eipa"

alfa_mia_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_mia_lws_eipa \
                                                              --query 'Addresses[0].PublicIp' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_mia_lws_instancea_public_ip=$alfa_mia_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/alfa-mia-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfmianlws01a.$alfa_mia_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_mia_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$alfa_mia_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfmianlws01a.$alfa_mia_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_mia_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_mia_lws_instancea_hostname=alfmianlws01a.$alfa_mia_public_domain"
echo "alfa_mia_lws_instancea_hostname_alias=lwsa.$alfa_mia_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/alfa-mia-lwsa-user-data-$$.sh
sed -e "s/@hostname@/alfmianlws01a.$alfa_mia_private_domain/g" \
    -e "s/@motd@/CaMeLz Alfa Miami Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

alfa_mia_lws_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                  --instance-type t3a.nano \
                                                  --iam-instance-profile Name=ManagedInstance \
                                                  --key-name administrator \
                                                  --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Miami-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_mia_lws_sg_id],SubnetId=$alfa_mia_public_subneta_id \
                                                  --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Miami-LinuxWebServer-InstanceA},{Key=Hostname,Value=alfmianlws01a},{Key=Company,Value=Alfa},{Key=Location,Value=Miami},{Key=Environment,Value=Network},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --user-data file://$tmpfile \
                                                  --client-token $(date +%s) \
                                                  --query 'Instances[0].InstanceId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_mia_lws_instancea_id=$alfa_mia_lws_instancea_id"

alfa_mia_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_mia_lws_instancea_id \
                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_mia_lws_instancea_private_ip=$alfa_mia_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/alfa-mia-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfmianlws01a.$alfa_mia_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_mia_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$alfa_mia_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfmianlws01a.$alfa_mia_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_mia_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $alfa_mia_lws_instancea_id --allocation-id $alfa_mia_lws_eipa \
                          --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Security Group
alfa_mia_las_sg_id=$(aws ec2 create-security-group --group-name Alfa-Miami-LinuxApplicationServer-InstanceSecurityGroup \
                                                   --description Alfa-Miami-LinuxApplicationServer-InstanceSecurityGroup \
                                                   --vpc-id $alfa_mia_vpc_id \
                                                   --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Miami-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Location,Value=Miami},{Key=Environment,Value=Network},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_mia_las_sg_id=$alfa_mia_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $alfa_mia_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_mia_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$alfa_mia_lws_sg_id,Description=\"Alfa-Miami-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $alfa_mia_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/alfa-mia-lasa-user-data-$$.sh
sed -e "s/@hostname@/alfmianlas01a.$alfa_mia_private_domain/g" \
    -e "s/@motd@/CaMeLz Alfa Miami Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

alfa_mia_las_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                  --instance-type t3a.nano \
                                                  --iam-instance-profile Name=ManagedInstance \
                                                  --key-name administrator \
                                                  --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Miami-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_mia_las_sg_id],SubnetId=$alfa_mia_private_subneta_id \
                                                  --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Miami-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=alfmianlas01a},{Key=Company,Value=Alfa},{Key=Location,Value=Miami},{Key=Environment,Value=Network},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-n}] \
                                                  --user-data file://$tmpfile \
                                                  --client-token $(date +%s) \
                                                  --query 'Instances[0].InstanceId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_mia_las_instancea_id=$alfa_mia_las_instancea_id"

alfa_mia_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_mia_las_instancea_id \
                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_mia_las_instancea_private_ip=$alfa_mia_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/alfa-mia-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfmianlas01a.$alfa_mia_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_mia_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$alfa_mia_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfmianlas01a.$alfa_mia_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_mia_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "alfa_mia_las_instancea_hostname=alfmianlas01a.$alfa_mia_private_domain"
echo "alfa_mia_las_instancea_hostname_alias=lasa.$alfa_mia_private_domain"


## Zulu Dallas Test Instances #########################################################################################
profile=$management_profile

# Create LinuxWebServer Security Group
zulu_dfw_lws_sg_id=$(aws ec2 create-security-group --group-name Zulu-Dallas-LinuxWebServer-InstanceSecurityGroup \
                                                   --description Zulu-Dallas-LinuxWebServer-InstanceSecurityGroup \
                                                   --vpc-id $zulu_dfw_vpc_id \
                                                   --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Dallas-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_lws_sg_id=$zulu_dfw_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxWebServer EIP
zulu_dfw_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                             --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=Zulu-Dallas-LinuxWebServer-EIPA},{Key=Hostname,Value=zuldfwnlws01a},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                             --query 'AllocationId' \
                                             --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_lws_eipa=$zulu_dfw_lws_eipa"

zulu_dfw_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $zulu_dfw_lws_eipa \
                                                              --query 'Addresses[0].PublicIp' \
                                                              --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_lws_instancea_public_ip=$zulu_dfw_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/zulu-dfw-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zuldfwnlws01a.$zulu_dfw_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_dfw_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$zulu_dfw_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "zuldfwnlws01a.$zulu_dfw_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_dfw_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "zulu_dfw_lws_instancea_hostname=zuldfwnlws01a.$zulu_dfw_public_domain"
echo "zulu_dfw_lws_instancea_hostname_alias=lwsa.$zulu_dfw_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/zulu-dfw-lwsa-user-data-$$.sh
sed -e "s/@hostname@/zuldfwnlws01a.$zulu_dfw_private_domain/g" \
    -e "s/@motd@/CaMeLz Zulu Dallas Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

zulu_dfw_lws_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                  --instance-type t3a.nano \
                                                  --iam-instance-profile Name=ManagedInstance \
                                                  --key-name administrator \
                                                  --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Zulu-Dallas-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_dfw_lws_sg_id],SubnetId=$zulu_dfw_public_subneta_id \
                                                  --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Dallas-LinuxWebServer-InstanceA},{Key=Hostname,Value=zuldfwnlws01a},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --user-data file://$tmpfile \
                                                  --client-token $(date +%s) \
                                                  --query 'Instances[0].InstanceId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_lws_instancea_id=$zulu_dfw_lws_instancea_id"

zulu_dfw_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_dfw_lws_instancea_id \
                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_lws_instancea_private_ip=$zulu_dfw_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/zulu-dfw-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zuldfwnlws01a.$zulu_dfw_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_dfw_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$zulu_dfw_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "zuldfwnlws01a.$zulu_dfw_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_dfw_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $zulu_dfw_lws_instancea_id --allocation-id $zulu_dfw_lws_eipa \
                          --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Security Group
zulu_dfw_las_sg_id=$(aws ec2 create-security-group --group-name Zulu-Dallas-LinuxApplicationServer-InstanceSecurityGroup \
                                                   --description Zulu-Dallas-LinuxApplicationServer-InstanceSecurityGroup \
                                                   --vpc-id $zulu_dfw_vpc_id \
                                                   --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Dallas-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_las_sg_id=$zulu_dfw_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$zulu_dfw_lws_sg_id,Description=\"Zulu-Dallas-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/zulu-dfw-lasa-user-data-$$.sh
sed -e "s/@hostname@/zuldfwnlas01a.$zulu_dfw_private_domain/g" \
    -e "s/@motd@/CaMeLz Zulu Dallas Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

zulu_dfw_las_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                  --instance-type t3a.nano \
                                                  --iam-instance-profile Name=ManagedInstance \
                                                  --key-name administrator \
                                                  --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Zulu-Dallas-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_dfw_las_sg_id],SubnetId=$zulu_dfw_private_subneta_id \
                                                  --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Dallas-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=zuldfwnlas01a},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --user-data file://$tmpfile \
                                                  --client-token $(date +%s) \
                                                  --query 'Instances[0].InstanceId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_las_instancea_id=$zulu_dfw_las_instancea_id"

zulu_dfw_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_dfw_las_instancea_id \
                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_las_instancea_private_ip=$zulu_dfw_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/zulu-dfw-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zuldfwnlas01a.$zulu_dfw_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_dfw_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$zulu_dfw_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "zuldfwnlas01a.$zulu_dfw_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_dfw_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "zulu_dfw_las_instancea_hostname=zuldfwnlas01a.$zulu_dfw_private_domain"
echo "zulu_dfw_las_instancea_hostname_alias=lasa.$zulu_dfw_private_domain"


## CaMeLz SantaBarbara Test Instances ####################################################################################
profile=$management_profile

# Create LinuxWebServer Security Group
cml_sba_lws_sg_id=$(aws ec2 create-security-group --group-name CaMeLz-SantaBarbara-LinuxWebServer-InstanceSecurityGroup \
                                                  --description CaMeLz-SantaBarbara-LinuxWebServer-InstanceSecurityGroup \
                                                  --vpc-id $cml_sba_vpc_id \
                                                  --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=CaMeLz-SantaBarbara-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Location,Value=SantaBarbara},{Key=Environment,Value=Network},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --query 'GroupId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "cml_sba_lws_sg_id=$cml_sba_lws_sg_id"

aws ec2 authorize-security-group-ingress --group-id $cml_sba_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $cml_sba_lws_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $cml_sba_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_msy_public_cidr,Description=\"Office-CaMeLz-NewOrleans (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $cml_sba_lws_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxWebServer EIP
cml_sba_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                            --tag-specifications ResourceType=elastic-ip,Tags=[{Key=Name,Value=CaMeLz-SantaBarbara-LinuxWebServer-EIPA},{Key=Hostname,Value=cmlsbanlws01a},{Key=Company,Value=CaMeLz},{Key=Location,Value=SantaBarbara},{Key=Environment,Value=Network},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                             --query 'AllocationId' \
                                            --profile $profile --region us-east-2 --output text)
echo "cml_sba_lws_eipa=$cml_sba_lws_eipa"

cml_sba_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $cml_sba_lws_eipa \
                                                             --query 'Addresses[0].PublicIp' \
                                                             --profile $profile --region us-east-2 --output text)
echo "cml_sba_lws_instancea_public_ip=$cml_sba_lws_instancea_public_ip"

# Create LinuxWebServer Public Domain Name
tmpfile=$tmpdir/cml-sba-lwsa-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlsbanlws01a.$cml_sba_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$cml_sba_lws_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$cml_sba_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlsbanlws01a.$cml_sba_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $cml_sba_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "cml_sba_lws_instancea_hostname=cmlnclws01a.$cml_sba_public_domain"
echo "cml_sba_lws_instancea_hostname_alias=lwsa.$cml_sba_public_domain"

# Create LinuxWebServer Instance
tmpfile=$tmpdir/cml-sba-lwsa-user-data-$$.sh
sed -e "s/@hostname@/cmlsbanlws01a.$cml_sba_private_domain/g" \
    -e "s/@motd@/CaMeLz CaMeLz Santa Barbara Linux Web Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

cml_sba_lws_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                 --instance-type t3a.nano \
                                                 --iam-instance-profile Name=ManagedInstance \
                                                 --key-name administrator \
                                                 --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=CaMeLz-SantaBarbara-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$cml_sba_lws_sg_id],SubnetId=$cml_sba_public_subneta_id \
                                                 --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=CaMeLz-SantaBarbara-LinuxWebServer-InstanceA},{Key=Hostname,Value=cmlnclws01a},{Key=Company,Value=CaMeLz},{Key=Location,Value=SantaBarbara},{Key=Environment,Value=Network},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                 --user-data file://$tmpfile \
                                                 --client-token $(date +%s) \
                                                 --query 'Instances[0].InstanceId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "cml_sba_lws_instancea_id=$cml_sba_lws_instancea_id"

cml_sba_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $cml_sba_lws_instancea_id \
                                                              --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                              --profile $profile --region us-east-2 --output text)
echo "cml_sba_lws_instancea_private_ip=$cml_sba_lws_instancea_private_ip"

# Create LinuxWebServer Private Domain Name
tmpfile=$tmpdir/cml-sba-lwsa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlsbanlws01a.$cml_sba_private_domain",
      "Type": "A",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "$cml_sba_lws_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lwsa.$cml_sba_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlsbanlws01a.$cml_sba_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $cml_sba_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $cml_sba_lws_instancea_id --allocation-id $cml_sba_lws_eipa \
                          --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Security Group
cml_sba_las_sg_id=$(aws ec2 create-security-group --group-name CaMeLz-SantaBarbara-LinuxApplicationServer-InstanceSecurityGroup \
                                                  --description CaMeLz-SantaBarbara-LinuxApplicationServer-InstanceSecurityGroup \
                                                  --vpc-id $cml_sba_vpc_id \
                                                  --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=CaMeLz-SantaBarbara-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Location,Value=SantaBarbara},{Key=Environment,Value=Network},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}] \
                                                  --query 'GroupId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "cml_sba_las_sg_id=$cml_sba_las_sg_id"

aws ec2 authorize-security-group-ingress --group-id $cml_sba_las_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $cml_sba_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$cml_sba_lws_sg_id,Description=\"CaMeLz-SantaBarbara-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $cml_sba_las_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create LinuxApplicationServer Instance
tmpfile=$tmpdir/cml-sba-lasa-user-data-$$.sh
sed -e "s/@hostname@/cmlnclas01a.$cml_sba_private_domain/g" \
    -e "s/@motd@/CaMeLz CaMeLz Santa Barbara Linux Application Server 01-A/g" \
    $templatesdir/linux-standard-user-data.sh > $tmpfile

cml_sba_las_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                 --instance-type t3a.nano \
                                                 --iam-instance-profile Name=ManagedInstance \
                                                 --key-name administrator \
                                                 --network-interfaces AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=CaMeLz-SantaBarbara-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$cml_sba_las_sg_id],SubnetId=$cml_sba_private_subneta_id \
                                                 --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=CaMeLz-SantaBarbara-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=cmlsbanlas01a},{Key=Company,Value=CaMeLz},{Key=Location,Value=SantaBarbara},{Key=Environment,Value=Network},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC}] \
                                                 --user-data file://$tmpfile \
                                                 --client-token $(date +%s) \
                                                 --query 'Instances[0].InstanceId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "cml_sba_las_instancea_id=$cml_sba_las_instancea_id"

cml_sba_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $cml_sba_las_instancea_id \
                                                              --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                              --profile $profile --region us-east-2 --output text)
echo "cml_sba_las_instancea_private_ip=$cml_sba_las_instancea_private_ip"

# Create LinuxApplicationServer Private Domain Name
tmpfile=$tmpdir/cml-sba-lasa-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlsbanlas01a.$cml_sba_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$cml_sba_las_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "lasa.$cml_sba_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlsbanlas01a.$cml_sba_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $cml_sba_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text
echo "cml_sba_las_instancea_hostname=cmlsbanlas01a.$cml_sba_private_domain"
echo "cml_sba_las_instancea_hostname_alias=lasa.$cml_sba_private_domain"
