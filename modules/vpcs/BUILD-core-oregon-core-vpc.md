# Modules:VPCs:Core Account:Oregon:Core VPC

This module builds the Core VPC in the AWS Oregon (us-west-2) Region within the CaMeLz-Core Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Core VPC

1. **Set Profile for Core Account**

    ```bash
    profile=$core_profile
    ```

1. **Create VPC**

    ```bash
    oregon_core_vpc_id=$(aws ec2 create-vpc --cidr-block $oregon_core_vpc_cidr \
                                            --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=Core-VPC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                            --query 'Vpc.VpcId' \
                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_vpc_id


    aws ec2 modify-vpc-attribute --vpc-id $oregon_core_vpc_id \
                                 --enable-dns-support \
                                 --profile $profile --region us-west-2 --output text

    aws ec2 modify-vpc-attribute --vpc-id $oregon_core_vpc_id \
                                 --enable-dns-hostnames \
                                 --profile $profile --region us-west-2 --output text
    ```

1. **Tag Attached Default Resources Created With VPC**

    Creating a VPC also creates a set of attached default resources which do not have the same tags propagated.
    We will also tag these associated resources to insure consistency in the list displays.

    ```bash
    # Tag Core-MainRouteTable
    main_rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$oregon_core_vpc_id \
                                                          Name=association.main,Values=true \
                                                --query 'RouteTables[0].RouteTableId' \
                                                --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $main_rtb_id \
                        --tags Key=Name,Value=Core-MainRouteTable \
                               Key=Company,Value=Camelz \
                               Key=Environment,Value=Core \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text

    # Tag Core-DefaultNetworkAcl
    default_nacl_id=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$oregon_core_vpc_id \
                                                              Name=default,Values=true \
                                                    --query 'NetworkAcls[0].NetworkAclId' \
                                                    --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $default_nacl_id \
                        --tags Key=Name,Value=Core-DefaultNetworkAcl \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text

    # Tag Core-DefaultSecurityGroup
    default_sg_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$oregon_core_vpc_id \
                                                               Name=group-name,Values=default \
                                                     --query 'SecurityGroups[0].GroupId' \
                                                     --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $default_sg_id \
                        --tags Key=Name,Value=Core-DefaultSecurityGroup \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text
    ```

1. **Create VPC Flow Log**

    ```bash
    aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Core" \
                              --profile $profile --region us-west-2 --output text

    aws logs put-retention-policy --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Core" \
                                  --retention-in-days 14 \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 create-flow-logs --resource-type VPC --resource-ids $oregon_core_vpc_id \
                             --traffic-type ALL \
                             --log-destination-type cloud-watch-logs \
                             --log-destination "arn:aws:logs:us-west-2:${core_account_id}:log-group:/${company_name_lc}/${system_name_lc}/FlowLog/Core" \
                             --deliver-logs-permission-arn "arn:aws:iam::${core_account_id}:role/FlowLog" \
                             --tag-specifications "ResourceType=vpc-flow-log,Tags=[{Key=Name,Value=Core-FlowLog},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                             --profile $profile --region us-west-2 --output text
    ```

1. **Create Internet Gateway**

    ```bash
    oregon_core_igw_id=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Core-InternetGateway},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'InternetGateway.InternetGatewayId' \
                                                         --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_igw_id

    aws ec2 attach-internet-gateway --vpc-id $oregon_core_vpc_id \
                                    --internet-gateway-id $oregon_core_igw_id \
                                    --profile $profile --region us-west-2 --output text
    ```

1. **Create Private Hosted Zone**

    ```bash
    oregon_core_private_hostedzone_id=$(aws route53 create-hosted-zone --name $oregon_core_private_domain \
                                                                       --vpc VPCRegion=us-west-2,VPCId=$oregon_core_vpc_id \
                                                                       --hosted-zone-config Comment="Private Zone for $oregon_core_private_domain",PrivateZone=true \
                                                                       --caller-reference $(date +%s) \
                                                                       --query 'HostedZone.Id' \
                                                                       --profile $profile --region us-west-2 --output text | cut -f3 -d /)
    camelz-variable oregon_core_private_hostedzone_id
    ```

1. **Create DHCP Options Set**

    ```bash
    oregon_core_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$oregon_core_private_domain]" \
                                                                            "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                      --tag-specifications "ResourceType=dhcp-options,Tags=[{Key=Name,Value=Core-DHCPOptions},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                      --query 'DhcpOptions.DhcpOptionsId' \
                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_dopt_id

    aws ec2 associate-dhcp-options --vpc-id $oregon_core_vpc_id \
                                   --dhcp-options-id $oregon_core_dopt_id \
                                   --profile $profile --region us-west-2 --output text
    ```

