# Modules:VPCs:Zulu Production Account:Ohio:Zulu Production VPC

This module builds the Zulu-Production VPC in the AWS Ohio (us-east-2) Region within the CaMeLz-Zulu-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Zulu-Production VPC

1. **Set Profile for Zulu-Production Account**

    ```bash
    profile=$zulu_production_profile
    ```

1. **Create VPC**

    ```bash
    zulu_ohio_production_vpc_id=$(aws ec2 create-vpc --cidr-block $zulu_ohio_production_vpc_cidr \
                                                     --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=Zulu-Production-VPC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                     --query 'Vpc.VpcId' \
                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_vpc_id


    aws ec2 modify-vpc-attribute --vpc-id $zulu_ohio_production_vpc_id \
                                 --enable-dns-support \
                                 --profile $profile --region us-east-2 --output text

    aws ec2 modify-vpc-attribute --vpc-id $zulu_ohio_production_vpc_id \
                                 --enable-dns-hostnames \
                                 --profile $profile --region us-east-2 --output text
    ```

1. **Tag Attached Default Resources Created With VPC**

    Creating a VPC also creates a set of attached default resources which do not have the same tags propagated.
    We will also tag these associated resources to insure consistency in the list displays.

    ```bash
    # Tag Zulu-Production-MainRouteTable
    main_rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$zulu_ohio_production_vpc_id \
                                                          Name=association.main,Values=true \
                                                --query 'RouteTables[0].RouteTableId' \
                                                --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $main_rtb_id \
                        --tags Key=Name,Value=Zulu-Production-MainRouteTable \
                               Key=Company,Value=Zulu \
                               Key=Environment,Value=Production \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

    # Tag Zulu-Production-DefaultNetworkAcl
    default_nacl_id=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$zulu_ohio_production_vpc_id \
                                                              Name=default,Values=true \
                                                    --query 'NetworkAcls[0].NetworkAclId' \
                                                    --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $default_nacl_id \
                        --tags Key=Name,Value=Zulu-Production-DefaultNetworkAcl \
                               Key=Company,Value=Zulu \
                               Key=Environment,Value=Production \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

    # Tag Zulu-Production-DefaultSecurityGroup
    default_sg_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$zulu_ohio_production_vpc_id \
                                                               Name=group-name,Values=default \
                                                     --query 'SecurityGroups[0].GroupId' \
                                                     --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $default_sg_id \
                        --tags Key=Name,Value=Zulu-Production-DefaultSecurityGroup \
                               Key=Company,Value=Zulu \
                               Key=Environment,Value=Production \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Flow Log**

    ```bash
    aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Zulu-Production/Ohio" \
                              --profile $profile --region us-east-2 --output text

    aws ec2 create-flow-logs --resource-type VPC --resource-ids $zulu_ohio_production_vpc_id \
                             --traffic-type ALL \
                             --log-destination-type cloud-watch-logs \
                             --log-destination "arn:aws:logs:us-east-2:${zulu_production_account_id}:log-group:/${company_name_lc}/${system_name_lc}/FlowLog/Zulu-Production/Ohio" \
                             --deliver-logs-permission-arn "arn:aws:iam::${zulu_production_account_id}:role/FlowLog" \
                             --profile $profile --region us-east-2 --output text
    ```

1. **Create Internet Gateway**

    ```bash
    zulu_ohio_production_igw_id=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Zulu-Production-InternetGateway},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'InternetGateway.InternetGatewayId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_igw_id

    aws ec2 attach-internet-gateway --vpc-id $zulu_ohio_production_vpc_id \
                                    --internet-gateway-id $zulu_ohio_production_igw_id \
                                    --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Hosted Zone**

    ```bash
    zulu_ohio_production_private_hostedzone_id=$(aws route53 create-hosted-zone --name $zulu_ohio_production_private_domain \
                                                                                --vpc VPCRegion=us-east-2,VPCId=$zulu_ohio_production_vpc_id \
                                                                                --hosted-zone-config Comment="Private Zone for $zulu_ohio_production_private_domain",PrivateZone=true \
                                                                                --caller-reference $(date +%s) \
                                                                                --query 'HostedZone.Id' \
                                                                                --profile $profile --region us-east-2 --output text | cut -f3 -d /)
    camelz-variable zulu_ohio_production_private_hostedzone_id
    ```

