# Modules:VPCs:Network Account:Ohio:Network VPC

This module builds the Network VPC in the AWS Ohio (us-east-2) Region within the CaMeLz-Network Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Network VPC

1. **Set Profile for Network Account**

    ```bash
    profile=$network_profile
    ```

1. **Create VPC**

    ```bash
    ohio_network_vpc_id=$(aws ec2 create-vpc --cidr-block $ohio_network_vpc_cidr \
                                             --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=Network-VPC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                             --query 'Vpc.VpcId' \
                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_vpc_id


    aws ec2 modify-vpc-attribute --vpc-id $ohio_network_vpc_id \
                                 --enable-dns-support \
                                 --profile $profile --region us-east-2 --output text

    aws ec2 modify-vpc-attribute --vpc-id $ohio_network_vpc_id \
                                 --enable-dns-hostnames \
                                 --profile $profile --region us-east-2 --output text
    ```

1. **Tag Attached Default Resources Created With VPC**

    Creating a VPC also creates a set of attached default resources which do not have the same tags propagated.
    We will also tag these associated resources to insure consistency in the list displays.

    ```bash
    # Tag Network-MainRouteTable
    main_rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$ohio_network_vpc_id \
                                                          Name=association.main,Values=true \
                                                --query 'RouteTables[0].RouteTableId' \
                                                --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $main_rtb_id \
                        --tags Key=Name,Value=Network-MainRouteTable \
                               Key=Company,Value=Camelz \
                               Key=Environment,Value=Network \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

    # Tag Network-DefaultNetworkAcl
    default_nacl_id=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$ohio_network_vpc_id \
                                                              Name=default,Values=true \
                                                    --query 'NetworkAcls[0].NetworkAclId' \
                                                    --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $default_nacl_id \
                        --tags Key=Name,Value=Network-DefaultNetworkAcl \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Network \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

    # Tag Default-DefaultSecurityGroup
    default_sg_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$ohio_network_vpc_id \
                                                               Name=group-name,Values=default \
                                                     --query 'SecurityGroups[0].GroupId' \
                                                     --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $default_sg_id \
                        --tags Key=Name,Value=Network-DefaultSecurityGroup \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Network \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Flow Log**

    ```bash
    aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Network/Ohio" \
                              --profile $profile --region us-east-2 --output text

    aws ec2 create-flow-logs --resource-type VPC --resource-ids $ohio_network_vpc_id \
                             --traffic-type ALL \
                             --log-destination-type cloud-watch-logs \
                             --log-destination "arn:aws:logs:us-east-2:${network_account_id}:log-group:/${company_name_lc}/${system_name_lc}/FlowLog/Network/Ohio" \
                             --deliver-logs-permission-arn "arn:aws:iam::${network_account_id}:role/FlowLog" \
                             --profile $profile --region us-east-2 --output text
    ```

1. **Create Internet Gateway**

    ```bash
    ohio_network_igw_id=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Network-InternetGateway},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'InternetGateway.InternetGatewayId' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_igw_id

    aws ec2 attach-internet-gateway --vpc-id $ohio_network_vpc_id \
                                    --internet-gateway-id $ohio_network_igw_id \
                                    --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Hosted Zone**

    ```bash
    ohio_network_private_hostedzone_id=$(aws route53 create-hosted-zone --name $ohio_network_private_domain \
                                                                        --vpc VPCRegion=us-east-2,VPCId=$ohio_network_vpc_id \
                                                                        --hosted-zone-config Comment="Private Zone for $ohio_network_private_domain",PrivateZone=true \
                                                                        --caller-reference $(date +%s) \
                                                                        --query 'HostedZone.Id' \
                                                                        --profile $profile --region us-east-2 --output text | cut -f3 -d /)
    camelz-variable ohio_network_private_hostedzone_id
    ```

1. **Create DHCP Options Set**

    ```bash
    ohio_network_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$ohio_network_private_domain]" \
                                                                             "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                       --tag-specifications "ResourceType=dhcp-options,Tags=[{Key=Name,Value=Network-DHCPOptions},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                       --query 'DhcpOptions.DhcpOptionsId' \
                                                       --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_dopt_id

    aws ec2 associate-dhcp-options --vpc-id $ohio_network_vpc_id \
                                   --dhcp-options-id $ohio_network_dopt_id \
                                   --profile $profile --region us-east-2 --output text
    ```