1. **Create Public Subnet A**

    ```bash
    oregon_core_public_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                          --cidr-block $oregon_core_public_subneta_cidr \
                                                          --availability-zone us-west-2a \
                                                          --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-PublicSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_public_subneta_id
    ```

1. **Create Public Subnet B**

    ```bash
    oregon_core_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                          --cidr-block $oregon_core_public_subnetb_cidr \
                                                          --availability-zone us-west-2b \
                                                          --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-PublicSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_public_subnetb_id
    ```

1. **Create Public Subnet C**

    ```bash
    oregon_core_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                          --cidr-block $oregon_core_public_subnetc_cidr \
                                                          --availability-zone us-west-2c \
                                                          --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-PublicSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_public_subnetc_id
    ```

1. **Create Public7 Subnet A**

    ```bash
    oregon_core_public7_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                           --cidr-block $oregon_core_public7_subneta_cidr \
                                                           --availability-zone us-west-2a \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-Public7SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_public7_subneta_id
    ```

1. **Create Public7 Subnet B**

    ```bash
    oregon_core_public7_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                           --cidr-block $oregon_core_public7_subnetb_cidr \
                                                           --availability-zone us-west-2b \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-Public7SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_public7_subnetb_id
    ```

1. **Create Public7 Subnet C**

    ```bash
    oregon_core_public7_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                           --cidr-block $oregon_core_public7_subnetc_cidr \
                                                           --availability-zone us-west-2c \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-Public7SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_public7_subnetc_id
    ```

1. **Create Web Subnet A**

    ```bash
    oregon_core_web_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                       --cidr-block $oregon_core_web_subneta_cidr \
                                                       --availability-zone us-west-2a \
                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-WebSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_web_subneta_id
    ```

1. **Create Web Subnet B**

    ```bash
    oregon_core_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                       --cidr-block $oregon_core_web_subnetb_cidr \
                                                       --availability-zone us-west-2b \
                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-WebSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_web_subnetb_id
    ```

1. **Create Web Subnet C**

    ```bash
    oregon_core_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                       --cidr-block $oregon_core_web_subnetc_cidr \
                                                       --availability-zone us-west-2c \
                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-WebSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_web_subnetc_id
    ```

1. **Create Web7 Subnet A**

    ```bash
    oregon_core_web7_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                        --cidr-block $oregon_core_web7_subneta_cidr \
                                                        --availability-zone us-west-2a \
                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-Web7SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_web7_subneta_id
    ```

1. **Create Web7 Subnet B**

    ```bash
    oregon_core_web7_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                        --cidr-block $oregon_core_web7_subnetb_cidr \
                                                        --availability-zone us-west-2b \
                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-Web7SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_web7_subnetb_id
    ```

1. **Create Web7 Subnet C**

    ```bash
    oregon_core_web7_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                        --cidr-block $oregon_core_web7_subnetc_cidr \
                                                        --availability-zone us-west-2c \
                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-Web7SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_web7_subnetc_id
    ```

1. **Create Application Subnet A**

    ```bash
    oregon_core_application_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                               --cidr-block $oregon_core_application_subneta_cidr \
                                                               --availability-zone us-west-2a \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-ApplicationSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_application_subneta_id
    ```

1. **Create Application Subnet B**

    ```bash
    oregon_core_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                               --cidr-block $oregon_core_application_subnetb_cidr \
                                                               --availability-zone us-west-2b \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-ApplicationSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_application_subnetb_id
    ```

1. **Create Application Subnet C**

    ```bash
    oregon_core_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                               --cidr-block $oregon_core_application_subnetc_cidr \
                                                               --availability-zone us-west-2c \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-ApplicationSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_application_subnetc_id
    ```

1. **Create Application1 Subnet A**

    ```bash
    oregon_core_application1_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                                --cidr-block $oregon_core_application1_subneta_cidr \
                                                                --availability-zone us-west-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-Application1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_application1_subneta_id
    ```

1. **Create Application1 Subnet B**

    ```bash
    oregon_core_application1_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                                --cidr-block $oregon_core_application1_subnetb_cidr \
                                                                --availability-zone us-west-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-Application1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_application1_subnetb_id
    ```

