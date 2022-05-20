# Modules:VPCs:Alfa Development Account:Ohio:Alfa Testing VPC

This module builds the Alfa-Testing VPC in the AWS Ohio (us-east-2) Region within the CaMeLz-Alfa-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Alfa-Testing VPC

1. **Set Profile for Alfa-Development Account**

    The Testing Environment does not have a dedicated Account, but is contained within the Development Account.

    ```bash
    profile=$alfa_development_profile
    ```

1. **Create VPC**

    ```bash
    alfa_ohio_testing_vpc_id=$(aws ec2 create-vpc --cidr-block $alfa_ohio_testing_vpc_cidr \
                                                  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=Alfa-Testing-VPC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                  --query 'Vpc.VpcId' \
                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_vpc_id


    aws ec2 modify-vpc-attribute --vpc-id $alfa_ohio_testing_vpc_id \
                                 --enable-dns-support \
                                 --profile $profile --region us-east-2 --output text

    aws ec2 modify-vpc-attribute --vpc-id $alfa_ohio_testing_vpc_id \
                                 --enable-dns-hostnames \
                                 --profile $profile --region us-east-2 --output text
    ```

1. **Tag Attached Default Resources Created With VPC**

    Creating a VPC also creates a set of attached default resources which do not have the same tags propagated.
    We will also tag these associated resources to insure consistency in the list displays.

    ```bash
    # Tag Alfa-Testing-MainRouteTable
    main_rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$alfa_ohio_testing_vpc_id \
                                                          Name=association.main,Values=true \
                                                --query 'RouteTables[0].RouteTableId' \
                                                --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $main_rtb_id \
                        --tags Key=Name,Value=Alfa-Testing-MainRouteTable \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Testing \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

    # Tag Alfa-Testing-DefaultNetworkAcl
    default_nacl_id=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$alfa_ohio_testing_vpc_id \
                                                              Name=default,Values=true \
                                                    --query 'NetworkAcls[0].NetworkAclId' \
                                                    --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $default_nacl_id \
                        --tags Key=Name,Value=Alfa-Testing-DefaultNetworkAcl \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Testing \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

    # Tag Alfa-Testing-DefaultSecurityGroup
    default_sg_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$alfa_ohio_testing_vpc_id \
                                                               Name=group-name,Values=default \
                                                     --query 'SecurityGroups[0].GroupId' \
                                                     --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $default_sg_id \
                        --tags Key=Name,Value=Alfa-Testing-DefaultSecurityGroup \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Testing \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Flow Log**

    ```bash
    aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Alfa-Testing" \
                              --profile $profile --region us-east-2 --output text

    aws logs put-retention-policy --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Alfa-Testing" \
                                  --retention-in-days 14 \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 create-flow-logs --resource-type VPC --resource-ids $alfa_ohio_testing_vpc_id \
                             --traffic-type ALL \
                             --log-destination-type cloud-watch-logs \
                             --log-destination "arn:aws:logs:us-east-2:${alfa_testing_account_id}:log-group:/${company_name_lc}/${system_name_lc}/FlowLog/Alfa-Testing" \
                             --deliver-logs-permission-arn "arn:aws:iam::${alfa_testing_account_id}:role/FlowLog" \
                             --tag-specifications "ResourceType=vpc-flow-log,Tags=[{Key=Name,Value=Alfa-Testing-FlowLog},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                             --profile $profile --region us-east-2 --output text
    ```

1. **Create Internet Gateway**

    ```bash
    alfa_ohio_testing_igw_id=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Alfa-Testing-InternetGateway},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'InternetGateway.InternetGatewayId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_igw_id

    aws ec2 attach-internet-gateway --vpc-id $alfa_ohio_testing_vpc_id \
                                    --internet-gateway-id $alfa_ohio_testing_igw_id \
                                    --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Hosted Zone**

    ```bash
    alfa_ohio_testing_private_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_ohio_testing_private_domain \
                                                                             --vpc VPCRegion=us-east-2,VPCId=$alfa_ohio_testing_vpc_id \
                                                                             --hosted-zone-config Comment="Private Zone for $alfa_ohio_testing_private_domain",PrivateZone=true \
                                                                             --caller-reference $(date +%s) \
                                                                             --query 'HostedZone.Id' \
                                                                             --profile $profile --region us-east-2 --output text | cut -f3 -d /)
    camelz-variable alfa_ohio_testing_private_hostedzone_id
    ```

