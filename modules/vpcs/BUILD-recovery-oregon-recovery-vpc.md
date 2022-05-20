# Modules:VPCs:Recovery Account:Oregon:Recovery VPC

This module builds the Recovery VPC in the AWS Oregon (us-west-2) Region within the CaMeLz-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Recovery VPC

1. **Set Profile for Recovery Account**

    ```bash
    profile=$recovery_profile
    ```

1. **Create VPC**

    ```bash
    oregon_recovery_vpc_id=$(aws ec2 create-vpc --cidr-block $oregon_recovery_vpc_cidr \
                                                --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=Recovery-VPC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                --query 'Vpc.VpcId' \
                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_vpc_id


    aws ec2 modify-vpc-attribute --vpc-id $oregon_recovery_vpc_id \
                                 --enable-dns-support \
                                 --profile $profile --region us-west-2 --output text

    aws ec2 modify-vpc-attribute --vpc-id $oregon_recovery_vpc_id \
                                 --enable-dns-hostnames \
                                 --profile $profile --region us-west-2 --output text
    ```

1. **Tag Attached Default Resources Created With VPC**

    Creating a VPC also creates a set of attached default resources which do not have the same tags propagated.
    We will also tag these associated resources to insure consistency in the list displays.

    ```bash
    # Tag Recovery-MainRouteTable
    main_rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$oregon_recovery_vpc_id \
                                                          Name=association.main,Values=true \
                                                --query 'RouteTables[0].RouteTableId' \
                                                --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $main_rtb_id \
                        --tags Key=Name,Value=Recovery-MainRouteTable \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Recovery \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text

    # Tag Recovery-DefaultNetworkAcl
    default_nacl_id=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$oregon_recovery_vpc_id \
                                                              Name=default,Values=true \
                                                    --query 'NetworkAcls[0].NetworkAclId' \
                                                    --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $default_nacl_id \
                        --tags Key=Name,Value=Recovery-DefaultNetworkAcl \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Recovery \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text

    # Tag Recovery-DefaultSecurityGroup
    default_sg_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$oregon_recovery_vpc_id \
                                                               Name=group-name,Values=default \
                                                     --query 'SecurityGroups[0].GroupId' \
                                                     --profile $profile --region us-west-2 --output text)

    aws ec2 create-tags --resources $default_sg_id \
                        --tags Key=Name,Value=Recovery-DefaultSecurityGroup \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Recovery \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-west-2 --output text
    ```

1. **Create VPC Flow Log**

    ```bash
    aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Recovery" \
                              --profile $profile --region us-west-2 --output text

    aws logs put-retention-policy --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Recovery" \
                                  --retention-in-days 14 \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 create-flow-logs --resource-type VPC --resource-ids $oregon_recovery_vpc_id \
                             --traffic-type ALL \
                             --log-destination-type cloud-watch-logs \
                             --log-destination "arn:aws:logs:us-west-2:${recovery_account_id}:log-group:/${company_name_lc}/${system_name_lc}/FlowLog/Recovery" \
                             --deliver-logs-permission-arn "arn:aws:iam::${recovery_account_id}:role/FlowLog" \
                             --tag-specifications "ResourceType=vpc-flow-log,Tags=[{Key=Name,Value=Recovery-FlowLog},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                             --profile $profile --region us-west-2 --output text
    ```

1. **Create Internet Gateway**

    ```bash
    oregon_recovery_igw_id=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Recovery-InternetGateway},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'InternetGateway.InternetGatewayId' \
                                                             --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_igw_id

    aws ec2 attach-internet-gateway --vpc-id $oregon_recovery_vpc_id \
                                    --internet-gateway-id $oregon_recovery_igw_id \
                                    --profile $profile --region us-west-2 --output text
    ```

1. **Create Private Hosted Zone**

    ```bash
    oregon_recovery_private_hostedzone_id=$(aws route53 create-hosted-zone --name $oregon_recovery_private_domain \
                                                                           --vpc VPCRegion=us-west-2,VPCId=$oregon_recovery_vpc_id \
                                                                           --hosted-zone-config Comment="Private Zone for $oregon_recovery_private_domain",PrivateZone=true \
                                                                           --caller-reference $(date +%s) \
                                                                           --query 'HostedZone.Id' \
                                                                           --profile $profile --region us-west-2 --output text | cut -f3 -d /)
    camelz-variable oregon_recovery_private_hostedzone_id
    ```

