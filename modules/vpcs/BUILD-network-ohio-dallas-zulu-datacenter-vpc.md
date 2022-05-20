# Modules:VPCs:Network Account:Ohio:Zulu Dallas Data Center VPC

This module builds the Zulu-Dallas-DataCenter VPC in the AWS Ohio (us-east-2) Region within the CaMeLz-Network Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Zulu-Dallas-DataCenter VPC

1. **Set Profile for Network Account**

    ```bash
    profile=$network_profile
    ```

1. **Create VPC**

    ```bash
    zulu_dfw_vpc_id=$(aws ec2 create-vpc --cidr-block $zulu_dfw_vpc_cidr \
                                         --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-VPC},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                         --query 'Vpc.VpcId' \
                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_vpc_id


    aws ec2 modify-vpc-attribute --vpc-id $zulu_dfw_vpc_id \
                                 --enable-dns-support \
                                 --profile $profile --region us-east-2 --output text

    aws ec2 modify-vpc-attribute --vpc-id $zulu_dfw_vpc_id \
                                 --enable-dns-hostnames \
                                 --profile $profile --region us-east-2 --output text
    ```

1. **Tag Attached Default Resources Created With VPC**

    Creating a VPC also creates a set of attached default resources which do not have the same tags propagated.
    We will also tag these associated resources to insure consistency in the list displays.

    ```bash
    # Tag Zulu-Dallas-DataCenter-MainRouteTable
    main_rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$zulu_dfw_vpc_id \
                                                          Name=association.main,Values=true \
                                                --query 'RouteTables[0].RouteTableId' \
                                                --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $main_rtb_id \
                        --tags Key=Name,Value=Zulu-Dallas-DataCenter-MainRouteTable \
                               Key=Company,Value=Zulu \
                               Key=Location,Value=Dallas \
                               Key=Environment,Value=Network \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

    # Tag Zulu-Dallas-DataCenter-DefaultNetworkAcl
    default_nacl_id=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$zulu_dfw_vpc_id \
                                                              Name=default,Values=true \
                                                    --query 'NetworkAcls[0].NetworkAclId' \
                                                    --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $default_nacl_id \
                        --tags Key=Name,Value=Zulu-Dallas-DataCenter-DefaultNetworkAcl \
                               Key=Company,Value=Zulu \
                               Key=Location,Value=Dallas \
                               Key=Environment,Value=Network \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

    # Tag Zulu-Dallas-DataCenter-DefaultSecurityGroup
    default_sg_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$zulu_dfw_vpc_id \
                                                               Name=group-name,Values=default \
                                                     --query 'SecurityGroups[0].GroupId' \
                                                     --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $default_sg_id \
                        --tags Key=Name,Value=Zulu-Dallas-DataCenter-DefaultSecurityGroup \
                               Key=Company,Value=Zulu \
                               Key=Location,Value=Dallas \
                               Key=Environment,Value=Network \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Flow Log**

    ```bash
    aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Zulu-Dallas-DataCenter" \
                              --profile $profile --region us-east-2 --output text

    aws logs put-retention-policy --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Zulu-Dallas-DataCenter" \
                                  --retention-in-days 14 \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 create-flow-logs --resource-type VPC --resource-ids $zulu_dfw_vpc_id \
                             --traffic-type ALL \
                             --log-destination-type cloud-watch-logs \
                             --log-destination "arn:aws:logs:us-east-2:${network_account_id}:log-group:/${company_name_lc}/${system_name_lc}/FlowLog/Zulu-Dallas-DataCenter" \
                             --deliver-logs-permission-arn "arn:aws:iam::${network_account_id}:role/FlowLog" \
                             --tag-specifications "ResourceType=vpc-flow-log,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-FlowLog},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                             --profile $profile --region us-east-2 --output text
    ```

1. **Create Internet Gateway**

    ```bash
    zulu_dfw_igw_id=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-InternetGateway},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                      --query 'InternetGateway.InternetGatewayId' \
                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_igw_id

    aws ec2 attach-internet-gateway --vpc-id $zulu_dfw_vpc_id \
                                    --internet-gateway-id $zulu_dfw_igw_id \
                                    --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Hosted Zone**

    ```bash
    zulu_dfw_private_hostedzone_id=$(aws route53 create-hosted-zone --name $zulu_dfw_private_domain \
                                                                    --vpc VPCRegion=us-east-2,VPCId=$zulu_dfw_vpc_id \
                                                                    --hosted-zone-config Comment="Private Zone for $zulu_dfw_private_domain",PrivateZone=true \
                                                                    --caller-reference $(date +%s) \
                                                                    --query 'HostedZone.Id' \
                                                                    --profile $profile --region us-east-2 --output text | cut -f3 -d /)
    camelz-variable zulu_dfw_private_hostedzone_id
    ```

