# Modules:VPCs:Alfa Production Account:Oregon:Alfa Production VPC

This module builds the Alfa-Production VPC in the AWS Oregon (us-west-2) Region within the CaMeLz-Alfa-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Alfa-Production VPC

1. **Set Profile for Alfa-Production Account**

    ```bash
    profile=$alfa_production_profile
    ```

1. **Create VPC**

    ```bash
    alfa_oregon_production_vpc_id=$(aws ec2 create-vpc --cidr-block $alfa_oregon_production_vpc_cidr \
                                                       --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=Alfa-Production-VPC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                       --query 'Vpc.VpcId' \
                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_vpc_id


    aws ec2 modify-vpc-attribute --vpc-id $alfa_oregon_production_vpc_id \
                                 --enable-dns-support \
                                 --profile $profile --region us-west-2 --output text

    aws ec2 modify-vpc-attribute --vpc-id $alfa_oregon_production_vpc_id \
                                 --enable-dns-hostnames \
                                 --profile $profile --region us-west-2 --output text
    ```

1. **Tag Attached Default Resources Created With VPC**

    Creating a VPC also creates a set of attached default resources which do not have the same tags propagated.
    We will also tag these associated resources to insure consistency in the list displays.

    ```bash
    # Tag Alfa-Production-MainRouteTable
    main_rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$alfa_oregon_production_vpc_id \
                                                          Name=association.main,Values=true \
                                                --query 'RouteTables[0].RouteTableId' \
                                                --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $main_rtb_id \
                        --tags Key=Name,Value=Alfa-Production-MainRouteTable \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Production \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text

    # Tag Alfa-Production-DefaultNetworkAcl
    default_nacl_id=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$alfa_oregon_production_vpc_id \
                                                              Name=default,Values=true \
                                                    --query 'NetworkAcls[0].NetworkAclId' \
                                                    --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $default_nacl_id \
                        --tags Key=Name,Value=Alfa-Production-DefaultNetworkAcl \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Production \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text

    # Tag Alfa-Production-DefaultSecurityGroup
    default_sg_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$alfa_oregon_production_vpc_id \
                                                               Name=group-name,Values=default \
                                                     --query 'SecurityGroups[0].GroupId' \
                                                     --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $default_sg_id \
                        --tags Key=Name,Value=Alfa-Production-DefaultSecurityGroup \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Production \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text
    ```

1. **Create VPC Flow Log**

    ```bash
    aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Alfa-Production" \
                              --profile $profile --region us-west-2 --output text

    aws ec2 create-flow-logs --resource-type VPC --resource-ids $alfa_oregon_production_vpc_id \
                             --traffic-type ALL \
                             --log-destination-type cloud-watch-logs \
                             --log-destination "arn:aws:logs:us-west-2:${alfa_production_account_id}:log-group:/${company_name_lc}/${system_name_lc}/FlowLog/Alfa-Production" \
                             --deliver-logs-permission-arn "arn:aws:iam::${alfa_production_account_id}:role/FlowLog" \
                             --tag-specifications "ResourceType=vpc-flow-log,Tags=[{Key=Name,Value=Alfa-Production-FlowLog},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                             --profile $profile --region us-west-2 --output text
    ```

1. **Create Internet Gateway**

    ```bash
    alfa_oregon_production_igw_id=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Alfa-Production-InternetGateway},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'InternetGateway.InternetGatewayId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_igw_id

    aws ec2 attach-internet-gateway --vpc-id $alfa_oregon_production_vpc_id \
                                    --internet-gateway-id $alfa_oregon_production_igw_id \
                                    --profile $profile --region us-west-2 --output text
    ```

1. **Create Private Hosted Zone**

    ```bash
    alfa_oregon_production_private_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_oregon_production_private_domain \
                                                                                  --vpc VPCRegion=us-west-2,VPCId=$alfa_oregon_production_vpc_id \
                                                                                  --hosted-zone-config Comment="Private Zone for $alfa_oregon_production_private_domain",PrivateZone=true \
                                                                                  --caller-reference $(date +%s) \
                                                                                  --query 'HostedZone.Id' \
                                                                                  --profile $profile --region us-west-2 --output text | cut -f3 -d /)
    camelz-variable alfa_oregon_production_private_hostedzone_id
    ```

