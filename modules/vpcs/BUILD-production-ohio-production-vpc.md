# Modules:VPCs:Production Account:Ohio:Production VPC

This module builds the Production VPC in the AWS Ohio (us-east-2) Region within the CaMeLz-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Production VPC

1. **Set Profile for Production Account**

    ```bash
    profile=$production_profile
    ```

1. **Create VPC**

    ```bash
    ohio_production_vpc_id=$(aws ec2 create-vpc --cidr-block $ohio_production_vpc_cidr \
                                                --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=Production-VPC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                --query 'Vpc.VpcId' \
                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_vpc_id


    aws ec2 modify-vpc-attribute --vpc-id $ohio_production_vpc_id \
                                 --enable-dns-support \
                                 --profile $profile --region us-east-2 --output text

    aws ec2 modify-vpc-attribute --vpc-id $ohio_production_vpc_id \
                                 --enable-dns-hostnames \
                                 --profile $profile --region us-east-2 --output text
    ```

1. **Tag Attached Default Resources Created With VPC**

    Creating a VPC also creates a set of attached default resources which do not have the same tags propagated.
    We will also tag these associated resources to insure consistency in the list displays.

    ```bash
    # Tag Production-MainRouteTable
    main_rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$ohio_production_vpc_id \
                                                          Name=association.main,Values=true \
                                                --query 'RouteTables[0].RouteTableId' \
                                                --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $main_rtb_id \
                        --tags Key=Name,Value=Production-MainRouteTable \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Production \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

    # Tag Production-DefaultNetworkAcl
    default_nacl_id=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$ohio_production_vpc_id \
                                                              Name=default,Values=true \
                                                    --query 'NetworkAcls[0].NetworkAclId' \
                                                    --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $default_nacl_id \
                        --tags Key=Name,Value=Production-DefaultNetworkAcl \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Production \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

    # Tag Production-DefaultSecurityGroup
    default_sg_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$ohio_production_vpc_id \
                                                               Name=group-name,Values=default \
                                                     --query 'SecurityGroups[0].GroupId' \
                                                     --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $default_sg_id \
                        --tags Key=Name,Value=Production-DefaultSecurityGroup \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Production \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Flow Log**

    ```bash
    aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Production" \
                              --profile $profile --region us-east-2 --output text

    aws ec2 create-flow-logs --resource-type VPC --resource-ids $ohio_production_vpc_id \
                             --traffic-type ALL \
                             --log-destination-type cloud-watch-logs \
                             --log-destination "arn:aws:logs:us-east-2:${production_account_id}:log-group:/${company_name_lc}/${system_name_lc}/FlowLog/Production" \
                             --deliver-logs-permission-arn "arn:aws:iam::${production_account_id}:role/FlowLog" \
                             --tag-specifications "ResourceType=vpc-flow-log,Tags=[{Key=Name,Value=Production-FlowLog},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                             --profile $profile --region us-east-2 --output text
    ```

1. **Create Internet Gateway**

    ```bash
    ohio_production_igw_id=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Production-InternetGateway},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'InternetGateway.InternetGatewayId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_igw_id

    aws ec2 attach-internet-gateway --vpc-id $ohio_production_vpc_id \
                                    --internet-gateway-id $ohio_production_igw_id \
                                    --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Hosted Zone**

    ```bash
    ohio_production_private_hostedzone_id=$(aws route53 create-hosted-zone --name $ohio_production_private_domain \
                                                                           --vpc VPCRegion=us-east-2,VPCId=$ohio_production_vpc_id \
                                                                           --hosted-zone-config Comment="Private Zone for $ohio_production_private_domain",PrivateZone=true \
                                                                           --caller-reference $(date +%s) \
                                                                           --query 'HostedZone.Id' \
                                                                           --profile $profile --region us-east-2 --output text | cut -f3 -d /)
    camelz-variable ohio_production_private_hostedzone_id
    ```

1. **Create DHCP Options Set**

    ```bash
    ohio_production_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$ohio_production_private_domain]" \
                                                                                "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                          --tag-specifications "ResourceType=dhcp-options,Tags=[{Key=Name,Value=Production-DHCPOptions},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'DhcpOptions.DhcpOptionsId' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_dopt_id

    aws ec2 associate-dhcp-options --vpc-id $ohio_production_vpc_id \
                                   --dhcp-options-id $ohio_production_dopt_id \
                                   --profile $profile --region us-east-2 --output text
    ```