1. **Create DHCP Options Set**

    ```bash
    alfa_ohio_testing_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$alfa_ohio_testing_private_domain]" \
                                                                                  "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                            --tag-specifications "ResourceType=dhcp-options,Tags=[{Key=Name,Value=Alfa-Testing-DHCPOptions},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'DhcpOptions.DhcpOptionsId' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_dopt_id

    aws ec2 associate-dhcp-options --vpc-id $alfa_ohio_testing_vpc_id \
                                   --dhcp-options-id $alfa_ohio_testing_dopt_id \
                                   --profile $profile --region us-east-2 --output text
    ```

1. **Create Public Subnet A**

    ```bash
    alfa_ohio_testing_public_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                --cidr-block $alfa_ohio_testing_public_subneta_cidr \
                                                                --availability-zone us-east-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-PublicSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_public_subneta_id
    ```

1. **Create Public Subnet B**

    ```bash
    alfa_ohio_testing_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                --cidr-block $alfa_ohio_testing_public_subnetb_cidr \
                                                                --availability-zone us-east-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-PublicSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_public_subnetb_id
    ```

1. **Create Public Subnet C**

    ```bash
    alfa_ohio_testing_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                --cidr-block $alfa_ohio_testing_public_subnetc_cidr \
                                                                --availability-zone us-east-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-PublicSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_public_subnetc_id
    ```

1. **Create Public1 Subnet A**

    ```bash
    alfa_ohio_testing_public1_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --cidr-block $alfa_ohio_testing_public1_subneta_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Public1SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_public1_subneta_id
    ```

1. **Create Public1 Subnet B**

    ```bash
    alfa_ohio_testing_public1_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --cidr-block $alfa_ohio_testing_public1_subnetb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Public1SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_public1_subnetb_id
    ```

1. **Create Public1 Subnet C**

    ```bash
    alfa_ohio_testing_public1_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --cidr-block $alfa_ohio_testing_public1_subnetc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Public1SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_public1_subnetc_id
    ```

1. **Create Public7 Subnet A**

    ```bash
    alfa_ohio_testing_public7_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --cidr-block $alfa_ohio_testing_public7_subneta_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Public7SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_public7_subneta_id
    ```

1. **Create Public7 Subnet B**

    ```bash
    alfa_ohio_testing_public7_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --cidr-block $alfa_ohio_testing_public7_subnetb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Public7SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_public7_subnetb_id
    ```

1. **Create Public7 Subnet C**

    ```bash
    alfa_ohio_testing_public7_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --cidr-block $alfa_ohio_testing_public7_subnetc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Public7SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_public7_subnetc_id
    ```

1. **Create Web Subnet A**

    ```bash
    alfa_ohio_testing_web_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                             --cidr-block $alfa_ohio_testing_web_subneta_cidr \
                                                             --availability-zone us-east-2a \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-WebSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_web_subneta_id
    ```

1. **Create Web Subnet B**

    ```bash
    alfa_ohio_testing_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                             --cidr-block $alfa_ohio_testing_web_subnetb_cidr \
                                                             --availability-zone us-east-2b \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-WebSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_web_subnetb_id
    ```

1. **Create Web Subnet C**

    ```bash
    alfa_ohio_testing_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                             --cidr-block $alfa_ohio_testing_web_subnetc_cidr \
                                                             --availability-zone us-east-2c \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-WebSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_web_subnetc_id
    ```

1. **Create Web1 Subnet A**

    ```bash
    alfa_ohio_testing_web1_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                              --cidr-block $alfa_ohio_testing_web1_subneta_cidr \
                                                              --availability-zone us-east-2a \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Web1SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_web1_subneta_id
    ```

1. **Create Web1 Subnet B**

    ```bash
    alfa_ohio_testing_web1_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                              --cidr-block $alfa_ohio_testing_web1_subnetb_cidr \
                                                              --availability-zone us-east-2b \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Web1SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_web1_subnetb_id
    ```

1. **Create Web1 Subnet C**

    ```bash
    alfa_ohio_testing_web1_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                              --cidr-block $alfa_ohio_testing_web1_subnetc_cidr \
                                                              --availability-zone us-east-2c \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Web1SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_web1_subnetc_id
    ```