1. **Create DHCP Options Set**

    ```bash
    alfa_oregon_production_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$alfa_oregon_production_private_domain]" \
                                                                                       "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                                 --tag-specifications "ResourceType=dhcp-options,Tags=[{Key=Name,Value=Alfa-Production-DHCPOptions},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'DhcpOptions.DhcpOptionsId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_dopt_id

    aws ec2 associate-dhcp-options --vpc-id $alfa_oregon_production_vpc_id \
                                   --dhcp-options-id $alfa_oregon_production_dopt_id \
                                   --profile $profile --region us-west-2 --output text
    ```

1. **Create Public Subnet A**

    ```bash
    alfa_oregon_production_public_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                     --cidr-block $alfa_oregon_production_public_subneta_cidr \
                                                                     --availability-zone us-west-2a \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-PublicSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_public_subneta_id
    ```

1. **Create Public Subnet B**

    ```bash
    alfa_oregon_production_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                     --cidr-block $alfa_oregon_production_public_subnetb_cidr \
                                                                     --availability-zone us-west-2b \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-PublicSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_public_subnetb_id
    ```

1. **Create Public Subnet C**

    ```bash
    alfa_oregon_production_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                     --cidr-block $alfa_oregon_production_public_subnetc_cidr \
                                                                     --availability-zone us-west-2c \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-PublicSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_public_subnetc_id
    ```

1. **Create Public1 Subnet A**

    ```bash
    alfa_oregon_production_public1_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                      --cidr-block $alfa_oregon_production_public1_subneta_cidr \
                                                                      --availability-zone us-west-2a \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Public1SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_public1_subneta_id
    ```

1. **Create Public1 Subnet B**

    ```bash
    alfa_oregon_production_public1_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                      --cidr-block $alfa_oregon_production_public1_subnetb_cidr \
                                                                      --availability-zone us-west-2b \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Public1SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_public1_subnetb_id
    ```

1. **Create Public1 Subnet C**

    ```bash
    alfa_oregon_production_public1_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                      --cidr-block $alfa_oregon_production_public1_subnetc_cidr \
                                                                      --availability-zone us-west-2c \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Public1SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_public1_subnetc_id
    ```

1. **Create Public7 Subnet A**

    ```bash
    alfa_oregon_production_public7_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                      --cidr-block $alfa_oregon_production_public7_subneta_cidr \
                                                                      --availability-zone us-west-2a \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Public7SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_public7_subneta_id
    ```

1. **Create Public7 Subnet B**

    ```bash
    alfa_oregon_production_public7_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                      --cidr-block $alfa_oregon_production_public7_subnetb_cidr \
                                                                      --availability-zone us-west-2b \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Public7SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_public7_subnetb_id
    ```

1. **Create Public7 Subnet C**

    ```bash
    alfa_oregon_production_public7_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                      --cidr-block $alfa_oregon_production_public7_subnetc_cidr \
                                                                      --availability-zone us-west-2c \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Public7SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_public7_subnetc_id
    ```

1. **Create Web Subnet A**

    ```bash
    alfa_oregon_production_web_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                  --cidr-block $alfa_oregon_production_web_subneta_cidr \
                                                                  --availability-zone us-west-2a \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-WebSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_web_subneta_id
    ```

1. **Create Web Subnet B**

    ```bash
    alfa_oregon_production_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                  --cidr-block $alfa_oregon_production_web_subnetb_cidr \
                                                                  --availability-zone us-west-2b \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-WebSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_web_subnetb_id
    ```

1. **Create Web Subnet C**

    ```bash
    alfa_oregon_production_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                  --cidr-block $alfa_oregon_production_web_subnetc_cidr \
                                                                  --availability-zone us-west-2c \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-WebSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_web_subnetc_id
    ```

