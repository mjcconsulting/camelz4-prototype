# Modules:VPCs:Management:Oregon

This module builds the Management VPC in the AWS Oregon (us-west-2) Region within the CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Management VPC

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1.  **Tag Default-VPC Resources**

    We tag the Devault-VPC resources so that they appear with a similar naming convention in list displays, and it's
    easy to differentiate them from CaMeLz-POC-4 Resources.

    ```bash
    # Tag Default-VPC
    oregon_default_vpc_id=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true \
                                                  --query 'Vpcs[0].VpcId' \
                                                  --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $oregon_default_vpc_id \
                        --tags Key=Name,Value=Default-VPC \
                               Key=Company,Value=Default \
                               Key=Environment,Value=Default \
                               Key=Project,Value=Default \
                        --profile $profile --region us-west-2 --output text

    # Tag Default-Subnets
    oregon_default_default_subnet_tuples=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$oregon_default_vpc_id \
                                                                    --query 'Subnets[].[SubnetId,AvailabilityZone]' \
                                                                    --profile $profile --region=us-west-2 --output text \
                                           | tr '\t' ',' | tr '\n' ' ')

    for tuple in $(echo $oregon_default_default_subnet_tuples); do
        subnet_id=${tuple%,*}
        az=${tuple#*,}; az=${az: -1}; az=$(echo $az | tr '[:lower:]' '[:upper:]')
        aws ec2 create-tags --resources $subnet_id \
                            --tags Key=Name,Value=Default-DefaultSubnet$az \
                                   Key=Company,Value=Default \
                                   Key=Environment,Value=Default \
                                   Key=Project,Value=Default\
                            --profile $profile --region us-west-2 --output text
    done

    # Tag Default-MainRouteTable
    oregon_default_main_rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$oregon_default_vpc_id \
                                                                         Name=association.main,Values=true \
                                                               --query 'RouteTables[0].RouteTableId' \
                                                               --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $oregon_default_main_rtb_id \
                        --tags Key=Name,Value=Default-MainRouteTable \
                               Key=Company,Value=Default \
                               Key=Environment,Value=Default \
                               Key=Project,Value=Default\
                        --profile $profile --region us-west-2 --output text

    # Tag Default-InternetGateway
    oregon_default_igw_id=$(aws ec2 describe-internet-gateways --filter Name=attachment.vpc-id,Values=$oregon_default_vpc_id \
                                                               --query='InternetGateways[0].InternetGatewayId' \
                                                               --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $oregon_default_igw_id \
                        --tags Key=Name,Value=Default-InternetGateway \
                               Key=Company,Value=Default \
                               Key=Environment,Value=Default \
                               Key=Project,Value=Default \
                        --profile $profile --region us-west-2 --output text

    # Tag Default-DHCPOptions
    oregon_default_dopt_id=$(aws ec2 describe-vpcs --vpc-id=$oregon_default_vpc_id \
                                                   --query 'Vpcs[0].DhcpOptionsId' \
                                                   --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $oregon_default_dopt_id \
                        --tags Key=Name,Value=Default-DHCPOptions \
                               Key=Company,Value=Default \
                               Key=Environment,Value=Default \
                               Key=Project,Value=Default \
                        --profile $profile --region us-west-2 --output text

    # Tag Default-DefaultNetworkAcl
    oregon_default_default_nacl_id=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$oregon_default_vpc_id \
                                                                             Name=default,Values=true \
                                                                   --query 'NetworkAcls[0].NetworkAclId' \
                                                                   --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $oregon_default_default_nacl_id \
                        --tags Key=Name,Value=Default-DefaultNetworkAcl \
                               Key=Company,Value=Default \
                               Key=Environment,Value=Default \
                               Key=Project,Value=Default \
                        --profile $profile --region us-west-2 --output text

    # Tag Default-DefaultSecurityGroup
    oregon_default_default_sg_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$oregon_default_vpc_id \
                                                                              Name=group-name,Values=default \
                                                                    --query 'SecurityGroups[0].GroupId' \
                                                                    --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $oregon_default_default_sg_id \
                        --tags Key=Name,Value=Default-DefaultSecurityGroup \
                               Key=Company,Value=Default \
                               Key=Environment,Value=Default \
                               Key=Project,Value=Default \
                        --profile $profile --region us-west-2 --output text
    ```

