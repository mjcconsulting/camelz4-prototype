# Modules:Instances:Management Account:Global:Management Linux Test Instances

This module creates Management Linux Test Instances in the Management VPC in the AWS Virginia (us-east-1) Region
within the CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.
- Role: ManagedInstance
- Public Hosted Zone: camelz.io
- KeyPair: administrator
- VPC: (Global) Management-VPC

## Global Management Linux Test Instances

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create LinuxWebServer Identifiers**

    ```bash
    global_management_lws_instancea_description="CaMeLz Global Management Linux Web Server 01-A"
    camelz-variable global_management_lws_instancea_description

    global_management_lws_instancea_public_hostname=cmlue1mlws01a.$global_management_public_domain
    camelz-variable global_management_lws_instancea_public_hostname

    global_management_lws_instancea_public_hostalias=lwsa.$global_management_public_domain
    camelz-variable global_management_lws_instancea_public_hostalias

    global_management_lws_instancea_private_hostname=cmlue1mlws01a.$global_management_private_domain
    camelz-variable global_management_lws_instancea_private_hostname

    global_management_lws_instancea_private_hostalias=lwsa.$global_management_private_domain
    camelz-variable global_management_lws_instancea_private_hostalias
    ```

1. **Create LinuxWebServer Security Group**

    ```bash
    global_management_lws_sg_id=$(aws ec2 create-security-group --group-name Management-LinuxWebServer-InstanceSecurityGroup \
                                                                --description Management-LinuxWebServer-InstanceSecurityGroup \
                                                                --vpc-id $global_management_vpc_id \
                                                                --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Management-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-east-1 --output text)
    camelz-variable global_management_lws_sg_id

    aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                             --profile $profile --region us-east-1 --output text
    aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_lax_public_cidr,Description=\"DataCenter-CaMeLz-LosAngeles (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-LosAngeles (ICMP)\"}]" \
                                             --profile $profile --region us-east-1 --output text
    aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sna_public_cidr,Description=\"Office-CaMeLz-Irvine (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Office-CaMeLz-Irvine (ICMP)\"}]" \
                                             --profile $profile --region us-east-1 --output text
    aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Home-MCrawford (ICMP)\"}]" \
                                             --profile $profile --region us-east-1 --output text

    aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --profile $profile --region us-east-1 --output text
    aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_lax_public_cidr,Description=\"DataCenter-CaMeLz-LosAngeles (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-LosAngeles (SSH)\"}]" \
                                             --profile $profile --region us-east-1 --output text
    aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sna_public_cidr,Description=\"Office-CaMeLz-Irvine (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Office-CaMeLz-Irvine (SSH)\"}]" \
                                             --profile $profile --region us-east-1 --output text
    aws ec2 authorize-security-group-ingress --group-id $global_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Home-MCrawford (SSH)\"}]" \
                                             --profile $profile --region us-east-1 --output text
    ```

1. **Create LinuxWebServer EIP**

    ```bash
    global_management_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                          --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Management-LinuxWebServer-EIPA},{Key=Hostname,Value=cmlue1mlws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'AllocationId' \
                                                          --profile $profile --region us-east-1 --output text)
    camelz-variable global_management_lws_eipa

    global_management_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $global_management_lws_eipa \
                                                                           --query 'Addresses[0].PublicIp' \
                                                                           --profile $profile --region us-east-1 --output text)
    camelz-variable global_management_lws_instancea_public_ip
    ```

1. **Create LinuxWebServer Public Domain Name**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/global-management-lwsa-public-$$.json
    sed -e "s/@hostname@/$global_management_lws_instancea_public_hostname/g" \
        -e "s/@servicename@/$global_management_lws_instancea_public_hostalias/g" \
        -e "s/@ip@/$global_management_lws_instancea_public_ip/g" \
        $CAMELZ_HOME/templates/route53-upsert-a-hostname-cname-servicename.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $global_management_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```

1. **Create LinuxWebServer Instance**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/global-management-lwsa-user-data-$$.sh
    sed -e "s/@hostname@/$global_management_lws_instancea_private_hostname/g" \
        -e "s/@motd@/$global_management_lws_instancea_description/g" \
        $CAMELZ_HOME/templates/linux-standard-user-data.sh > $tmpfile

    global_management_lws_instancea_id=$(aws ec2 run-instances --image-id $global_amzn2_ami_id \
                                                               --instance-type t3a.nano \
                                                               --iam-instance-profile Name=ManagedInstance \
                                                               --key-name administrator \
                                                               --network-interfaces "AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_management_lws_sg_id],SubnetId=$global_management_web_subneta_id" \
                                                               --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Management-LinuxWebServer-InstanceA},{Key=Hostname,Value=cmlue1mlws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --user-data file://$tmpfile \
                                                               --client-token $(date +%s) \
                                                               --query 'Instances[0].InstanceId' \
                                                               --profile $profile --region us-east-1 --output text)
    camelz-variable global_management_lws_instancea_id

    global_management_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $global_management_lws_instancea_id \
                                                                            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                            --profile $profile --region us-east-1 --output text)
    camelz-variable global_management_lws_instancea_private_ip
    ```