1. **Create Web1 Subnet A**

    ```bash
    alfa_oregon_production_web1_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                   --cidr-block $alfa_oregon_production_web1_subneta_cidr \
                                                                   --availability-zone us-west-2a \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Web1SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_web1_subneta_id
    ```

1. **Create Web1 Subnet B**

    ```bash
    alfa_oregon_production_web1_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                   --cidr-block $alfa_oregon_production_web1_subnetb_cidr \
                                                                   --availability-zone us-west-2b \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Web1SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_web1_subnetb_id
    ```

1. **Create Web1 Subnet C**

    ```bash
    alfa_oregon_production_web1_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                   --cidr-block $alfa_oregon_production_web1_subnetc_cidr \
                                                                   --availability-zone us-west-2c \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Web1SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_web1_subnetc_id
    ```

1. **Create Web7 Subnet A**

    ```bash
    alfa_oregon_production_web7_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                   --cidr-block $alfa_oregon_production_web7_subneta_cidr \
                                                                   --availability-zone us-west-2a \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Web7SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_web7_subneta_id
    ```

1. **Create Web7 Subnet B**

    ```bash
    alfa_oregon_production_web7_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                   --cidr-block $alfa_oregon_production_web7_subnetb_cidr \
                                                                   --availability-zone us-west-2b \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Web7SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_web7_subnetb_id
    ```

1. **Create Web7 Subnet C**

    ```bash
    alfa_oregon_production_web7_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                   --cidr-block $alfa_oregon_production_web7_subnetc_cidr \
                                                                   --availability-zone us-west-2c \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Web7SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_web7_subnetc_id
    ```

1. **Create Application Subnet A**

    ```bash
    alfa_oregon_production_application_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                          --cidr-block $alfa_oregon_production_application_subneta_cidr \
                                                                          --availability-zone us-west-2a \
                                                                          --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-ApplicationSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                          --query 'Subnet.SubnetId' \
                                                                          --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_application_subneta_id
    ```

1. **Create Application Subnet B**

    ```bash
    alfa_oregon_production_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                          --cidr-block $alfa_oregon_production_application_subnetb_cidr \
                                                                          --availability-zone us-west-2b \
                                                                          --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-ApplicationSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                          --query 'Subnet.SubnetId' \
                                                                          --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_application_subnetb_id
    ```

1. **Create Application Subnet C**

    ```bash
    alfa_oregon_production_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                          --cidr-block $alfa_oregon_production_application_subnetc_cidr \
                                                                          --availability-zone us-west-2c \
                                                                          --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-ApplicationSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                          --query 'Subnet.SubnetId' \
                                                                          --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_application_subnetc_id
    ```

1. **Create Application1 Subnet A**

    ```bash
    alfa_oregon_production_application1_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                           --cidr-block $alfa_oregon_production_application1_subneta_cidr \
                                                                           --availability-zone us-west-2a \
                                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Application1SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                           --query 'Subnet.SubnetId' \
                                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_application1_subneta_id
    ```

1. **Create Application1 Subnet B**

    ```bash
    alfa_oregon_production_application1_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                           --cidr-block $alfa_oregon_production_application1_subnetb_cidr \
                                                                           --availability-zone us-west-2b \
                                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Application1SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                           --query 'Subnet.SubnetId' \
                                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_application1_subnetb_id
    ```

1. **Create Application1 Subnet C**

    ```bash
    alfa_oregon_production_application1_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                           --cidr-block $alfa_oregon_production_application1_subnetc_cidr \
                                                                           --availability-zone us-west-2c \
                                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Application1SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                           --query 'Subnet.SubnetId' \
                                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_application1_subnetc_id
    ```

1. **Create Application2 Subnet A**

    ```bash
    alfa_oregon_production_application2_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                           --cidr-block $alfa_oregon_production_application2_subneta_cidr \
                                                                           --availability-zone us-west-2a \
                                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Application2SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                           --query 'Subnet.SubnetId' \
                                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_application2_subneta_id
    ```