1. **Create DHCP Options Set**

    ```bash
    zulu_ohio_production_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$zulu_ohio_production_private_domain]" \
                                                                                     "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                               --tag-specifications "ResourceType=dhcp-options,Tags=[{Key=Name,Value=Zulu-Production-DHCPOptions},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'DhcpOptions.DhcpOptionsId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_dopt_id

    aws ec2 associate-dhcp-options --vpc-id $zulu_ohio_production_vpc_id \
                                   --dhcp-options-id $zulu_ohio_production_dopt_id \
                                   --profile $profile --region us-east-2 --output text
    ```

1. **Create Public Subnet A**

    ```bash
    zulu_ohio_production_public_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                   --cidr-block $zulu_ohio_production_public_subneta_cidr \
                                                                   --availability-zone us-east-2a \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-PublicSubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_public_subneta_id
    ```

1. **Create Public Subnet B**

    ```bash
    zulu_ohio_production_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                   --cidr-block $zulu_ohio_production_public_subnetb_cidr \
                                                                   --availability-zone us-east-2b \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-PublicSubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_public_subnetb_id
    ```

1. **Create Public Subnet C**

    ```bash
    zulu_ohio_production_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                   --cidr-block $zulu_ohio_production_public_subnetc_cidr \
                                                                   --availability-zone us-east-2c \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-PublicSubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_public_subnetc_id
    ```

1. **Create Public1 Subnet A**

    ```bash
    zulu_ohio_production_public1_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --cidr-block $zulu_ohio_production_public1_subneta_cidr \
                                                                    --availability-zone us-east-2a \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Public1SubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_public1_subneta_id
    ```

1. **Create Public1 Subnet B**

    ```bash
    zulu_ohio_production_public1_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --cidr-block $zulu_ohio_production_public1_subnetb_cidr \
                                                                    --availability-zone us-east-2b \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Public1SubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_public1_subnetb_id
    ```

1. **Create Public1 Subnet C**

    ```bash
    zulu_ohio_production_public1_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --cidr-block $zulu_ohio_production_public1_subnetc_cidr \
                                                                    --availability-zone us-east-2c \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Public1SubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_public1_subnetc_id
    ```

1. **Create Public7 Subnet A**

    ```bash
    zulu_ohio_production_public7_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --cidr-block $zulu_ohio_production_public7_subneta_cidr \
                                                                    --availability-zone us-east-2a \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Public7SubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_public7_subneta_id
    ```

1. **Create Public7 Subnet B**

    ```bash
    zulu_ohio_production_public7_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --cidr-block $zulu_ohio_production_public7_subnetb_cidr \
                                                                    --availability-zone us-east-2b \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Public7SubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_public7_subnetb_id
    ```

1. **Create Public7 Subnet C**

    ```bash
    zulu_ohio_production_public7_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --cidr-block $zulu_ohio_production_public7_subnetc_cidr \
                                                                    --availability-zone us-east-2c \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Public7SubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_public7_subnetc_id
    ```

1. **Create Web Subnet A**

    ```bash
    zulu_ohio_production_web_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                --cidr-block $zulu_ohio_production_web_subneta_cidr \
                                                                --availability-zone us-east-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-WebSubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_web_subneta_id
    ```

1. **Create Web Subnet B**

    ```bash
    zulu_ohio_production_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                --cidr-block $zulu_ohio_production_web_subnetb_cidr \
                                                                --availability-zone us-east-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-WebSubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_web_subnetb_id
    ```

1. **Create Web Subnet C**

    ```bash
    zulu_ohio_production_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                --cidr-block $zulu_ohio_production_web_subnetc_cidr \
                                                                --availability-zone us-east-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-WebSubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_web_subnetc_id
    ```

1. **Create Web1 Subnet A**

    ```bash
    zulu_ohio_production_web1_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                 --cidr-block $zulu_ohio_production_web1_subneta_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Web1SubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_web1_subneta_id
    ```

1. **Create Web1 Subnet B**

    ```bash
    zulu_ohio_production_web1_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                 --cidr-block $zulu_ohio_production_web1_subnetb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Web1SubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_web1_subnetb_id
    ```

1. **Create Web1 Subnet C**

    ```bash
    zulu_ohio_production_web1_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                 --cidr-block $zulu_ohio_production_web1_subnetc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Web1SubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_web1_subnetc_id
    ```