1. **Create DHCP Options Set**

    ```bash
    oregon_recovery_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$oregon_recovery_private_domain]" \
                                                                                "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                          --tag-specifications "ResourceType=dhcp-options,Tags=[{Key=Name,Value=Recovery-DHCPOptions},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'DhcpOptions.DhcpOptionsId' \
                                                          --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_dopt_id

    aws ec2 associate-dhcp-options --vpc-id $oregon_recovery_vpc_id \
                                   --dhcp-options-id $oregon_recovery_dopt_id \
                                   --profile $profile --region us-west-2 --output text
    ```

1. **Create Public Subnet A**

    ```bash
    oregon_recovery_public_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                              --cidr-block $oregon_recovery_public_subneta_cidr \
                                                              --availability-zone us-west-2a \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-PublicSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_public_subneta_id
    ```

1. **Create Public Subnet B**

    ```bash
    oregon_recovery_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                              --cidr-block $oregon_recovery_public_subnetb_cidr \
                                                              --availability-zone us-west-2b \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-PublicSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_public_subnetb_id
    ```

1. **Create Public Subnet C**

    ```bash
    oregon_recovery_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                              --cidr-block $oregon_recovery_public_subnetc_cidr \
                                                              --availability-zone us-west-2c \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-PublicSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_public_subnetc_id
    ```

1. **Create Public1 Subnet A**

    ```bash
    oregon_recovery_public1_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                               --cidr-block $oregon_recovery_public1_subneta_cidr \
                                                               --availability-zone us-west-2a \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Public1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_public1_subneta_id
    ```

1. **Create Public1 Subnet B**

    ```bash
    oregon_recovery_public1_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                               --cidr-block $oregon_recovery_public1_subnetb_cidr \
                                                               --availability-zone us-west-2b \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Public1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_public1_subnetb_id
    ```

1. **Create Public1 Subnet C**

    ```bash
    oregon_recovery_public1_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                               --cidr-block $oregon_recovery_public1_subnetc_cidr \
                                                               --availability-zone us-west-2c \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Public1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_public1_subnetc_id
    ```

1. **Create Public7 Subnet A**

    ```bash
    oregon_recovery_public7_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                               --cidr-block $oregon_recovery_public7_subneta_cidr \
                                                               --availability-zone us-west-2a \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Public7SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_public7_subneta_id
    ```

1. **Create Public7 Subnet B**

    ```bash
    oregon_recovery_public7_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                               --cidr-block $oregon_recovery_public7_subnetb_cidr \
                                                               --availability-zone us-west-2b \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Public7SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_public7_subnetb_id
    ```

1. **Create Public7 Subnet C**

    ```bash
    oregon_recovery_public7_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                               --cidr-block $oregon_recovery_public7_subnetc_cidr \
                                                               --availability-zone us-west-2c \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Public7SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_public7_subnetc_id
    ```

1. **Create Web Subnet A**

    ```bash
    oregon_recovery_web_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                           --cidr-block $oregon_recovery_web_subneta_cidr \
                                                           --availability-zone us-west-2a \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-WebSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_web_subneta_id
    ```

1. **Create Web Subnet B**

    ```bash
    oregon_recovery_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                           --cidr-block $oregon_recovery_web_subnetb_cidr \
                                                           --availability-zone us-west-2b \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-WebSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_web_subnetb_id
    ```

1. **Create Web Subnet C**

    ```bash
    oregon_recovery_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                           --cidr-block $oregon_recovery_web_subnetc_cidr \
                                                           --availability-zone us-west-2c \
                                                           --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-WebSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_web_subnetc_id
    ```

1. **Create Web1 Subnet A**

    ```bash
    oregon_recovery_web1_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                            --cidr-block $oregon_recovery_web1_subneta_cidr \
                                                            --availability-zone us-west-2a \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Web1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_web1_subneta_id
    ```

1. **Create Web1 Subnet B**

    ```bash
    oregon_recovery_web1_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                            --cidr-block $oregon_recovery_web1_subnetb_cidr \
                                                            --availability-zone us-west-2b \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Web1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_web1_subnetb_id
    ```

1. **Create Web1 Subnet C**

    ```bash
    oregon_recovery_web1_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                            --cidr-block $oregon_recovery_web1_subnetc_cidr \
                                                            --availability-zone us-west-2c \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Web1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_web1_subnetc_id
    ```