1. **Create Application2 Subnet B**

    ```bash
    alfa_oregon_production_application2_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                           --cidr-block $alfa_oregon_production_application2_subnetb_cidr \
                                                                           --availability-zone us-west-2b \
                                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Application2SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                           --query 'Subnet.SubnetId' \
                                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_application2_subnetb_id
    ```

1. **Create Application2 Subnet C**

    ```bash
    alfa_oregon_production_application2_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                           --cidr-block $alfa_oregon_production_application2_subnetc_cidr \
                                                                           --availability-zone us-west-2c \
                                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Application2SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                           --query 'Subnet.SubnetId' \
                                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_application2_subnetc_id
    ```

1. **Create Application3 Subnet A**

    ```bash
    alfa_oregon_production_application3_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                           --cidr-block $alfa_oregon_production_application3_subneta_cidr \
                                                                           --availability-zone us-west-2a \
                                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Application3SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                           --query 'Subnet.SubnetId' \
                                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_application3_subneta_id
    ```

1. **Create Application3 Subnet B**

    ```bash
    alfa_oregon_production_application3_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                           --cidr-block $alfa_oregon_production_application3_subnetb_cidr \
                                                                           --availability-zone us-west-2b \
                                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Application3SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                           --query 'Subnet.SubnetId' \
                                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_application3_subnetb_id
    ```

1. **Create Application3 Subnet C**

    ```bash
    alfa_oregon_production_application3_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                           --cidr-block $alfa_oregon_production_application3_subnetc_cidr \
                                                                           --availability-zone us-west-2c \
                                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Application3SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                           --query 'Subnet.SubnetId' \
                                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_application3_subnetc_id
    ```

1. **Create Cache Subnet A**

    ```bash
    alfa_oregon_production_cache_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                    --cidr-block $alfa_oregon_production_cache_subneta_cidr \
                                                                    --availability-zone us-west-2a \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-CacheSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_cache_subneta_id
    ```

1. **Create Cache Subnet B**

    ```bash
    alfa_oregon_production_cache_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                    --cidr-block $alfa_oregon_production_cache_subnetb_cidr \
                                                                    --availability-zone us-west-2b \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-CacheSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_cache_subnetb_id
    ```

1. **Create Cache Subnet C**

    ```bash
    alfa_oregon_production_cache_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                    --cidr-block $alfa_oregon_production_cache_subnetc_cidr \
                                                                    --availability-zone us-west-2c \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-CacheSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_cache_subnetc_id
    ```

1. **Create Cache1 Subnet A**

    ```bash
    alfa_oregon_production_cache1_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                     --cidr-block $alfa_oregon_production_cache1_subneta_cidr \
                                                                     --availability-zone us-west-2a \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Cache1SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_cache1_subneta_id
    ```

1. **Create Cache1 Subnet B**

    ```bash
    alfa_oregon_production_cache1_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                     --cidr-block $alfa_oregon_production_cache1_subnetb_cidr \
                                                                     --availability-zone us-west-2b \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Cache1SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_cache1_subnetb_id
    ```

1. **Create Cache1 Subnet C**

    ```bash
    alfa_oregon_production_cache1_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                     --cidr-block $alfa_oregon_production_cache1_subnetc_cidr \
                                                                     --availability-zone us-west-2c \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Cache1SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_cache1_subnetc_id
    ```

1. **Create Database Subnet A**

    ```bash
    alfa_oregon_production_database_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                       --cidr-block $alfa_oregon_production_database_subneta_cidr \
                                                                       --availability-zone us-west-2a \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-DatabaseSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_database_subneta_id
    ```

1. **Create Database Subnet B**

    ```bash
    alfa_oregon_production_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                       --cidr-block $alfa_oregon_production_database_subnetb_cidr \
                                                                       --availability-zone us-west-2b \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-DatabaseSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_database_subnetb_id
    ```