1. **Create Web7 Subnet A**

    ```bash
    zulu_ohio_production_web7_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                 --cidr-block $zulu_ohio_production_web7_subneta_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Web7SubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_web7_subneta_id
    ```

1. **Create Web7 Subnet B**

    ```bash
    zulu_ohio_production_web7_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                 --cidr-block $zulu_ohio_production_web7_subnetb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Web7SubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_web7_subnetb_id
    ```

1. **Create Web7 Subnet C**

    ```bash
    zulu_ohio_production_web7_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                 --cidr-block $zulu_ohio_production_web7_subnetc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Web7SubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_web7_subnetc_id
    ```

1. **Create Application Subnet A**

    ```bash
    zulu_ohio_production_application_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                        --cidr-block $zulu_ohio_production_application_subneta_cidr \
                                                                        --availability-zone us-east-2a \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-ApplicationSubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_application_subneta_id
    ```

1. **Create Application Subnet B**

    ```bash
    zulu_ohio_production_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                        --cidr-block $zulu_ohio_production_application_subnetb_cidr \
                                                                        --availability-zone us-east-2b \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-ApplicationSubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_application_subnetb_id
    ```

1. **Create Application Subnet C**

    ```bash
    zulu_ohio_production_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                        --cidr-block $zulu_ohio_production_application_subnetc_cidr \
                                                                        --availability-zone us-east-2c \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-ApplicationSubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_application_subnetc_id
    ```

1. **Create Application1 Subnet A**

    ```bash
    zulu_ohio_production_application1_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                         --cidr-block $zulu_ohio_production_application1_subneta_cidr \
                                                                         --availability-zone us-east-2a \
                                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Application1SubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                         --query 'Subnet.SubnetId' \
                                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_application1_subneta_id
    ```

1. **Create Application1 Subnet B**

    ```bash
    zulu_ohio_production_application1_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                         --cidr-block $zulu_ohio_production_application1_subnetb_cidr \
                                                                         --availability-zone us-east-2b \
                                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Application1SubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                         --query 'Subnet.SubnetId' \
                                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_application1_subnetb_id
    ```

1. **Create Application1 Subnet C**

    ```bash
    zulu_ohio_production_application1_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                         --cidr-block $zulu_ohio_production_application1_subnetc_cidr \
                                                                         --availability-zone us-east-2c \
                                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Application1SubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                         --query 'Subnet.SubnetId' \
                                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_application1_subnetc_id
    ```

1. **Create Application2 Subnet A**

    ```bash
    zulu_ohio_production_application2_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                         --cidr-block $zulu_ohio_production_application2_subneta_cidr \
                                                                         --availability-zone us-east-2a \
                                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Application2SubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                         --query 'Subnet.SubnetId' \
                                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_application2_subneta_id
    ```

1. **Create Application2 Subnet B**

    ```bash
    zulu_ohio_production_application2_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                         --cidr-block $zulu_ohio_production_application2_subnetb_cidr \
                                                                         --availability-zone us-east-2b \
                                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Application2SubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                         --query 'Subnet.SubnetId' \
                                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_application2_subnetb_id
    ```

1. **Create Application2 Subnet C**

    ```bash
    zulu_ohio_production_application2_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                         --cidr-block $zulu_ohio_production_application2_subnetc_cidr \
                                                                         --availability-zone us-east-2c \
                                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Application2SubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                         --query 'Subnet.SubnetId' \
                                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_application2_subnetc_id
    ```

1. **Create Application3 Subnet A**

    ```bash
    zulu_ohio_production_application3_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                         --cidr-block $zulu_ohio_production_application3_subneta_cidr \
                                                                         --availability-zone us-east-2a \
                                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Application3SubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                         --query 'Subnet.SubnetId' \
                                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_application3_subneta_id
    ```

1. **Create Application3 Subnet B**

    ```bash
    zulu_ohio_production_application3_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                         --cidr-block $zulu_ohio_production_application3_subnetb_cidr \
                                                                         --availability-zone us-east-2b \
                                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Application3SubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                         --query 'Subnet.SubnetId' \
                                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_application3_subnetb_id
    ```

1. **Create Application3 Subnet C**

    ```bash
    zulu_ohio_production_application3_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                         --cidr-block $zulu_ohio_production_application3_subnetc_cidr \
                                                                         --availability-zone us-east-2c \
                                                                         --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Application3SubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                         --query 'Subnet.SubnetId' \
                                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_application3_subnetc_id
    ```

