# Modules:VPCs:Alfa Recovery Account:Oregon:Alfa Recovery VPC

This module builds the Alfa-Recovery VPC in the AWS Oregon (us-west-2) Region within the Alfa-CaMeLz-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Alfa-Recovery VPC

1. **Set Profile for Alfa-Recovery Account**

    ```bash
    profile=$alfa_recovery_profile
    ```

1. **Create VPC**

    ```bash
    alfa_oregon_recovery_vpc_id=$(aws ec2 create-vpc --cidr-block $alfa_oregon_recovery_vpc_cidr \
                                                     --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=Alfa-Recovery-VPC},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                     --query 'Vpc.VpcId' \
                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_vpc_id


    aws ec2 modify-vpc-attribute --vpc-id $alfa_oregon_recovery_vpc_id \
                                 --enable-dns-support \
                                 --profile $profile --region us-west-2 --output text

    aws ec2 modify-vpc-attribute --vpc-id $alfa_oregon_recovery_vpc_id \
                                 --enable-dns-hostnames \
                                 --profile $profile --region us-west-2 --output text
    ```

1. **Tag Attached Default Resources Created With VPC**

    Creating a VPC also creates a set of attached default resources which do not have the same tags propagated.
    We will also tag these associated resources to insure consistency in the list displays.

    ```bash
    # Tag Alfa-Recovery-MainRouteTable
    main_rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$alfa_oregon_recovery_vpc_id \
                                                          Name=association.main,Values=true \
                                                --query 'RouteTables[0].RouteTableId' \
                                                --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $main_rtb_id \
                        --tags Key=Name,Value=Alfa-Recovery-MainRouteTable \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Recovery \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text

    # Tag Alfa-Recovery-DefaultNetworkAcl
    default_nacl_id=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$alfa_oregon_recovery_vpc_id \
                                                              Name=default,Values=true \
                                                    --query 'NetworkAcls[0].NetworkAclId' \
                                                    --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $default_nacl_id \
                        --tags Key=Name,Value=Alfa-Recovery-DefaultNetworkAcl \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Recovery \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text

    # Tag Default-DefaultSecurityGroup
    default_sg_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$alfa_oregon_recovery_vpc_id \
                                                               Name=group-name,Values=default \
                                                     --query 'SecurityGroups[0].GroupId' \
                                                     --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $default_sg_id \
                        --tags Key=Name,Value=Alfa-Recovery-DefaultSecurityGroup \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Recovery \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text
    ```

1. **Create VPC Flow Log**

    ```bash
    aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Alfa-Recovery/Oregon" \
                              --profile $profile --region us-west-2 --output text

    aws ec2 create-flow-logs --resource-type VPC --resource-ids $alfa_oregon_recovery_vpc_id \
                             --traffic-type ALL \
                             --log-destination-type cloud-watch-logs \
                             --log-destination "arn:aws:logs:us-west-2:${alfa_recovery_account_id}:log-group:/${company_name_lc}/${system_name_lc}/FlowLog/Alfa-Recovery/Oregon" \
                             --deliver-logs-permission-arn "arn:aws:iam::${alfa_recovery_account_id}:role/FlowLog" \
                             --profile $profile --region us-west-2 --output text
    ```

1. **Create Internet Gateway**

    ```bash
    alfa_oregon_recovery_igw_id=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Alfa-Recovery-InternetGateway},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'InternetGateway.InternetGatewayId' \
                                                                  --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_igw_id

    aws ec2 attach-internet-gateway --vpc-id $alfa_oregon_recovery_vpc_id \
                                    --internet-gateway-id $alfa_oregon_recovery_igw_id \
                                    --profile $profile --region us-west-2 --output text
    ```

1. **Create Private Hosted Zone**

    ```bash
    alfa_oregon_recovery_private_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_oregon_recovery_private_domain \
                                                                                --vpc VPCRegion=us-west-2,VPCId=$alfa_oregon_recovery_vpc_id \
                                                                                --hosted-zone-config Comment="Private Zone for $alfa_oregon_recovery_private_domain",PrivateZone=true \
                                                                                --caller-reference $(date +%s) \
                                                                                --query 'HostedZone.Id' \
                                                                                --profile $profile --region us-west-2 --output text | cut -f3 -d /)
    camelz-variable alfa_oregon_recovery_private_hostedzone_id
    ```

