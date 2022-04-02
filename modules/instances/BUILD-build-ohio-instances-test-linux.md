# Modules:Instances:Build Account:Ohio:Linux Test Instances

This module builds Linux Test Instances in the Build VPC in the AWS Ohio (us-east-2) Region within the
CaMeLz-Build Account.

## Dependencies

**TODO**: Determine Dependencies and list.
- Role: ManagedInstance
- Public Hosted Zone: b.us-east-2.camelz.io
- KeyPair: administrator
- VPC: (Ohio) Build-VPC

## Ohio Build Linux Test Instances

1. **Set Profile for Build Account**

    ```bash
    profile=$build_profile
    ```

1. **Create LinuxWebServer Identifiers**

    ```bash
    ohio_build_lws_instancea_description="CaMeLz Ohio Build Linux Web Server 01-A"
    camelz-variable ohio_build_lws_instancea_description

    ohio_build_lws_instancea_public_hostname=cmlue2blws01a.$ohio_build_public_domain
    camelz-variable ohio_build_lws_instancea_public_hostname

    ohio_build_lws_instancea_public_hostalias=lwsa.$ohio_build_public_domain
    camelz-variable ohio_build_lws_instancea_public_hostalias

    ohio_build_lws_instancea_private_hostname=cmlue2blws01a.$ohio_build_private_domain
    camelz-variable ohio_build_lws_instancea_private_hostname

    ohio_build_lws_instancea_private_hostalias=lwsa.$ohio_build_private_domain
    camelz-variable ohio_build_lws_instancea_private_hostalias
    ```

1. **Create LinuxWebServer Security Group**

    ```bash
    ohio_build_lws_sg_id=$(aws ec2 create-security-group --group-name Build-LinuxWebServer-InstanceSecurityGroup \
                                                         --description Build-LinuxWebServer-InstanceSecurityGroup \
                                                         --vpc-id $ohio_build_vpc_id \
                                                         --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Build-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'GroupId' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_lws_sg_id

    aws ec2 authorize-security-group-ingress --group-id $ohio_build_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $ohio_build_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_lax_public_cidr,Description=\"DataCenter-CaMeLz-LosAngeles (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-LosAngeles (ICMP)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $ohio_build_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sna_public_cidr,Description=\"Office-CaMeLz-Irvine (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Office-CaMeLz-Irvine (ICMP)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $ohio_build_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Home-MCrawford (ICMP)\"}]" \
                                             --profile $profile --region us-east-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $ohio_build_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $ohio_build_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_lax_public_cidr,Description=\"DataCenter-CaMeLz-LosAngeles (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-LosAngeles (SSH)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $ohio_build_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sna_public_cidr,Description=\"Office-CaMeLz-Irvine (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Office-CaMeLz-Irvine (SSH)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $ohio_build_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Home-MCrawford (SSH)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    ```

1. **Create LinuxWebServer EIP**

    ```bash
    ohio_build_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                   --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Build-LinuxWebServer-EIPA},{Key=Hostname,Value=cmlue2blws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                   --query 'AllocationId' \
                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_lws_eipa

    ohio_build_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $ohio_build_lws_eipa \
                                                                           --query 'Addresses[0].PublicIp' \
                                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_lws_instancea_public_ip
    ```

1. **Create LinuxWebServer Public Domain Name**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/ohio-build-lwsa-public-$$.json
    sed -e "s/@hostname@/$ohio_build_lws_instancea_public_hostname/g" \
        -e "s/@servicename@/$ohio_build_lws_instancea_public_hostalias/g" \
        -e "s/@ip@/$ohio_build_lws_instancea_public_ip/g" \
        $CAMELZ_HOME/templates/route53-upsert-a-hostname-cname-servicename.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $ohio_build_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```

1. **Create LinuxWebServer Instance**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/ohio-build-lwsa-user-data-$$.sh
    sed -e "s/@hostname@/$ohio_build_lws_instancea_private_hostname/g" \
        -e "s/@motd@/$ohio_build_lws_instancea_description/g" \
        $CAMELZ_HOME/templates/linux-standard-user-data.sh > $tmpfile

    ohio_build_lws_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                        --instance-type t3a.nano \
                                                        --iam-instance-profile Name=ManagedInstance \
                                                        --key-name administrator \
                                                        --network-interfaces "AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Build-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_build_lws_sg_id],SubnetId=$ohio_build_web_subneta_id" \
                                                        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Build-LinuxWebServer-InstanceA},{Key=Hostname,Value=cmlue2blws01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --user-data file://$tmpfile \
                                                        --client-token $(date +%s) \
                                                        --query 'Instances[0].InstanceId' \
                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_lws_instancea_id

    ohio_build_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_build_lws_instancea_id \
                                                                     --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_lws_instancea_private_ip
    ```