1. **Create Web7 Subnet A**

    ```bash
    alfa_ohio_testing_web7_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                              --cidr-block $alfa_ohio_testing_web7_subneta_cidr \
                                                              --availability-zone us-east-2a \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Web7SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_web7_subneta_id
    ```

1. **Create Web7 Subnet B**

    ```bash
    alfa_ohio_testing_web7_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                              --cidr-block $alfa_ohio_testing_web7_subnetb_cidr \
                                                              --availability-zone us-east-2b \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Web7SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_web7_subnetb_id
    ```

1. **Create Web7 Subnet C**

    ```bash
    alfa_ohio_testing_web7_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                              --cidr-block $alfa_ohio_testing_web7_subnetc_cidr \
                                                              --availability-zone us-east-2c \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Web7SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_web7_subnetc_id
    ```

1. **Create Application Subnet A**

    ```bash
    alfa_ohio_testing_application_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                     --cidr-block $alfa_ohio_testing_application_subneta_cidr \
                                                                     --availability-zone us-east-2a \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-ApplicationSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_application_subneta_id
    ```

1. **Create Application Subnet B**

    ```bash
    alfa_ohio_testing_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                     --cidr-block $alfa_ohio_testing_application_subnetb_cidr \
                                                                     --availability-zone us-east-2b \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-ApplicationSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_application_subnetb_id
    ```

1. **Create Application Subnet C**

    ```bash
    alfa_ohio_testing_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                     --cidr-block $alfa_ohio_testing_application_subnetc_cidr \
                                                                     --availability-zone us-east-2c \
                                                                     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-ApplicationSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_application_subnetc_id
    ```

1. **Create Application1 Subnet A**

    ```bash
    alfa_ohio_testing_application1_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                      --cidr-block $alfa_ohio_testing_application1_subneta_cidr \
                                                                      --availability-zone us-east-2a \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Application1SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_application1_subneta_id
    ```

1. **Create Application1 Subnet B**

    ```bash
    alfa_ohio_testing_application1_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                      --cidr-block $alfa_ohio_testing_application1_subnetb_cidr \
                                                                      --availability-zone us-east-2b \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Application1SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_application1_subnetb_id
    ```

1. **Create Application1 Subnet C**

    ```bash
    alfa_ohio_testing_application1_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                      --cidr-block $alfa_ohio_testing_application1_subnetc_cidr \
                                                                      --availability-zone us-east-2c \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Application1SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_application1_subnetc_id
    ```

1. **Create Application2 Subnet A**

    ```bash
    alfa_ohio_testing_application2_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                      --cidr-block $alfa_ohio_testing_application2_subneta_cidr \
                                                                      --availability-zone us-east-2a \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Application2SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_application2_subneta_id
    ```

1. **Create Application2 Subnet B**

    ```bash
    alfa_ohio_testing_application2_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                      --cidr-block $alfa_ohio_testing_application2_subnetb_cidr \
                                                                      --availability-zone us-east-2b \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Application2SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_application2_subnetb_id
    ```

1. **Create Application2 Subnet C**

    ```bash
    alfa_ohio_testing_application2_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                      --cidr-block $alfa_ohio_testing_application2_subnetc_cidr \
                                                                      --availability-zone us-east-2c \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Application2SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_application2_subnetc_id
    ```

1. **Create Application3 Subnet A**

    ```bash
    alfa_ohio_testing_application3_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                      --cidr-block $alfa_ohio_testing_application3_subneta_cidr \
                                                                      --availability-zone us-east-2a \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Application3SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_application3_subneta_id
    ```

1. **Create Application3 Subnet B**

    ```bash
    alfa_ohio_testing_application3_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                      --cidr-block $alfa_ohio_testing_application3_subnetb_cidr \
                                                                      --availability-zone us-east-2b \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Application3SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_application3_subnetb_id
    ```

1. **Create Application3 Subnet C**

    ```bash
    alfa_ohio_testing_application3_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                      --cidr-block $alfa_ohio_testing_application3_subnetc_cidr \
                                                                      --availability-zone us-east-2c \
                                                                      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Application3SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                      --query 'Subnet.SubnetId' \
                                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_application3_subnetc_id
    ```