1. **Create Cache Subnet A**

    ```bash
    zulu_ohio_production_cache_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                  --cidr-block $zulu_ohio_production_cache_subneta_cidr \
                                                                  --availability-zone us-east-2a \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-CacheSubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_cache_subneta_id
    ```

1. **Create Cache Subnet B**

    ```bash
    zulu_ohio_production_cache_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                  --cidr-block $zulu_ohio_production_cache_subnetb_cidr \
                                                                  --availability-zone us-east-2b \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-CacheSubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_cache_subnetb_id
    ```

1. **Create Cache Subnet C**

    ```bash
    zulu_ohio_production_cache_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                  --cidr-block $zulu_ohio_production_cache_subnetc_cidr \
                                                                  --availability-zone us-east-2c \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-CacheSubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_cache_subnetc_id
    ```

1. **Create Cache1 Subnet A**

    ```bash
    zulu_ohio_production_cache1_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                   --cidr-block $zulu_ohio_production_cache1_subneta_cidr \
                                                                   --availability-zone us-east-2a \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Cache1SubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_cache1_subneta_id
    ```

1. **Create Cache1 Subnet B**

    ```bash
    zulu_ohio_production_cache1_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                   --cidr-block $zulu_ohio_production_cache1_subnetb_cidr \
                                                                   --availability-zone us-east-2b \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Cache1SubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_cache1_subnetb_id
    ```

1. **Create Cache1 Subnet C**

    ```bash
    zulu_ohio_production_cache1_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                   --cidr-block $zulu_ohio_production_cache1_subnetc_cidr \
                                                                   --availability-zone us-east-2c \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Cache1SubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_cache1_subnetc_id
    ```

1. **Create Database Subnet A**

    ```bash
    zulu_ohio_production_database_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                     --cidr-block $zulu_ohio_production_database_subneta_cidr \
                                                                     --availability-zone us-east-2a \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-DatabaseSubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_database_subneta_id
    ```

1. **Create Database Subnet B**

    ```bash
    zulu_ohio_production_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                     --cidr-block $zulu_ohio_production_database_subnetb_cidr \
                                                                     --availability-zone us-east-2b \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-DatabaseSubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_database_subnetb_id
    ```

1. **Create Database Subnet C**

    ```bash
    zulu_ohio_production_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                     --cidr-block $zulu_ohio_production_database_subnetc_cidr \
                                                                     --availability-zone us-east-2c \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-DatabaseSubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_database_subnetc_id
    ```

1. **Create Database1 Subnet A**

    ```bash
    zulu_ohio_production_database1_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                      --cidr-block $zulu_ohio_production_database1_subneta_cidr \
                                                                      --availability-zone us-east-2a \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Database1SubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_database1_subneta_id
    ```

1. **Create Database1 Subnet B**

    ```bash
    zulu_ohio_production_database1_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                      --cidr-block $zulu_ohio_production_database1_subnetb_cidr \
                                                                      --availability-zone us-east-2b \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Database1SubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_database1_subnetb_id
    ```

1. **Create Database1 Subnet C**

    ```bash
    zulu_ohio_production_database1_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                      --cidr-block $zulu_ohio_production_database1_subnetc_cidr \
                                                                      --availability-zone us-east-2c \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Database1SubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_database1_subnetc_id
    ```

1. **Create Optional Subnet A**

    ```bash
    zulu_ohio_production_optional_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                     --cidr-block $zulu_ohio_production_optional_subneta_cidr \
                                                                     --availability-zone us-east-2a \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-OptionalSubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_optional_subneta_id
    ```

1. **Create Optional Subnet B**

    ```bash
    zulu_ohio_production_optional_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                     --cidr-block $zulu_ohio_production_optional_subnetb_cidr \
                                                                     --availability-zone us-east-2b \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-OptionalSubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_optional_subnetb_id
    ```

1. **Create Optional Subnet C**

    ```bash
    zulu_ohio_production_optional_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                     --cidr-block $zulu_ohio_production_optional_subnetc_cidr \
                                                                     --availability-zone us-east-2c \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-OptionalSubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_optional_subnetc_id
    ```