1. **Create Public Subnet A**

    ```bash
    ohio_production_public_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                              --cidr-block $ohio_production_public_subneta_cidr \
                                                              --availability-zone us-east-2a \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-PublicSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_public_subneta_id
    ```

1. **Create Public Subnet B**

    ```bash
    ohio_production_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                              --cidr-block $ohio_production_public_subnetb_cidr \
                                                              --availability-zone us-east-2b \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-PublicSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_public_subnetb_id
    ```

1. **Create Public Subnet C**

    ```bash
    ohio_production_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                              --cidr-block $ohio_production_public_subnetc_cidr \
                                                              --availability-zone us-east-2c \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-PublicSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_public_subnetc_id
    ```

1. **Create Public1 Subnet A**

    ```bash
    ohio_production_public1_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                               --cidr-block $ohio_production_public1_subneta_cidr \
                                                               --availability-zone us-east-2a \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Public1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_public1_subneta_id
    ```

1. **Create Public1 Subnet B**

    ```bash
    ohio_production_public1_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                               --cidr-block $ohio_production_public1_subnetb_cidr \
                                                               --availability-zone us-east-2b \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Public1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_public1_subnetb_id
    ```

1. **Create Public1 Subnet C**

    ```bash
    ohio_production_public1_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                               --cidr-block $ohio_production_public1_subnetc_cidr \
                                                               --availability-zone us-east-2c \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Public1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_public1_subnetc_id
    ```

1. **Create Public7 Subnet A**

    ```bash
    ohio_production_public7_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                               --cidr-block $ohio_production_public7_subneta_cidr \
                                                               --availability-zone us-east-2a \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Public7SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_public7_subneta_id
    ```

1. **Create Public7 Subnet B**

    ```bash
    ohio_production_public7_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                               --cidr-block $ohio_production_public7_subnetb_cidr \
                                                               --availability-zone us-east-2b \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Public7SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_public7_subnetb_id
    ```

1. **Create Public7 Subnet C**

    ```bash
    ohio_production_public7_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                               --cidr-block $ohio_production_public7_subnetc_cidr \
                                                               --availability-zone us-east-2c \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Public7SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_public7_subnetc_id
    ```

1. **Create Web Subnet A**

    ```bash
    ohio_production_web_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                           --cidr-block $ohio_production_web_subneta_cidr \
                                                           --availability-zone us-east-2a \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-WebSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_web_subneta_id
    ```

1. **Create Web Subnet B**

    ```bash
    ohio_production_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                           --cidr-block $ohio_production_web_subnetb_cidr \
                                                           --availability-zone us-east-2b \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-WebSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_web_subnetb_id
    ```

1. **Create Web Subnet C**

    ```bash
    ohio_production_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                           --cidr-block $ohio_production_web_subnetc_cidr \
                                                           --availability-zone us-east-2c \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-WebSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_web_subnetc_id
    ```

1. **Create Web1 Subnet A**

    ```bash
    ohio_production_web1_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                            --cidr-block $ohio_production_web1_subneta_cidr \
                                                            --availability-zone us-east-2a \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Web1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_web1_subneta_id
    ```

1. **Create Web1 Subnet B**

    ```bash
    ohio_production_web1_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                            --cidr-block $ohio_production_web1_subnetb_cidr \
                                                            --availability-zone us-east-2b \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Web1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_web1_subnetb_id
    ```

1. **Create Web1 Subnet C**

    ```bash
    ohio_production_web1_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                            --cidr-block $ohio_production_web1_subnetc_cidr \
                                                            --availability-zone us-east-2c \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Web1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_web1_subnetc_id
    ```

1. **Create Web7 Subnet A**

    ```bash
    ohio_production_web7_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                            --cidr-block $ohio_production_web7_subneta_cidr \
                                                            --availability-zone us-east-2a \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Web7SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_web7_subneta_id
    ```

1. **Create Web7 Subnet B**

    ```bash
    ohio_production_web7_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                            --cidr-block $ohio_production_web7_subnetb_cidr \
                                                            --availability-zone us-east-2b \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Web7SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_web7_subnetb_id
    ```

1. **Create Web7 Subnet C**

    ```bash
    ohio_production_web7_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                            --cidr-block $ohio_production_web7_subnetc_cidr \
                                                            --availability-zone us-east-2c \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Web7SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_web7_subnetc_id
    ```

1. **Create Application Subnet A**

    ```bash
    ohio_production_application_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                   --cidr-block $ohio_production_application_subneta_cidr \
                                                                   --availability-zone us-east-2a \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-ApplicationSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_application_subneta_id
    ```