1. **Create DHCP Options Set**

    ```bash
    alfa_oregon_recovery_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$alfa_oregon_recovery_private_domain]" \
                                                                                     "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                               --tag-specifications "ResourceType=dhcp-options,Tags=[{Key=Name,Value=Alfa-Recovery-DHCPOptions},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'DhcpOptions.DhcpOptionsId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_dopt_id

    aws ec2 associate-dhcp-options --vpc-id $alfa_oregon_recovery_vpc_id \
                                   --dhcp-options-id $alfa_oregon_recovery_dopt_id \
                                   --profile $profile --region us-west-2 --output text
    ```

1. **Create Public Subnet A**

    ```bash
    alfa_oregon_recovery_public_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                   --cidr-block $alfa_oregon_recovery_subnet_publica_cidr \
                                                                   --availability-zone us-west-2a \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-PublicSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_public_subneta_id
    ```

1. **Create Public Subnet B**

    ```bash
    alfa_oregon_recovery_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                   --cidr-block $alfa_oregon_recovery_subnet_publicb_cidr \
                                                                   --availability-zone us-west-2b \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-PublicSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_public_subnetb_id
    ```

1. **Create Public Subnet C**

    ```bash
    alfa_oregon_recovery_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                   --cidr-block $alfa_oregon_recovery_subnet_publicc_cidr \
                                                                   --availability-zone us-west-2c \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-PublicSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_public_subnetc_id
    ```

1. **Create Web Subnet A**

    ```bash
    alfa_oregon_recovery_web_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                --cidr-block $alfa_oregon_recovery_subnet_weba_cidr \
                                                                --availability-zone us-west-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-WebSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_web_subneta_id
    ```

1. **Create Web Subnet B**

    ```bash
    alfa_oregon_recovery_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                --cidr-block $alfa_oregon_recovery_subnet_webb_cidr \
                                                                --availability-zone us-west-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-WebSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_web_subnetb_id
    ```

1. **Create Web Subnet C**

    ```bash
    alfa_oregon_recovery_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                --cidr-block $alfa_oregon_recovery_subnet_webc_cidr \
                                                                --availability-zone us-west-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-WebSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_web_subnetc_id
    ```

1. **Create Application Subnet A**

    ```bash
    alfa_oregon_recovery_application_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                        --cidr-block $alfa_oregon_recovery_subnet_applicationa_cidr \
                                                                        --availability-zone us-west-2a \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-ApplicationSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_application_subneta_id
    ```

1. **Create Application Subnet B**

    ```bash
    alfa_oregon_recovery_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                        --cidr-block $alfa_oregon_recovery_subnet_applicationb_cidr \
                                                                        --availability-zone us-west-2b \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-ApplicationSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_application_subnetb_id
    ```

1. **Create Application Subnet C**

    ```bash
    alfa_oregon_recovery_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                        --cidr-block $alfa_oregon_recovery_subnet_applicationc_cidr \
                                                                        --availability-zone us-west-2c \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-ApplicationSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_application_subnetc_id
    ```

1. **Create Database Subnet A**

    ```bash
    alfa_oregon_recovery_database_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                     --cidr-block $alfa_oregon_recovery_subnet_databasea_cidr \
                                                                     --availability-zone us-west-2a \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-DatabaseSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_database_subneta_id
    ```

1. **Create Database Subnet B**

    ```bash
    alfa_oregon_recovery_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                     --cidr-block $alfa_oregon_recovery_subnet_databaseb_cidr \
                                                                     --availability-zone us-west-2b \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-DatabaseSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_database_subnetb_id
    ```

1. **Create Database Subnet C**

    ```bash
    alfa_oregon_recovery_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                     --cidr-block $alfa_oregon_recovery_subnet_databasec_cidr \
                                                                     --availability-zone us-west-2c \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-DatabaseSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_database_subnetc_id
    ```

1. **Create Directory Subnet A**

    ```bash
    alfa_oregon_recovery_directory_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                      --cidr-block $alfa_oregon_recovery_subnet_directorya_cidr \
                                                                      --availability-zone us-west-2a \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-DirectorySubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_directory_subneta_id
    ```

1. **Create Directory Subnet B**

    ```bash
    alfa_oregon_recovery_directory_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                      --cidr-block $alfa_oregon_recovery_subnet_directoryb_cidr \
                                                                      --availability-zone us-west-2b \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-DirectorySubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_directory_subnetb_id
    ```