1. **Create Cache Subnet A**

    ```bash
    alfa_ohio_testing_cache_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                               --cidr-block $alfa_ohio_testing_cache_subneta_cidr \
                                                               --availability-zone us-east-2a \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-CacheSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_cache_subneta_id
    ```

1. **Create Cache Subnet B**

    ```bash
    alfa_ohio_testing_cache_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                               --cidr-block $alfa_ohio_testing_cache_subnetb_cidr \
                                                               --availability-zone us-east-2b \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-CacheSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_cache_subnetb_id
    ```

1. **Create Cache Subnet C**

    ```bash
    alfa_ohio_testing_cache_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                               --cidr-block $alfa_ohio_testing_cache_subnetc_cidr \
                                                               --availability-zone us-east-2c \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-CacheSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_cache_subnetc_id
    ```

1. **Create Cache1 Subnet A**

    ```bash
    alfa_ohio_testing_cache1_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                --cidr-block $alfa_ohio_testing_cache1_subneta_cidr \
                                                                --availability-zone us-east-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Cache1SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_cache1_subneta_id
    ```

1. **Create Cache1 Subnet B**

    ```bash
    alfa_ohio_testing_cache1_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                --cidr-block $alfa_ohio_testing_cache1_subnetb_cidr \
                                                                --availability-zone us-east-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Cache1SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_cache1_subnetb_id
    ```

1. **Create Cache1 Subnet C**

    ```bash
    alfa_ohio_testing_cache1_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                --cidr-block $alfa_ohio_testing_cache1_subnetc_cidr \
                                                                --availability-zone us-east-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Cache1SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_cache1_subnetc_id
    ```

1. **Create Database Subnet A**

    ```bash
    alfa_ohio_testing_database_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --cidr-block $alfa_ohio_testing_database_subneta_cidr \
                                                                  --availability-zone us-east-2a \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-DatabaseSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_database_subneta_id
    ```

1. **Create Database Subnet B**

    ```bash
    alfa_ohio_testing_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --cidr-block $alfa_ohio_testing_database_subnetb_cidr \
                                                                  --availability-zone us-east-2b \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-DatabaseSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_database_subnetb_id
    ```

1. **Create Database Subnet C**

    ```bash
    alfa_ohio_testing_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --cidr-block $alfa_ohio_testing_database_subnetc_cidr \
                                                                  --availability-zone us-east-2c \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-DatabaseSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_database_subnetc_id
    ```

1. **Create Database1 Subnet A**

    ```bash
    alfa_ohio_testing_database1_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                   --cidr-block $alfa_ohio_testing_database1_subneta_cidr \
                                                                   --availability-zone us-east-2a \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Database1SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_database1_subneta_id
    ```

1. **Create Database1 Subnet B**

    ```bash
    alfa_ohio_testing_database1_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                   --cidr-block $alfa_ohio_testing_database1_subnetb_cidr \
                                                                   --availability-zone us-east-2b \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Database1SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_database1_subnetb_id
    ```

1. **Create Database1 Subnet C**

    ```bash
    alfa_ohio_testing_database1_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                   --cidr-block $alfa_ohio_testing_database1_subnetc_cidr \
                                                                   --availability-zone us-east-2c \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Database1SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_database1_subnetc_id
    ```

1. **Create Optional Subnet A**

    ```bash
    alfa_ohio_testing_optional_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --cidr-block $alfa_ohio_testing_optional_subneta_cidr \
                                                                  --availability-zone us-east-2a \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-OptionalSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_optional_subneta_id
    ```

1. **Create Optional Subnet B**

    ```bash
    alfa_ohio_testing_optional_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --cidr-block $alfa_ohio_testing_optional_subnetb_cidr \
                                                                  --availability-zone us-east-2b \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-OptionalSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_optional_subnetb_id
    ```

1. **Create Optional Subnet C**

    ```bash
    alfa_ohio_testing_optional_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --cidr-block $alfa_ohio_testing_optional_subnetc_cidr \
                                                                  --availability-zone us-east-2c \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-OptionalSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_optional_subnetc_id
    ```

1. **Create Optional1 Subnet A**

    ```bash
    alfa_ohio_testing_optional1_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                   --cidr-block $alfa_ohio_testing_optional1_subneta_cidr \
                                                                   --availability-zone us-east-2a \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Optional1SubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_optional1_subneta_id
    ```