1. **Create Application Subnet C**

    ```bash
    oregon_core_application1_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                                --cidr-block $oregon_core_application1_subnetc_cidr \
                                                                --availability-zone us-west-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-Application1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_application1_subnetc_id
    ```

1. **Create Cache Subnet A**

    ```bash
    oregon_core_cache_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                         --cidr-block $oregon_core_cache_subneta_cidr \
                                                         --availability-zone us-west-2a \
                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-CacheSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_cache_subneta_id
    ```

1. **Create Cache Subnet B**

    ```bash
    oregon_core_cache_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                         --cidr-block $oregon_core_cache_subnetb_cidr \
                                                         --availability-zone us-west-2b \
                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-CacheSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_cache_subnetb_id
    ```

1. **Create Cache Subnet C**

    ```bash
    oregon_core_cache_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                         --cidr-block $oregon_core_cache_subnetc_cidr \
                                                         --availability-zone us-west-2c \
                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-CacheSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_cache_subnetc_id
    ```

1. **Create Database Subnet A**

    ```bash
    oregon_core_database_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                            --cidr-block $oregon_core_database_subneta_cidr \
                                                            --availability-zone us-west-2a \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-DatabaseSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_database_subneta_id
    ```

1. **Create Database Subnet B**

    ```bash
    oregon_core_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                            --cidr-block $oregon_core_database_subnetb_cidr \
                                                            --availability-zone us-west-2b \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-DatabaseSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_database_subnetb_id
    ```

1. **Create Database Subnet C**

    ```bash
    oregon_core_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                            --cidr-block $oregon_core_database_subnetc_cidr \
                                                            --availability-zone us-west-2c \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-DatabaseSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_database_subnetc_id
    ```

1. **Create Endpoint Subnet A**

    ```bash
    oregon_core_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                            --cidr-block $oregon_core_endpoint_subneta_cidr \
                                                            --availability-zone us-west-2a \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-EndpointSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_endpoint_subneta_id
    ```

1. **Create Endpoint Subnet B**

    ```bash
    oregon_core_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                            --cidr-block $oregon_core_endpoint_subnetb_cidr \
                                                            --availability-zone us-west-2b \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-EndpointSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_endpoint_subnetb_id
    ```

1. **Create Endpoint Subnet C**

    ```bash
    oregon_core_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                            --cidr-block $oregon_core_endpoint_subnetc_cidr \
                                                            --availability-zone us-west-2c \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-EndpointSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_endpoint_subnetc_id
    ```

1. **Create Firewall Subnet A**

    ```bash
    oregon_core_firewall_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                            --cidr-block $oregon_core_firewall_subneta_cidr \
                                                            --availability-zone us-west-2a \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-FirewallSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_firewall_subneta_id
    ```

1. **Create Firewall Subnet B**

    ```bash
    oregon_core_firewall_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                            --cidr-block $oregon_core_firewall_subnetb_cidr \
                                                            --availability-zone us-west-2b \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-FirewallSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_firewall_subnetb_id
    ```

1. **Create Firewall Subnet C**

    ```bash
    oregon_core_firewall_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                            --cidr-block $oregon_core_firewall_subnetc_cidr \
                                                            --availability-zone us-west-2c \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-FirewallSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_firewall_subnetc_id
    ```

1. **Create Gateway Subnet A**

    ```bash
    oregon_core_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                           --cidr-block $oregon_core_gateway_subneta_cidr \
                                                           --availability-zone us-west-2a \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-GatewaySubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_gateway_subneta_id
    ```

1. **Create Gateway Subnet B**

    ```bash
    oregon_core_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                           --cidr-block $oregon_core_gateway_subnetb_cidr \
                                                           --availability-zone us-west-2b \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-GatewaySubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_gateway_subnetb_id
    ```

1. **Create Gateway Subnet C**

    ```bash
    oregon_core_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_core_vpc_id \
                                                           --cidr-block $oregon_core_gateway_subnetc_cidr \
                                                           --availability-zone us-west-2c \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Core-GatewaySubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_gateway_subnetc_id
    ```