1. **Create Application Subnet B**

    ```bash
    ohio_production_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                   --cidr-block $ohio_production_application_subnetb_cidr \
                                                                   --availability-zone us-east-2b \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-ApplicationSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_application_subnetb_id
    ```

1. **Create Application Subnet C**

    ```bash
    ohio_production_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                   --cidr-block $ohio_production_application_subnetc_cidr \
                                                                   --availability-zone us-east-2c \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-ApplicationSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_application_subnetc_id
    ```

1. **Create Application1 Subnet A**

    ```bash
    ohio_production_application1_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                    --cidr-block $ohio_production_application1_subneta_cidr \
                                                                    --availability-zone us-east-2a \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Application1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_application1_subneta_id
    ```

1. **Create Application1 Subnet B**

    ```bash
    ohio_production_application1_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                    --cidr-block $ohio_production_application1_subnetb_cidr \
                                                                    --availability-zone us-east-2b \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Application1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_application1_subnetb_id
    ```

1. **Create Application1 Subnet C**

    ```bash
    ohio_production_application1_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                    --cidr-block $ohio_production_application1_subnetc_cidr \
                                                                    --availability-zone us-east-2c \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Application1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_application1_subnetc_id
    ```

1. **Create Application2 Subnet A**

    ```bash
    ohio_production_application2_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                    --cidr-block $ohio_production_application2_subneta_cidr \
                                                                    --availability-zone us-east-2a \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Application2SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_application2_subneta_id
    ```

1. **Create Application2 Subnet B**

    ```bash
    ohio_production_application2_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                    --cidr-block $ohio_production_application2_subnetb_cidr \
                                                                    --availability-zone us-east-2b \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Application2SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_application2_subnetb_id
    ```

1. **Create Application2 Subnet C**

    ```bash
    ohio_production_application2_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                    --cidr-block $ohio_production_application2_subnetc_cidr \
                                                                    --availability-zone us-east-2c \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Application2SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_application2_subnetc_id
    ```

1. **Create Application3 Subnet A**

    ```bash
    ohio_production_application3_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                    --cidr-block $ohio_production_application3_subneta_cidr \
                                                                    --availability-zone us-east-2a \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Application3SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_application3_subneta_id
    ```

1. **Create Application3 Subnet B**

    ```bash
    ohio_production_application3_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                    --cidr-block $ohio_production_application3_subnetb_cidr \
                                                                    --availability-zone us-east-2b \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Application3SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_application3_subnetb_id
    ```

1. **Create Application3 Subnet C**

    ```bash
    ohio_production_application3_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                    --cidr-block $ohio_production_application3_subnetc_cidr \
                                                                    --availability-zone us-east-2c \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Application3SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_application3_subnetc_id
    ```

1. **Create Cache Subnet A**

    ```bash
    ohio_production_cache_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                             --cidr-block $ohio_production_cache_subneta_cidr \
                                                             --availability-zone us-east-2a \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-CacheSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_cache_subneta_id
    ```

1. **Create Cache Subnet B**

    ```bash
    ohio_production_cache_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                             --cidr-block $ohio_production_cache_subnetb_cidr \
                                                             --availability-zone us-east-2b \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-CacheSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_cache_subnetb_id
    ```

1. **Create Cache Subnet C**

    ```bash
    ohio_production_cache_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                             --cidr-block $ohio_production_cache_subnetc_cidr \
                                                             --availability-zone us-east-2c \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-CacheSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_cache_subnetc_id
    ```

1. **Create Cache1 Subnet A**

    ```bash
    ohio_production_cache1_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                              --cidr-block $ohio_production_cache1_subneta_cidr \
                                                              --availability-zone us-east-2a \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Cache1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_cache1_subneta_id
    ```

1. **Create Cache1 Subnet B**

    ```bash
    ohio_production_cache1_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                              --cidr-block $ohio_production_cache1_subnetb_cidr \
                                                              --availability-zone us-east-2b \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Cache1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_cache1_subnetb_id
    ```

1. **Create Cache1 Subnet C**

    ```bash
    ohio_production_cache1_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                              --cidr-block $ohio_production_cache1_subnetc_cidr \
                                                              --availability-zone us-east-2c \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Cache1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_cache1_subnetc_id
    ```

1. **Create Database Subnet A**

    ```bash
    ohio_production_database_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                --cidr-block $ohio_production_database_subneta_cidr \
                                                                --availability-zone us-east-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-DatabaseSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_database_subneta_id
    ```