1. **Create Optional1 Subnet B**

    ```bash
    alfa_ohio_testing_optional1_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                   --cidr-block $alfa_ohio_testing_optional1_subnetb_cidr \
                                                                   --availability-zone us-east-2b \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Optional1SubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_optional1_subnetb_id
    ```

1. **Create Optional1 Subnet C**

    ```bash
    alfa_ohio_testing_optional1_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                   --cidr-block $alfa_ohio_testing_optional1_subnetc_cidr \
                                                                   --availability-zone us-east-2c \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-Optional1SubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_optional1_subnetc_id
    ```

1. **Create Endpoint Subnet A**

    ```bash
    alfa_ohio_testing_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --cidr-block $alfa_ohio_testing_endpoint_subneta_cidr \
                                                                  --availability-zone us-east-2a \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-EndpointSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_endpoint_subneta_id
    ```

1. **Create Endpoint Subnet B**

    ```bash
    alfa_ohio_testing_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --cidr-block $alfa_ohio_testing_endpoint_subnetb_cidr \
                                                                  --availability-zone us-east-2b \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-EndpointSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_endpoint_subnetb_id
    ```

1. **Create Endpoint Subnet C**

    ```bash
    alfa_ohio_testing_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --cidr-block $alfa_ohio_testing_endpoint_subnetc_cidr \
                                                                  --availability-zone us-east-2c \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-EndpointSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_endpoint_subnetc_id
    ```

1. **Create Firewall Subnet A**

    ```bash
    alfa_ohio_testing_firewall_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --cidr-block $alfa_ohio_testing_firewall_subneta_cidr \
                                                                  --availability-zone us-east-2a \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-FirewallSubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_firewall_subneta_id
    ```

1. **Create Firewall Subnet B**

    ```bash
    alfa_ohio_testing_firewall_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --cidr-block $alfa_ohio_testing_firewall_subnetb_cidr \
                                                                  --availability-zone us-east-2b \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-FirewallSubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_firewall_subnetb_id
    ```

1. **Create Firewall Subnet C**

    ```bash
    alfa_ohio_testing_firewall_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --cidr-block $alfa_ohio_testing_firewall_subnetc_cidr \
                                                                  --availability-zone us-east-2c \
                                                                  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-FirewallSubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_firewall_subnetc_id
    ```

1. **Create Gateway Subnet A**

    ```bash
    alfa_ohio_testing_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --cidr-block $alfa_ohio_testing_gateway_subneta_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-GatewaySubnetA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_gateway_subneta_id
    ```

1. **Create Gateway Subnet B**

    ```bash
    alfa_ohio_testing_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --cidr-block $alfa_ohio_testing_gateway_subnetb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-GatewaySubnetB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_gateway_subnetb_id
    ```

1. **Create Gateway Subnet C**

    ```bash
    alfa_ohio_testing_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --cidr-block $alfa_ohio_testing_gateway_subnetc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Alfa-Testing-GatewaySubnetC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_gateway_subnetc_id
    ```