1. **Create Optional1 Subnet A**

    ```bash
    zulu_ohio_production_optional1_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                      --cidr-block $zulu_ohio_production_optional1_subneta_cidr \
                                                                      --availability-zone us-east-2a \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Optional1SubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_optional1_subneta_id
    ```

1. **Create Optional1 Subnet B**

    ```bash
    zulu_ohio_production_optional1_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                      --cidr-block $zulu_ohio_production_optional1_subnetb_cidr \
                                                                      --availability-zone us-east-2b \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Optional1SubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_optional1_subnetb_id
    ```

1. **Create Optional1 Subnet C**

    ```bash
    zulu_ohio_production_optional1_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                      --cidr-block $zulu_ohio_production_optional1_subnetc_cidr \
                                                                      --availability-zone us-east-2c \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-Optional1SubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_optional1_subnetc_id
    ```

1. **Create Directory Subnet A**

    ```bash
    zulu_ohio_production_directory_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                      --cidr-block $zulu_ohio_production_subnet_directorya_cidr \
                                                                      --availability-zone us-east-2a \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-DirectorySubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_directory_subneta_id
    ```

1. **Create Directory Subnet B**

    ```bash
    zulu_ohio_production_directory_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                      --cidr-block $zulu_ohio_production_subnet_directoryb_cidr \
                                                                      --availability-zone us-east-2b \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-DirectorySubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_directory_subnetb_id
    ```

1. **Create Directory Subnet C**

    ```bash
    zulu_ohio_production_directory_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                      --cidr-block $zulu_ohio_production_subnet_directoryc_cidr \
                                                                      --availability-zone us-east-2c \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-DirectorySubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_directory_subnetc_id
    ```

1. **Create Endpoint Subnet A**

    ```bash
    zulu_ohio_production_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                     --cidr-block $zulu_ohio_production_endpoint_subneta_cidr \
                                                                     --availability-zone us-east-2a \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-EndpointSubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_endpoint_subneta_id
    ```

1. **Create Endpoint Subnet B**

    ```bash
    zulu_ohio_production_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                     --cidr-block $zulu_ohio_production_endpoint_subnetb_cidr \
                                                                     --availability-zone us-east-2b \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-EndpointSubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_endpoint_subnetb_id
    ```

1. **Create Endpoint Subnet C**

    ```bash
    zulu_ohio_production_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                     --cidr-block $zulu_ohio_production_endpoint_subnetc_cidr \
                                                                     --availability-zone us-east-2c \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-EndpointSubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_endpoint_subnetc_id
    ```

1. **Create Firewall Subnet A**

    ```bash
    zulu_ohio_production_firewall_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                     --cidr-block $zulu_ohio_production_firewall_subneta_cidr \
                                                                     --availability-zone us-east-2a \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-FirewallSubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_firewall_subneta_id
    ```

1. **Create Firewall Subnet B**

    ```bash
    zulu_ohio_production_firewall_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                     --cidr-block $zulu_ohio_production_firewall_subnetb_cidr \
                                                                     --availability-zone us-east-2b \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-FirewallSubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_firewall_subnetb_id
    ```

1. **Create Firewall Subnet C**

    ```bash
    zulu_ohio_production_firewall_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                     --cidr-block $zulu_ohio_production_firewall_subnetc_cidr \
                                                                     --availability-zone us-east-2c \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-FirewallSubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_firewall_subnetc_id
    ```

1. **Create Gateway Subnet A**

    ```bash
    zulu_ohio_production_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --cidr-block $zulu_ohio_production_gateway_subneta_cidr \
                                                                    --availability-zone us-east-2a \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-GatewaySubnetA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_gateway_subneta_id
    ```

1. **Create Gateway Subnet B**

    ```bash
    zulu_ohio_production_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --cidr-block $zulu_ohio_production_gateway_subnetb_cidr \
                                                                    --availability-zone us-east-2b \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-GatewaySubnetB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_gateway_subnetb_id
    ```

1. **Create Gateway Subnet C**

    ```bash
    zulu_ohio_production_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --cidr-block $zulu_ohio_production_gateway_subnetc_cidr \
                                                                    --availability-zone us-east-2c \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Zulu-Production-GatewaySubnetC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_gateway_subnetc_id
    ```

