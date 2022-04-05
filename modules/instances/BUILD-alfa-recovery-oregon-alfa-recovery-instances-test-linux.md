# Modules:Instances:Alfa Recovery Account:Oregon:Linux Test Instances

This module builds Linux Test Instances in the Alfa-Recovery VPC in the AWS Oregon (us-west-2) Region within the
Alfa-CaMeLz-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.
- Role: ManagedInstance
- Public Hosted Zone: r.us-west-2.alfa.camelz.io
- KeyPair: administrator
- VPC: (Oregon) Alfa-Recovery-VPC

## Oregon Alfa-Recovery Linux Test Instances

1. **Set Profile for Alfa-Recovery Account**

    ```bash
    profile=$alfa_recovery_profile
    ```

1. **Create LinuxWebServer Identifiers**

    ```bash
    alfa_oregon_recovery_lws_instancea_description="Alfa Oregon Recovery Linux Web Server 01-A"
    camelz-variable alfa_oregon_recovery_lws_instancea_description

    alfa_oregon_recovery_lws_instancea_public_hostname=alfuw2rlws01a.$alfa_oregon_recovery_public_domain
    camelz-variable alfa_oregon_recovery_lws_instancea_public_hostname

    alfa_oregon_recovery_lws_instancea_public_hostalias=lwsa.$alfa_oregon_recovery_public_domain
    camelz-variable alfa_oregon_recovery_lws_instancea_public_hostalias

    alfa_oregon_recovery_lws_instancea_private_hostname=alfuw2rlws01a.$alfa_oregon_recovery_private_domain
    camelz-variable alfa_oregon_recovery_lws_instancea_private_hostname

    alfa_oregon_recovery_lws_instancea_private_hostalias=lwsa.$alfa_oregon_recovery_private_domain
    camelz-variable alfa_oregon_recovery_lws_instancea_private_hostalias
    ```

1. **Create LinuxWebServer Security Group**

    ```bash
    alfa_oregon_recovery_lws_sg_id=$(aws ec2 create-security-group --group-name Alfa-Recovery-LinuxWebServer-InstanceSecurityGroup \
                                                                   --description Alfa-Recovery-LinuxWebServer-InstanceSecurityGroup \
                                                                   --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                   --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Recovery-LinuxWebServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'GroupId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_lws_sg_id

    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-SantaBarbara (ICMP)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_lax_public_cidr,Description=\"DataCenter-CaMeLz-LosAngeles (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-LosAngeles (ICMP)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$cml_sna_public_cidr,Description=\"Office-CaMeLz-Irvine (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Office-CaMeLz-Irvine (ICMP)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_lws_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Home-MCrawford (ICMP)\"}]" \
                                             --profile $profile --region us-west-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_lax_public_cidr,Description=\"DataCenter-CaMeLz-LosAngeles (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-LosAngeles (SSH)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sna_public_cidr,Description=\"Office-CaMeLz-Irvine (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Office-CaMeLz-Irvine (SSH)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_lws_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Home-MCrawford (SSH)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    ```

1. **Create LinuxWebServer EIP**

    ```bash
    alfa_oregon_recovery_lws_eipa=$(aws ec2 allocate-address --domain vpc \
                                                             --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Recovery-LinuxWebServer-EIPA},{Key=Hostname,Value=alfue2plws01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'AllocationId' \
                                                             --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_lws_eipa

    alfa_oregon_recovery_lws_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_oregon_recovery_lws_eipa \
                                                                              --query 'Addresses[0].PublicIp' \
                                                                              --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_lws_instancea_public_ip
    ```

1. **Create LinuxWebServer Public Domain Name**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/alfa-oregon-recovery-lwsa-public-$$.json
    sed -e "s/@hostname@/$alfa_oregon_recovery_lws_instancea_public_hostname/g" \
        -e "s/@servicename@/$alfa_oregon_recovery_lws_instancea_public_hostalias/g" \
        -e "s/@ip@/$alfa_oregon_recovery_lws_instancea_public_ip/g" \
        $CAMELZ_HOME/templates/route53-upsert-a-hostname-cname-servicename.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $alfa_oregon_recovery_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```

1. **Create LinuxWebServer Instance**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/alfa-oregon-recovery-lwsa-user-data-$$.sh
    sed -e "s/@hostname@/$alfa_oregon_recovery_lws_instancea_private_hostname/g" \
        -e "s/@motd@/$alfa_oregon_recovery_lws_instancea_description/g" \
        $CAMELZ_HOME/templates/linux-standard-user-data.sh > $tmpfile

    alfa_oregon_recovery_lws_instancea_id=$(aws ec2 run-instances --image-id $oregon_amzn2_ami_id \
                                                                  --instance-type t3a.nano \
                                                                  --iam-instance-profile Name=ManagedInstance \
                                                                  --key-name administrator \
                                                                  --network-interfaces "AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Recovery-LinuxWebServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_oregon_recovery_lws_sg_id],SubnetId=$alfa_oregon_recovery_web_subneta_id" \
                                                                  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Recovery-LinuxWebServer-InstanceA},{Key=Hostname,Value=alfue2plws01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Application,Value=LinuxWebServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --user-data file://$tmpfile \
                                                                  --client-token $(date +%s) \
                                                                  --query 'Instances[0].InstanceId' \
                                                                  --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_lws_instancea_id

    alfa_oregon_recovery_lws_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_oregon_recovery_lws_instancea_id \
                                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_lws_instancea_private_ip
    ```