1. **Create Directory Subnet C**

    ```bash
    alfa_oregon_recovery_directory_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                      --cidr-block $alfa_oregon_recovery_subnet_directoryc_cidr \
                                                                      --availability-zone us-west-2c \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-DirectorySubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_directory_subnetc_id
    ```

1. **Create Management Subnet A**

    ```bash
    alfa_oregon_recovery_management_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                       --cidr-block $alfa_oregon_recovery_subnet_managementa_cidr \
                                                                       --availability-zone us-west-2a \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-ManagementSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_management_subneta_id
    ```

1. **Create Management Subnet B**

    ```bash
    alfa_oregon_recovery_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                       --cidr-block $alfa_oregon_recovery_subnet_managementb_cidr \
                                                                       --availability-zone us-west-2b \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-ManagementSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_management_subnetb_id
    ```

1. **Create Management Subnet C**

    ```bash
    alfa_oregon_recovery_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                       --cidr-block $alfa_oregon_recovery_subnet_managementc_cidr \
                                                                       --availability-zone us-west-2c \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-ManagementSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_management_subnetc_id
    ```

1. **Create Gateway Subnet A**

    ```bash
    alfa_oregon_recovery_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                    --cidr-block $alfa_oregon_recovery_subnet_gatewaya_cidr \
                                                                    --availability-zone us-west-2a \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-GatewaySubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_gateway_subneta_id
    ```

1. **Create Gateway Subnet B**

    ```bash
    alfa_oregon_recovery_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                    --cidr-block $alfa_oregon_recovery_subnet_gatewayb_cidr \
                                                                    --availability-zone us-west-2b \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-GatewaySubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_gateway_subnetb_id
    ```

1. **Create Gateway Subnet C**

    ```bash
    alfa_oregon_recovery_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                    --cidr-block $alfa_oregon_recovery_subnet_gatewayc_cidr \
                                                                    --availability-zone us-west-2c \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-GatewaySubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_gateway_subnetc_id
    ```

1. **Create Endpoint Subnet A**

    ```bash
    alfa_oregon_recovery_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                     --cidr-block $alfa_oregon_recovery_subnet_endpointa_cidr \
                                                                     --availability-zone us-west-2a \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-EndpointSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_endpoint_subneta_id
    ```

1. **Create Endpoint Subnet B**

    ```bash
    alfa_oregon_recovery_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                     --cidr-block $alfa_oregon_recovery_subnet_endpointb_cidr \
                                                                     --availability-zone us-west-2b \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-EndpointSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_endpoint_subnetb_id
    ```

1. **Create Endpoint Subnet C**

    ```bash
    alfa_oregon_recovery_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                     --cidr-block $alfa_oregon_recovery_subnet_endpointc_cidr \
                                                                     --availability-zone us-west-2c \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Recovery-EndpointSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_endpoint_subnetc_id
    ```