1. **Create Public Route Table, Default Route and Associate with Public Subnets**

    ```bash
    alfa_ohio_testing_public_rtb_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Alfa-Testing-PublicRouteTable},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'RouteTable.RouteTableId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_public_rtb_id

    aws ec2 create-route --route-table-id $alfa_ohio_testing_public_rtb_id \
                         --destination-cidr-block '0.0.0.0/0' \
                         --gateway-id $alfa_ohio_testing_igw_id \
                         --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_public_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_public_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_public_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_public1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_public1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_public1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_public7_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_public7_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_public7_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_web_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_web_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_web_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_web1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_web1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_web1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text

    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_web7_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_web7_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_web7_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create NAT Gateways - OR - NAT Instances**

    This Step can create either NAT Gateway(s) or NAT Instance(s), depending on what you want to do.
    - NAT Gateways are the recommended and scalable approach. But, you can't turn them off, and they are $32/each per
      month.
    - NAT Instances are neither recommended nor scalable. If they fail, you must manually replace them. But, you can
      pick very inexpensive instance types which are about $5/month and turn them off when not in use, so for
      prototyping and testing environments, this is a way to save on costs.

    This Step can also create either a fully HA set of the NAT device, or a single instance in AZ A, used by the other
    AZs. The risk of an AZ failure is extremely small, so it's questionable if the cost to have 3 copies is worthwhile.

    TBD: Not sure if showing the if statement logic is better than just having the user choose which statements to run
    based on a description here without explicit if statements.

    ```bash
    if [ $use_ngw = 1 ]; then
      # Create NAT Gateways
      alfa_ohio_testing_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                            --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Testing-NAT-EIPA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'AllocationId' \
                                                            --profile $profile --region us-east-2 --output text)
      camelz-variable alfa_ohio_testing_ngw_eipa

      alfa_ohio_testing_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_ohio_testing_ngw_eipa \
                                                             --subnet-id $alfa_ohio_testing_public_subneta_id \
                                                             --client-token $(date +%s) \
                                                             --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Alfa-Testing-NAT-GatewayA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'NatGateway.NatGatewayId' \
                                                             --profile $profile --region us-east-2 --output text)
      camelz-variable alfa_ohio_testing_ngwa_id

      if [ $ha_ngw = 1 ]; then
        alfa_ohio_testing_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                              --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Testing-NAT-EIPB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'AllocationId' \
                                                              --profile $profile --region us-east-2 --output text)
        camelz-variable alfa_ohio_testing_ngw_eipb

        alfa_ohio_testing_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_ohio_testing_ngw_eipb \
                                                               --subnet-id $alfa_ohio_testing_public_subnetb_id \
                                                               --client-token $(date +%s) \
                                                               --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Alfa-Testing-NAT-GatewayB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'NatGateway.NatGatewayId' \
                                                               --profile $profile --region us-east-2 --output text)
        camelz-variable alfa_ohio_testing_ngwb_id

        alfa_ohio_testing_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                              --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Alfa-Testing-NAT-EIPC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'AllocationId' \
                                                              --profile $profile --region us-east-2 --output text)
        camelz-variable alfa_ohio_testing_ngw_eipc

        alfa_ohio_testing_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_ohio_testing_ngw_eipc \
                                                               --subnet-id $alfa_ohio_testing_public_subnetc_id \
                                                               --client-token $(date +%s) \
                                                               --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Alfa-Testing-NAT-GatewayC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'NatGateway.NatGatewayId' \
                                                               --profile $profile --region us-east-2 --output text)
        camelz-variable alfa_ohio_testing_ngwc_id
      fi
    else
      # Create NAT Security Group
      alfa_ohio_testing_nat_sg_id=$(aws ec2 create-security-group --group-name Alfa-Testing-NAT-InstanceSecurityGroup \
                                                                  --description Alfa-Testing-NAT-InstanceSecurityGroup \
                                                                  --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Testing-NAT-InstanceSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'GroupId' \
                                                                  --profile $profile --region us-east-2 --output text)
      camelz-variable alfa_ohio_testing_nat_sg_id

      aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_nat_sg_id \
                                               --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$alfa_ohio_testing_vpc_cidr,Description=\"VPC (All)\"}]" \
                                               --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All)\"}]" \
                                               --profile $profile --region us-east-2 --output text

      # Create NAT Instance
      alfa_ohio_testing_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                                --instance-type t3a.nano \
                                                                --iam-instance-profile Name=ManagedInstance \
                                                                --key-name administrator \
                                                                --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Alfa-Testing-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_testing_nat_sg_id],SubnetId=$alfa_ohio_testing_public_subneta_id" \
                                                                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Testing-NAT-Instance},{Key=Hostname,Value=alfue2pnat01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Instances[0].InstanceId' \
                                                                --profile $profile --region us-east-2 --output text)
      camelz-variable alfa_ohio_testing_nat_instance_id

      aws ec2 modify-instance-attribute --instance-id $alfa_ohio_testing_nat_instance_id \
                                        --no-source-dest-check \
                                        --profile $profile --region us-east-2 --output text

      alfa_ohio_testing_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $alfa_ohio_testing_nat_instance_id \
                                                                         --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                         --profile $profile --region us-east-2 --output text)
      camelz-variable alfa_ohio_testing_nat_instance_eni_id

      alfa_ohio_testing_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_testing_nat_instance_id \
                                                                             --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                             --profile $profile --region us-east-2 --output text)
      camelz-variable alfa_ohio_testing_nat_instance_private_ip
    fi
    ```

1. **Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets**

    ```bash
    alfa_ohio_testing_private_rtba_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_testing_vpc_id \
                                                                   --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Alfa-Testing-PrivateRouteTableA},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_private_rtba_id

    if [ $use_ngw = 1 ]; then
      aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $alfa_ohio_testing_ngwa_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $alfa_ohio_testing_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_application_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_application1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_application2_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_application3_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_cache_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_cache1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_database_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_database1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_optional_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_optional1_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_endpoint_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_firewall_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_gateway_subneta_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Route Table for Availability Zone B, Default Route and Associate with Private Subnets**

    ```bash
    alfa_ohio_testing_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_testing_vpc_id \
                                                                   --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Alfa-Testing-PrivateRouteTableB},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_private_rtbb_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then alfa_ohio_testing_ngw_id=$alfa_ohio_testing_ngwb_id; else alfa_ohio_testing_ngw_id=$alfa_ohio_testing_ngwa_id; fi
      aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $alfa_ohio_testing_ngw_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $alfa_ohio_testing_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_application_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_application1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_application2_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_application3_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_cache_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_cache1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_database_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_database1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_optional_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_optional1_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_endpoint_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_firewall_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_gateway_subnetb_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create Private Route Table for Availability Zone C, Default Route and Associate with Private Subnets**

    ```bash
    alfa_ohio_testing_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_testing_vpc_id \
                                                                   --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Alfa-Testing-PrivateRouteTableC},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_private_rtbc_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then alfa_ohio_testing_ngw_id=$alfa_ohio_testing_ngwc_id; else alfa_ohio_testing_ngw_id=$alfa_ohio_testing_ngwa_id; fi
      aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $alfa_ohio_testing_ngw_id \
                           --profile $profile --region us-east-2 --output text
    else
      aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $alfa_ohio_testing_nat_instance_eni_id \
                           --profile $profile --region us-east-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_application_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_application1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_application2_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_application3_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_cache_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_cache1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_database_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_database1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_optional_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_optional1_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_endpoint_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_firewall_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_gateway_subnetc_id \
                                  --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Endpoint Security Group**

    ```bash
    alfa_ohio_testing_vpce_sg_id=$(aws ec2 create-security-group --group-name Alfa-Testing-VPCEndpointSecurityGroup \
                                                                 --description Alfa-Testing-VPCEndpointSecurityGroup \
                                                                 --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Alfa-Testing-VPCEndpointSecurityGroup},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'GroupId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_vpce_sg_id

    aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_vpce_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_ohio_testing_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All TCP)\"}]" \
                                             --profile $profile --region us-east-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_vpce_sg_id \
                                             --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_ohio_testing_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All UDP)\"}]" \
                                             --profile $profile --region us-east-2 --output text
    ```