1.  **Create VPC**

    ```bash
    oregon_management_vpc_id=$(aws ec2 create-vpc --cidr-block $oregon_management_vpc_cidr \
                                                  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=Management-VPC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                  --query 'Vpc.VpcId' \
                                                  --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_vpc_id


    aws ec2 modify-vpc-attribute --vpc-id $oregon_management_vpc_id \
                                 --enable-dns-support \
                                 --profile $profile --region us-west-2 --output text

    aws ec2 modify-vpc-attribute --vpc-id $oregon_management_vpc_id \
                                 --enable-dns-hostnames \
                                 --profile $profile --region us-west-2 --output text
    ```

1.  **Tag Attached Default Resources Created With VPC**

    Creating a VPC also creates a set of attached default resources which do not have the same tags propagated.
    We will also tag these associated resources to insure consistency in the list displays.

    ```bash
    # Tag Management-MainRouteTable
    main_rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$oregon_management_vpc_id \
                                                          Name=association.main,Values=true \
                                                --query 'RouteTables[0].RouteTableId' \
                                                --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $main_rtb_id \
                        --tags Key=Name,Value=Management-MainRouteTable \
                               Key=Company,Value=Camelz \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text

    # Tag Management-DefaultNetworkAcl
    default_nacl_id=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$oregon_management_vpc_id \
                                                              Name=default,Values=true \
                                                    --query 'NetworkAcls[0].NetworkAclId' \
                                                    --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $default_nacl_id \
                        --tags Key=Name,Value=Management-DefaultNetworkAcl \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text

    # Tag Default-DefaultSecurityGroup
    default_sg_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$oregon_management_vpc_id \
                                                               Name=group-name,Values=default \
                                                     --query 'SecurityGroups[0].GroupId' \
                                                     --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $default_sg_id \
                        --tags Key=Name,Value=Management-DefaultSecurityGroup \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text
    ```

1.  **Create VPC Flow Log**

    ```bash
    aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Management/Oregon" \
                              --profile $profile --region us-west-2 --output text

    aws ec2 create-flow-logs --resource-type VPC --resource-ids $oregon_management_vpc_id \
                             --traffic-type ALL \
                             --log-destination-type cloud-watch-logs \
                             --log-destination "arn:aws:logs:us-west-2:${management_account_id}:log-group:/${company_name_lc}/${system_name_lc}/FlowLog/Management/Oregon" \
                             --deliver-logs-permission-arn "arn:aws:iam::${management_account_id}:role/FlowLog" \
                             --profile $profile --region us-west-2 --output text
    ```

1.  **Create Internet Gateway**

    ```bash
    oregon_management_igw_id=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Management-InternetGateway},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'InternetGateway.InternetGatewayId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_igw_id

    aws ec2 attach-internet-gateway --vpc-id $oregon_management_vpc_id \
                                    --internet-gateway-id $oregon_management_igw_id \
                                    --profile $profile --region us-west-2 --output text
    ```

1.  **Create Private Hosted Zone**

    ```bash
    oregon_management_private_hostedzone_id=$(aws route53 create-hosted-zone --name $oregon_management_private_domain \
                                                                             --vpc VPCRegion=us-west-2,VPCId=$oregon_management_vpc_id \
                                                                             --hosted-zone-config Comment="Private Zone for $oregon_management_private_domain",PrivateZone=true \
                                                                             --caller-reference $(date +%s) \
                                                                             --query 'HostedZone.Id' \
                                                                             --profile $profile --region us-west-2 --output text | cut -f3 -d /)
    camelz-variable oregon_management_private_hostedzone_id
    ```

1.  **Create DHCP Options Set**

    ```bash
    oregon_management_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$oregon_management_private_domain]" \
                                                                                  "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                            --tag-specifications "ResourceType=dhcp-options,Tags=[{Key=Name,Value=Management-DHCPOptions},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'DhcpOptions.DhcpOptionsId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_dopt_id

    aws ec2 associate-dhcp-options --vpc-id $oregon_management_vpc_id \
                                   --dhcp-options-id $oregon_management_dopt_id \
                                   --profile $profile --region us-west-2 --output text
    ```

1.  **Create Public Subnet A**

    ```bash
    oregon_management_public_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                --cidr-block $oregon_management_subnet_publica_cidr \
                                                                --availability-zone us-west-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-PublicSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_public_subneta_id
    ```

1.  **Create Public Subnet B**

    ```bash
    oregon_management_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                --cidr-block $oregon_management_subnet_publicb_cidr \
                                                                --availability-zone us-west-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-PublicSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_public_subnetb_id
    ```

1.  **Create Public Subnet C**

    ```bash
    oregon_management_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                --cidr-block $oregon_management_subnet_publicc_cidr \
                                                                --availability-zone us-west-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-PublicSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_public_subnetc_id
    ```