1. **Create Database Subnet B**

    ```bash
    ohio_production_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                --cidr-block $ohio_production_database_subnetb_cidr \
                                                                --availability-zone us-east-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-DatabaseSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_database_subnetb_id
    ```

1. **Create Database Subnet C**

    ```bash
    ohio_production_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                --cidr-block $ohio_production_database_subnetc_cidr \
                                                                --availability-zone us-east-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-DatabaseSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_database_subnetc_id
    ```

1. **Create Database1 Subnet A**

    ```bash
    ohio_production_database1_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                 --cidr-block $ohio_production_database1_subneta_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Database1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_database1_subneta_id
    ```

1. **Create Database1 Subnet B**

    ```bash
    ohio_production_database1_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                 --cidr-block $ohio_production_database1_subnetb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Database1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_database1_subnetb_id
    ```

1. **Create Database1 Subnet C**

    ```bash
    ohio_production_database1_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                 --cidr-block $ohio_production_database1_subnetc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Database1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_database1_subnetc_id
    ```

1. **Create Optional Subnet A**

    ```bash
    ohio_production_optional_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                --cidr-block $ohio_production_optional_subneta_cidr \
                                                                --availability-zone us-east-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-OptionalSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_optional_subneta_id
    ```

1. **Create Optional Subnet B**

    ```bash
    ohio_production_optional_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                --cidr-block $ohio_production_optional_subnetb_cidr \
                                                                --availability-zone us-east-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-OptionalSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_optional_subnetb_id
    ```

1. **Create Optional Subnet C**

    ```bash
    ohio_production_optional_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                --cidr-block $ohio_production_optional_subnetc_cidr \
                                                                --availability-zone us-east-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-OptionalSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_optional_subnetc_id
    ```

1. **Create Optional1 Subnet A**

    ```bash
    ohio_production_optional1_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                 --cidr-block $ohio_production_optional1_subneta_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Optional1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_optional1_subneta_id
    ```

1. **Create Optional1 Subnet B**

    ```bash
    ohio_production_optional1_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                 --cidr-block $ohio_production_optional1_subnetb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Optional1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_optional1_subnetb_id
    ```

1. **Create Optional1 Subnet C**

    ```bash
    ohio_production_optional1_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                 --cidr-block $ohio_production_optional1_subnetc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-Optional1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_optional1_subnetc_id
    ```

1. **Create Directory Subnet A**

    ```bash
    ohio_production_directory_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                 --cidr-block $ohio_production_subnet_directorya_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-DirectorySubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_directory_subneta_id
    ```

1. **Create Directory Subnet B**

    ```bash
    ohio_production_directory_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                 --cidr-block $ohio_production_subnet_directoryb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-DirectorySubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_directory_subnetb_id
    ```

1. **Create Directory Subnet C**

    ```bash
    ohio_production_directory_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                 --cidr-block $ohio_production_subnet_directoryc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-DirectorySubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_directory_subnetc_id
    ```

1. **Create Endpoint Subnet A**

    ```bash
    ohio_production_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                --cidr-block $ohio_production_endpoint_subneta_cidr \
                                                                --availability-zone us-east-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-EndpointSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_endpoint_subneta_id
    ```

1. **Create Endpoint Subnet B**

    ```bash
    ohio_production_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                --cidr-block $ohio_production_endpoint_subnetb_cidr \
                                                                --availability-zone us-east-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-EndpointSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_endpoint_subnetb_id
    ```

1. **Create Endpoint Subnet C**

    ```bash
    ohio_production_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                --cidr-block $ohio_production_endpoint_subnetc_cidr \
                                                                --availability-zone us-east-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-EndpointSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_endpoint_subnetc_id
    ```

1. **Create Firewall Subnet A**

    ```bash
    ohio_production_firewall_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                --cidr-block $ohio_production_firewall_subneta_cidr \
                                                                --availability-zone us-east-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-FirewallSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_firewall_subneta_id
    ```

1. **Create Firewall Subnet B**

    ```bash
    ohio_production_firewall_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                --cidr-block $ohio_production_firewall_subnetb_cidr \
                                                                --availability-zone us-east-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-FirewallSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_firewall_subnetb_id
    ```

1. **Create Firewall Subnet C**

    ```bash
    ohio_production_firewall_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                                --cidr-block $ohio_production_firewall_subnetc_cidr \
                                                                --availability-zone us-east-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-FirewallSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_firewall_subnetc_id
    ```