1. **Create Web7 Subnet A**

    ```bash
    oregon_recovery_web7_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                            --cidr-block $oregon_recovery_web7_subneta_cidr \
                                                            --availability-zone us-west-2a \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Web7SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_web7_subneta_id
    ```

1. **Create Web7 Subnet B**

    ```bash
    oregon_recovery_web7_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                            --cidr-block $oregon_recovery_web7_subnetb_cidr \
                                                            --availability-zone us-west-2b \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Web7SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_web7_subnetb_id
    ```

1. **Create Web7 Subnet C**

    ```bash
    oregon_recovery_web7_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                            --cidr-block $oregon_recovery_web7_subnetc_cidr \
                                                            --availability-zone us-west-2c \
                                                            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Web7SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_web7_subnetc_id
    ```

1. **Create Application Subnet A**

    ```bash
    oregon_recovery_application_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                   --cidr-block $oregon_recovery_application_subneta_cidr \
                                                                   --availability-zone us-west-2a \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-ApplicationSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_application_subneta_id
    ```

1. **Create Application Subnet B**

    ```bash
    oregon_recovery_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                   --cidr-block $oregon_recovery_application_subnetb_cidr \
                                                                   --availability-zone us-west-2b \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-ApplicationSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_application_subnetb_id
    ```

1. **Create Application Subnet C**

    ```bash
    oregon_recovery_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                   --cidr-block $oregon_recovery_application_subnetc_cidr \
                                                                   --availability-zone us-west-2c \
                                                                   --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-ApplicationSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_application_subnetc_id
    ```

1. **Create Application1 Subnet A**

    ```bash
    oregon_recovery_application1_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                    --cidr-block $oregon_recovery_application1_subneta_cidr \
                                                                    --availability-zone us-west-2a \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Application1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_application1_subneta_id
    ```

1. **Create Application1 Subnet B**

    ```bash
    oregon_recovery_application1_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                    --cidr-block $oregon_recovery_application1_subnetb_cidr \
                                                                    --availability-zone us-west-2b \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Application1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_application1_subnetb_id
    ```

1. **Create Application1 Subnet C**

    ```bash
    oregon_recovery_application1_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                    --cidr-block $oregon_recovery_application1_subnetc_cidr \
                                                                    --availability-zone us-west-2c \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Application1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_application1_subnetc_id
    ```

1. **Create Application2 Subnet A**

    ```bash
    oregon_recovery_application2_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                    --cidr-block $oregon_recovery_application2_subneta_cidr \
                                                                    --availability-zone us-west-2a \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Application2SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_application2_subneta_id
    ```

1. **Create Application2 Subnet B**

    ```bash
    oregon_recovery_application2_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                    --cidr-block $oregon_recovery_application2_subnetb_cidr \
                                                                    --availability-zone us-west-2b \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Application2SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_application2_subnetb_id
    ```

1. **Create Application2 Subnet C**

    ```bash
    oregon_recovery_application2_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                    --cidr-block $oregon_recovery_application2_subnetc_cidr \
                                                                    --availability-zone us-west-2c \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Application2SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_application2_subnetc_id
    ```

1. **Create Application3 Subnet A**

    ```bash
    oregon_recovery_application3_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                    --cidr-block $oregon_recovery_application3_subneta_cidr \
                                                                    --availability-zone us-west-2a \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Application3SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_application3_subneta_id
    ```

1. **Create Application3 Subnet B**

    ```bash
    oregon_recovery_application3_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                    --cidr-block $oregon_recovery_application3_subnetb_cidr \
                                                                    --availability-zone us-west-2b \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Application3SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_application3_subnetb_id
    ```

1. **Create Application3 Subnet C**

    ```bash
    oregon_recovery_application3_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                    --cidr-block $oregon_recovery_application3_subnetc_cidr \
                                                                    --availability-zone us-west-2c \
                                                                    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Application3SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_application3_subnetc_id
    ```

1. **Create Cache Subnet A**

    ```bash
    oregon_recovery_cache_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                             --cidr-block $oregon_recovery_cache_subneta_cidr \
                                                             --availability-zone us-west-2a \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-CacheSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_cache_subneta_id
    ```

1. **Create Cache Subnet B**

    ```bash
    oregon_recovery_cache_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                             --cidr-block $oregon_recovery_cache_subnetb_cidr \
                                                             --availability-zone us-west-2b \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-CacheSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_cache_subnetb_id
    ```