1. **Create Public Route Table, Default Route and Associate with Public Subnets**

    ```bash
    oregon_core_public_rtb_id=$(aws ec2 create-route-table --vpc-id $oregon_core_vpc_id \
                                                           --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Core-PublicRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'RouteTable.RouteTableId' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_public_rtb_id

    aws ec2 create-route --route-table-id $oregon_core_public_rtb_id \
                         --destination-cidr-block '0.0.0.0/0' \
                         --gateway-id $oregon_core_igw_id \
                         --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $oregon_core_public_rtb_id --subnet-id $oregon_core_public_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_public_rtb_id --subnet-id $oregon_core_public_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_public_rtb_id --subnet-id $oregon_core_public_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $oregon_core_public_rtb_id --subnet-id $oregon_core_public7_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_public_rtb_id --subnet-id $oregon_core_public7_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_public_rtb_id --subnet-id $oregon_core_public7_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $oregon_core_public_rtb_id --subnet-id $oregon_core_web_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_public_rtb_id --subnet-id $oregon_core_web_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_public_rtb_id --subnet-id $oregon_core_web_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $oregon_core_public_rtb_id --subnet-id $oregon_core_web7_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_public_rtb_id --subnet-id $oregon_core_web7_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_public_rtb_id --subnet-id $oregon_core_web7_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
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
      oregon_core_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                      --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Core-NAT-EIPA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                      --query 'AllocationId' \
                                                      --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_core_ngw_eipa

      oregon_core_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $oregon_core_ngw_eipa \
                                                       --subnet-id $oregon_core_public_subneta_id \
                                                       --client-token $(date +%s) \
                                                       --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Core-NAT-GatewayA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                       --query 'NatGateway.NatGatewayId' \
                                                       --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_core_ngwa_id

      if [ $ha_ngw = 1 ]; then
        oregon_core_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                        --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Core-NAT-EIPB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'AllocationId' \
                                                        --profile $profile --region us-west-2 --output text)
        camelz-variable oregon_core_ngw_eipb

        oregon_core_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $oregon_core_ngw_eipb \
                                                         --subnet-id $oregon_core_public_subnetb_id \
                                                         --client-token $(date +%s) \
                                                         --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Core-NAT-GatewayB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'NatGateway.NatGatewayId' \
                                                         --profile $profile --region us-west-2 --output text)
        camelz-variable oregon_core_ngwb_id

        oregon_core_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                        --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Core-NAT-EIPC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'AllocationId' \
                                                        --profile $profile --region us-west-2 --output text)
        camelz-variable oregon_core_ngw_eipc

        oregon_core_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $oregon_core_ngw_eipc \
                                                         --subnet-id $oregon_core_public_subnetc_id \
                                                         --client-token $(date +%s) \
                                                         --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Core-NAT-GatewayC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'NatGateway.NatGatewayId' \
                                                         --profile $profile --region us-west-2 --output text)
        camelz-variable oregon_core_ngwc_id
      fi
    else
      # Create NAT Security Group
      oregon_core_nat_sg_id=$(aws ec2 create-security-group --group-name Core-NAT-InstanceSecurityGroup \
                                                            --description Core-NAT-InstanceSecurityGroup \
                                                            --vpc-id $oregon_core_vpc_id \
                                                            --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Core-NAT-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'GroupId' \
                                                            --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_core_nat_sg_id

      aws ec2 authorize-security-group-ingress --group-id $oregon_core_nat_sg_id \
                                               --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$oregon_core_vpc_cidr,Description=\"VPC (All)\"}]" \
                                               --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All)\"}]" \
                                               --profile $profile --region us-west-2 --output text

      # Create NAT Instance
      oregon_core_nat_instance_id=$(aws ec2 run-instances --image-id $oregon_nat_ami_id \
                                                          --instance-type t3a.nano \
                                                          --iam-instance-profile Name=ManagedInstance \
                                                          --key-name administrator \
                                                          --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Core-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$oregon_core_nat_sg_id],SubnetId=$oregon_core_public_subneta_id" \
                                                          --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Core-NAT-Instance},{Key=Hostname,Value=cmluw2mnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'Instances[0].InstanceId' \
                                                          --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_core_nat_instance_id

      aws ec2 modify-instance-attribute --instance-id $oregon_core_nat_instance_id \
                                        --no-source-dest-check \
                                        --profile $profile --region us-west-2 --output text

      oregon_core_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $oregon_core_nat_instance_id \
                                                                   --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                   --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_core_nat_instance_eni_id

      oregon_core_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $oregon_core_nat_instance_id \
                                                                       --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                       --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_core_nat_instance_private_ip
    fi
    ```