1. **Create Public Subnet A**

    ```bash
    ohio_network_public_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                           --cidr-block $ohio_network_public_subneta_cidr \
                                                           --availability-zone us-east-2a \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-PublicSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_public_subneta_id
    ```

1. **Create Public Subnet B**

    ```bash
    ohio_network_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                           --cidr-block $ohio_network_public_subnetb_cidr \
                                                           --availability-zone us-east-2b \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-PublicSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_public_subnetb_id
    ```

1. **Create Public Subnet C**

    ```bash
    ohio_network_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                           --cidr-block $ohio_network_public_subnetc_cidr \
                                                           --availability-zone us-east-2c \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-PublicSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_public_subnetc_id
    ```

1. **Create Public7 Subnet A**

    ```bash
    ohio_network_public7_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                            --cidr-block $ohio_network_public7_subneta_cidr \
                                                            --availability-zone us-east-2a \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-Public7SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_public7_subneta_id
    ```

1. **Create Public7 Subnet B**

    ```bash
    ohio_network_public7_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                            --cidr-block $ohio_network_public7_subnetb_cidr \
                                                            --availability-zone us-east-2b \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-Public7SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_public7_subnetb_id
    ```

1. **Create Public7 Subnet C**

    ```bash
    ohio_network_public7_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                            --cidr-block $ohio_network_public7_subnetc_cidr \
                                                            --availability-zone us-east-2c \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-Public7SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_public7_subnetc_id
    ```

1. **Create Web Subnet A**

    ```bash
    ohio_network_web_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                        --cidr-block $ohio_network_web_subneta_cidr \
                                                        --availability-zone us-east-2a \
                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-WebSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_web_subneta_id
    ```

1. **Create Web Subnet B**

    ```bash
    ohio_network_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                        --cidr-block $ohio_network_web_subnetb_cidr \
                                                        --availability-zone us-east-2b \
                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-WebSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_web_subnetb_id
    ```

1. **Create Web Subnet C**

    ```bash
    ohio_network_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                        --cidr-block $ohio_network_web_subnetc_cidr \
                                                        --availability-zone us-east-2c \
                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-WebSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_web_subnetc_id
    ```

1. **Create Web7 Subnet A**

    ```bash
    ohio_network_web7_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                         --cidr-block $ohio_network_web7_subneta_cidr \
                                                         --availability-zone us-east-2a \
                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-Web7SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_web7_subneta_id
    ```

1. **Create Web7 Subnet B**

    ```bash
    ohio_network_web7_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                         --cidr-block $ohio_network_web7_subnetb_cidr \
                                                         --availability-zone us-east-2b \
                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-Web7SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_web7_subnetb_id
    ```

1. **Create Web7 Subnet C**

    ```bash
    ohio_network_web7_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                         --cidr-block $ohio_network_web7_subnetc_cidr \
                                                         --availability-zone us-east-2c \
                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-Web7SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_web7_subnetc_id
    ```

1. **Create Application Subnet A**

    ```bash
    ohio_network_application_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                                --cidr-block $ohio_network_application_subneta_cidr \
                                                                --availability-zone us-east-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-ApplicationSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_application_subneta_id
    ```

1. **Create Application Subnet B**

    ```bash
    ohio_network_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                                --cidr-block $ohio_network_application_subnetb_cidr \
                                                                --availability-zone us-east-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-ApplicationSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_application_subnetb_id
    ```

1. **Create Application Subnet C**

    ```bash
    ohio_network_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                                --cidr-block $ohio_network_application_subnetc_cidr \
                                                                --availability-zone us-east-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-ApplicationSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_application_subnetc_id
    ```

1. **Create Application1 Subnet A**

    ```bash
    ohio_network_application1_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                                 --cidr-block $ohio_network_application1_subneta_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-Application1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_application1_subneta_id
    ```

1. **Create Application1 Subnet B**

    ```bash
    ohio_network_application1_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                                 --cidr-block $ohio_network_application1_subnetb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-Application1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_application1_subnetb_id
    ```

1. **Create Application1 Subnet C**

    ```bash
    ohio_network_application1_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                                 --cidr-block $ohio_network_application1_subnetc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-Application1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_application1_subnetc_id
    ```