1. **Create Cache Subnet C**

    ```bash
    oregon_recovery_cache_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                             --cidr-block $oregon_recovery_cache_subnetc_cidr \
                                                             --availability-zone us-west-2c \
                                                             --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-CacheSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_cache_subnetc_id
    ```

1. **Create Cache1 Subnet A**

    ```bash
    oregon_recovery_cache1_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                              --cidr-block $oregon_recovery_cache1_subneta_cidr \
                                                              --availability-zone us-west-2a \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Cache1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_cache1_subneta_id
    ```

1. **Create Cache1 Subnet B**

    ```bash
    oregon_recovery_cache1_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                              --cidr-block $oregon_recovery_cache1_subnetb_cidr \
                                                              --availability-zone us-west-2b \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Cache1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_cache1_subnetb_id
    ```

1. **Create Cache1 Subnet C**

    ```bash
    oregon_recovery_cache1_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                              --cidr-block $oregon_recovery_cache1_subnetc_cidr \
                                                              --availability-zone us-west-2c \
                                                              --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Cache1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_cache1_subnetc_id
    ```

1. **Create Database Subnet A**

    ```bash
    oregon_recovery_database_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                --cidr-block $oregon_recovery_database_subneta_cidr \
                                                                --availability-zone us-west-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-DatabaseSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_database_subneta_id
    ```

1. **Create Database Subnet B**

    ```bash
    oregon_recovery_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                --cidr-block $oregon_recovery_database_subnetb_cidr \
                                                                --availability-zone us-west-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-DatabaseSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_database_subnetb_id
    ```

1. **Create Database Subnet C**

    ```bash
    oregon_recovery_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                --cidr-block $oregon_recovery_database_subnetc_cidr \
                                                                --availability-zone us-west-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-DatabaseSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_database_subnetc_id
    ```

1. **Create Database1 Subnet A**

    ```bash
    oregon_recovery_database1_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                 --cidr-block $oregon_recovery_database1_subneta_cidr \
                                                                 --availability-zone us-west-2a \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Database1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_database1_subneta_id
    ```

1. **Create Database1 Subnet B**

    ```bash
    oregon_recovery_database1_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                 --cidr-block $oregon_recovery_database1_subnetb_cidr \
                                                                 --availability-zone us-west-2b \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Database1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_database1_subnetb_id
    ```

1. **Create Database1 Subnet C**

    ```bash
    oregon_recovery_database1_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                 --cidr-block $oregon_recovery_database1_subnetc_cidr \
                                                                 --availability-zone us-west-2c \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Database1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_database1_subnetc_id
    ```

1. **Create Optional Subnet A**

    ```bash
    oregon_recovery_optional_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                --cidr-block $oregon_recovery_optional_subneta_cidr \
                                                                --availability-zone us-west-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-OptionalSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_optional_subneta_id
    ```

1. **Create Optional Subnet B**

    ```bash
    oregon_recovery_optional_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                --cidr-block $oregon_recovery_optional_subnetb_cidr \
                                                                --availability-zone us-west-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-OptionalSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_optional_subnetb_id
    ```

1. **Create Optional Subnet C**

    ```bash
    oregon_recovery_optional_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                --cidr-block $oregon_recovery_optional_subnetc_cidr \
                                                                --availability-zone us-west-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-OptionalSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_optional_subnetc_id
    ```

1. **Create Optional1 Subnet A**

    ```bash
    oregon_recovery_optional1_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                 --cidr-block $oregon_recovery_optional1_subneta_cidr \
                                                                 --availability-zone us-west-2a \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Optional1SubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_optional1_subneta_id
    ```

1. **Create Optional1 Subnet B**

    ```bash
    oregon_recovery_optional1_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                 --cidr-block $oregon_recovery_optional1_subnetb_cidr \
                                                                 --availability-zone us-west-2b \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Optional1SubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_optional1_subnetb_id
    ```

1. **Create Optional1 Subnet C**

    ```bash
    oregon_recovery_optional1_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                 --cidr-block $oregon_recovery_optional1_subnetc_cidr \
                                                                 --availability-zone us-west-2c \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-Optional1SubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_optional1_subnetc_id
    ```

1. **Create Directory Subnet A**

    ```bash
    oregon_recovery_directory_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                 --cidr-block $oregon_recovery_directory_subneta_cidr \
                                                                 --availability-zone us-west-2a \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-DirectorySubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_directory_subneta_id
    ```