1. **Create Public Route Table, Default Route and Associate with Public Subnets**

    ```bash
    alfa_oregon_recovery_public_rtb_id=$(aws ec2 create-route-table --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Alfa-Recovery-PublicRouteTable},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'RouteTable.RouteTableId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_public_rtb_id

    aws ec2 create-route --route-table-id $alfa_oregon_recovery_public_rtb_id \
                         --destination-cidr-block '0.0.0.0/0' \
                         --gateway-id $alfa_oregon_recovery_igw_id \
                         --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_public_rtb_id --subnet-id $alfa_oregon_recovery_public_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_public_rtb_id --subnet-id $alfa_oregon_recovery_public_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_public_rtb_id --subnet-id $alfa_oregon_recovery_public_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_public_rtb_id --subnet-id $alfa_oregon_recovery_web_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_public_rtb_id --subnet-id $alfa_oregon_recovery_web_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_public_rtb_id --subnet-id $alfa_oregon_recovery_web_subnetc_id \
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
      alfa_oregon_recovery_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                               --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Recovery-NAT-EIPA},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'AllocationId' \
                                                               --profile $profile --region us-west-2 --output text)
      camelz-variable alfa_oregon_recovery_ngw_eipa

      alfa_oregon_recovery_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_oregon_recovery_ngw_eipa \
                                                                --subnet-id $alfa_oregon_recovery_public_subneta_id \
                                                                --client-token $(date +%s) \
                                                                --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Alfa-Recovery-NAT-GatewayA},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'NatGateway.NatGatewayId' \
                                                                --profile $profile --region us-west-2 --output text)
      camelz-variable alfa_oregon_recovery_ngwa_id

      if [ $ha_ngw = 1 ]; then
        alfa_oregon_recovery_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                                 --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Recovery-NAT-EIPB},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'AllocationId' \
                                                                 --profile $profile --region us-west-2 --output text)
        camelz-variable alfa_oregon_recovery_ngw_eipb

        alfa_oregon_recovery_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_oregon_recovery_ngw_eipb \
                                                                  --subnet-id $alfa_oregon_recovery_public_subnetb_id \
                                                                  --client-token $(date +%s) \
                                                                  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Alfa-Recovery-NAT-GatewayB},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'NatGateway.NatGatewayId' \
                                                                  --profile $profile --region us-west-2 --output text)
        camelz-variable alfa_oregon_recovery_ngwb_id

        alfa_oregon_recovery_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                                 --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Recovery-NAT-EIPC},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'AllocationId' \
                                                                 --profile $profile --region us-west-2 --output text)
        camelz-variable alfa_oregon_recovery_ngw_eipc

        alfa_oregon_recovery_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_oregon_recovery_ngw_eipc \
                                                                  --subnet-id $alfa_oregon_recovery_public_subnetc_id \
                                                                  --client-token $(date +%s) \
                                                                  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Alfa-Recovery-NAT-GatewayC},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'NatGateway.NatGatewayId' \
                                                                  --profile $profile --region us-west-2 --output text)
        camelz-variable alfa_oregon_recovery_ngwc_id
      fi
    else
      # Create NAT Security Group
      alfa_oregon_recovery_nat_sg_id=$(aws ec2 create-security-group --group-name Alfa-Recovery-NAT-InstanceSecurityGroup \
                                                                     --description Alfa-Recovery-NAT-InstanceSecurityGroup \
                                                                     --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                     --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Recovery-NAT-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'GroupId' \
                                                                     --profile $profile --region us-west-2 --output text)
      camelz-variable alfa_oregon_recovery_nat_sg_id

      aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_nat_sg_id \
                                               --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$alfa_oregon_recovery_vpc_cidr,Description=\"VPC (All)\"}]" \
                                               --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All)\"}]" \
                                               --profile $profile --region us-west-2 --output text

      # Create NAT Instance
      alfa_oregon_recovery_nat_instance_id=$(aws ec2 run-instances --image-id $oregon_nat_ami_id \
                                                                   --instance-type t3a.nano \
                                                                   --iam-instance-profile Name=ManagedInstance \
                                                                   --key-name administrator \
                                                                   --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Alfa-Recovery-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_oregon_recovery_nat_sg_id],SubnetId=$alfa_oregon_recovery_public_subneta_id" \
                                                                   --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Recovery-NAT-Instance},{Key=Hostname,Value=alfuw2rnat01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Instances[0].InstanceId' \
                                                                   --profile $profile --region us-west-2 --output text)
      camelz-variable alfa_oregon_recovery_nat_instance_id

      aws ec2 modify-instance-attribute --instance-id $alfa_oregon_recovery_nat_instance_id \
                                        --no-source-dest-check \
                                        --profile $profile --region us-west-2 --output text

      alfa_oregon_recovery_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $alfa_oregon_recovery_nat_instance_id \
                                                                            --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                            --profile $profile --region us-west-2 --output text)
      camelz-variable alfa_oregon_recovery_nat_instance_eni_id

      alfa_oregon_recovery_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_oregon_recovery_nat_instance_id \
                                                                                --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                                --profile $profile --region us-west-2 --output text)
      camelz-variable alfa_oregon_recovery_nat_instance_private_ip
    fi
    ```