1. **Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets**

    ```bash
    oregon_core_private_rtba_id=$(aws ec2 create-route-table --vpc-id $oregon_core_vpc_id \
                                                             --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Core-PrivateRouteTableA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'RouteTable.RouteTableId' \
                                                             --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_private_rtba_id

    if [ $use_ngw = 1 ]; then
      aws ec2 create-route --route-table-id $oregon_core_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $oregon_core_ngwa_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $oregon_core_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $oregon_core_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtba_id --subnet-id $oregon_core_application_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtba_id --subnet-id $oregon_core_application1_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtba_id --subnet-id $oregon_core_cache_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtba_id --subnet-id $oregon_core_database_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtba_id --subnet-id $oregon_core_endpoint_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtba_id --subnet-id $oregon_core_firewall_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtba_id --subnet-id $oregon_core_gateway_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1. **Create Private Route Table for Availability Zone B, Default Route and Associate with Private Subnets**

    ```bash
    oregon_core_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $oregon_core_vpc_id \
                                                             --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Core-PrivateRouteTableB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'RouteTable.RouteTableId' \
                                                             --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_private_rtbb_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then oregon_core_ngw_id=$oregon_core_ngwb_id; else oregon_core_ngw_id=$oregon_core_ngwa_id; fi
      aws ec2 create-route --route-table-id $oregon_core_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $oregon_core_ngw_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $oregon_core_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $oregon_core_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbb_id --subnet-id $oregon_core_application_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbb_id --subnet-id $oregon_core_application1_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbb_id --subnet-id $oregon_core_cache_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbb_id --subnet-id $oregon_core_database_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbb_id --subnet-id $oregon_core_endpoint_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbb_id --subnet-id $oregon_core_firewall_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbb_id --subnet-id $oregon_core_gateway_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1. **Create Private Route Table for Availability Zone C, Default Route and Associate with Private Subnets**

    ```bash
    oregon_core_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $oregon_core_vpc_id \
                                                             --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Core-PrivateRouteTableC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'RouteTable.RouteTableId' \
                                                             --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_private_rtbc_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then oregon_core_ngw_id=$oregon_core_ngwc_id; else oregon_core_ngw_id=$oregon_core_ngwa_id; fi
      aws ec2 create-route --route-table-id $oregon_core_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $oregon_core_ngw_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $oregon_core_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $oregon_core_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbc_id --subnet-id $oregon_core_application_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbc_id --subnet-id $oregon_core_application1_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbc_id --subnet-id $oregon_core_cache_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbc_id --subnet-id $oregon_core_database_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbc_id --subnet-id $oregon_core_endpoint_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbc_id --subnet-id $oregon_core_firewall_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_core_private_rtbc_id --subnet-id $oregon_core_gateway_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1. **Create VPC Endpoint Security Group**

    ```bash
    oregon_core_vpce_sg_id=$(aws ec2 create-security-group --group-name Core-VPCEndpointSecurityGroup \
                                                           --description Core-VPCEndpointSecurityGroup \
                                                           --vpc-id $oregon_core_vpc_id \
                                                           --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Core-VPCEndpointSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'GroupId' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_vpce_sg_id

    aws ec2 authorize-security-group-ingress --group-id $oregon_core_vpce_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$oregon_core_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All TCP)\"}]" \
                                             --profile $profile --region us-west-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $oregon_core_vpce_sg_id \
                                             --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$oregon_core_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All UDP)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    ```

1. **Create VPC Endpoints for SSM and SSMMessages**

    ```bash
    oregon_core_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $oregon_core_vpc_id \
                                                          --vpc-endpoint-type Interface \
                                                          --service-name com.amazonaws.us-west-2.ssm \
                                                          --private-dns-enabled \
                                                          --security-group-ids $oregon_core_vpce_sg_id \
                                                          --subnet-ids $oregon_core_endpoint_subneta_id $oregon_core_endpoint_subnetb_id $oregon_core_endpoint_subnetc_id \
                                                          --client-token $(date +%s) \
                                                          --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Core-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'VpcEndpoint.VpcEndpointId' \
                                                          --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_ssm_vpce_id

    oregon_core_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $oregon_core_vpc_id \
                                                           --vpc-endpoint-type Interface \
                                                           --service-name com.amazonaws.us-west-2.ssmmessages \
                                                           --private-dns-enabled \
                                                           --security-group-ids $oregon_core_vpce_sg_id \
                                                           --subnet-ids $oregon_core_endpoint_subneta_id $oregon_core_endpoint_subnetb_id $oregon_core_endpoint_subnetc_id \
                                                           --client-token $(date +%s) \
                                                           --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Core-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'VpcEndpoint.VpcEndpointId' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_core_ssmm_vpce_id
    ```
