# Modules:VPCs:Build Account:Ohio:Build VPC

This module builds the Build VPC in the AWS Ohio (us-east-2) Region within the CaMeLz-Build Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Build VPC

1. **Set Profile for Build Account**

    ```bash
    profile=$build_profile
    ```

1.  **Create VPC**

    ```bash
    ohio_build_vpc_id=$(aws ec2 create-vpc --cidr-block $ohio_build_vpc_cidr \
                                           --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=Build-VPC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                           --query 'Vpc.VpcId' \
                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_vpc_id


    aws ec2 modify-vpc-attribute --vpc-id $ohio_build_vpc_id \
                                 --enable-dns-support \
                                 --profile $profile --region us-east-2 --output text

    aws ec2 modify-vpc-attribute --vpc-id $ohio_build_vpc_id \
                                 --enable-dns-hostnames \
                                 --profile $profile --region us-east-2 --output text
    ```

1.  **Tag Attached Default Resources Created With VPC**

    Creating a VPC also creates a set of attached default resources which do not have the same tags propagated.
    We will also tag these associated resources to insure consistency in the list displays.

    ```bash
    # Tag Build-MainRouteTable
    main_rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$ohio_build_vpc_id \
                                                          Name=association.main,Values=true \
                                                --query 'RouteTables[0].RouteTableId' \
                                                --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $main_rtb_id \
                        --tags Key=Name,Value=Build-MainRouteTable \
                               Key=Company,Value=Camelz \
                               Key=Environment,Value=Build \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

    # Tag Build-DefaultNetworkAcl
    default_nacl_id=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$ohio_build_vpc_id \
                                                              Name=default,Values=true \
                                                    --query 'NetworkAcls[0].NetworkAclId' \
                                                    --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $default_nacl_id \
                        --tags Key=Name,Value=Build-DefaultNetworkAcl \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Build \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

    # Tag Default-DefaultSecurityGroup
    default_sg_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$ohio_build_vpc_id \
                                                               Name=group-name,Values=default \
                                                     --query 'SecurityGroups[0].GroupId' \
                                                     --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $default_sg_id \
                        --tags Key=Name,Value=Build-DefaultSecurityGroup \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Build \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text
    ```

1.  **Create VPC Flow Log**

    ```bash
    aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Build/Ohio" \
                              --profile $profile --region us-east-2 --output text

    aws ec2 create-flow-logs --resource-type VPC --resource-ids $ohio_build_vpc_id \
                             --traffic-type ALL \
                             --log-destination-type cloud-watch-logs \
                             --log-destination "arn:aws:logs:us-east-2:${build_account_id}:log-group:/${company_name_lc}/${system_name_lc}/FlowLog/Build/Ohio" \
                             --deliver-logs-permission-arn "arn:aws:iam::${build_account_id}:role/FlowLog" \
                             --profile $profile --region us-east-2 --output text
    ```

1.  **Create Internet Gateway**

    ```bash
    ohio_build_igw_id=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Build-InternetGateway},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'InternetGateway.InternetGatewayId' \
                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_igw_id

    aws ec2 attach-internet-gateway --vpc-id $ohio_build_vpc_id \
                                    --internet-gateway-id $ohio_build_igw_id \
                                    --profile $profile --region us-east-2 --output text
    ```

1.  **Create Private Hosted Zone**

    ```bash
    ohio_build_private_hostedzone_id=$(aws route53 create-hosted-zone --name $ohio_build_private_domain \
                                                                      --vpc VPCRegion=us-east-2,VPCId=$ohio_build_vpc_id \
                                                                      --hosted-zone-config Comment="Private Zone for $ohio_build_private_domain",PrivateZone=true \
                                                                      --caller-reference $(date +%s) \
                                                                      --query 'HostedZone.Id' \
                                                                      --profile $profile --region us-east-2 --output text | cut -f3 -d /)
    camelz-variable ohio_build_private_hostedzone_id
    ```

1.  **Create DHCP Options Set**

    ```bash
    ohio_build_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$ohio_build_private_domain]" \
                                                                           "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                     --tag-specifications "ResourceType=dhcp-options,Tags=[{Key=Name,Value=Build-DHCPOptions},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                     --query 'DhcpOptions.DhcpOptionsId' \
                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_dopt_id

    aws ec2 associate-dhcp-options --vpc-id $ohio_build_vpc_id \
                                   --dhcp-options-id $ohio_build_dopt_id \
                                   --profile $profile --region us-east-2 --output text
    ```

1.  **Create Public Subnet A**

    ```bash
    ohio_build_public_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                         --cidr-block $ohio_build_subnet_publica_cidr \
                                                         --availability-zone us-east-2a \
                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-PublicSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_public_subneta_id
    ```