1. **Create LinuxWebServer Private Domain Name**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/ohio-build-lwsa-private-$$.json
    sed -e "s/@hostname@/$ohio_build_lws_instancea_private_hostname/g" \
        -e "s/@servicename@/$ohio_build_lws_instancea_private_hostalias/g" \
        -e "s/@ip@/$ohio_build_lws_instancea_private_ip/g" \
        $CAMELZ_HOME/templates/route53-upsert-a-hostname-cname-servicename.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $ohio_build_private_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```

1. **Associate LinuxWebServer EIP with Instance & Create Reverse DNS Public Domain Name**

    ```bash
    aws ec2 associate-address --instance-id $ohio_build_lws_instancea_id --allocation-id $ohio_build_lws_eipa \
                              --profile $profile --region us-east-2 --output text

    aws ec2 modify-address-attribute --allocation-id $ohio_build_lws_eipa \
                                     --domain-name $ohio_build_lws_instancea_public_hostname \
                                     --profile $profile --region us-east-2 --output text
    ```

1. **Create LinuxApplicationServer Identifiers**

    ```bash
    ohio_build_las_instancea_description="CaMeLz Ohio Build Linux Application Server 01-A"
    camelz-variable ohio_build_las_instancea_description

    ohio_build_las_instancea_private_hostname=cmlue2blas01a.$ohio_build_private_domain
    camelz-variable ohio_build_las_instancea_private_hostname

    ohio_build_las_instancea_private_hostalias=lasa.$ohio_build_private_domain
    camelz-variable ohio_build_las_instancea_private_hostalias
    ```

1. **Create LinuxApplicationServer Security Group**

    ```bash
    ohio_build_las_sg_id=$(aws ec2 create-security-group --group-name Build-LinuxApplicationServer-InstanceSecurityGroup \
                                                         --description Build-LinuxApplicationServer-InstanceSecurityGroup \
                                                         --vpc-id $ohio_build_vpc_id \
                                                         --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Build-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'GroupId' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_las_sg_id

    aws ec2 authorize-security-group-ingress --group-id $ohio_build_las_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Global (ICMP)\"}]" \
                                             --profile $profile --region us-east-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $ohio_build_las_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$ohio_build_lws_sg_id,Description=\"Build-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Build-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $ohio_build_las_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    ```

1. **Create LinuxApplicationServer Instance**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/ohio-build-lasa-user-data-$$.sh
    sed -e "s/@hostname@/$ohio_build_las_instancea_private_hostname/g" \
        -e "s/@motd@/$ohio_build_las_instancea_description/g" \
        $CAMELZ_HOME/templates/linux-standard-user-data.sh > $tmpfile

    ohio_build_las_instancea_id=$(aws ec2 run-instances --image-id $ohio_amzn2_ami_id \
                                                        --instance-type t3a.nano \
                                                        --iam-instance-profile Name=ManagedInstance \
                                                        --key-name administrator \
                                                        --network-interfaces "AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Build-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_build_las_sg_id],SubnetId=$ohio_build_application_subneta_id" \
                                                        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Build-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=cmlue2blas01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --user-data file://$tmpfile \
                                                        --client-token $(date +%s) \
                                                        --query 'Instances[0].InstanceId' \
                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_las_instancea_id

    ohio_build_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_build_las_instancea_id \
                                                                     --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_las_instancea_private_ip
    ```

1. **Create LinuxApplicationServer Private Domain Name**

    ```bash
    tmpfile=$CAMELS_HOME/tmp/ohio-build-lasa-private-$$.json
    sed -e "s/@hostname@/$ohio_build_las_instancea_private_hostname/g" \
        -e "s/@servicename@/$ohio_build_las_instancea_private_hostalias/g" \
        -e "s/@ip@/$ohio_build_las_instancea_private_ip/g" \
        $CAMELZ_HOME/templates/route53-upsert-a-hostname-cname-servicename.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $ohio_build_private_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```