1. **Create Cache Subnet A**

    ```bash
    ohio_network_cache_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                          --cidr-block $ohio_network_cache_subneta_cidr \
                                                          --availability-zone us-east-2a \
                                                          --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-CacheSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_cache_subneta_id
    ```

1. **Create Cache Subnet B**

    ```bash
    ohio_network_cache_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                          --cidr-block $ohio_network_cache_subnetb_cidr \
                                                          --availability-zone us-east-2b \
                                                          --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-CacheSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_cache_subnetb_id
    ```

1. **Create Cache Subnet C**

    ```bash
    ohio_network_cache_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                          --cidr-block $ohio_network_cache_subnetc_cidr \
                                                          --availability-zone us-east-2c \
                                                          --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-CacheSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_cache_subnetc_id
    ```

1. **Create Database Subnet A**

    ```bash
    ohio_network_database_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                             --cidr-block $ohio_network_database_subneta_cidr \
                                                             --availability-zone us-east-2a \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-DatabaseSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_database_subneta_id
    ```

1. **Create Database Subnet B**

    ```bash
    ohio_network_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                             --cidr-block $ohio_network_database_subnetb_cidr \
                                                             --availability-zone us-east-2b \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-DatabaseSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_database_subnetb_id
    ```

1. **Create Database Subnet C**

    ```bash
    ohio_network_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                             --cidr-block $ohio_network_database_subnetc_cidr \
                                                             --availability-zone us-east-2c \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-DatabaseSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_database_subnetc_id
    ```

1. **Create Endpoint Subnet A**

    ```bash
    ohio_network_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                             --cidr-block $ohio_network_endpoint_subneta_cidr \
                                                             --availability-zone us-east-2a \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-EndpointSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_endpoint_subneta_id
    ```

1. **Create Endpoint Subnet B**

    ```bash
    ohio_network_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                             --cidr-block $ohio_network_endpoint_subnetb_cidr \
                                                             --availability-zone us-east-2b \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-EndpointSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_endpoint_subnetb_id
    ```

1. **Create Endpoint Subnet C**

    ```bash
    ohio_network_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                             --cidr-block $ohio_network_endpoint_subnetc_cidr \
                                                             --availability-zone us-east-2c \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-EndpointSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_endpoint_subnetc_id
    ```

1. **Create Firewall Subnet A**

    ```bash
    ohio_network_firewall_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                             --cidr-block $ohio_network_firewall_subneta_cidr \
                                                             --availability-zone us-east-2a \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-FirewallSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_firewall_subneta_id
    ```

1. **Create Firewall Subnet B**

    ```bash
    ohio_network_firewall_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                             --cidr-block $ohio_network_firewall_subnetb_cidr \
                                                             --availability-zone us-east-2b \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-FirewallSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_firewall_subnetb_id
    ```

1. **Create Firewall Subnet C**

    ```bash
    ohio_network_firewall_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                             --cidr-block $ohio_network_firewall_subnetc_cidr \
                                                             --availability-zone us-east-2c \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-FirewallSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_firewall_subnetc_id
    ```

1. **Create Gateway Subnet A**

    ```bash
    ohio_network_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                            --cidr-block $ohio_network_gateway_subneta_cidr \
                                                            --availability-zone us-east-2a \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-GatewaySubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_gateway_subneta_id
    ```

1. **Create Gateway Subnet B**

    ```bash
    ohio_network_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                            --cidr-block $ohio_network_gateway_subnetb_cidr \
                                                            --availability-zone us-east-2b \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-GatewaySubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_gateway_subnetb_id
    ```

1. **Create Gateway Subnet C**

    ```bash
    ohio_network_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_network_vpc_id \
                                                            --cidr-block $ohio_network_gateway_subnetc_cidr \
                                                            --availability-zone us-east-2c \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Network-GatewaySubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_gateway_subnetc_id
    ```