1. **Create Database Subnet C**

    ```bash
    alfa_oregon_production_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                       --cidr-block $alfa_oregon_production_database_subnetc_cidr \
                                                                       --availability-zone us-west-2c \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-DatabaseSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_database_subnetc_id
    ```

1. **Create Database1 Subnet A**

    ```bash
    alfa_oregon_production_database1_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                        --cidr-block $alfa_oregon_production_database1_subneta_cidr \
                                                                        --availability-zone us-west-2a \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Database1SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_database1_subneta_id
    ```

1. **Create Database1 Subnet B**

    ```bash
    alfa_oregon_production_database1_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                        --cidr-block $alfa_oregon_production_database1_subnetb_cidr \
                                                                        --availability-zone us-west-2b \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Database1SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_database1_subnetb_id
    ```

1. **Create Database1 Subnet C**

    ```bash
    alfa_oregon_production_database1_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                        --cidr-block $alfa_oregon_production_database1_subnetc_cidr \
                                                                        --availability-zone us-west-2c \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Database1SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_database1_subnetc_id
    ```

1. **Create Optional Subnet A**

    ```bash
    alfa_oregon_production_optional_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                       --cidr-block $alfa_oregon_production_optional_subneta_cidr \
                                                                       --availability-zone us-west-2a \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-OptionalSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_optional_subneta_id
    ```

1. **Create Optional Subnet B**

    ```bash
    alfa_oregon_production_optional_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                       --cidr-block $alfa_oregon_production_optional_subnetb_cidr \
                                                                       --availability-zone us-west-2b \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-OptionalSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_optional_subnetb_id
    ```

1. **Create Optional Subnet C**

    ```bash
    alfa_oregon_production_optional_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                       --cidr-block $alfa_oregon_production_optional_subnetc_cidr \
                                                                       --availability-zone us-west-2c \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-OptionalSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_optional_subnetc_id
    ```

1. **Create Optional1 Subnet A**

    ```bash
    alfa_oregon_production_optional1_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                        --cidr-block $alfa_oregon_production_optional1_subneta_cidr \
                                                                        --availability-zone us-west-2a \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Optional1SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_optional1_subneta_id
    ```

1. **Create Optional1 Subnet B**

    ```bash
    alfa_oregon_production_optional1_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                        --cidr-block $alfa_oregon_production_optional1_subnetb_cidr \
                                                                        --availability-zone us-west-2b \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Optional1SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_optional1_subnetb_id
    ```

1. **Create Optional1 Subnet C**

    ```bash
    alfa_oregon_production_optional1_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                        --cidr-block $alfa_oregon_production_optional1_subnetc_cidr \
                                                                        --availability-zone us-west-2c \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-Optional1SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_optional1_subnetc_id
    ```

1. **Create Directory Subnet A**

    ```bash
    alfa_oregon_production_directory_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                        --cidr-block $alfa_oregon_production_subnet_directorya_cidr \
                                                                        --availability-zone us-west-2a \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-DirectorySubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_directory_subneta_id
    ```

1. **Create Directory Subnet B**

    ```bash
    alfa_oregon_production_directory_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                        --cidr-block $alfa_oregon_production_subnet_directoryb_cidr \
                                                                        --availability-zone us-west-2b \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-DirectorySubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_directory_subnetb_id
    ```

1. **Create Directory Subnet C**

    ```bash
    alfa_oregon_production_directory_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                        --cidr-block $alfa_oregon_production_subnet_directoryc_cidr \
                                                                        --availability-zone us-west-2c \
                                                                        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-DirectorySubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'Subnet.SubnetId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_directory_subnetc_id
    ```

1. **Create Endpoint Subnet A**

    ```bash
    alfa_oregon_production_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                       --cidr-block $alfa_oregon_production_endpoint_subneta_cidr \
                                                                       --availability-zone us-west-2a \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-EndpointSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_endpoint_subneta_id
    ```

1. **Create Endpoint Subnet B**

    ```bash
    alfa_oregon_production_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                       --cidr-block $alfa_oregon_production_endpoint_subnetb_cidr \
                                                                       --availability-zone us-west-2b \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-EndpointSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_endpoint_subnetb_id
    ```