1. **Create DHCP Options Set**

    ```bash
    zulu_dfw_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$zulu_dfw_private_domain]" \
                                                                         "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                   --tag-specifications "ResourceType=dhcp-options,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-DHCPOptions},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                   --query 'DhcpOptions.DhcpOptionsId' \
                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_dopt_id

    aws ec2 associate-dhcp-options --vpc-id $zulu_dfw_vpc_id \
                                   --dhcp-options-id $zulu_dfw_dopt_id \
                                   --profile $profile --region us-east-2 --output text
    ```

1. **Create Public Subnet A**

    ```bash
    zulu_dfw_public_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                       --cidr-block $zulu_dfw_public_subneta_cidr \
                                                       --availability-zone us-east-2a \
                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-PublicSubnetA},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_public_subneta_id
    ```

1. **Create Public Subnet B**

    ```bash
    zulu_dfw_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                       --cidr-block $zulu_dfw_public_subnetb_cidr \
                                                       --availability-zone us-east-2b \
                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-PublicSubnetB},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_public_subnetb_id
    ```

1. **Create Private Subnet A**

    ```bash
    zulu_dfw_private_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                        --cidr-block $zulu_dfw_private_subneta_cidr \
                                                        --availability-zone us-east-2a \
                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-PrivateSubnetA},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_private_subneta_id
    ```

1. **Create Private Subnet B**

    ```bash
    zulu_dfw_private_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                        --cidr-block $zulu_dfw_private_subnetb_cidr \
                                                        --availability-zone us-east-2b \
                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-PrivateSubnetB},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_private_subnetb_id
    ```

1. **Create Endpoint Subnet A**

    ```bash
    zulu_dfw_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                         --cidr-block $zulu_dfw_endpoint_subneta_cidr \
                                                         --availability-zone us-east-2a \
                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-EndpointSubnetA},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_endpoint_subneta_id
    ```

1. **Create Endpoint Subnet B**

    ```bash
    zulu_dfw_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                         --cidr-block $zulu_dfw_endpoint_subnetb_cidr \
                                                         --availability-zone us-east-2b \
                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-EndpointSubnetB},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_endpoint_subnetb_id
    ```

1. **Create Firewall Subnet A**

    ```bash
    zulu_dfw_firewall_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                         --cidr-block $zulu_dfw_firewall_subneta_cidr \
                                                         --availability-zone us-east-2a \
                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-FirewallSubnetA},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_firewall_subneta_id
    ```

1. **Create Firewall Subnet B**

    ```bash
    zulu_dfw_firewall_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                         --cidr-block $zulu_dfw_firewall_subnetb_cidr \
                                                         --availability-zone us-east-2b \
                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-FirewallSubnetB},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_firewall_subnetb_id
    ```

1. **Create Gateway Subnet A**

    ```bash
    zulu_dfw_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                        --cidr-block $zulu_dfw_gateway_subneta_cidr \
                                                        --availability-zone us-east-2a \
                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-GatewaySubnetA},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_gateway_subneta_id
    ```

1. **Create Gateway Subnet B**

    ```bash
    zulu_dfw_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                        --cidr-block $zulu_dfw_gateway_subnetb_cidr \
                                                        --availability-zone us-east-2b \
                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-GatewaySubnetB},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_gateway_subnetb_id
    ```