1. **Create Directory Subnet B**

    ```bash
    oregon_recovery_directory_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                 --cidr-block $oregon_recovery_directory_subnetb_cidr \
                                                                 --availability-zone us-west-2b \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-DirectorySubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_directory_subnetb_id
    ```

1. **Create Directory Subnet C**

    ```bash
    oregon_recovery_directory_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                 --cidr-block $oregon_recovery_directory_subnetc_cidr \
                                                                 --availability-zone us-west-2c \
                                                                 --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-DirectorySubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_directory_subnetc_id
    ```

1. **Create Endpoint Subnet A**

    ```bash
    oregon_recovery_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                --cidr-block $oregon_recovery_endpoint_subneta_cidr \
                                                                --availability-zone us-west-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-EndpointSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_endpoint_subneta_id
    ```

1. **Create Endpoint Subnet B**

    ```bash
    oregon_recovery_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                --cidr-block $oregon_recovery_endpoint_subnetb_cidr \
                                                                --availability-zone us-west-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-EndpointSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_endpoint_subnetb_id
    ```

1. **Create Endpoint Subnet C**

    ```bash
    oregon_recovery_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                --cidr-block $oregon_recovery_endpoint_subnetc_cidr \
                                                                --availability-zone us-west-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-EndpointSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_endpoint_subnetc_id
    ```

1. **Create Firewall Subnet A**

    ```bash
    oregon_recovery_firewall_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                --cidr-block $oregon_recovery_firewall_subneta_cidr \
                                                                --availability-zone us-west-2a \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-FirewallSubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_firewall_subneta_id
    ```

1. **Create Firewall Subnet B**

    ```bash
    oregon_recovery_firewall_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                --cidr-block $oregon_recovery_firewall_subnetb_cidr \
                                                                --availability-zone us-west-2b \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-FirewallSubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_firewall_subnetb_id
    ```

1. **Create Firewall Subnet C**

    ```bash
    oregon_recovery_firewall_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                                --cidr-block $oregon_recovery_firewall_subnetc_cidr \
                                                                --availability-zone us-west-2c \
                                                                --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-FirewallSubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_firewall_subnetc_id
    ```

1. **Create Gateway Subnet A**

    ```bash
    oregon_recovery_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                               --cidr-block $oregon_recovery_gateway_subneta_cidr \
                                                               --availability-zone us-west-2a \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-GatewaySubnetA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_gateway_subneta_id
    ```

1. **Create Gateway Subnet B**

    ```bash
    oregon_recovery_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                               --cidr-block $oregon_recovery_gateway_subnetb_cidr \
                                                               --availability-zone us-west-2b \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-GatewaySubnetB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_gateway_subnetb_id
    ```

1. **Create Gateway Subnet C**

    ```bash
    oregon_recovery_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $oregon_recovery_vpc_id \
                                                               --cidr-block $oregon_recovery_gateway_subnetc_cidr \
                                                               --availability-zone us-west-2c \
                                                               --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Recovery-GatewaySubnetC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_gateway_subnetc_id
    ```