1. **Create Endpoint Subnet C**

    ```bash
    alfa_oregon_production_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                       --cidr-block $alfa_oregon_production_endpoint_subnetc_cidr \
                                                                       --availability-zone us-west-2c \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-EndpointSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_endpoint_subnetc_id
    ```

1. **Create Firewall Subnet A**

    ```bash
    alfa_oregon_production_firewall_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                       --cidr-block $alfa_oregon_production_firewall_subneta_cidr \
                                                                       --availability-zone us-west-2a \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-FirewallSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_firewall_subneta_id
    ```

1. **Create Firewall Subnet B**

    ```bash
    alfa_oregon_production_firewall_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                       --cidr-block $alfa_oregon_production_firewall_subnetb_cidr \
                                                                       --availability-zone us-west-2b \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-FirewallSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_firewall_subnetb_id
    ```

1. **Create Firewall Subnet C**

    ```bash
    alfa_oregon_production_firewall_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                       --cidr-block $alfa_oregon_production_firewall_subnetc_cidr \
                                                                       --availability-zone us-west-2c \
                                                                       --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-FirewallSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'Subnet.SubnetId' \
                                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_firewall_subnetc_id
    ```

1. **Create Gateway Subnet A**

    ```bash
    alfa_oregon_production_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                      --cidr-block $alfa_oregon_production_gateway_subneta_cidr \
                                                                      --availability-zone us-west-2a \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-GatewaySubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_gateway_subneta_id
    ```

1. **Create Gateway Subnet B**

    ```bash
    alfa_oregon_production_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                      --cidr-block $alfa_oregon_production_gateway_subnetb_cidr \
                                                                      --availability-zone us-west-2b \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-GatewaySubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_gateway_subnetb_id
    ```

1. **Create Gateway Subnet C**

    ```bash
    alfa_oregon_production_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_oregon_production_vpc_id \
                                                                      --cidr-block $alfa_oregon_production_gateway_subnetc_cidr \
                                                                      --availability-zone us-west-2c \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Production-GatewaySubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_gateway_subnetc_id
    ```