1. **Create Gateway Subnet A**

    ```bash
    ohio_production_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                               --cidr-block $ohio_production_gateway_subneta_cidr \
                                                               --availability-zone us-east-2a \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-GatewaySubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_gateway_subneta_id
    ```

1. **Create Gateway Subnet B**

    ```bash
    ohio_production_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                               --cidr-block $ohio_production_gateway_subnetb_cidr \
                                                               --availability-zone us-east-2b \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-GatewaySubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_gateway_subnetb_id
    ```

1. **Create Gateway Subnet C**

    ```bash
    ohio_production_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_production_vpc_id \
                                                               --cidr-block $ohio_production_gateway_subnetc_cidr \
                                                               --availability-zone us-east-2c \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Production-GatewaySubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_gateway_subnetc_id
    ```

1. **Create Public Route Table, Default Route and Associate with Public Subnets**

    ```bash
    ohio_production_public_rtb_id=$(aws ec2 create-route-table --vpc-id $ohio_production_vpc_id \
                                                               --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Production-PublicRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'RouteTable.RouteTableId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_public_rtb_id

    aws ec2 create-route --route-table-id $ohio_production_public_rtb_id \
                         --destination-cidr-block '0.0.0.0/0' \
                         --gateway-id $ohio_production_igw_id \
                         --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_public_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_public_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_public_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_public1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_public1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_public1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_public7_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_public7_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_public7_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_web_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_web_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_web_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_web1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_web1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_web1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_web7_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_web7_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_public_rtb_id --subnet-id $ohio_production_web7_subnetc_id \
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
      ohio_production_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                          --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Production-NAT-EIPA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'AllocationId' \
                                                          --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_production_ngw_eipa

      ohio_production_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_production_ngw_eipa \
                                                           --subnet-id $ohio_production_public_subneta_id \
                                                           --client-token $(date +%s) \
                                                           --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Production-NAT-GatewayA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'NatGateway.NatGatewayId' \
                                                           --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_production_ngwa_id

      if [ $ha_ngw = 1 ]; then
        ohio_production_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                            --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Production-NAT-EIPB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'AllocationId' \
                                                            --profile $profile --region us-east-2 --output text)
        camelz-variable ohio_production_ngw_eipb

        ohio_production_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_production_ngw_eipb \
                                                             --subnet-id $ohio_production_public_subnetb_id \
                                                             --client-token $(date +%s) \
                                                             --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Production-NAT-GatewayB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'NatGateway.NatGatewayId' \
                                                             --profile $profile --region us-east-2 --output text)
        camelz-variable ohio_production_ngwb_id

        ohio_production_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                            --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Production-NAT-EIPC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'AllocationId' \
                                                            --profile $profile --region us-east-2 --output text)
        camelz-variable ohio_production_ngw_eipc

        ohio_production_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_production_ngw_eipc \
                                                             --subnet-id $ohio_production_public_subnetc_id \
                                                             --client-token $(date +%s) \
                                                             --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Production-NAT-GatewayC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'NatGateway.NatGatewayId' \
                                                             --profile $profile --region us-east-2 --output text)
        camelz-variable ohio_production_ngwc_id
      fi
    else
      # Create NAT Security Group
      ohio_production_nat_sg_id=$(aws ec2 create-security-group --group-name Production-NAT-InstanceSecurityGroup \
                                                                --description Production-NAT-InstanceSecurityGroup \
                                                                --vpc-id $ohio_production_vpc_id \
                                                                --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Production-NAT-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_production_nat_sg_id

      aws ec2 authorize-security-group-ingress --group-id $ohio_production_nat_sg_id \
                                               --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$ohio_production_vpc_cidr,Description=\"VPC (All)\"}]" \
                                               --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All)\"}]" \
                                               --profile $profile --region us-east-2 --output text

      # Create NAT Instance
      ohio_production_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                              --instance-type t3a.nano \
                                                              --iam-instance-profile Name=ManagedInstance \
                                                              --key-name administrator \
                                                              --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Production-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_production_nat_sg_id],SubnetId=$ohio_production_public_subneta_id" \
                                                              --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Production-NAT-Instance},{Key=Hostname,Value=alfue2pnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Instances[0].InstanceId' \
                                                              --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_production_nat_instance_id

      aws ec2 modify-instance-attribute --instance-id $ohio_production_nat_instance_id \
                                        --no-source-dest-check \
                                        --profile $profile --region us-east-2 --output text

      ohio_production_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $ohio_production_nat_instance_id \
                                                                       --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                       --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_production_nat_instance_eni_id

      ohio_production_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_production_nat_instance_id \
                                                                           --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                           --profile $profile --region us-east-2 --output text)
      camelz-variable ohio_production_nat_instance_private_ip
    fi
    ```