1. **Create Public Route Table, Default Route and Associate with Public Subnets**

    ```bash
    ohio_network_public_rtb_id=$(aws ec2 create-route-table --vpc-id $ohio_network_vpc_id \
                                                            --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Network-PublicRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'RouteTable.RouteTableId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_public_rtb_id

    aws ec2 create-route --route-table-id $ohio_network_public_rtb_id \
                         --destination-cidr-block '0.0.0.0/0' \
                         --gateway-id $ohio_network_igw_id \
                         --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $ohio_network_public_rtb_id --subnet-id $ohio_network_public_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_public_rtb_id --subnet-id $ohio_network_public_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_public_rtb_id --subnet-id $ohio_network_public_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $ohio_network_public_rtb_id --subnet-id $ohio_network_public7_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_public_rtb_id --subnet-id $ohio_network_public7_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_public_rtb_id --subnet-id $ohio_network_public7_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $ohio_network_public_rtb_id --subnet-id $ohio_network_web_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_public_rtb_id --subnet-id $ohio_network_web_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_public_rtb_id --subnet-id $ohio_network_web_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $ohio_network_public_rtb_id --subnet-id $ohio_network_web7_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_public_rtb_id --subnet-id $ohio_network_web7_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_public_rtb_id --subnet-id $ohio_network_web7_subnetc_id \
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
      ohio_network_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                       --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Network-NAT-EIPA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                       --query 'AllocationId' \
                                                       --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_network_ngw_eipa

      ohio_network_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_network_ngw_eipa \
                                                        --subnet-id $ohio_network_public_subneta_id \
                                                        --client-token $(date +%s) \
                                                        --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Network-NAT-GatewayA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'NatGateway.NatGatewayId' \
                                                        --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_network_ngwa_id

      if [ $ha_ngw = 1 ]; then
        ohio_network_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                         --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Network-NAT-EIPB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'AllocationId' \
                                                         --profile $profile --region us-east-2 --output text)
        camelz-variable ohio_network_ngw_eipb

        ohio_network_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_network_ngw_eipb \
                                                          --subnet-id $ohio_network_public_subnetb_id \
                                                          --client-token $(date +%s) \
                                                          --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Network-NAT-GatewayB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'NatGateway.NatGatewayId' \
                                                          --profile $profile --region us-east-2 --output text)
        camelz-variable ohio_network_ngwb_id

        ohio_network_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                         --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Network-NAT-EIPC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'AllocationId' \
                                                         --profile $profile --region us-east-2 --output text)
        camelz-variable ohio_network_ngw_eipc

        ohio_network_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_network_ngw_eipc \
                                                          --subnet-id $ohio_network_public_subnetc_id \
                                                          --client-token $(date +%s) \
                                                          --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Network-NAT-GatewayC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'NatGateway.NatGatewayId' \
                                                          --profile $profile --region us-east-2 --output text)
        camelz-variable ohio_network_ngwc_id
      fi
    else
      # Create NAT Security Group
      ohio_network_nat_sg_id=$(aws ec2 create-security-group --group-name Network-NAT-InstanceSecurityGroup \
                                                             --description Network-NAT-InstanceSecurityGroup \
                                                             --vpc-id $ohio_network_vpc_id \
                                                             --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Network-NAT-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'GroupId' \
                                                             --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_network_nat_sg_id

      aws ec2 authorize-security-group-ingress --group-id $ohio_network_nat_sg_id \
                                               --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$ohio_network_vpc_cidr,Description=\"VPC (All)\"}]" \
                                               --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All)\"}]" \
                                               --profile $profile --region us-east-2 --output text

      # Create NAT Instance
      ohio_network_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                           --instance-type t3a.nano \
                                                           --iam-instance-profile Name=ManagedInstance \
                                                           --key-name administrator \
                                                           --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Network-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_network_nat_sg_id],SubnetId=$ohio_network_public_subneta_id" \
                                                           --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Network-NAT-Instance},{Key=Hostname,Value=cmlue2mnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Instances[0].InstanceId' \
                                                           --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_network_nat_instance_id

      aws ec2 modify-instance-attribute --instance-id $ohio_network_nat_instance_id \
                                        --no-source-dest-check \
                                        --profile $profile --region us-east-2 --output text

      ohio_network_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $ohio_network_nat_instance_id \
                                                                    --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                    --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_network_nat_instance_eni_id

      ohio_network_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_network_nat_instance_id \
                                                                        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                        --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_network_nat_instance_private_ip
    fi
    ```