1. **Create Public Route Table, Default Route and Associate with Public Subnets**

    ```bash
    alfa_oregon_production_public_rtb_id=$(aws ec2 create-route-table --vpc-id $alfa_oregon_production_vpc_id \
                                                                      --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Alfa-Production-PublicRouteTable},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'RouteTable.RouteTableId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_public_rtb_id

    aws ec2 create-route --route-table-id $alfa_oregon_production_public_rtb_id \
                         --destination-cidr-block '0.0.0.0/0' \
                         --gateway-id $alfa_oregon_production_igw_id \
                         --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_public_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_public_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_public_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_public1_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_public1_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_public1_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_public7_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_public7_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_public7_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_web_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_web_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_web_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_web1_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_web1_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_web1_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_web7_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_web7_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_public_rtb_id --subnet-id $alfa_oregon_production_web7_subnetc_id \
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
      alfa_oregon_production_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                                 --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Production-NAT-EIPA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'AllocationId' \
                                                                 --profile $profile --region us-west-2 --output text)
      camelz-variable alfa_oregon_production_ngw_eipa

      alfa_oregon_production_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_oregon_production_ngw_eipa \
                                                                  --subnet-id $alfa_oregon_production_public_subneta_id \
                                                                  --client-token $(date +%s) \
                                                                  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Alfa-Production-NAT-GatewayA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'NatGateway.NatGatewayId' \
                                                                  --profile $profile --region us-west-2 --output text)
      camelz-variable alfa_oregon_production_ngwa_id

      if [ $ha_ngw = 1 ]; then
        alfa_oregon_production_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                                   --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Production-NAT-EIPB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'AllocationId' \
                                                                   --profile $profile --region us-west-2 --output text)
        camelz-variable alfa_oregon_production_ngw_eipb

        alfa_oregon_production_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_oregon_production_ngw_eipb \
                                                                    --subnet-id $alfa_oregon_production_public_subnetb_id \
                                                                    --client-token $(date +%s) \
                                                                    --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Alfa-Production-NAT-GatewayB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'NatGateway.NatGatewayId' \
                                                                    --profile $profile --region us-west-2 --output text)
        camelz-variable alfa_oregon_production_ngwb_id

        alfa_oregon_production_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                                   --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Production-NAT-EIPC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'AllocationId' \
                                                                   --profile $profile --region us-west-2 --output text)
        camelz-variable alfa_oregon_production_ngw_eipc

        alfa_oregon_production_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_oregon_production_ngw_eipc \
                                                                    --subnet-id $alfa_oregon_production_public_subnetc_id \
                                                                    --client-token $(date +%s) \
                                                                    --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Alfa-Production-NAT-GatewayC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'NatGateway.NatGatewayId' \
                                                                    --profile $profile --region us-west-2 --output text)
        camelz-variable alfa_oregon_production_ngwc_id
      fi
    else
      # Create NAT Security Group
      alfa_oregon_production_nat_sg_id=$(aws ec2 create-security-group --group-name Alfa-Production-NAT-InstanceSecurityGroup \
                                                                       --description Alfa-Production-NAT-InstanceSecurityGroup \
                                                                       --vpc-id $alfa_oregon_production_vpc_id \
                                                                       --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Production-NAT-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                       --query 'GroupId' \
                                                                       --profile $profile --region us-west-2 --output text)
      camelz-variable alfa_oregon_production_nat_sg_id

      aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_production_nat_sg_id \
                                               --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$alfa_oregon_production_vpc_cidr,Description=\"VPC (All)\"}]" \
                                               --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All)\"}]" \
                                               --profile $profile --region us-west-2 --output text

      # Create NAT Instance
      alfa_oregon_production_nat_instance_id=$(aws ec2 run-instances --image-id $oregon_nat_ami_id \
                                                                     --instance-type t3a.nano \
                                                                     --iam-instance-profile Name=ManagedInstance \
                                                                     --key-name administrator \
                                                                     --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Alfa-Production-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_oregon_production_nat_sg_id],SubnetId=$alfa_oregon_production_public_subneta_id" \
                                                                     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Production-NAT-Instance},{Key=Hostname,Value=alfue2pnat01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Instances[0].InstanceId' \
                                                                     --profile $profile --region us-west-2 --output text)
      camelz-variable alfa_oregon_production_nat_instance_id

      aws ec2 modify-instance-attribute --instance-id $alfa_oregon_production_nat_instance_id \
                                        --no-source-dest-check \
                                        --profile $profile --region us-west-2 --output text

      alfa_oregon_production_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $alfa_oregon_production_nat_instance_id \
                                                                              --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                              --profile $profile --region us-west-2 --output text)
      camelz-variable alfa_oregon_production_nat_instance_eni_id

      alfa_oregon_production_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_oregon_production_nat_instance_id \
                                                                                  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                                  --profile $profile --region us-west-2 --output text)
      camelz-variable alfa_oregon_production_nat_instance_private_ip
    fi
    ```