1.  **Create Web Subnet A**

    ```bash
    oregon_management_web_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                             --cidr-block $oregon_management_subnet_weba_cidr \
                                                             --availability-zone us-west-2a \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-WebSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_web_subneta_id
    ```

1.  **Create Web Subnet B**

    ```bash
    oregon_management_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                             --cidr-block $oregon_management_subnet_webb_cidr \
                                                             --availability-zone us-west-2b \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-WebSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_web_subnetb_id
    ```

1.  **Create Web Subnet C**

    ```bash
    oregon_management_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                             --cidr-block $oregon_management_subnet_webc_cidr \
                                                             --availability-zone us-west-2c \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-WebSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_web_subnetc_id
    ```

1.  **Create Application Subnet A**

    ```bash
    oregon_management_application_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                     --cidr-block $oregon_management_subnet_applicationa_cidr \
                                                                     --availability-zone us-west-2a \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-ApplicationSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_application_subneta_id
    ```

1.  **Create Application Subnet B**

    ```bash
    oregon_management_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                     --cidr-block $oregon_management_subnet_applicationb_cidr \
                                                                     --availability-zone us-west-2b \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-ApplicationSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_application_subnetb_id

1.  **Create Application Subnet C**

    ```bash
    oregon_management_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                     --cidr-block $oregon_management_subnet_applicationc_cidr \
                                                                     --availability-zone us-west-2c \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-ApplicationSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_application_subnetc_id

1.  **Create Database Subnet A**

    ```bash
    oregon_management_database_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                  --cidr-block $oregon_management_subnet_databasea_cidr \
                                                                  --availability-zone us-west-2a \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-DatabaseSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_database_subneta_id

1.  **Create Database Subnet B**

    ```bash
    oregon_management_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                  --cidr-block $oregon_management_subnet_databaseb_cidr \
                                                                  --availability-zone us-west-2b \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-DatabaseSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_database_subnetb_id

1.  **Create Database Subnet C**

    ```bash
    oregon_management_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                  --cidr-block $oregon_management_subnet_databasec_cidr \
                                                                  --availability-zone us-west-2c \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-DatabaseSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_database_subnetc_id

1.  **Create Directory Subnet A**

    ```bash
    oregon_management_directory_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                   --cidr-block $oregon_management_subnet_directorya_cidr \
                                                                   --availability-zone us-west-2a \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-DirectorySubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_directory_subneta_id

1.  **Create Directory Subnet B**

    ```bash
    oregon_management_directory_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                   --cidr-block $oregon_management_subnet_directoryb_cidr \
                                                                   --availability-zone us-west-2b \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-DirectorySubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_directory_subnetb_id

1.  **Create Directory Subnet C**

    ```bash
    oregon_management_directory_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                   --cidr-block $oregon_management_subnet_directoryc_cidr \
                                                                   --availability-zone us-west-2c \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-DirectorySubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_directory_subnetc_id

1.  **Create Management Subnet A**

    ```bash
    oregon_management_management_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                    --cidr-block $oregon_management_subnet_managementa_cidr \
                                                                    --availability-zone us-west-2a \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-ManagementSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_management_subneta_id

1.  **Create Management Subnet B**

    ```bash
    oregon_management_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                    --cidr-block $oregon_management_subnet_managementb_cidr \
                                                                    --availability-zone us-west-2b \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-ManagementSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_management_subnetb_id

1.  **Create Management Subnet C**

    ```bash
    oregon_management_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                    --cidr-block $oregon_management_subnet_managementc_cidr \
                                                                    --availability-zone us-west-2c \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-ManagementSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_management_subnetc_id

1.  **Create Gateway Subnet A**

    ```bash
    oregon_management_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                 --cidr-block $oregon_management_subnet_gatewaya_cidr \
                                                                 --availability-zone us-west-2a \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-GatewaySubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_gateway_subneta_id

1.  **Create Gateway Subnet B**

    ```bash
    oregon_management_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                 --cidr-block $oregon_management_subnet_gatewayb_cidr \
                                                                 --availability-zone us-west-2b \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-GatewaySubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_gateway_subnetb_id

1.  **Create Gateway Subnet C**

    ```bash
    oregon_management_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                 --cidr-block $oregon_management_subnet_gatewayc_cidr \
                                                                 --availability-zone us-west-2c \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-GatewaySubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_gateway_subnetc_id

1.  **Create Endpoint Subnet A**

    ```bash
    oregon_management_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                  --cidr-block $oregon_management_subnet_endpointa_cidr \
                                                                  --availability-zone us-west-2a \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-EndpointSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_endpoint_subneta_id

1.  **Create Endpoint Subnet B**

    ```bash
    oregon_management_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                  --cidr-block $oregon_management_subnet_endpointb_cidr \
                                                                  --availability-zone us-west-2b \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-EndpointSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_endpoint_subnetb_id

