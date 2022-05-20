# Modules:Instances:Management Account:Oregon:Management Linux Test Instances

This module creates Management Linux Test Instances in the Management VPC in the AWS Virginia (us-west-2) Region
within the CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.
- Role: ManagedInstance
- Public Hosted Zone: us-west-2.camelz.io
- KeyPair: administrator
- VPC: (Oregon) Management-VPC

## Oregon Management Linux Test Instances

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create LinuxWebServer Identifiers**

    ```bash
    oregon_management_lws_instancea_description="CaMeLz Oregon Management Linux Web Server 01-A"
    camelz-variable oregon_management_lws_instancea_description

    oregon_management_lws_instancea_public_hostname=cmlue1mlws01a.$oregon_management_public_domain
    camelz-variable oregon_management_lws_instancea_public_hostname

    oregon_management_lws_instancea_public_hostalias=lwsa.$oregon_management_public_domain
    camelz-variable oregon_management_lws_instancea_public_hostalias

    oregon_management_lws_instancea_private_hostname=cmlue1mlws01a.$oregon_management_private_domain
    camelz-variable oregon_management_lws_instancea_private_hostname

    oregon_management_lws_instancea_private_hostalias=lwsa.$oregon_management_private_domain
    camelz-variable oregon_management_lws_instancea_private_hostalias
    ```

1. **Create LinuxWebServer Security Group**

    ```bash
    oregon_management_lws_sg_id=$(aws ec2 create-security-group --group-name Management-LinuxWebServer-InstanceSecurityGroup \
                                                                --description Management-LinuxWebServer-InstanceSecurityGroup \
                                                                --vpc-id $oregon_management_vpc_id \
                                                                --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Management-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_lws_sg_id

    aws ec2 authorize-security-group-ingress --group-id $oregon_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $oregon_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_lax_public_cidr,Description=\"DataCenter-CaMeLz-LosAngeles (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-LosAngeles (ICMP)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $oregon_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sna_public_cidr,Description=\"Office-CaMeLz-Irvine (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Office-CaMeLz-Irvine (ICMP)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $oregon_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Home-MCrawford (ICMP)\"}]" \
                                             --profile $profile --region us-west-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $oregon_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $oregon_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_lax_public_cidr,Description=\"DataCenter-CaMeLz-LosAngeles (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-LosAngeles (SSH)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $oregon_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sna_public_cidr,Description=\"Office-CaMeLz-Irvine (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Office-CaMeLz-Irvine (SSH)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $oregon_management_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Home-MCrawford (SSH)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    ```

1. **Create LinuxWebServer EIP**

    ```bash
    oregon_management_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                          --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Management-LinuxWebServer-EIPA},{Key=Hostname,Value=cmlue1mlws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'AllocationId' \
                                                          --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_lws_eipa

    oregon_management_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $oregon_management_lws_eipa \
                                                                           --query 'Addresses[0].PublicIp' \
                                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_lws_instancea_public_ip
    ```

1. **Create LinuxWebServer Public Domain Name**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/oregon-management-lwsa-public-$$.json
    sed -e "s/@hostname@/$oregon_management_lws_instancea_public_hostname/g" \
        -e "s/@servicename@/$oregon_management_lws_instancea_public_hostalias/g" \
        -e "s/@ip@/$oregon_management_lws_instancea_public_ip/g" \
        $CAMELZ_HOME/templates/route53-upsert-a-hostname-cname-servicename.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $oregon_management_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-west-2 --output text
    ```

1. **Create LinuxWebServer Instance**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/oregon-management-lwsa-user-data-$$.sh
    sed -e "s/@hostname@/$oregon_management_lws_instancea_private_hostname/g" \
        -e "s/@motd@/$oregon_management_lws_instancea_description/g" \
        $CAMELZ_HOME/templates/linux-standard-user-data.sh > $tmpfile

    oregon_management_lws_instancea_id=$(aws ec2 run-instances --image-id $oregon_amzn2_ami_id \
                                                               --instance-type t3a.nano \
                                                               --iam-instance-profile Name=ManagedInstance \
                                                               --key-name administrator \
                                                               --network-interfaces "AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$oregon_management_lws_sg_id],SubnetId=$oregon_management_web_subneta_id" \
                                                               --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Management-LinuxWebServer-InstanceA},{Key=Hostname,Value=cmlue1mlws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --user-data file://$tmpfile \
                                                               --client-token $(date +%s) \
                                                               --query 'Instances[0].InstanceId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_lws_instancea_id

    oregon_management_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $oregon_management_lws_instancea_id \
                                                                            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_lws_instancea_private_ip
    ```