1. **Create LinuxWebServer Private Domain Name**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/global-management-lwsa-private-$$.json
    sed -e "s/@hostname@/$global_management_lws_instancea_private_hostname/g" \
        -e "s/@servicename@/$global_management_lws_instancea_private_hostalias/g" \
        -e "s/@ip@/$global_management_lws_instancea_private_ip/g" \
        $CAMELZ_HOME/templates/route53-upsert-a-hostname-cname-servicename.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $global_management_private_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```

1. **Associate LinuxWebServer EIP with Instance & Create Reverse DNS Public Domain Name**

    ```bash
    aws ec2 associate-address --instance-id $global_management_lws_instancea_id --allocation-id $global_management_lws_eipa \
                              --profile $profile --region us-east-1 --output text

    aws ec2 modify-address-attribute --allocation-id $global_management_lws_eipa \
                                     --domain-name $global_management_lws_instancea_public_hostname \
                                     --profile $profile --region us-east-1 --output text
    ```

1. **Create LinuxApplicationServer Identifiers**

    ```bash
    global_management_las_instancea_description="CaMeLz Global Management Linux Application Server 01-A"
    camelz-variable global_management_las_instancea_description

    global_management_las_instancea_private_hostname=cmlue1mlas01a.$global_management_private_domain
    camelz-variable global_management_las_instancea_private_hostname

    global_management_las_instancea_private_hostalias=lasa.$global_management_private_domain
    camelz-variable global_management_las_instancea_private_hostalias
    ```

1. **Create LinuxApplicationServer Security Group**

    ```bash
    global_management_las_sg_id=$(aws ec2 create-security-group --group-name Management-LinuxApplicationServer-InstanceSecurityGroup \
                                                                --description Management-LinuxApplicationServer-InstanceSecurityGroup \
                                                                --vpc-id $global_management_vpc_id \
                                                                --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Management-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-east-1 --output text)
    camelz-variable global_management_las_sg_id

    aws ec2 authorize-security-group-ingress --group-id $global_management_las_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"All (ICMP)\"}]" \
                                             --profile $profile --region us-east-1 --output text

    aws ec2 authorize-security-group-ingress --group-id $global_management_las_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$global_management_lws_sg_id,Description=\"Management-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                             --profile $profile --region us-east-1 --output text
    aws ec2 authorize-security-group-ingress --group-id $global_management_las_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --profile $profile --region us-east-1 --output text
    ```

1. **Create LinuxApplicationServer Instance**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/global-management-lasa-user-data-$$.sh
    sed -e "s/@hostname@/$global_management_las_instancea_private_hostname/g" \
        -e "s/@motd@/$global_management_las_instancea_description/g" \
        $CAMELZ_HOME/templates/linux-standard-user-data.sh > $tmpfile

    global_management_las_instancea_id=$(aws ec2 run-instances --image-id $global_amzn2_ami_id \
                                                               --instance-type t3a.nano \
                                                               --iam-instance-profile Name=ManagedInstance \
                                                               --key-name administrator \
                                                               --network-interfaces "AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_management_las_sg_id],SubnetId=$global_management_application_subneta_id" \
                                                               --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Management-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=cmlue1mlas01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --user-data file://$tmpfile \
                                                               --client-token $(date +%s) \
                                                               --query 'Instances[0].InstanceId' \
                                                               --profile $profile --region us-east-1 --output text)
    camelz-variable global_management_las_instancea_id

    global_management_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $global_management_las_instancea_id \
                                                                            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                            --profile $profile --region us-east-1 --output text)
    camelz-variable global_management_las_instancea_private_ip
    ```

1. **Create LinuxApplicationServer Private Domain Name**

    ```bash
    tmpfile=$CAMELS_HOME/tmp/global-management-lasa-private-$$.json
    sed -e "s/@hostname@/$global_management_las_instancea_private_hostname/g" \
        -e "s/@servicename@/$global_management_las_instancea_private_hostalias/g" \
        -e "s/@ip@/$global_management_las_instancea_private_ip/g" \
        $CAMELZ_HOME/templates/route53-upsert-a-hostname-cname-servicename.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $global_management_private_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```