1. **Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets**

    ```bash
    alfa_oregon_production_private_rtba_id=$(aws ec2 create-route-table --vpc-id $alfa_oregon_production_vpc_id \
                                                                        --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Alfa-Production-PrivateRouteTableA},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'RouteTable.RouteTableId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_private_rtba_id

    if [ $use_ngw = 1 ]; then
      aws ec2 create-route --route-table-id $alfa_oregon_production_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $alfa_oregon_production_ngwa_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $alfa_oregon_production_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $alfa_oregon_production_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_application_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_application1_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_application2_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_application3_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_cache_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_cache1_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_database_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_database1_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_optional_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_optional1_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_directory_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_endpoint_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_firewall_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtba_id --subnet-id $alfa_oregon_production_gateway_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1. **Create Private Route Table for Availability Zone B, Default Route and Associate with Private Subnets**

    ```bash
    alfa_oregon_production_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $alfa_oregon_production_vpc_id \
                                                                        --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Alfa-Production-PrivateRouteTableB},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'RouteTable.RouteTableId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_private_rtbb_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then alfa_oregon_production_ngw_id=$alfa_oregon_production_ngwb_id; else alfa_oregon_production_ngw_id=$alfa_oregon_production_ngwa_id; fi
      aws ec2 create-route --route-table-id $alfa_oregon_production_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $alfa_oregon_production_ngw_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $alfa_oregon_production_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $alfa_oregon_production_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_application_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_application1_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_application2_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_application3_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_cache_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_cache1_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_database_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_database1_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_optional_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_optional1_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_directory_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_endpoint_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_firewall_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbb_id --subnet-id $alfa_oregon_production_gateway_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1. **Create Private Route Table for Availability Zone C, Default Route and Associate with Private Subnets**

    ```bash
    alfa_oregon_production_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $alfa_oregon_production_vpc_id \
                                                                        --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Alfa-Production-PrivateRouteTableC},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                        --query 'RouteTable.RouteTableId' \
                                                                        --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_private_rtbc_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then alfa_oregon_production_ngw_id=$alfa_oregon_production_ngwc_id; else alfa_oregon_production_ngw_id=$alfa_oregon_production_ngwa_id; fi
      aws ec2 create-route --route-table-id $alfa_oregon_production_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $alfa_oregon_production_ngw_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $alfa_oregon_production_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $alfa_oregon_production_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_application_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_application1_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_application2_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_application3_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_cache_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_cache1_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_database_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_database1_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_optional_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_optional1_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_directory_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_endpoint_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_firewall_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_oregon_production_private_rtbc_id --subnet-id $alfa_oregon_production_gateway_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1. **Create VPC Endpoint Security Group**

    ```bash
    alfa_oregon_production_vpce_sg_id=$(aws ec2 create-security-group --group-name Alfa-Production-VPCEndpointSecurityGroup \
                                                                      --description Alfa-Production-VPCEndpointSecurityGroup \
                                                                      --vpc-id $alfa_oregon_production_vpc_id \
                                                                      --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Production-VPCEndpointSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'GroupId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_vpce_sg_id

    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_production_vpce_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_oregon_production_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All TCP)\"}]" \
                                             --profile $profile --region us-west-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $alfa_oregon_production_vpce_sg_id \
                                             --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_oregon_production_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All UDP)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    ```

1. **Create VPC Endpoints for SSM and SSMMessages**

    ```bash
    alfa_oregon_production_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_oregon_production_vpc_id \
                                                                     --vpc-endpoint-type Interface \
                                                                     --service-name com.amazonaws.us-west-2.ssm \
                                                                     --private-dns-enabled \
                                                                     --security-group-ids $alfa_oregon_production_vpce_sg_id \
                                                                     --subnet-ids $alfa_oregon_production_endpoint_subneta_id $alfa_oregon_production_endpoint_subnetb_id $alfa_oregon_production_endpoint_subnetc_id \
                                                                     --client-token $(date +%s) \
                                                                     --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Production-SSMVpcEndpoint},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'VpcEndpoint.VpcEndpointId' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_ssm_vpce_id

    alfa_oregon_production_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_oregon_production_vpc_id \
                                                                      --vpc-endpoint-type Interface \
                                                                      --service-name com.amazonaws.us-west-2.ssmmessages \
                                                                      --private-dns-enabled \
                                                                      --security-group-ids $alfa_oregon_production_vpce_sg_id \
                                                                      --subnet-ids $alfa_oregon_production_endpoint_subneta_id $alfa_oregon_production_endpoint_subnetb_id $alfa_oregon_production_endpoint_subnetc_id \
                                                                      --client-token $(date +%s) \
                                                                      --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Production-SSMMessagesVpcEndpoint},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'VpcEndpoint.VpcEndpointId' \
                                                                      --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_production_ssmm_vpce_id
    ```