1. **Create Public Route Table, Default Route and Associate with Public Subnets**

    ```bash
    oregon_recovery_public_rtb_id=$(aws ec2 create-route-table --vpc-id $oregon_recovery_vpc_id \
                                                               --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Recovery-PublicRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'RouteTable.RouteTableId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_public_rtb_id

    aws ec2 create-route --route-table-id $oregon_recovery_public_rtb_id \
                         --destination-cidr-block '0.0.0.0/0' \
                         --gateway-id $oregon_recovery_igw_id \
                         --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_public_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_public_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_public_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_public1_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_public1_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_public1_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_public7_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_public7_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_public7_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_web_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_web_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_web_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_web1_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_web1_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_web1_subnetc_id \
                                  --profile $profile --region us-west-2 --output text

    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_web7_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_web7_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_public_rtb_id --subnet-id $oregon_recovery_web7_subnetc_id \
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
      oregon_recovery_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                          --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Recovery-NAT-EIPA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                          --query 'AllocationId' \
                                                          --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_recovery_ngw_eipa

      oregon_recovery_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $oregon_recovery_ngw_eipa \
                                                           --subnet-id $oregon_recovery_public_subneta_id \
                                                           --client-token $(date +%s) \
                                                           --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Recovery-NAT-GatewayA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                           --query 'NatGateway.NatGatewayId' \
                                                           --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_recovery_ngwa_id

      if [ $ha_ngw = 1 ]; then
        oregon_recovery_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                            --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Recovery-NAT-EIPB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'AllocationId' \
                                                            --profile $profile --region us-west-2 --output text)
        camelz-variable oregon_recovery_ngw_eipb

        oregon_recovery_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $oregon_recovery_ngw_eipb \
                                                             --subnet-id $oregon_recovery_public_subnetb_id \
                                                             --client-token $(date +%s) \
                                                             --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Recovery-NAT-GatewayB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'NatGateway.NatGatewayId' \
                                                             --profile $profile --region us-west-2 --output text)
        camelz-variable oregon_recovery_ngwb_id

        oregon_recovery_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                            --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=Recovery-NAT-EIPC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                            --query 'AllocationId' \
                                                            --profile $profile --region us-west-2 --output text)
        camelz-variable oregon_recovery_ngw_eipc

        oregon_recovery_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $oregon_recovery_ngw_eipc \
                                                             --subnet-id $oregon_recovery_public_subnetc_id \
                                                             --client-token $(date +%s) \
                                                             --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Recovery-NAT-GatewayC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                             --query 'NatGateway.NatGatewayId' \
                                                             --profile $profile --region us-west-2 --output text)
        camelz-variable oregon_recovery_ngwc_id
      fi
    else
      # Create NAT Security Group
      oregon_recovery_nat_sg_id=$(aws ec2 create-security-group --group-name Recovery-NAT-InstanceSecurityGroup \
                                                                --description Recovery-NAT-InstanceSecurityGroup \
                                                                --vpc-id $oregon_recovery_vpc_id \
                                                                --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Recovery-NAT-InstanceSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_recovery_nat_sg_id

      aws ec2 authorize-security-group-ingress --group-id $oregon_recovery_nat_sg_id \
                                               --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$oregon_recovery_vpc_cidr,Description=\"VPC (All)\"}]" \
                                               --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All)\"}]" \
                                               --profile $profile --region us-west-2 --output text

      # Create NAT Instance
      oregon_recovery_nat_instance_id=$(aws ec2 run-instances --image-id $oregon_nat_ami_id \
                                                              --instance-type t3a.nano \
                                                              --iam-instance-profile Name=ManagedInstance \
                                                              --key-name administrator \
                                                              --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Recovery-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$oregon_recovery_nat_sg_id],SubnetId=$oregon_recovery_public_subneta_id" \
                                                              --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Recovery-NAT-Instance},{Key=Hostname,Value=alfue2pnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Utility,Value=NAT},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'Instances[0].InstanceId' \
                                                              --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_recovery_nat_instance_id

      aws ec2 modify-instance-attribute --instance-id $oregon_recovery_nat_instance_id \
                                        --no-source-dest-check \
                                        --profile $profile --region us-west-2 --output text

      oregon_recovery_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $oregon_recovery_nat_instance_id \
                                                                       --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                       --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_recovery_nat_instance_eni_id

      oregon_recovery_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $oregon_recovery_nat_instance_id \
                                                                           --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                           --profile $profile --region us-west-2 --output text)
      camelz-variable oregon_recovery_nat_instance_private_ip
    fi
    ```