1. **Create LinuxWebServer Private Domain Name**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/oregon-management-lwsa-private-$$.json
    sed -e "s/@hostname@/$oregon_management_lws_instancea_private_hostname/g" \
        -e "s/@servicename@/$oregon_management_lws_instancea_private_hostalias/g" \
        -e "s/@ip@/$oregon_management_lws_instancea_private_ip/g" \
        $CAMELZ_HOME/templates/route53-upsert-a-hostname-cname-servicename.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $oregon_management_private_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-west-2 --output text
    ```

1. **Associate LinuxWebServer EIP with Instance & Create Reverse DNS Public Domain Name**

    ```bash
    aws ec2 associate-address --instance-id $oregon_management_lws_instancea_id --allocation-id $oregon_management_lws_eipa \
                              --profile $profile --region us-west-2 --output text

    aws ec2 modify-address-attribute --allocation-id $oregon_management_lws_eipa \
                                     --domain-name $oregon_management_lws_instancea_public_hostname \
                                     --profile $profile --region us-west-2 --output text
    ```

1. **Create LinuxApplicationServer Identifiers**

    ```bash
    oregon_management_las_instancea_description="CaMeLz Oregon Management Linux Application Server 01-A"
    camelz-variable oregon_management_las_instancea_description

    oregon_management_las_instancea_private_hostname=cmlue1mlas01a.$oregon_management_private_domain
    camelz-variable oregon_management_las_instancea_private_hostname

    oregon_management_las_instancea_private_hostalias=lasa.$oregon_management_private_domain
    camelz-variable oregon_management_las_instancea_private_hostalias
    ```

1. **Create LinuxApplicationServer Security Group**

    ```bash
    oregon_management_las_sg_id=$(aws ec2 create-security-group --group-name Management-LinuxApplicationServer-InstanceSecurityGroup \
                                                                --description Management-LinuxApplicationServer-InstanceSecurityGroup \
                                                                --vpc-id $oregon_management_vpc_id \
                                                                --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Management-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_las_sg_id

    aws ec2 authorize-security-group-ingress --group-id $oregon_management_las_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"All (ICMP)\"}]" \
                                             --profile $profile --region us-west-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $oregon_management_las_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$oregon_management_lws_sg_id,Description=\"Management-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $oregon_management_las_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    ```

1. **Create LinuxApplicationServer Instance**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/oregon-management-lasa-user-data-$$.sh
    sed -e "s/@hostname@/$oregon_management_las_instancea_private_hostname/g" \
        -e "s/@motd@/$oregon_management_las_instancea_description/g" \
        $CAMELZ_HOME/templates/linux-standard-user-data.sh > $tmpfile

    oregon_management_las_instancea_id=$(aws ec2 run-instances --image-id $oregon_amzn2_ami_id \
                                                               --instance-type t3a.nano \
                                                               --iam-instance-profile Name=ManagedInstance \
                                                               --key-name administrator \
                                                               --network-interfaces "AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Management-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$oregon_management_las_sg_id],SubnetId=$oregon_management_application_subneta_id" \
                                                               --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Management-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=cmlue1mlas01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --user-data file://$tmpfile \
                                                               --client-token $(date +%s) \
                                                               --query 'Instances[0].InstanceId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_las_instancea_id

    oregon_management_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $oregon_management_las_instancea_id \
                                                                            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_las_instancea_private_ip
    ```

1. **Create LinuxApplicationServer Private Domain Name**

    ```bash
    tmpfile=$CAMELS_HOME/tmp/oregon-management-lasa-private-$$.json
    sed -e "s/@hostname@/$oregon_management_las_instancea_private_hostname/g" \
        -e "s/@servicename@/$oregon_management_las_instancea_private_hostalias/g" \
        -e "s/@ip@/$oregon_management_las_instancea_private_ip/g" \
        $CAMELZ_HOME/templates/route53-upsert-a-hostname-cname-servicename.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $oregon_management_private_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-west-2 --output text
    ```