1. **Create VPC Endpoints for SSM and SSMMessages**

    ```bash
    alfa_ohio_testing_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_ohio_testing_vpc_id \
                                                                --vpc-endpoint-type Interface \
                                                                --service-name com.amazonaws.us-east-2.ssm \
                                                                --private-dns-enabled \
                                                               --security-group-ids $alfa_ohio_testing_vpce_sg_id \
                                                                --subnet-ids $alfa_ohio_testing_endpoint_subneta_id $alfa_ohio_testing_endpoint_subnetb_id $alfa_ohio_testing_endpoint_subnetc_id \
                                                                --client-token $(date +%s) \
                                                                --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Testing-SSMVpcEndpoint},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'VpcEndpoint.VpcEndpointId' \
                                                                --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_ssm_vpce_id

    alfa_ohio_testing_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --vpc-endpoint-type Interface \
                                                                 --service-name com.amazonaws.us-east-2.ssmmessages \
                                                                 --private-dns-enabled \
                                                                 --security-group-ids $alfa_ohio_testing_vpce_sg_id \
                                                                 --subnet-ids $alfa_ohio_testing_endpoint_subneta_id $alfa_ohio_testing_endpoint_subnetb_id $alfa_ohio_testing_endpoint_subnetc_id \
                                                                 --client-token $(date +%s) \
                                                                 --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Testing-SSMMessagesVpcEndpoint},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'VpcEndpoint.VpcEndpointId' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_testing_ssmm_vpce_id
    ```