1. **Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets**

    ```bash
    oregon_recovery_private_rtba_id=$(aws ec2 create-route-table --vpc-id $oregon_recovery_vpc_id \
                                                                 --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Recovery-PrivateRouteTableA},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'RouteTable.RouteTableId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_private_rtba_id

    if [ $use_ngw = 1 ]; then
      aws ec2 create-route --route-table-id $oregon_recovery_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $oregon_recovery_ngwa_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $oregon_recovery_private_rtba_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $oregon_recovery_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_application_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_application1_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_application2_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_application3_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_cache_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_cache1_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_database_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_database1_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_optional_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_optional1_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_directory_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_endpoint_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_firewall_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtba_id --subnet-id $oregon_recovery_gateway_subneta_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1. **Create Private Route Table for Availability Zone B, Default Route and Associate with Private Subnets**

    ```bash
    oregon_recovery_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $oregon_recovery_vpc_id \
                                                                 --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Recovery-PrivateRouteTableB},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'RouteTable.RouteTableId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_private_rtbb_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then oregon_recovery_ngw_id=$oregon_recovery_ngwb_id; else oregon_recovery_ngw_id=$oregon_recovery_ngwa_id; fi
      aws ec2 create-route --route-table-id $oregon_recovery_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $oregon_recovery_ngw_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $oregon_recovery_private_rtbb_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $oregon_recovery_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_application_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_application1_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_application2_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_application3_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_cache_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_cache1_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_database_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_database1_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_optional_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_optional1_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_directory_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_endpoint_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_firewall_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbb_id --subnet-id $oregon_recovery_gateway_subnetb_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1. **Create Private Route Table for Availability Zone C, Default Route and Associate with Private Subnets**

    ```bash
    oregon_recovery_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $oregon_recovery_vpc_id \
                                                                 --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Recovery-PrivateRouteTableC},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                 --query 'RouteTable.RouteTableId' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_private_rtbc_id

    if [ $use_ngw = 1 ]; then
      if [ $ha_ngw = 1 ]; then oregon_recovery_ngw_id=$oregon_recovery_ngwc_id; else oregon_recovery_ngw_id=$oregon_recovery_ngwa_id; fi
      aws ec2 create-route --route-table-id $oregon_recovery_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --gateway-id $oregon_recovery_ngw_id \
                           --profile $profile --region us-west-2 --output text
    else
      aws ec2 create-route --route-table-id $oregon_recovery_private_rtbc_id \
                           --destination-cidr-block '0.0.0.0/0' \
                           --network-interface-id $oregon_recovery_nat_instance_eni_id \
                           --profile $profile --region us-west-2 --output text
    fi

    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_application_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_application1_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_application2_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_application3_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_cache_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_cache1_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_database_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_database1_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_optional_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_optional1_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_directory_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_endpoint_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_firewall_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    aws ec2 associate-route-table --route-table-id $oregon_recovery_private_rtbc_id --subnet-id $oregon_recovery_gateway_subnetc_id \
                                  --profile $profile --region us-west-2 --output text
    ```

1. **Create VPC Endpoint Security Group**

    ```bash
    oregon_recovery_vpce_sg_id=$(aws ec2 create-security-group --group-name Recovery-VPCEndpointSecurityGroup \
                                                               --description Recovery-VPCEndpointSecurityGroup \
                                                               --vpc-id $oregon_recovery_vpc_id \
                                                               --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Recovery-VPCEndpointSecurityGroup},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'GroupId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_vpce_sg_id

    aws ec2 authorize-security-group-ingress --group-id $oregon_recovery_vpce_sg_id \
                                             --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$oregon_recovery_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All TCP)\"}]" \
                                             --profile $profile --region us-west-2 --output text

    aws ec2 authorize-security-group-ingress --group-id $oregon_recovery_vpce_sg_id \
                                             --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$oregon_recovery_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                             --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=\"VPC (All UDP)\"}]" \
                                             --profile $profile --region us-west-2 --output text
    ```

1. **Create VPC Endpoints for SSM and SSMMessages**

    ```bash
    oregon_recovery_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $oregon_recovery_vpc_id \
                                                              --vpc-endpoint-type Interface \
                                                              --service-name com.amazonaws.us-west-2.ssm \
                                                              --private-dns-enabled \
                                                              --security-group-ids $oregon_recovery_vpce_sg_id \
                                                              --subnet-ids $oregon_recovery_endpoint_subneta_id $oregon_recovery_endpoint_subnetb_id $oregon_recovery_endpoint_subnetc_id \
                                                              --client-token $(date +%s) \
                                                              --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Recovery-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                              --query 'VpcEndpoint.VpcEndpointId' \
                                                              --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_ssm_vpce_id

    oregon_recovery_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $oregon_recovery_vpc_id \
                                                               --vpc-endpoint-type Interface \
                                                               --service-name com.amazonaws.us-west-2.ssmmessages \
                                                               --private-dns-enabled \
                                                               --security-group-ids $oregon_recovery_vpce_sg_id \
                                                               --subnet-ids $oregon_recovery_endpoint_subneta_id $oregon_recovery_endpoint_subnetb_id $oregon_recovery_endpoint_subnetc_id \
                                                               --client-token $(date +%s) \
                                                               --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Recovery-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                               --query 'VpcEndpoint.VpcEndpointId' \
                                                               --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_recovery_ssmm_vpce_id
    ```