1. **Create Public Route Table, Default Route and Associate with Public Subnets**

    ```bash
    zulu_ohio_production_public_rtb_id=$(aws ec2 create-route-table --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Zulu-Production-PublicRouteTable},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'RouteTable.RouteTableId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_public_rtb_id

    aws ec2 create-route --route-table-id $zulu_ohio_production_public_rtb_id \
                         --destination-cidr-block '0.0.0.0/0' \
                         --gateway-id $zulu_ohio_production_igw_id \
                         --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_public_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_public_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_public_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_public1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_public1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_public1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_public7_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_public7_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_public7_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_web_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_web_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_web_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_web1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_web1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_web1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_web7_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_web7_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_web7_subnetc_id \
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
      zulu_ohio_production_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                               --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Zulu-Production-NAT-EIPA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'AllocationId' \
                                                               --profile $profile --region us-east-2 --output text)
      camelz-variable zulu_ohio_production_ngw_eipa

      zulu_ohio_production_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $zulu_ohio_production_ngw_eipa \
                                                                --subnet-id $zulu_ohio_production_public_subneta_id \
                                                                --client-token $(date +%s) \
                                                                --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Zulu-Production-NAT-GatewayA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'NatGateway.NatGatewayId' \
                                                                --profile $profile --region us-east-2 --output text)
      camelz-variable zulu_ohio_production_ngwa_id

      if [ $ha_ngw = 1 ]; then
        zulu_ohio_production_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                                 --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Zulu-Production-NAT-EIPB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'AllocationId' \
                                                                 --profile $profile --region us-east-2 --output text)
        camelz-variable zulu_ohio_production_ngw_eipb

        zulu_ohio_production_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $zulu_ohio_production_ngw_eipb \
                                                                  --subnet-id $zulu_ohio_production_public_subnetb_id \
                                                                  --client-token $(date +%s) \
                                                                  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Zulu-Production-NAT-GatewayB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'NatGateway.NatGatewayId' \
                                                                  --profile $profile --region us-east-2 --output text)
        camelz-variable zulu_ohio_production_ngwb_id

        zulu_ohio_production_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                                 --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Zulu-Production-NAT-EIPC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'AllocationId' \
                                                                 --profile $profile --region us-east-2 --output text)
        camelz-variable zulu_ohio_production_ngw_eipc

        zulu_ohio_production_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $zulu_ohio_production_ngw_eipc \
                                                                  --subnet-id $zulu_ohio_production_public_subnetc_id \
                                                                  --client-token $(date +%s) \
                                                                  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Zulu-Production-NAT-GatewayC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'NatGateway.NatGatewayId' \
                                                                  --profile $profile --region us-east-2 --output text)
        camelz-variable zulu_ohio_production_ngwc_id
      fi
    else
      # Create NAT Security Group
      zulu_ohio_production_nat_sg_id=$(aws ec2 create-security-group --group-name Zulu-Production-NAT-InstanceSecurityGroup \
                                                                     --description Zulu-Production-NAT-InstanceSecurityGroup \
                                                                     --vpc-id $zulu_ohio_production_vpc_id \
                                                                     --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Production-NAT-InstanceSecurityGroup},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'GroupId' \
                                                                     --profile $profile --region us-east-2 --output text)
      camelz-variable zulu_ohio_production_nat_sg_id

      aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_nat_sg_id \
                                               --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$zulu_ohio_production_vpc_cidr,Description=\"VPC (All)\"}]" \
                                               --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All)\"}]" \
                                               --profile $profile --region us-east-2 --output text

      # Create NAT Instance
      zulu_ohio_production_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                                   --instance-type t3a.nano \
                                                                   --iam-instance-profile Name=ManagedInstance \
                                                                   --key-name administrator \
                                                                   --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Zulu-Production-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_ohio_production_nat_sg_id],SubnetId=$zulu_ohio_production_public_subneta_id" \
                                                                   --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Production-NAT-Instance},{Key=Hostname,Value=alfue2pnat01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Instances[0].InstanceId' \
                                                                   --profile $profile --region us-east-2 --output text)
      camelz-variable zulu_ohio_production_nat_instance_id

      aws ec2 modify-instance-attribute --instance-id $zulu_ohio_production_nat_instance_id \
                                        --no-source-dest-check \
                                        --profile $profile --region us-east-2 --output text

      zulu_ohio_production_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $zulu_ohio_production_nat_instance_id \
                                                                            --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                            --profile $profile --region us-east-2 --output text)
      camelz-variable zulu_ohio_production_nat_instance_eni_id

      zulu_ohio_production_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_ohio_production_nat_instance_id \
                                                                                --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                                --profile $profile --region us-east-2 --output text)
      camelz-variable zulu_ohio_production_nat_instance_private_ip
    fi
    ```