1. **Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets**

    ```bash
    ohio_production_private_rtba_id=$(aws ec2 create-route-table --vpc-id $ohio_production_vpc_id \
                                                                 --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Production-PrivateRouteTableA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'RouteTable.RouteTableId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_private_rtba_id

    if [ $use_ngw = 1 ]; then
      aws ec2 create-route --route-table-id $ohio_production_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $ohio_production_ngwa_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $ohio_production_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $ohio_production_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_application_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_application1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_application2_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_application3_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_cache_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_cache1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_database_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_database1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_optional_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_optional1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_directory_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_endpoint_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_firewall_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtba_id --subnet-id $ohio_production_gateway_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Route Table for Availability Zone B, Default Route and Associate with Private Subnets**

    ```bash
    ohio_production_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $ohio_production_vpc_id \
                                                                 --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Production-PrivateRouteTableB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'RouteTable.RouteTableId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_private_rtbb_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then ohio_production_ngw_id=$ohio_production_ngwb_id; else ohio_production_ngw_id=$ohio_production_ngwa_id; fi
      aws ec2 create-route --route-table-id $ohio_production_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $ohio_production_ngw_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $ohio_production_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $ohio_production_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_application_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_application1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_application2_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_application3_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_cache_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_cache1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_database_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_database1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_optional_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_optional1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_directory_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_endpoint_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_firewall_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbb_id --subnet-id $ohio_production_gateway_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Route Table for Availability Zone C, Default Route and Associate with Private Subnets**

    ```bash
    ohio_production_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $ohio_production_vpc_id \
                                                                 --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Production-PrivateRouteTableC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'RouteTable.RouteTableId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_private_rtbc_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then ohio_production_ngw_id=$ohio_production_ngwc_id; else ohio_production_ngw_id=$ohio_production_ngwa_id; fi
      aws ec2 create-route --route-table-id $ohio_production_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $ohio_production_ngw_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $ohio_production_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $ohio_production_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_application_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_application1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_application2_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_application3_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_cache_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_cache1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_database_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_database1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_optional_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_optional1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_directory_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_endpoint_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_firewall_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $ohio_production_private_rtbc_id --subnet-id $ohio_production_gateway_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Endpoint Security Group**

    ```bash
    ohio_production_vpce_sg_id=$(aws ec2 create-security-group --group-name Production-VPCEndpointSecurityGroup \
                                                               --description Production-VPCEndpointSecurityGroup \
                                                               --vpc-id $ohio_production_vpc_id \
                                                               --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Production-VPCEndpointSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'GroupId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_vpce_sg_id

    aws ec2 authorize-security-group-ingress --group-id $ohio_production_vpce_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ohio_production_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All TCP)\"}]" \
                                             --profile $profile --region us-east-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $ohio_production_vpce_sg_id \
                                             --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ohio_production_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All UDP)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Endpoints for SSM and SSMMessages**

    ```bash
    ohio_production_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ohio_production_vpc_id \
                                                              --vpc-endpoint-type Interface \
                                                              --service-name com.amazonaws.us-east-2.ssm \
                                                              --private-dns-enabled \
                                                              --security-group-ids $ohio_production_vpce_sg_id \
                                                              --subnet-ids $ohio_production_endpoint_subneta_id $ohio_production_endpoint_subnetb_id $ohio_production_endpoint_subnetc_id \
                                                              --client-token $(date +%s) \
                                                              --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Production-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'VpcEndpoint.VpcEndpointId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_ssm_vpce_id

    ohio_production_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ohio_production_vpc_id \
                                                               --vpc-endpoint-type Interface \
                                                               --service-name com.amazonaws.us-east-2.ssmmessages \
                                                               --private-dns-enabled \
                                                               --security-group-ids $ohio_production_vpce_sg_id \
                                                               --subnet-ids $ohio_production_endpoint_subneta_id $ohio_production_endpoint_subnetb_id $ohio_production_endpoint_subnetc_id \
                                                               --client-token $(date +%s) \
                                                               --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Production-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'VpcEndpoint.VpcEndpointId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_ssmm_vpce_id
    ```