1.  **Create Public Subnet B**

    ```bash
    ohio_build_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                         --cidr-block $ohio_build_subnet_publicb_cidr \
                                                         --availability-zone us-east-2b \
                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-PublicSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_public_subnetb_id
    ```

1.  **Create Public Subnet C**

    ```bash
    ohio_build_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                         --cidr-block $ohio_build_subnet_publicc_cidr \
                                                         --availability-zone us-east-2c \
                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-PublicSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_public_subnetc_id
    ```

1.  **Create Web Subnet A**

    ```bash
    ohio_build_web_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                      --cidr-block $ohio_build_subnet_weba_cidr \
                                                      --availability-zone us-east-2a \
                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-WebSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_web_subneta_id
    ```

1.  **Create Web Subnet B**

    ```bash
    ohio_build_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                      --cidr-block $ohio_build_subnet_webb_cidr \
                                                      --availability-zone us-east-2b \
                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-WebSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_web_subnetb_id
    ```

1.  **Create Web Subnet C**

    ```bash
    ohio_build_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                      --cidr-block $ohio_build_subnet_webc_cidr \
                                                      --availability-zone us-east-2c \
                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-WebSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_web_subnetc_id
    ```

1.  **Create Application Subnet A**

    ```bash
    ohio_build_application_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                              --cidr-block $ohio_build_subnet_applicationa_cidr \
                                                              --availability-zone us-east-2a \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-ApplicationSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_application_subneta_id
    ```

1.  **Create Application Subnet B**

    ```bash
    ohio_build_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                              --cidr-block $ohio_build_subnet_applicationb_cidr \
                                                              --availability-zone us-east-2b \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-ApplicationSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_application_subnetb_id

1.  **Create Application Subnet C**

    ```bash
    ohio_build_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                              --cidr-block $ohio_build_subnet_applicationc_cidr \
                                                              --availability-zone us-east-2c \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-ApplicationSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_application_subnetc_id

1.  **Create Database Subnet A**

    ```bash
    ohio_build_database_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                           --cidr-block $ohio_build_subnet_databasea_cidr \
                                                           --availability-zone us-east-2a \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-DatabaseSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_database_subneta_id

1.  **Create Database Subnet B**

    ```bash
    ohio_build_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                           --cidr-block $ohio_build_subnet_databaseb_cidr \
                                                           --availability-zone us-east-2b \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-DatabaseSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_database_subnetb_id

1.  **Create Database Subnet C**

    ```bash
    ohio_build_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                           --cidr-block $ohio_build_subnet_databasec_cidr \
                                                           --availability-zone us-east-2c \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-DatabaseSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_database_subnetc_id

1.  **Create Directory Subnet A**

    ```bash
    ohio_build_directory_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                            --cidr-block $ohio_build_subnet_directorya_cidr \
                                                            --availability-zone us-east-2a \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-DirectorySubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_directory_subneta_id

1.  **Create Directory Subnet B**

    ```bash
    ohio_build_directory_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                            --cidr-block $ohio_build_subnet_directoryb_cidr \
                                                            --availability-zone us-east-2b \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-DirectorySubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_directory_subnetb_id

1.  **Create Directory Subnet C**

    ```bash
    ohio_build_directory_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                            --cidr-block $ohio_build_subnet_directoryc_cidr \
                                                            --availability-zone us-east-2c \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-DirectorySubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_directory_subnetc_id

1.  **Create Management Subnet A**

    ```bash
    ohio_build_management_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                             --cidr-block $ohio_build_subnet_managementa_cidr \
                                                             --availability-zone us-east-2a \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-ManagementSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_management_subneta_id

1.  **Create Management Subnet B**

    ```bash
    ohio_build_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                             --cidr-block $ohio_build_subnet_managementb_cidr \
                                                             --availability-zone us-east-2b \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-ManagementSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_management_subnetb_id

1.  **Create Management Subnet C**

    ```bash
    ohio_build_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                             --cidr-block $ohio_build_subnet_managementc_cidr \
                                                             --availability-zone us-east-2c \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-ManagementSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_management_subnetc_id

1.  **Create Gateway Subnet A**

    ```bash
    ohio_build_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                          --cidr-block $ohio_build_subnet_gatewaya_cidr \
                                                          --availability-zone us-east-2a \
                                                          --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-GatewaySubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_gateway_subneta_id

1.  **Create Gateway Subnet B**

    ```bash
    ohio_build_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                          --cidr-block $ohio_build_subnet_gatewayb_cidr \
                                                          --availability-zone us-east-2b \
                                                          --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-GatewaySubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_gateway_subnetb_id

1.  **Create Gateway Subnet C**

    ```bash
    ohio_build_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                          --cidr-block $ohio_build_subnet_gatewayc_cidr \
                                                          --availability-zone us-east-2c \
                                                          --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-GatewaySubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_gateway_subnetc_id