1. **Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets**

    ```bash
    ohio_network_private_rtba_id=$(aws ec2 create-route-table --vpc-id $ohio_network_vpc_id \
                                                              --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Network-PrivateRouteTableA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'RouteTable.RouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_private_rtba_id

    if [ $use_ngw = 1 ]; then
      aws ec2 create-route --route-table-id $ohio_network_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $ohio_network_ngwa_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $ohio_network_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $ohio_network_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtba_id --subnet-id $ohio_network_application_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtba_id --subnet-id $ohio_network_application1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtba_id --subnet-id $ohio_network_cache_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtba_id --subnet-id $ohio_network_database_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtba_id --subnet-id $ohio_network_directory_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtba_id --subnet-id $ohio_network_endpoint_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtba_id --subnet-id $ohio_network_firewall_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtba_id --subnet-id $ohio_network_gateway_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Route Table for Availability Zone B, Default Route and Associate with Private Subnets**

    ```bash
    ohio_network_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $ohio_network_vpc_id \
                                                              --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Network-PrivateRouteTableB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'RouteTable.RouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_private_rtbb_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then ohio_network_ngw_id=$ohio_network_ngwb_id; else ohio_network_ngw_id=$ohio_network_ngwa_id; fi
      aws ec2 create-route --route-table-id $ohio_network_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $ohio_network_ngw_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $ohio_network_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $ohio_network_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbb_id --subnet-id $ohio_network_application_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbb_id --subnet-id $ohio_network_application1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbb_id --subnet-id $ohio_network_cache_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbb_id --subnet-id $ohio_network_database_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbb_id --subnet-id $ohio_network_directory_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbb_id --subnet-id $ohio_network_endpoint_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbb_id --subnet-id $ohio_network_firewall_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbb_id --subnet-id $ohio_network_gateway_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Route Table for Availability Zone C, Default Route and Associate with Private Subnets**

    ```bash
    ohio_network_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $ohio_network_vpc_id \
                                                              --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Network-PrivateRouteTableC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'RouteTable.RouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_private_rtbc_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then ohio_network_ngw_id=$ohio_network_ngwc_id; else ohio_network_ngw_id=$ohio_network_ngwa_id; fi
      aws ec2 create-route --route-table-id $ohio_network_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $ohio_network_ngw_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $ohio_network_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $ohio_network_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbc_id --subnet-id $ohio_network_application_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbc_id --subnet-id $ohio_network_application1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbc_id --subnet-id $ohio_network_cache_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbc_id --subnet-id $ohio_network_database_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbc_id --subnet-id $ohio_network_directory_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbc_id --subnet-id $ohio_network_endpoint_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbc_id --subnet-id $ohio_network_firewall_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_network_private_rtbc_id --subnet-id $ohio_network_gateway_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Endpoint Security Group**

    ```bash
    ohio_network_vpce_sg_id=$(aws ec2 create-security-group --group-name Network-VPCEndpointSecurityGroup \
                                                            --description Network-VPCEndpointSecurityGroup \
                                                            --vpc-id $ohio_network_vpc_id \
                                                            --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Network-VPCEndpointSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'GroupId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_vpce_sg_id

    aws ec2 authorize-security-group-ingress --group-id $ohio_network_vpce_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ohio_network_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All TCP)\"}]" \
                                             --profile $profile --region us-east-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $ohio_network_vpce_sg_id \
                                             --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ohio_network_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All UDP)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Endpoints for SSM and SSMMessages**

    ```bash
    ohio_network_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ohio_network_vpc_id \
                                                           --vpc-endpoint-type Interface \
                                                           --service-name com.amazonaws.us-east-2.ssm \
                                                           --private-dns-enabled \
                                                           --security-group-ids $ohio_network_vpce_sg_id \
                                                           --subnet-ids $ohio_network_endpoint_subneta_id $ohio_network_endpoint_subnetb_id $ohio_network_endpoint_subnetc_id \
                                                           --client-token $(date +%s) \
                                                           --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Network-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'VpcEndpoint.VpcEndpointId' \
                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_ssm_vpce_id

    ohio_network_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ohio_network_vpc_id \
                                                            --vpc-endpoint-type Interface \
                                                            --service-name com.amazonaws.us-east-2.ssmmessages \
                                                            --private-dns-enabled \
                                                            --security-group-ids $ohio_network_vpce_sg_id \
                                                            --subnet-ids $ohio_network_endpoint_subneta_id $ohio_network_endpoint_subnetb_id $ohio_network_endpoint_subnetc_id \
                                                            --client-token $(date +%s) \
                                                            --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Network-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'VpcEndpoint.VpcEndpointId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_ssmm_vpce_id
    ```