1. **Create LinuxWebServer Private Domain Name**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/alfa-oregon-recovery-lwsa-private-$$.json
    sed -e "s/@hostname@/$alfa_oregon_recovery_lws_instancea_private_hostname/g" \
        -e "s/@servicename@/$alfa_oregon_recovery_lws_instancea_private_hostalias/g" \
        -e "s/@ip@/$alfa_oregon_recovery_lws_instancea_private_ip/g" \
        $CAMELZ_HOME/templates/route53-upsert-a-hostname-cname-servicename.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $alfa_oregon_recovery_private_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```

1. **Associate LinuxWebServer EIP with Instance & Create Reverse DNS Public Domain Name**

    ```bash
    aws ec2 associate-address --instance-id $alfa_oregon_recovery_lws_instancea_id --allocation-id $alfa_oregon_recovery_lws_eipa \
                              --profile $profile --region us-west-2 --output text

    aws ec2 modify-address-attribute --allocation-id $alfa_oregon_recovery_lws_eipa \
                                     --domain-name $alfa_oregon_recovery_lws_instancea_public_hostname \
                                     --profile $profile --region us-west-2 --output text
    ```

1. **Create LinuxApplicationServer Identifiers**

    ```bash
    alfa_oregon_recovery_las_instancea_description="Alfa Oregon Recovery Linux Application Server 01-A"
    camelz-variable alfa_oregon_recovery_las_instancea_description

    alfa_oregon_recovery_las_instancea_private_hostname=alfuw2rlas01a.$alfa_oregon_recovery_private_domain
    camelz-variable alfa_oregon_recovery_las_instancea_private_hostname

    alfa_oregon_recovery_las_instancea_private_hostalias=lasa.$alfa_oregon_recovery_private_domain
    camelz-variable alfa_oregon_recovery_las_instancea_private_hostalias
    ```

1. **Create LinuxApplicationServer Security Group**

    ```bash
    alfa_oregon_recovery_las_sg_id=$(aws ec2 create-security-group --group-name Alfa-Recovery-LinuxApplicationServer-InstanceSecurityGroup \
                                                                   --description Alfa-Recovery-LinuxApplicationServer-InstanceSecurityGroup \
                                                                   --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                   --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Recovery-LinuxApplicationServer-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'GroupId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_las_sg_id

    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_las_sg_id \
                                             --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (ICMP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Global (ICMP)\"}]" \
                                             --profile $profile --region us-west-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_las_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,UserIdGroupPairs=[{GroupId=$alfa_oregon_recovery_lws_sg_id,Description=\"Alfa-Recovery-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"Alfa-Recovery-LinuxWebServer-InstanceSecurityGroup (SSH)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_las_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"DataCenter-CaMeLz-SantaBarbara (SSH)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    ```

1. **Create LinuxApplicationServer Instance**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/alfa-oregon-recovery-lasa-user-data-$$.sh
    sed -e "s/@hostname@/$alfa_oregon_recovery_las_instancea_private_hostname/g" \
        -e "s/@motd@/$alfa_oregon_recovery_las_instancea_description/g" \
        $CAMELZ_HOME/templates/linux-standard-user-data.sh > $tmpfile

    alfa_oregon_recovery_las_instancea_id=$(aws ec2 run-instances --image-id $oregon_amzn2_ami_id \
                                                                  --instance-type t3a.nano \
                                                                  --iam-instance-profile Name=ManagedInstance \
                                                                  --key-name administrator \
                                                                  --network-interfaces "AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Recovery-LinuxApplicationServer-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_oregon_recovery_las_sg_id],SubnetId=$alfa_oregon_recovery_application_subneta_id" \
                                                                  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Recovery-LinuxApplicationServer-InstanceA},{Key=Hostname,Value=alfue2plas01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Application,Value=LinuxApplicationServer},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --user-data file://$tmpfile \
                                                                  --client-token $(date +%s) \
                                                                  --query 'Instances[0].InstanceId' \
                                                                  --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_las_instancea_id

    alfa_oregon_recovery_las_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_oregon_recovery_las_instancea_id \
                                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_las_instancea_private_ip
    ```

1. **Create LinuxApplicationServer Private Domain Name**

    ```bash
    tmpfile=$CAMELS_HOME/tmp/alfa-oregon-recovery-lasa-private-$$.json
    sed -e "s/@hostname@/$alfa_oregon_recovery_las_instancea_private_hostname/g" \
        -e "s/@servicename@/$alfa_oregon_recovery_las_instancea_private_hostalias/g" \
        -e "s/@ip@/$alfa_oregon_recovery_las_instancea_private_ip/g" \
        $CAMELZ_HOME/templates/route53-upsert-a-hostname-cname-servicename.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $alfa_oregon_recovery_private_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```