1. **Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets**

    ```bash
    alfa_oregon_recovery_private_rtba_id=$(aws ec2 create-route-table --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                      --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Alfa-Recovery-PrivateRouteTableA},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'RouteTable.RouteTableId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_private_rtba_id

    if [ $use_ngw = 1 ]; then
      aws ec2 create-route --route-table-id $alfa_oregon_recovery_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $alfa_oregon_recovery_ngwa_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $alfa_oregon_recovery_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $alfa_oregon_recovery_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtba_id --subnet-id $alfa_oregon_recovery_application_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtba_id --subnet-id $alfa_oregon_recovery_database_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtba_id --subnet-id $alfa_oregon_recovery_directory_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtba_id --subnet-id $alfa_oregon_recovery_management_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtba_id --subnet-id $alfa_oregon_recovery_gateway_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtba_id --subnet-id $alfa_oregon_recovery_endpoint_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1. **Create Private Route Table for Availability Zone B, Default Route and Associate with Private Subnets**

    ```bash
    alfa_oregon_recovery_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                      --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Alfa-Recovery-PrivateRouteTableB},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'RouteTable.RouteTableId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_private_rtbb_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then alfa_oregon_recovery_ngw_id=$alfa_oregon_recovery_ngwb_id; else alfa_oregon_recovery_ngw_id=$alfa_oregon_recovery_ngwa_id; fi
      aws ec2 create-route --route-table-id $alfa_oregon_recovery_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $alfa_oregon_recovery_ngw_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $alfa_oregon_recovery_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $alfa_oregon_recovery_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtbb_id --subnet-id $alfa_oregon_recovery_application_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtbb_id --subnet-id $alfa_oregon_recovery_database_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtbb_id --subnet-id $alfa_oregon_recovery_directory_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtbb_id --subnet-id $alfa_oregon_recovery_management_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtbb_id --subnet-id $alfa_oregon_recovery_gateway_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtbb_id --subnet-id $alfa_oregon_recovery_endpoint_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1. **Create Private Route Table for Availability Zone C, Default Route and Associate with Private Subnets**

    ```bash
    alfa_oregon_recovery_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                      --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Alfa-Recovery-PrivateRouteTableC},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'RouteTable.RouteTableId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_private_rtbc_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then alfa_oregon_recovery_ngw_id=$alfa_oregon_recovery_ngwc_id; else alfa_oregon_recovery_ngw_id=$alfa_oregon_recovery_ngwa_id; fi
      aws ec2 create-route --route-table-id $alfa_oregon_recovery_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $alfa_oregon_recovery_ngw_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $alfa_oregon_recovery_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $alfa_oregon_recovery_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtbc_id --subnet-id $alfa_oregon_recovery_application_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtbc_id --subnet-id $alfa_oregon_recovery_database_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtbc_id --subnet-id $alfa_oregon_recovery_directory_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtbc_id --subnet-id $alfa_oregon_recovery_management_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtbc_id --subnet-id $alfa_oregon_recovery_gateway_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_recovery_private_rtbc_id --subnet-id $alfa_oregon_recovery_endpoint_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1. **Create VPC Endpoint Security Group**

    ```bash
    alfa_oregon_recovery_vpce_sg_id=$(aws ec2 create-security-group --group-name Alfa-Recovery-VPCEndpointSecurityGroup \
                                                                    --description Alfa-Recovery-VPCEndpointSecurityGroup \
                                                                    --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Recovery-VPCEndpointSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'GroupId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_vpce_sg_id

    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_vpce_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_oregon_recovery_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All TCP)\"}]" \
                                             --profile $profile --region us-west-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_recovery_vpce_sg_id \
                                             --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_oregon_recovery_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All UDP)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    ```

1. **Create VPC Endpoints for SSM and SSMMessages**

    ```bash
    alfa_oregon_recovery_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                   --vpc-endpoint-type Interface \
                                                                   --service-name com.amazonaws.us-west-2.ssm \
                                                                   --private-dns-enabled \
                                                                   --security-group-ids $alfa_oregon_recovery_vpce_sg_id \
                                                                   --subnet-ids $alfa_oregon_recovery_endpoint_subneta_id $alfa_oregon_recovery_endpoint_subnetb_id $alfa_oregon_recovery_endpoint_subnetc_id \
                                                                   --client-token $(date +%s) \
                                                                   --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Recovery-SSMVpcEndpoint},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'VpcEndpoint.VpcEndpointId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_ssm_vpce_id

    alfa_oregon_recovery_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_oregon_recovery_vpc_id \
                                                                    --vpc-endpoint-type Interface \
                                                                    --service-name com.amazonaws.us-west-2.ssmmessages \
                                                                    --private-dns-enabled \
                                                                    --security-group-ids $alfa_oregon_recovery_vpce_sg_id \
                                                                    --subnet-ids $alfa_oregon_recovery_endpoint_subneta_id $alfa_oregon_recovery_endpoint_subnetb_id $alfa_oregon_recovery_endpoint_subnetc_id \
                                                                    --client-token $(date +%s) \
                                                                    --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Recovery-SSMMessagesVpcEndpoint},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'VpcEndpoint.VpcEndpointId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_ssmm_vpce_id
    ```