1.  **Create Endpoint Subnet C**

    ```bash
    oregon_management_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_management_vpc_id \
                                                                  --cidr-block $oregon_management_subnet_endpointc_cidr \
                                                                  --availability-zone us-west-2c \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Management-EndpointSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_endpoint_subnetc_id

1.  **Create Public Route Table, Default Route and Associate with Public Subnets**

    ```bash
    oregon_management_public_rtb_id=$(aws ec2 create-route-table --vpc-id $oregon_management_vpc_id \
                                                                 --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Management-PublicRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'RouteTable.RouteTableId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_public_rtb_id

    aws ec2 create-route --route-table-id $oregon_management_public_rtb_id \
                         --destination-cidr-block '0.0.0.0/0' \
                         --gateway-id $oregon_management_igw_id \
                         --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $oregon_management_public_rtb_id --subnet-id $oregon_management_public_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_public_rtb_id --subnet-id $oregon_management_public_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_public_rtb_id --subnet-id $oregon_management_public_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $oregon_management_public_rtb_id --subnet-id $oregon_management_web_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_public_rtb_id --subnet-id $oregon_management_web_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_public_rtb_id --subnet-id $oregon_management_web_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

1.  **Create NAT Gateways - OR - NAT Instances**

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
      oregon_management_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                            --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Management-NAT-EIPA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'AllocationId' \
                                                            --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_management_ngw_eipa

      oregon_management_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $oregon_management_ngw_eipa \
                                                             --subnet-id $oregon_management_public_subneta_id \
                                                             --client-token $(date +%s) \
                                                             --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Management-NAT-GatewayA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'NatGateway.NatGatewayId' \
                                                             --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_management_ngwa_id

      if [ $ha_ngw = 1 ]; then
        oregon_management_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                              --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Management-NAT-EIPB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'AllocationId' \
                                                              --profile $profile --region us-west-2 --output text)
        camelz-variable oregon_management_ngw_eipb

        oregon_management_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $oregon_management_ngw_eipb \
                                                               --subnet-id $oregon_management_public_subnetb_id \
                                                               --client-token $(date +%s) \
                                                               --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Management-NAT-GatewayB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'NatGateway.NatGatewayId' \
                                                               --profile $profile --region us-west-2 --output text)
        camelz-variable oregon_management_ngwb_id

        oregon_management_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                              --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Management-NAT-EIPC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'AllocationId' \
                                                              --profile $profile --region us-west-2 --output text)
        camelz-variable oregon_management_ngw_eipc

        oregon_management_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $oregon_management_ngw_eipc \
                                                               --subnet-id $oregon_management_public_subnetc_id \
                                                               --client-token $(date +%s) \
                                                               --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Management-NAT-GatewayC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'NatGateway.NatGatewayId' \
                                                               --profile $profile --region us-west-2 --output text)
        camelz-variable oregon_management_ngwc_id
      fi
    else
      # Create NAT Security Group
      oregon_management_nat_sg_id=$(aws ec2 create-security-group --group-name Management-NAT-InstanceSecurityGroup \
                                                                  --description Management-NAT-InstanceSecurityGroup \
                                                                  --vpc-id $oregon_management_vpc_id \
                                                                  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Management-NAT-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'GroupId' \
                                                                  --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_management_nat_sg_id

      aws ec2 authorize-security-group-ingress --group-id $oregon_management_nat_sg_id \
                                               --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$oregon_management_vpc_cidr,Description=\"VPC (All)\"}]" \
                                               --profile $profile --region us-west-2 --output text

      # Create NAT Instance
      oregon_management_nat_instance_id=$(aws ec2 run-instances --image-id $oregon_nat_ami_id \
                                                                --instance-type t3a.nano \
                                                                --iam-instance-profile Name=ManagedInstance \
                                                                --key-name administrator \
                                                                --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Management-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$oregon_management_nat_sg_id],SubnetId=$oregon_management_public_subneta_id" \
                                                                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Management-NAT-Instance},{Key=Hostname,Value=cmlue1mnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Instances[0].InstanceId' \
                                                                --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_management_nat_instance_id

      aws ec2 modify-instance-attribute --instance-id $oregon_management_nat_instance_id \
                                        --no-source-dest-check \
                                        --profile $profile --region us-west-2 --output text

      oregon_management_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $oregon_management_nat_instance_id \
                                                                         --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                         --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_management_nat_instance_eni_id

      oregon_management_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $oregon_management_nat_instance_id \
                                                                             --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                             --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_management_nat_instance_private_ip
    fi
    ```

1.  **Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets**

    ```bash
    oregon_management_private_rtba_id=$(aws ec2 create-route-table --vpc-id $oregon_management_vpc_id \
                                                                   --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Management-PrivateRouteTableA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_private_rtba_id

    if [ $use_ngw = 1 ]; then
      aws ec2 create-route --route-table-id $oregon_management_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $oregon_management_ngwa_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $oregon_management_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $oregon_management_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtba_id --subnet-id $oregon_management_application_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtba_id --subnet-id $oregon_management_database_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtba_id --subnet-id $oregon_management_directory_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtba_id --subnet-id $oregon_management_management_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtba_id --subnet-id $oregon_management_gateway_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtba_id --subnet-id $oregon_management_endpoint_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1.  **Create Private Route Table for Availability Zone B, Default Route and Associate with Private Subnets**

    ```bash
    oregon_management_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $oregon_management_vpc_id \
                                                                   --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Management-PrivateRouteTableB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_private_rtbb_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then oregon_management_ngw_id=$oregon_management_ngwb_id; else oregon_management_ngw_id=$oregon_management_ngwa_id; fi
      aws ec2 create-route --route-table-id $oregon_management_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $oregon_management_ngw_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $oregon_management_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $oregon_management_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtbb_id --subnet-id $oregon_management_application_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtbb_id --subnet-id $oregon_management_database_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtbb_id --subnet-id $oregon_management_directory_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtbb_id --subnet-id $oregon_management_management_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtbb_id --subnet-id $oregon_management_gateway_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtbb_id --subnet-id $oregon_management_endpoint_subnetb_id \
                                  --profile $profile --region us-west-2 --output text

1.  **Create Private Route Table for Availability Zone C, Default Route and Associate with Private Subnets**

    ```bash
    oregon_management_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $oregon_management_vpc_id \
                                                                   --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Management-PrivateRouteTableC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_private_rtbc_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then oregon_management_ngw_id=$oregon_management_ngwc_id; else oregon_management_ngw_id=$oregon_management_ngwa_id; fi
      aws ec2 create-route --route-table-id $oregon_management_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $oregon_management_ngw_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $oregon_management_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $oregon_management_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtbc_id --subnet-id $oregon_management_application_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtbc_id --subnet-id $oregon_management_database_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtbc_id --subnet-id $oregon_management_directory_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtbc_id --subnet-id $oregon_management_management_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtbc_id --subnet-id $oregon_management_gateway_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_management_private_rtbc_id --subnet-id $oregon_management_endpoint_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1.  **Create VPC Endpoint Security Group**

    ```bash
    oregon_management_vpce_sg_id=$(aws ec2 create-security-group --group-name Management-VPCEndpointSecurityGroup \
                                                                 --description Management-VPCEndpointSecurityGroup \
                                                                 --vpc-id $oregon_management_vpc_id \
                                                                 --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Management-VPCEndpointSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'GroupId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_vpce_sg_id

    aws ec2 authorize-security-group-ingress --group-id $oregon_management_vpce_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$oregon_management_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                             --profile $profile --region us-west-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $oregon_management_vpce_sg_id \
                                             --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$oregon_management_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    ```

1.  **Create VPC Endpoints for SSM and SSMMessages**

    ```bash
    oregon_management_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $oregon_management_vpc_id \
                                                                --vpc-endpoint-type Interface \
                                                                --service-name com.amazonaws.us-west-2.ssm \
                                                                --private-dns-enabled \
                                                                --security-group-ids $oregon_management_vpce_sg_id \
                                                                --subnet-ids $oregon_management_endpoint_subneta_id $oregon_management_endpoint_subnetb_id $oregon_management_endpoint_subnetc_id \
                                                                --client-token $(date +%s) \
                                                                --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Management-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'VpcEndpoint.VpcEndpointId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_ssm_vpce_id

    oregon_management_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $oregon_management_vpc_id \
                                                                 --vpc-endpoint-type Interface \
                                                                 --service-name com.amazonaws.us-west-2.ssmmessages \
                                                                 --private-dns-enabled \
                                                                 --security-group-ids $oregon_management_vpce_sg_id \
                                                                 --subnet-ids $oregon_management_endpoint_subneta_id $oregon_management_endpoint_subnetb_id $oregon_management_endpoint_subnetc_id \
                                                                 --client-token $(date +%s) \
                                                                 --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Management-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'VpcEndpoint.VpcEndpointId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_ssmm_vpce_id
    ```