1. **Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets**

    ```bash
    zulu_ohio_production_private_rtba_id=$(aws ec2 create-route-table --vpc-id $zulu_ohio_production_vpc_id \
                                                                      --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Zulu-Production-PrivateRouteTableA},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'RouteTable.RouteTableId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_private_rtba_id

    if [ $use_ngw = 1 ]; then
      aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $zulu_ohio_production_ngwa_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $zulu_ohio_production_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_application_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_application1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_application2_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_application3_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_cache_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_cache1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_database_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_database1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_optional_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_optional1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_directory_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_endpoint_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_firewall_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_gateway_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Route Table for Availability Zone B, Default Route and Associate with Private Subnets**

    ```bash
    zulu_ohio_production_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $zulu_ohio_production_vpc_id \
                                                                      --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Zulu-Production-PrivateRouteTableB},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'RouteTable.RouteTableId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_private_rtbb_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then zulu_ohio_production_ngw_id=$zulu_ohio_production_ngwb_id; else zulu_ohio_production_ngw_id=$zulu_ohio_production_ngwa_id; fi
      aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $zulu_ohio_production_ngw_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $zulu_ohio_production_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_application_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_application1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_application2_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_application3_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_cache_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_cache1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_database_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_database1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_optional_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_optional1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_directory_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_endpoint_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_firewall_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_gateway_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Route Table for Availability Zone C, Default Route and Associate with Private Subnets**

    ```bash
    zulu_ohio_production_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $zulu_ohio_production_vpc_id \
                                                                      --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Zulu-Production-PrivateRouteTableC},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'RouteTable.RouteTableId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_private_rtbc_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then zulu_ohio_production_ngw_id=$zulu_ohio_production_ngwc_id; else zulu_ohio_production_ngw_id=$zulu_ohio_production_ngwa_id; fi
      aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $zulu_ohio_production_ngw_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $zulu_ohio_production_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_application_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_application1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_application2_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_application3_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_cache_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_cache1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_database_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_database1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_optional_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_optional1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_directory_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_endpoint_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_firewall_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_gateway_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Endpoint Security Group**

    ```bash
    zulu_ohio_production_vpce_sg_id=$(aws ec2 create-security-group --group-name Zulu-Production-VPCEndpointSecurityGroup \
                                                                    --description Zulu-Production-VPCEndpointSecurityGroup \
                                                                    --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Zulu-Production-VPCEndpointSecurityGroup},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'GroupId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_vpce_sg_id

    aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_vpce_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$zulu_ohio_production_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All TCP)\"}]" \
                                             --profile $profile --region us-east-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_vpce_sg_id \
                                             --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$zulu_ohio_production_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All UDP)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Endpoints for SSM and SSMMessages**

    ```bash
    zulu_ohio_production_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $zulu_ohio_production_vpc_id \
                                                                   --vpc-endpoint-type Interface \
                                                                   --service-name com.amazonaws.us-east-2.ssm \
                                                                   --private-dns-enabled \
                                                                   --security-group-ids $zulu_ohio_production_vpce_sg_id \
                                                                   --subnet-ids $zulu_ohio_production_endpoint_subneta_id $zulu_ohio_production_endpoint_subnetb_id $zulu_ohio_production_endpoint_subnetc_id \
                                                                   --client-token $(date +%s) \
                                                                   --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Zulu-Production-SSMVpcEndpoint},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'VpcEndpoint.VpcEndpointId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_ssm_vpce_id

    zulu_ohio_production_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --vpc-endpoint-type Interface \
                                                                    --service-name com.amazonaws.us-east-2.ssmmessages \
                                                                    --private-dns-enabled \
                                                                    --security-group-ids $zulu_ohio_production_vpce_sg_id \
                                                                    --subnet-ids $zulu_ohio_production_endpoint_subneta_id $zulu_ohio_production_endpoint_subnetb_id $zulu_ohio_production_endpoint_subnetc_id \
                                                                    --client-token $(date +%s) \
                                                                    --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Zulu-Production-SSMMessagesVpcEndpoint},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'VpcEndpoint.VpcEndpointId' \
                                                                    --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_ssmm_vpce_id
    ```