1. **Create Public Route Table, Default Route and Associate with Public Subnets**

    ```bash
    zulu_dfw_public_rtb_id=$(aws ec2 create-route-table --vpc-id $zulu_dfw_vpc_id \
                                                        --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-PublicRouteTable},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'RouteTable.RouteTableId' \
                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_public_rtb_id

    aws ec2 create-route --route-table-id $zulu_dfw_public_rtb_id \
                         --destination-cidr-block '0.0.0.0/0' \
                         --gateway-id $zulu_dfw_igw_id \
                         --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $zulu_dfw_public_rtb_id --subnet-id $zulu_dfw_public_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_dfw_public_rtb_id --subnet-id $zulu_dfw_public_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create NAT Gateways - OR - NAT Instances**

    This Step can create either NAT Gateway(s) or NAT Instance(s), depending on what you want to do.
    - NAT Gateways are the recommended and scalable approach. But, you can't turn them off, and they are $32/each per
      month.
    - NAT Instances are neither recommended nor scalable. If they fail, you must manually replace them. But, you can
      pick very inexpensive instance types which are about $5/month and turn them off when not in use, so for
      prototyping and development environments, this is a way to save on costs.

    This Step can also create either a fully HA set of the NAT device, or a single instance in AZ A, used by the other
    AZs. The risk of an AZ failure is extremely small, so it's questionable if the cost to have 3 copies is worthwhile.

    TBD: Not sure if showing the if statement logic is better than just having the user choose which statements to run
    based on a description here without explicit if statements.

    ```bash
    if [ $use_ngw = 1 ]; then
      # Create NAT Gateways
      zulu_dfw_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                   --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-NAT-EIPA},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                   --query 'AllocationId' \
                                                   --profile $profile --region us-east-2 --output text)
      camelz-variable zulu_dfw_ngw_eipa

      zulu_dfw_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $zulu_dfw_ngw_eipa \
                                                    --subnet-id $zulu_dfw_public_subneta_id \
                                                    --client-token $(date +%s) \
                                                    --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-NAT-GatewayA},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                    --query 'NatGateway.NatGatewayId' \
                                                    --profile $profile --region us-east-2 --output text)
      camelz-variable zulu_dfw_ngwa_id

      if [ $ha_ngw = 1 ]; then
        zulu_dfw_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                     --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-NAT-EIPB},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                     --query 'AllocationId' \
                                                     --profile $profile --region us-east-2 --output text)
        camelz-variable zulu_dfw_ngw_eipb

        zulu_dfw_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $zulu_dfw_ngw_eipb \
                                                      --subnet-id $zulu_dfw_public_subnetb_id \
                                                      --client-token $(date +%s) \
                                                      --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-NAT-GatewayB},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                      --query 'NatGateway.NatGatewayId' \
                                                      --profile $profile --region us-east-2 --output text)
        camelz-variable zulu_dfw_ngwb_id
      fi
    else
      # Create NAT Security Group
      zulu_dfw_nat_sg_id=$(aws ec2 create-security-group --group-name Zulu-Dallas-DataCenter-NAT-InstanceSecurityGroup \
                                                         --description Zulu-Dallas-DataCenter-NAT-InstanceSecurityGroup \
                                                         --vpc-id $zulu_dfw_vpc_id \
                                                         --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-NAT-InstanceSecurityGroup},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'GroupId' \
                                                         --profile $profile --region us-east-2 --output text)
      camelz-variable zulu_dfw_nat_sg_id

      aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_nat_sg_id \
                                               --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"VPC (All)\"}]" \
                                               --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All)\"}]" \
                                               --profile $profile --region us-east-2 --output text

      # Create NAT Instance
      zulu_dfw_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                       --instance-type t3a.nano \
                                                       --iam-instance-profile Name=ManagedInstance \
                                                       --key-name administrator \
                                                       --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Zulu-Dallas-DataCenter-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_dfw_nat_sg_id],SubnetId=$zulu_dfw_public_subneta_id" \
                                                       --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-NAT-Instance},{Key=Hostname,Value=cmlue2bnat01a},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                       --query 'Instances[0].InstanceId' \
                                                       --profile $profile --region us-east-2 --output text)
      camelz-variable zulu_dfw_nat_instance_id

      aws ec2 modify-instance-attribute --instance-id $zulu_dfw_nat_instance_id \
                                        --no-source-dest-check \
                                        --profile $profile --region us-east-2 --output text

      zulu_dfw_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $zulu_dfw_nat_instance_id \
                                                                --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                --profile $profile --region us-east-2 --output text)
      camelz-variable zulu_dfw_nat_instance_eni_id

      zulu_dfw_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_dfw_nat_instance_id \
                                                                    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                    --profile $profile --region us-east-2 --output text)
      camelz-variable zulu_dfw_nat_instance_private_ip
    fi
    ```

1. **Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets**

    ```bash
    zulu_dfw_private_rtba_id=$(aws ec2 create-route-table --vpc-id $zulu_dfw_vpc_id \
                                                          --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-PrivateRouteTableA},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'RouteTable.RouteTableId' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_private_rtba_id

    if [ $use_ngw = 1 ]; then
      aws ec2 create-route --route-table-id $zulu_dfw_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $zulu_dfw_ngwa_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $zulu_dfw_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $zulu_dfw_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtba_id --subnet-id $zulu_dfw_private_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtba_id --subnet-id $zulu_dfw_endpoint_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtba_id --subnet-id $zulu_dfw_firewall_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtba_id --subnet-id $zulu_dfw_gateway_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Route Table for Availability Zone B, Default Route and Associate with Private Subnets**

    ```bash
    zulu_dfw_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $zulu_dfw_vpc_id \
                                                          --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-PrivateRouteTableB},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'RouteTable.RouteTableId' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_private_rtbb_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then zulu_dfw_ngw_id=$zulu_dfw_ngwb_id; else zulu_dfw_ngw_id=$zulu_dfw_ngwa_id; fi
      aws ec2 create-route --route-table-id $zulu_dfw_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $zulu_dfw_ngw_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $zulu_dfw_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $zulu_dfw_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtbb_id --subnet-id $zulu_dfw_private_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtbb_id --subnet-id $zulu_dfw_endpoint_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtbb_id --subnet-id $zulu_dfw_firewall_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtbb_id --subnet-id $zulu_dfw_gateway_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Endpoint Security Group**

    ```bash
    zulu_dfw_vpce_sg_id=$(aws ec2 create-security-group --group-name Zulu-Dallas-DataCenter-VPCEndpointSecurityGroup \
                                                        --description Zulu-Dallas-DataCenter-VPCEndpointSecurityGroup \
                                                        --vpc-id $zulu_dfw_vpc_id \
                                                        --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-VPCEndpointSecurityGroup},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'GroupId' \
                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_vpce_sg_id

    aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_vpce_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All TCP)\"}]" \
                                             --profile $profile --region us-east-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_vpce_sg_id \
                                             --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All UDP)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Endpoints for SSM and SSMMessages**

    ```bash
    zulu_dfw_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $zulu_dfw_vpc_id \
                                                       --vpc-endpoint-type Interface \
                                                       --service-name com.amazonaws.us-east-2.ssm \
                                                       --private-dns-enabled \
                                                       --security-group-ids $zulu_dfw_vpce_sg_id \
                                                       --subnet-ids $zulu_dfw_endpoint_subneta_id $zulu_dfw_endpoint_subnetb_id \
                                                       --client-token $(date +%s) \
                                                       --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-SSMVpcEndpoint},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                       --query 'VpcEndpoint.VpcEndpointId' \
                                                       --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_ssm_vpce_id

    zulu_dfw_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $zulu_dfw_vpc_id \
                                                        --vpc-endpoint-type Interface \
                                                        --service-name com.amazonaws.us-east-2.ssmmessages \
                                                        --private-dns-enabled \
                                                        --security-group-ids $zulu_dfw_vpce_sg_id \
                                                        --subnet-ids $zulu_dfw_endpoint_subneta_id $zulu_dfw_endpoint_subnetb_id \
                                                        --client-token $(date +%s) \
                                                        --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Zulu-Dallas-DataCenter-SSMMessagesVpcEndpoint},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'VpcEndpoint.VpcEndpointId' \
                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_dfw_ssmm_vpce_id
    ```