1.  **Create Endpoint Subnet A**

    ```bash
    ohio_build_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                           --cidr-block $ohio_build_subnet_endpointa_cidr \
                                                           --availability-zone us-east-2a \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-EndpointSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_endpoint_subneta_id

1.  **Create Endpoint Subnet B**

    ```bash
    ohio_build_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                           --cidr-block $ohio_build_subnet_endpointb_cidr \
                                                           --availability-zone us-east-2b \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-EndpointSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_endpoint_subnetb_id

1.  **Create Endpoint Subnet C**

    ```bash
    ohio_build_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_build_vpc_id \
                                                           --cidr-block $ohio_build_subnet_endpointc_cidr \
                                                           --availability-zone us-east-2c \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Build-EndpointSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_endpoint_subnetc_id

1.  **Create Public Route Table, Default Route and Associate with Public Subnets**

    ```bash
    ohio_build_public_rtb_id=$(aws ec2 create-route-table --vpc-id $ohio_build_vpc_id \
                                                          --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Build-PublicRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'RouteTable.RouteTableId' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_public_rtb_id

    aws ec2 create-route --route-table-id $ohio_build_public_rtb_id \
                         --destination-cidr-block '0.0.0.0/0' \
                         --gateway-id $ohio_build_igw_id \
                         --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $ohio_build_public_rtb_id --subnet-id $ohio_build_public_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_public_rtb_id --subnet-id $ohio_build_public_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_public_rtb_id --subnet-id $ohio_build_public_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $ohio_build_public_rtb_id --subnet-id $ohio_build_web_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_public_rtb_id --subnet-id $ohio_build_web_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_public_rtb_id --subnet-id $ohio_build_web_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

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
      ohio_build_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                     --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Build-NAT-EIPA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                     --query 'AllocationId' \
                                                     --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_build_ngw_eipa

      ohio_build_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_build_ngw_eipa \
                                                      --subnet-id $ohio_build_public_subneta_id \
                                                      --client-token $(date +%s) \
                                                      --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Build-NAT-GatewayA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                      --query 'NatGateway.NatGatewayId' \
                                                      --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_build_ngwa_id

      if [ $ha_ngw = 1 ]; then
        ohio_build_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                       --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Build-NAT-EIPB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                       --query 'AllocationId' \
                                                       --profile $profile --region us-east-2 --output text)
        camelz-variable ohio_build_ngw_eipb

        ohio_build_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_build_ngw_eipb \
                                                        --subnet-id $ohio_build_public_subnetb_id \
                                                        --client-token $(date +%s) \
                                                        --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Build-NAT-GatewayB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'NatGateway.NatGatewayId' \
                                                        --profile $profile --region us-east-2 --output text)
        camelz-variable ohio_build_ngwb_id

        ohio_build_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                       --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Build-NAT-EIPC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                       --query 'AllocationId' \
                                                       --profile $profile --region us-east-2 --output text)
        camelz-variable ohio_build_ngw_eipc

        ohio_build_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_build_ngw_eipc \
                                                        --subnet-id $ohio_build_public_subnetc_id \
                                                        --client-token $(date +%s) \
                                                        --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Build-NAT-GatewayC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                        --query 'NatGateway.NatGatewayId' \
                                                        --profile $profile --region us-east-2 --output text)
        camelz-variable ohio_build_ngwc_id
      fi
    else
      # Create NAT Security Group
      ohio_build_nat_sg_id=$(aws ec2 create-security-group --group-name Build-NAT-InstanceSecurityGroup \
                                                           --description Build-NAT-InstanceSecurityGroup \
                                                           --vpc-id $ohio_build_vpc_id \
                                                           --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Build-NAT-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'GroupId' \
                                                           --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_build_nat_sg_id

      aws ec2 authorize-security-group-ingress --group-id $ohio_build_nat_sg_id \
                                               --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$ohio_build_vpc_cidr,Description=\"VPC (All)\"}]" \
                                               --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All)\"}]" \
                                               --profile $profile --region us-east-2 --output text

      # Create NAT Instance
      ohio_build_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                         --instance-type t3a.nano \
                                                         --iam-instance-profile Name=ManagedInstance \
                                                         --key-name administrator \
                                                         --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Build-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_build_nat_sg_id],SubnetId=$ohio_build_public_subneta_id" \
                                                         --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Build-NAT-Instance},{Key=Hostname,Value=cmlue2bnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'Instances[0].InstanceId' \
                                                         --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_build_nat_instance_id

      aws ec2 modify-instance-attribute --instance-id $ohio_build_nat_instance_id \
                                        --no-source-dest-check \
                                        --profile $profile --region us-east-2 --output text

      ohio_build_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $ohio_build_nat_instance_id \
                                                                  --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                  --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_build_nat_instance_eni_id

      ohio_build_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_build_nat_instance_id \
                                                                      --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                      --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_build_nat_instance_private_ip
    fi
    ```

1.  **Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets**

    ```bash
    ohio_build_private_rtba_id=$(aws ec2 create-route-table --vpc-id $ohio_build_vpc_id \
                                                            --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Build-PrivateRouteTableA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'RouteTable.RouteTableId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_private_rtba_id

    if [ $use_ngw = 1 ]; then
      aws ec2 create-route --route-table-id $ohio_build_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $ohio_build_ngwa_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $ohio_build_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $ohio_build_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtba_id --subnet-id $ohio_build_application_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtba_id --subnet-id $ohio_build_database_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtba_id --subnet-id $ohio_build_directory_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtba_id --subnet-id $ohio_build_build_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtba_id --subnet-id $ohio_build_gateway_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtba_id --subnet-id $ohio_build_endpoint_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1.  **Create Private Route Table for Availability Zone B, Default Route and Associate with Private Subnets**

    ```bash
    ohio_build_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $ohio_build_vpc_id \
                                                            --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Build-PrivateRouteTableB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'RouteTable.RouteTableId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_private_rtbb_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then ohio_build_ngw_id=$ohio_build_ngwb_id; else ohio_build_ngw_id=$ohio_build_ngwa_id; fi
      aws ec2 create-route --route-table-id $ohio_build_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $ohio_build_ngw_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $ohio_build_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $ohio_build_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtbb_id --subnet-id $ohio_build_application_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtbb_id --subnet-id $ohio_build_database_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtbb_id --subnet-id $ohio_build_directory_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtbb_id --subnet-id $ohio_build_build_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtbb_id --subnet-id $ohio_build_gateway_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtbb_id --subnet-id $ohio_build_endpoint_subnetb_id \
                                  --profile $profile --region us-east-2 --output text

1.  **Create Private Route Table for Availability Zone C, Default Route and Associate with Private Subnets**

    ```bash
    ohio_build_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $ohio_build_vpc_id \
                                                            --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Build-PrivateRouteTableC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'RouteTable.RouteTableId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_private_rtbc_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then ohio_build_ngw_id=$ohio_build_ngwc_id; else ohio_build_ngw_id=$ohio_build_ngwa_id; fi
      aws ec2 create-route --route-table-id $ohio_build_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $ohio_build_ngw_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $ohio_build_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $ohio_build_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtbc_id --subnet-id $ohio_build_application_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtbc_id --subnet-id $ohio_build_database_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtbc_id --subnet-id $ohio_build_directory_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtbc_id --subnet-id $ohio_build_build_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtbc_id --subnet-id $ohio_build_gateway_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_build_private_rtbc_id --subnet-id $ohio_build_endpoint_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1.  **Create VPC Endpoint Security Group**

    ```bash
    ohio_build_vpce_sg_id=$(aws ec2 create-security-group --group-name Build-VPCEndpointSecurityGroup \
                                                          --description Build-VPCEndpointSecurityGroup \
                                                          --vpc-id $ohio_build_vpc_id \
                                                          --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Build-VPCEndpointSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'GroupId' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_vpce_sg_id

    aws ec2 authorize-security-group-ingress --group-id $ohio_build_vpce_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ohio_build_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All TCP)\"}]" \
                                             --profile $profile --region us-east-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $ohio_build_vpce_sg_id \
                                             --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ohio_build_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All UDP)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    ```

1.  **Create VPC Endpoints for SSM and SSMMessages**

    ```bash
    ohio_build_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ohio_build_vpc_id \
                                                         --vpc-endpoint-type Interface \
                                                         --service-name com.amazonaws.us-east-2.ssm \
                                                         --private-dns-enabled \
                                                         --security-group-ids $ohio_build_vpce_sg_id \
                                                         --subnet-ids $ohio_build_endpoint_subneta_id $ohio_build_endpoint_subnetb_id $ohio_build_endpoint_subnetc_id \
                                                         --client-token $(date +%s) \
                                                         --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Build-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                         --query 'VpcEndpoint.VpcEndpointId' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_ssm_vpce_id

    ohio_build_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ohio_build_vpc_id \
                                                          --vpc-endpoint-type Interface \
                                                          --service-name com.amazonaws.us-east-2.ssmmessages \
                                                          --private-dns-enabled \
                                                          --security-group-ids $ohio_build_vpce_sg_id \
                                                          --subnet-ids $ohio_build_endpoint_subneta_id $ohio_build_endpoint_subnetb_id $ohio_build_endpoint_subnetc_id \
                                                          --client-token $(date +%s) \
                                                          --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Build-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'VpcEndpoint.VpcEndpointId' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_build_ssmm_vpce_id
    ```
