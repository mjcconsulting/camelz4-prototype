#!/usr/bin/env bash
#
# This is part of a set of scripts to setup a realistic CaMeLz Prototype which uses multiple Accounts, VPCs and
# Transit Gateway to connect them all
#
# You will need to sign up for the "Cisco Cloud Services Router (CSR) 1000V - BYOL for Maximum Performance" Marketplace AMI
# in the Management Account (or the account where you will run simulated customer on-prem locations).
#
# Using words which correspond to the NATO Phonetic Alphabet for simulated company examples (i.e. Alfa, Bravo, Charlie, ..., Zulu)
#

echo "This script has not been tested to run non-interactively. It has no error handling, re-try or restart logic."
echo "You must paste the commands in this script one by one into a terminal, and manually handle errors and re-try."
exit 1

echo "#######################################################################################################################"
echo "## STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP STOP     ##"
echo "#######################################################################################################################"
echo "## All prior scripts in the run order must be run before you run this script                                        ##"
echo "#######################################################################################################################"

#######################################################################################################################
## VPCs ###############################################################################################################
#######################################################################################################################

## Global Management VPC #####################################################################################################
echo "management_account_id=$management_account_id"

profile=$management_profile

# Create VPC
global_management_vpc_id=$(aws ec2 create-vpc --cidr-block $global_management_vpc_cidr \
                                              --query 'Vpc.VpcId' \
                                              --profile $profile --region us-east-1 --output text)
echo "global_management_vpc_id=$global_management_vpc_id"

aws ec2 create-tags --resources $global_management_vpc_id \
                    --tags Key=Name,Value=Management-VPC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $global_management_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $global_management_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-1 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Management/Global" \
                          --profile $profile --region us-east-1 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $global_management_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-1:$management_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Management/Global" \
                         --deliver-logs-permission-arn "arn:aws:iam::$management_account_id:role/FlowLog" \
                         --profile $profile --region us-east-1 --output text

# Create Internet Gateway & Attach
global_management_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                           --profile $profile --region us-east-1 --output text)
echo "global_management_igw_id=$global_management_igw_id"

aws ec2 create-tags --resources $global_management_igw_id \
                    --tags Key=Name,Value=Management-InternetGateway \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 attach-internet-gateway --vpc-id $global_management_vpc_id \
                                --internet-gateway-id $global_management_igw_id \
                                --profile $profile --region us-east-1 --output text

# Create Private Hosted Zone
global_management_private_hostedzone_id=$(aws route53 create-hosted-zone --name $global_management_private_domain \
                                                                         --vpc VPCRegion=us-east-1,VPCId=$global_management_vpc_id \
                                                                         --hosted-zone-config Comment="Private Zone for $global_management_private_domain",PrivateZone=true \
                                                                         --caller-reference $(date +%s) \
                                                                         --query 'HostedZone.Id' \
                                                                         --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "global_management_private_hostedzone_id=$global_management_private_hostedzone_id"

# Create DHCP Options Set
global_management_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$global_management_private_domain]" \
                                                                              "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                        --query 'DhcpOptions.DhcpOptionsId' \
                                                        --profile $profile --region us-east-1 --output text)
echo "global_management_dopt_id=$global_management_dopt_id"

aws ec2 create-tags --resources $global_management_dopt_id \
                    --tags Key=Name,Value=Management-DHCPOptions \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 associate-dhcp-options --vpc-id $global_management_vpc_id \
                               --dhcp-options-id $global_management_dopt_id \
                               --profile $profile --region us-east-1 --output text

# Create Public Subnet A
global_management_public_subneta_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                            --cidr-block $global_management_subnet_publica_cidr \
                                                            --availability-zone us-east-1a \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-1 --output text)
echo "global_management_public_subneta_id=$global_management_public_subneta_id"

aws ec2 create-tags --resources $global_management_public_subneta_id \
                    --tags Key=Name,Value=Management-PublicSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Public Subnet B
global_management_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                            --cidr-block $global_management_subnet_publicb_cidr \
                                                            --availability-zone us-east-1b \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-1 --output text)
echo "global_management_public_subnetb_id=$global_management_public_subnetb_id"

aws ec2 create-tags --resources $global_management_public_subnetb_id \
                    --tags Key=Name,Value=Management-PublicSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Public Subnet C
global_management_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                            --cidr-block $global_management_subnet_publicc_cidr \
                                                            --availability-zone us-east-1c \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-1 --output text)
echo "global_management_public_subnetc_id=$global_management_public_subnetc_id"

aws ec2 create-tags --resources $global_management_public_subnetc_id \
                    --tags Key=Name,Value=Management-PublicSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Web Subnet A
global_management_web_subneta_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                         --cidr-block $global_management_subnet_weba_cidr \
                                                         --availability-zone us-east-1a \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-1 --output text)
echo "global_management_web_subneta_id=$global_management_web_subneta_id"

aws ec2 create-tags --resources $global_management_web_subneta_id \
                    --tags Key=Name,Value=Management-WebSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Web Subnet B
global_management_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                         --cidr-block $global_management_subnet_webb_cidr \
                                                         --availability-zone us-east-1b \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-1 --output text)
echo "global_management_web_subnetb_id=$global_management_web_subnetb_id"

aws ec2 create-tags --resources $global_management_web_subnetb_id \
                    --tags Key=Name,Value=Management-WebSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Web Subnet C
global_management_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                         --cidr-block $global_management_subnet_webc_cidr \
                                                         --availability-zone us-east-1c \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-1 --output text)
echo "global_management_web_subnetc_id=$global_management_web_subnetc_id"

aws ec2 create-tags --resources $global_management_web_subnetc_id \
                    --tags Key=Name,Value=Management-WebSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Application Subnet A
global_management_application_subneta_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                                 --cidr-block $global_management_subnet_applicationa_cidr \
                                                                 --availability-zone us-east-1a \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-1 --output text)
echo "global_management_application_subneta_id=$global_management_application_subneta_id"

aws ec2 create-tags --resources $global_management_application_subneta_id \
                    --tags Key=Name,Value=Management-ApplicationSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Application Subnet B
global_management_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                                 --cidr-block $global_management_subnet_applicationb_cidr \
                                                                 --availability-zone us-east-1b \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-1 --output text)
echo "global_management_application_subnetb_id=$global_management_application_subnetb_id"

aws ec2 create-tags --resources $global_management_application_subnetb_id \
                    --tags Key=Name,Value=Management-ApplicationSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Application Subnet C
global_management_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                                 --cidr-block $global_management_subnet_applicationc_cidr \
                                                                 --availability-zone us-east-1c \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-1 --output text)
echo "global_management_application_subnetc_id=$global_management_application_subnetc_id"

aws ec2 create-tags --resources $global_management_application_subnetc_id \
                    --tags Key=Name,Value=Management-ApplicationSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Database Subnet A
global_management_database_subneta_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                              --cidr-block $global_management_subnet_databasea_cidr \
                                                              --availability-zone us-east-1a \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-1 --output text)
echo "global_management_database_subneta_id=$global_management_database_subneta_id"

aws ec2 create-tags --resources $global_management_database_subneta_id \
                    --tags Key=Name,Value=Management-DatabaseSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Database Subnet B
global_management_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                              --cidr-block $global_management_subnet_databaseb_cidr \
                                                              --availability-zone us-east-1b \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-1 --output text)
echo "global_management_database_subnetb_id=$global_management_database_subnetb_id"

aws ec2 create-tags --resources $global_management_database_subnetb_id \
                    --tags Key=Name,Value=Management-DatabaseSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Database Subnet C
global_management_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                              --cidr-block $global_management_subnet_databasec_cidr \
                                                              --availability-zone us-east-1c \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-1 --output text)
echo "global_management_database_subnetc_id=$global_management_database_subnetc_id"

aws ec2 create-tags --resources $global_management_database_subnetc_id \
                    --tags Key=Name,Value=Management-DatabaseSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Directory Subnet A
global_management_directory_subneta_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                               --cidr-block $global_management_subnet_directorya_cidr \
                                                               --availability-zone us-east-1a \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-1 --output text)
echo "global_management_directory_subneta_id=$global_management_directory_subneta_id"

aws ec2 create-tags --resources $global_management_directory_subneta_id \
                    --tags Key=Name,Value=Management-DirectorySubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Directory Subnet B
global_management_directory_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                               --cidr-block $global_management_subnet_directoryb_cidr \
                                                               --availability-zone us-east-1b \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-1 --output text)
echo "global_management_directory_subnetb_id=$global_management_directory_subnetb_id"

aws ec2 create-tags --resources $global_management_directory_subnetb_id \
                    --tags Key=Name,Value=Management-DirectorySubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Directory Subnet C
global_management_directory_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                               --cidr-block $global_management_subnet_directoryc_cidr \
                                                               --availability-zone us-east-1c \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-1 --output text)
echo "global_management_directory_subnetc_id=$global_management_directory_subnetc_id"

aws ec2 create-tags --resources $global_management_directory_subnetc_id \
                    --tags Key=Name,Value=Management-DirectorySubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Management Subnet A
global_management_management_subneta_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                                --cidr-block $global_management_subnet_managementa_cidr \
                                                                --availability-zone us-east-1a \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-1 --output text)
echo "global_management_management_subneta_id=$global_management_management_subneta_id"

aws ec2 create-tags --resources $global_management_management_subneta_id \
                    --tags Key=Name,Value=Management-ManagementSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Management Subnet B
global_management_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                                --cidr-block $global_management_subnet_managementb_cidr \
                                                                --availability-zone us-east-1b \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-1 --output text)
echo "global_management_management_subnetb_id=$global_management_management_subnetb_id"

aws ec2 create-tags --resources $global_management_management_subnetb_id \
                    --tags Key=Name,Value=Management-ManagementSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Management Subnet C
global_management_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                                --cidr-block $global_management_subnet_managementc_cidr \
                                                                --availability-zone us-east-1c \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-1 --output text)
echo "global_management_management_subnetc_id=$global_management_management_subnetc_id"

aws ec2 create-tags --resources $global_management_management_subnetc_id \
                    --tags Key=Name,Value=Management-ManagementSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Gateway Subnet A
global_management_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                             --cidr-block $global_management_subnet_gatewaya_cidr \
                                                             --availability-zone us-east-1a \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-1 --output text)
echo "global_management_gateway_subneta_id=$global_management_gateway_subneta_id"

aws ec2 create-tags --resources $global_management_gateway_subneta_id \
                    --tags Key=Name,Value=Management-GatewaySubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Gateway Subnet B
global_management_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                             --cidr-block $global_management_subnet_gatewayb_cidr \
                                                             --availability-zone us-east-1b \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-1 --output text)
echo "global_management_gateway_subnetb_id=$global_management_gateway_subnetb_id"

aws ec2 create-tags --resources $global_management_gateway_subnetb_id \
                    --tags Key=Name,Value=Management-GatewaySubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Gateway Subnet C
global_management_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                             --cidr-block $global_management_subnet_gatewayc_cidr \
                                                             --availability-zone us-east-1c \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-1 --output text)
echo "global_management_gateway_subnetc_id=$global_management_gateway_subnetc_id"

aws ec2 create-tags --resources $global_management_gateway_subnetc_id \
                    --tags Key=Name,Value=Management-GatewaySubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Endpoint Subnet A
global_management_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                              --cidr-block $global_management_subnet_endpointa_cidr \
                                                              --availability-zone us-east-1a \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-1 --output text)
echo "global_management_endpoint_subneta_id=$global_management_endpoint_subneta_id"

aws ec2 create-tags --resources $global_management_endpoint_subneta_id \
                    --tags Key=Name,Value=Management-EndpointSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Endpoint Subnet B
global_management_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                              --cidr-block $global_management_subnet_endpointb_cidr \
                                                              --availability-zone us-east-1b \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-1 --output text)
echo "global_management_endpoint_subnetb_id=$global_management_endpoint_subnetb_id"

aws ec2 create-tags --resources $global_management_endpoint_subnetb_id \
                    --tags Key=Name,Value=Management-EndpointSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Endpoint Subnet C
global_management_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_management_vpc_id \
                                                              --cidr-block $global_management_subnet_endpointc_cidr \
                                                              --availability-zone us-east-1c \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-1 --output text)
echo "global_management_endpoint_subnetc_id=$global_management_endpoint_subnetc_id"

aws ec2 create-tags --resources $global_management_endpoint_subnetc_id \
                    --tags Key=Name,Value=Management-EndpointSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
global_management_public_rtb_id=$(aws ec2 create-route-table --vpc-id $global_management_vpc_id \
                                                             --query 'RouteTable.RouteTableId' \
                                                             --profile $profile --region us-east-1 --output text)
echo "global_management_public_rtb_id=$global_management_public_rtb_id"

aws ec2 create-tags --resources $global_management_public_rtb_id \
                    --tags Key=Name,Value=Management-PublicRouteTable \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 create-route --route-table-id $global_management_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $global_management_igw_id \
                     --profile $profile --region us-east-1 --output text

aws ec2 associate-route-table --route-table-id $global_management_public_rtb_id --subnet-id $global_management_public_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_public_rtb_id --subnet-id $global_management_public_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_public_rtb_id --subnet-id $global_management_public_subnetc_id \
                              --profile $profile --region us-east-1 --output text

aws ec2 associate-route-table --route-table-id $global_management_public_rtb_id --subnet-id $global_management_web_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_public_rtb_id --subnet-id $global_management_web_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_public_rtb_id --subnet-id $global_management_web_subnetc_id \
                              --profile $profile --region us-east-1 --output text

# Create NAT Gateways
if [ $use_ngw = 1 ]; then
  global_management_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                        --query 'AllocationId' \
                                                        --profile $profile --region us-east-1 --output text)
  echo "global_management_ngw_eipa=$global_management_ngw_eipa"

  aws ec2 create-tags --resources $global_management_ngw_eipa \
                      --tags Key=Name,Value=Management-NAT-EIPA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-1 --output text

  global_management_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $global_management_ngw_eipa \
                                                        --subnet-id $global_management_public_subneta_id \
                                                        --client-token $(date +%s) \
                                                        --query 'NatGateway.NatGatewayId' \
                                                        --profile $profile --region us-east-1 --output text)
  echo "global_management_ngwa_id=$global_management_ngwa_id"

  aws ec2 create-tags --resources $global_management_ngwa_id \
                      --tags Key=Name,Value=Management-NAT-GatewayA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-1 --output text

  if [ $ha_ngw = 1 ]; then
    global_management_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                          --query 'AllocationId' \
                                                          --profile $profile --region us-east-1 --output text)
    echo "global_management_ngw_eipb=$global_management_ngw_eipb"

    aws ec2 create-tags --resources $global_management_ngw_eipb \
                        --tags Key=Name,Value=Management-NAT-EIPB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-1 --output text

    global_management_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $global_management_ngw_eipb \
                                                           --subnet-id $global_management_public_subnetb_id \
                                                           --client-token $(date +%s) \
                                                           --query 'NatGateway.NatGatewayId' \
                                                           --profile $profile --region us-east-1 --output text)
    echo "global_management_ngwb_id=$global_management_ngwb_id"

    aws ec2 create-tags --resources $global_management_ngwb_id \
                        --tags Key=Name,Value=Management-NAT-GatewayB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-1 --output text

    global_management_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                          --query 'AllocationId' \
                                                          --profile $profile --region us-east-1 --output text)
    echo "global_management_ngw_eipc=$global_management_ngw_eipc"

    aws ec2 create-tags --resources $global_management_ngw_eipc \
                        --tags Key=Name,Value=Management-NAT-EIPC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-1 --output text

    global_management_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $global_management_ngw_eipc \
                                                           --subnet-id $global_management_public_subnetc_id \
                                                           --client-token $(date +%s) \
                                                           --query 'NatGateway.NatGatewayId' \
                                                           --profile $profile --region us-east-1 --output text)
    echo "global_management_ngwc_id=$global_management_ngwc_id"

    aws ec2 create-tags --resources $global_management_ngwc_id \
                        --tags Key=Name,Value=Management-NAT-GatewayC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-1 --output text
  fi
else
  # Create NAT Security Group
  global_management_nat_sg_id=$(aws ec2 create-security-group --group-name Management-NAT-InstanceSecurityGroup \
                                                              --description Management-NAT-InstanceSecurityGroup \
                                                              --vpc-id $global_management_vpc_id \
                                                              --query 'GroupId' \
                                                              --profile $profile --region us-east-1 --output text)
  echo "global_management_nat_sg_id=$global_management_nat_sg_id"

  aws ec2 create-tags --resources $global_management_nat_sg_id \
                      --tags Key=Name,Value=Management-NAT-InstanceSecurityGroup \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Utility,Value=NAT \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-1 --output text

  aws ec2 authorize-security-group-ingress --group-id $global_management_nat_sg_id \
                                           --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$global_management_vpc_cidr,Description=\"VPC (All)\"}]" \
                                           --profile $profile --region us-east-1 --output text

  # Create NAT Instance
  global_management_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                            --instance-type t3a.nano \
                                                            --iam-instance-profile Name=ManagedInstance \
                                                            --key-name administrator \
                                                            --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Management-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_management_nat_sg_id],SubnetId=$global_management_public_subneta_id" \
                                                            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Management-NAT-Instance},{Key=Hostname,Value=cmlue1mnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                            --query 'Instances[0].InstanceId' \
                                                            --profile $profile --region us-east-1 --output text)
  echo "global_management_nat_instance_id=$global_management_nat_instance_id"

  aws ec2 modify-instance-attribute --instance-id $global_management_nat_instance_id \
                                    --no-source-dest-check \
                                    --profile $profile --region us-east-1 --output text

  global_management_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $global_management_nat_instance_id \
                                                                     --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                     --profile $profile --region us-east-1 --output text)
  echo "global_management_nat_instance_eni_id=$global_management_nat_instance_eni_id"

  global_management_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $global_management_nat_instance_id \
                                                                         --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                         --profile $profile --region us-east-1 --output text)
  echo "global_management_nat_instance_private_ip=$global_management_nat_instance_private_ip"
fi

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
global_management_private_rtba_id=$(aws ec2 create-route-table --vpc-id $global_management_vpc_id \
                                                               --query 'RouteTable.RouteTableId' \
                                                               --profile $profile --region us-east-1 --output text)
echo "global_management_private_rtba_id=$global_management_private_rtba_id"

aws ec2 create-tags --resources $global_management_private_rtba_id \
                    --tags Key=Name,Value=Management-PrivateRouteTableA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

if [ $use_ngw = 1 ]; then
  aws ec2 create-route --route-table-id $global_management_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $global_management_ngwa_id \
                       --profile $profile --region us-east-1 --output text
else
  aws ec2 create-route --route-table-id $global_management_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $global_management_nat_instance_eni_id \
                       --profile $profile --region us-east-1 --output text
fi

aws ec2 associate-route-table --route-table-id $global_management_private_rtba_id --subnet-id $global_management_application_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtba_id --subnet-id $global_management_database_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtba_id --subnet-id $global_management_directory_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtba_id --subnet-id $global_management_management_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtba_id --subnet-id $global_management_gateway_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtba_id --subnet-id $global_management_endpoint_subneta_id \
                              --profile $profile --region us-east-1 --output text

global_management_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $global_management_vpc_id \
                                                               --query 'RouteTable.RouteTableId' \
                                                               --profile $profile --region us-east-1 --output text)
echo "global_management_private_rtbb_id=$global_management_private_rtbb_id"

aws ec2 create-tags --resources $global_management_private_rtbb_id \
                    --tags Key=Name,Value=Management-PrivateRouteTableB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then global_management_ngw_id=$global_management_ngwb_id; else global_management_ngw_id=$global_management_ngwa_id; fi
  aws ec2 create-route --route-table-id $global_management_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $global_management_ngw_id \
                       --profile $profile --region us-east-1 --output text
else
  aws ec2 create-route --route-table-id $global_management_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $global_management_nat_instance_eni_id \
                       --profile $profile --region us-east-1 --output text
fi

aws ec2 associate-route-table --route-table-id $global_management_private_rtbb_id --subnet-id $global_management_application_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtbb_id --subnet-id $global_management_database_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtbb_id --subnet-id $global_management_directory_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtbb_id --subnet-id $global_management_management_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtbb_id --subnet-id $global_management_gateway_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtbb_id --subnet-id $global_management_endpoint_subnetb_id \
                              --profile $profile --region us-east-1 --output text

global_management_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $global_management_vpc_id \
                                                               --query 'RouteTable.RouteTableId' \
                                                               --profile $profile --region us-east-1 --output text)
echo "global_management_private_rtbc_id=$global_management_private_rtbc_id"

aws ec2 create-tags --resources $global_management_private_rtbc_id \
                    --tags Key=Name,Value=Management-PrivateRouteTableC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then global_management_ngw_id=$global_management_ngwc_id; else global_management_ngw_id=$global_management_ngwa_id; fi
  aws ec2 create-route --route-table-id $global_management_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $global_management_ngw_id \
                       --profile $profile --region us-east-1 --output text
else
  aws ec2 create-route --route-table-id $global_management_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $global_management_nat_instance_eni_id \
                       --profile $profile --region us-east-1 --output text
fi

aws ec2 associate-route-table --route-table-id $global_management_private_rtbc_id --subnet-id $global_management_application_subnetc_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtbc_id --subnet-id $global_management_database_subnetc_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtbc_id --subnet-id $global_management_directory_subnetc_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtbc_id --subnet-id $global_management_management_subnetc_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtbc_id --subnet-id $global_management_gateway_subnetc_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_management_private_rtbc_id --subnet-id $global_management_endpoint_subnetc_id \
                              --profile $profile --region us-east-1 --output text

# Create VPC Endpoint Security Group
global_management_vpce_sg_id=$(aws ec2 create-security-group --group-name Management-VPCEndpointSecurityGroup \
                                                             --description Management-VPCEndpointSecurityGroup \
                                                             --vpc-id $global_management_vpc_id \
                                                             --query 'GroupId' \
                                                             --profile $profile --region us-east-1 --output text)
echo "global_management_vpce_sg_id=$global_management_vpce_sg_id"

aws ec2 create-tags --resources $global_management_vpce_sg_id \
                    --tags Key=Name,Value=Management-VPCEndpointSecurityGroup \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_management_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$global_management_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_management_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$global_management_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

# Create VPC Endpoints for SSM and SSMMessages
global_management_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $global_management_vpc_id \
                                                            --vpc-endpoint-type Interface \
                                                            --service-name com.amazonaws.us-east-1.ssm \
                                                            --private-dns-enabled \
                                                            --security-group-ids $global_management_vpce_sg_id \
                                                            --subnet-ids $global_management_endpoint_subneta_id $global_management_endpoint_subnetb_id $global_management_endpoint_subnetc_id \
                                                            --client-token $(date +%s) \
                                                            --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Management-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                            --query 'VpcEndpoint.VpcEndpointId' \
                                                            --profile $profile --region us-east-1 --output text)
echo "global_management_ssm_vpce_id=$global_management_ssm_vpce_id"

global_management_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $global_management_vpc_id \
                                                             --vpc-endpoint-type Interface \
                                                             --service-name com.amazonaws.us-east-1.ssmmessages \
                                                             --private-dns-enabled \
                                                             --security-group-ids $global_management_vpce_sg_id \
                                                             --subnet-ids $global_management_endpoint_subneta_id $global_management_endpoint_subnetb_id $global_management_endpoint_subnetc_id \
                                                             --client-token $(date +%s) \
                                                             --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Management-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                             --query 'VpcEndpoint.VpcEndpointId' \
                                                             --profile $profile --region us-east-1 --output text)
echo "global_management_ssmm_vpce_id=$global_management_ssmm_vpce_id"


## Global Core VPC ####################################################################################################
echo "core_account_id=$core_account_id"

profile=$core_profile

# Create VPC
global_core_vpc_id=$(aws ec2 create-vpc --cidr-block $global_core_vpc_cidr \
                                        --query 'Vpc.VpcId' \
                                        --profile $profile --region us-east-1 --output text)
echo "global_core_vpc_id=$global_core_vpc_id"

aws ec2 create-tags --resources $global_core_vpc_id \
                    --tags Key=Name,Value=Core-VPC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $global_core_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $global_core_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-1 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Core/Global" \
                          --profile $profile --region us-east-1 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $global_core_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-1:$core_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Core/Global" \
                         --deliver-logs-permission-arn "arn:aws:iam::$core_account_id:role/FlowLog" \
                         --profile $profile --region us-east-1 --output text

# Create Internet Gateway & Attach
global_core_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                     --profile $profile --region us-east-1 --output text)
echo "global_core_igw_id=$global_core_igw_id"

aws ec2 create-tags --resources $global_core_igw_id \
                    --tags Key=Name,Value=Core-InternetGateway \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 attach-internet-gateway --vpc-id $global_core_vpc_id \
                                --internet-gateway-id $global_core_igw_id \
                                --profile $profile --region us-east-1 --output text

# Create Private Hosted Zone
global_core_private_hostedzone_id=$(aws route53 create-hosted-zone --name $global_core_private_domain \
                                                                   --vpc VPCRegion=us-east-1,VPCId=$global_core_vpc_id \
                                                                   --hosted-zone-config Comment="Private Zone for $global_core_private_domain",PrivateZone=true \
                                                                   --caller-reference $(date +%s) \
                                                                   --query 'HostedZone.Id' \
                                                                   --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "global_core_private_hostedzone_id=$global_core_private_hostedzone_id"

# Create DHCP Options Set
global_core_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$global_core_private_domain]" \
                                                                        "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                  --query 'DhcpOptions.DhcpOptionsId' \
                                                  --profile $profile --region us-east-1 --output text)
echo "global_core_dopt_id=$global_core_dopt_id"

aws ec2 create-tags --resources $global_core_dopt_id \
                    --tags Key=Name,Value=Core-DHCPOptions \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 associate-dhcp-options --vpc-id $global_core_vpc_id \
                               --dhcp-options-id $global_core_dopt_id \
                               --profile $profile --region us-east-1 --output text

# Create Public Subnet A
global_core_public_subneta_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                      --cidr-block $global_core_subnet_publica_cidr \
                                                      --availability-zone us-east-1a \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-1 --output text)
echo "global_core_public_subneta_id=$global_core_public_subneta_id"

aws ec2 create-tags --resources $global_core_public_subneta_id \
                    --tags Key=Name,Value=Core-PublicSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Public Subnet B
global_core_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                      --cidr-block $global_core_subnet_publicb_cidr \
                                                      --availability-zone us-east-1b \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-1 --output text)
echo "global_core_public_subnetb_id=$global_core_public_subnetb_id"

aws ec2 create-tags --resources $global_core_public_subnetb_id \
                    --tags Key=Name,Value=Core-PublicSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Public Subnet C
global_core_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                      --cidr-block $global_core_subnet_publicc_cidr \
                                                      --availability-zone us-east-1c \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-1 --output text)
echo "global_core_public_subnetc_id=$global_core_public_subnetc_id"

aws ec2 create-tags --resources $global_core_public_subnetc_id \
                    --tags Key=Name,Value=Core-PublicSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Web Subnet A
global_core_web_subneta_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                   --cidr-block $global_core_subnet_weba_cidr \
                                                   --availability-zone us-east-1a \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-1 --output text)
echo "global_core_web_subneta_id=$global_core_web_subneta_id"

aws ec2 create-tags --resources $global_core_web_subneta_id \
                    --tags Key=Name,Value=Core-WebSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Web Subnet B
global_core_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                   --cidr-block $global_core_subnet_webb_cidr \
                                                   --availability-zone us-east-1b \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-1 --output text)
echo "global_core_web_subnetb_id=$global_core_web_subnetb_id"

aws ec2 create-tags --resources $global_core_web_subnetb_id \
                    --tags Key=Name,Value=Core-WebSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Web Subnet C
global_core_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                   --cidr-block $global_core_subnet_webc_cidr \
                                                   --availability-zone us-east-1c \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-1 --output text)
echo "global_core_web_subnetc_id=$global_core_web_subnetc_id"

aws ec2 create-tags --resources $global_core_web_subnetc_id \
                    --tags Key=Name,Value=Core-WebSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Application Subnet A
global_core_application_subneta_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                           --cidr-block $global_core_subnet_applicationa_cidr \
                                                           --availability-zone us-east-1a \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-1 --output text)
echo "global_core_application_subneta_id=$global_core_application_subneta_id"

aws ec2 create-tags --resources $global_core_application_subneta_id \
                    --tags Key=Name,Value=Core-ApplicationSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Application Subnet B
global_core_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                           --cidr-block $global_core_subnet_applicationb_cidr \
                                                           --availability-zone us-east-1b \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-1 --output text)
echo "global_core_application_subnetb_id=$global_core_application_subnetb_id"

aws ec2 create-tags --resources $global_core_application_subnetb_id \
                    --tags Key=Name,Value=Core-ApplicationSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Application Subnet C
global_core_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                           --cidr-block $global_core_subnet_applicationc_cidr \
                                                           --availability-zone us-east-1c \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-1 --output text)
echo "global_core_application_subnetc_id=$global_core_application_subnetc_id"

aws ec2 create-tags --resources $global_core_application_subnetc_id \
                    --tags Key=Name,Value=Core-ApplicationSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Database Subnet A
global_core_database_subneta_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                        --cidr-block $global_core_subnet_databasea_cidr \
                                                        --availability-zone us-east-1a \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-1 --output text)
echo "global_core_database_subneta_id=$global_core_database_subneta_id"

aws ec2 create-tags --resources $global_core_database_subneta_id \
                    --tags Key=Name,Value=Core-DatabaseSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Database Subnet B
global_core_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                        --cidr-block $global_core_subnet_databaseb_cidr \
                                                        --availability-zone us-east-1b \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-1 --output text)
echo "global_core_database_subnetb_id=$global_core_database_subnetb_id"

aws ec2 create-tags --resources $global_core_database_subnetb_id \
                    --tags Key=Name,Value=Core-DatabaseSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Database Subnet C
global_core_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                        --cidr-block $global_core_subnet_databasec_cidr \
                                                        --availability-zone us-east-1c \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-1 --output text)
echo "global_core_database_subnetc_id=$global_core_database_subnetc_id"

aws ec2 create-tags --resources $global_core_database_subnetc_id \
                    --tags Key=Name,Value=Core-DatabaseSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Management Subnet A
global_core_management_subneta_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                          --cidr-block $global_core_subnet_managementa_cidr \
                                                          --availability-zone us-east-1a \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-1 --output text)
echo "global_core_management_subneta_id=$global_core_management_subneta_id"

aws ec2 create-tags --resources $global_core_management_subneta_id \
                    --tags Key=Name,Value=Core-ManagementSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Management Subnet B
global_core_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                          --cidr-block $global_core_subnet_managementb_cidr \
                                                          --availability-zone us-east-1b \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-1 --output text)
echo "global_core_management_subnetb_id=$global_core_management_subnetb_id"

aws ec2 create-tags --resources $global_core_management_subnetb_id \
                    --tags Key=Name,Value=Core-ManagementSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Management Subnet C
global_core_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                          --cidr-block $global_core_subnet_managementc_cidr \
                                                          --availability-zone us-east-1c \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-1 --output text)
echo "global_core_management_subnetc_id=$global_core_management_subnetc_id"

aws ec2 create-tags --resources $global_core_management_subnetc_id \
                    --tags Key=Name,Value=Core-ManagementSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Gateway Subnet A
global_core_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                       --cidr-block $global_core_subnet_gatewaya_cidr \
                                                       --availability-zone us-east-1a \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-1 --output text)
echo "global_core_gateway_subneta_id=$global_core_gateway_subneta_id"

aws ec2 create-tags --resources $global_core_gateway_subneta_id \
                    --tags Key=Name,Value=Core-GatewaySubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Gateway Subnet B
global_core_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                       --cidr-block $global_core_subnet_gatewayb_cidr \
                                                       --availability-zone us-east-1b \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-1 --output text)
echo "global_core_gateway_subnetb_id=$global_core_gateway_subnetb_id"

aws ec2 create-tags --resources $global_core_gateway_subnetb_id \
                    --tags Key=Name,Value=Core-GatewaySubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Gateway Subnet C
global_core_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                       --cidr-block $global_core_subnet_gatewayc_cidr \
                                                       --availability-zone us-east-1c \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-1 --output text)
echo "global_core_gateway_subnetc_id=$global_core_gateway_subnetc_id"

aws ec2 create-tags --resources $global_core_gateway_subnetc_id \
                    --tags Key=Name,Value=Core-GatewaySubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Endpoint Subnet A
global_core_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                        --cidr-block $global_core_subnet_endpointa_cidr \
                                                        --availability-zone us-east-1a \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-1 --output text)
echo "global_core_endpoint_subneta_id=$global_core_endpoint_subneta_id"

aws ec2 create-tags --resources $global_core_endpoint_subneta_id \
                    --tags Key=Name,Value=Core-EndpointSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Endpoint Subnet B
global_core_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                        --cidr-block $global_core_subnet_endpointb_cidr \
                                                        --availability-zone us-east-1b \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-1 --output text)
echo "global_core_endpoint_subnetb_id=$global_core_endpoint_subnetb_id"

aws ec2 create-tags --resources $global_core_endpoint_subnetb_id \
                    --tags Key=Name,Value=Core-EndpointSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Endpoint Subnet C
global_core_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_core_vpc_id \
                                                        --cidr-block $global_core_subnet_endpointc_cidr \
                                                        --availability-zone us-east-1c \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-1 --output text)
echo "global_core_endpoint_subnetc_id=$global_core_endpoint_subnetc_id"

aws ec2 create-tags --resources $global_core_endpoint_subnetc_id \
                    --tags Key=Name,Value=Core-EndpointSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
global_core_public_rtb_id=$(aws ec2 create-route-table --vpc-id $global_core_vpc_id \
                                                       --query 'RouteTable.RouteTableId' \
                                                       --profile $profile --region us-east-1 --output text)
echo "global_core_public_rtb_id=$global_core_public_rtb_id"

aws ec2 create-tags --resources $global_core_public_rtb_id \
                    --tags Key=Name,Value=Core-PublicRouteTable \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 create-route --route-table-id $global_core_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $global_core_igw_id \
                     --profile $profile --region us-east-1 --output text

aws ec2 associate-route-table --route-table-id $global_core_public_rtb_id --subnet-id $global_core_public_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_public_rtb_id --subnet-id $global_core_public_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_public_rtb_id --subnet-id $global_core_public_subnetc_id \
                              --profile $profile --region us-east-1 --output text

aws ec2 associate-route-table --route-table-id $global_core_public_rtb_id --subnet-id $global_core_web_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_public_rtb_id --subnet-id $global_core_web_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_public_rtb_id --subnet-id $global_core_web_subnetc_id \
                              --profile $profile --region us-east-1 --output text

# Create NAT Gateways
if [ $use_ngw = 1 ]; then
  global_core_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                  --query 'AllocationId' \
                                                  --profile $profile --region us-east-1 --output text)
  echo "global_core_ngw_eipa=$global_core_ngw_eipa"

  aws ec2 create-tags --resources $global_core_ngw_eipa \
                      --tags Key=Name,Value=Core-NAT-EIPA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-1 --output text

  global_core_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $global_core_ngw_eipa \
                                                   --subnet-id $global_core_public_subneta_id \
                                                   --client-token $(date +%s) \
                                                   --query 'NatGateway.NatGatewayId' \
                                                   --profile $profile --region us-east-1 --output text)
  echo "global_core_ngwa_id=$global_core_ngwa_id"

  aws ec2 create-tags --resources $global_core_ngwa_id \
                      --tags Key=Name,Value=Core-NAT-GatewayA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-1 --output text

  if [ $ha_ngw = 1 ]; then
    global_core_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                    --query 'AllocationId' \
                                                    --profile $profile --region us-east-1 --output text)
    echo "global_core_ngw_eipb=$global_core_ngw_eipb"

    aws ec2 create-tags --resources $global_core_ngw_eipb \
                        --tags Key=Name,Value=Core-NAT-EIPB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-1 --output text

    global_core_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $global_core_ngw_eipb \
                                                     --subnet-id $global_core_public_subnetb_id \
                                                     --client-token $(date +%s) \
                                                     --query 'NatGateway.NatGatewayId' \
                                                     --profile $profile --region us-east-1 --output text)
    echo "global_core_ngwb_id=$global_core_ngwb_id"

    aws ec2 create-tags --resources $global_core_ngwb_id \
                        --tags Key=Name,Value=Core-NAT-GatewayB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-1 --output text

    global_core_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                    --query 'AllocationId' \
                                                    --profile $profile --region us-east-1 --output text)
    echo "global_core_ngw_eipc=$global_core_ngw_eipc"

    aws ec2 create-tags --resources $global_core_ngw_eipc \
                        --tags Key=Name,Value=Core-NAT-EIPC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-1 --output text

    global_core_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $global_core_ngw_eipc \
                                                     --subnet-id $global_core_public_subnetc_id \
                                                     --client-token $(date +%s) \
                                                     --query 'NatGateway.NatGatewayId' \
                                                     --profile $profile --region us-east-1 --output text)
    echo "global_core_ngwc_id=$global_core_ngwc_id"

    aws ec2 create-tags --resources $global_core_ngwc_id \
                        --tags Key=Name,Value=Core-NAT-GatewayC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-1 --output text
  fi
else
  # Create NAT Security Group
  global_core_nat_sg_id=$(aws ec2 create-security-group --group-name Core-NAT-InstanceSecurityGroup \
                                                        --description Core-NAT-InstanceSecurityGroup \
                                                        --vpc-id $global_core_vpc_id \
                                                        --query 'GroupId' \
                                                        --profile $profile --region us-east-1 --output text)
  echo "global_core_nat_sg_id=$global_core_nat_sg_id"

  aws ec2 create-tags --resources $global_core_nat_sg_id \
                      --tags Key=Name,Value=Core-NAT-InstanceSecurityGroup \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Utility,Value=NAT \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-1 --output text

  aws ec2 authorize-security-group-ingress --group-id $global_core_nat_sg_id \
                                           --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$global_core_vpc_cidr,Description=\"VPC (All)\"}]" \
                                           --profile $profile --region us-east-1 --output text

  # Create NAT Instance
  global_core_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                      --instance-type t3a.nano \
                                                      --iam-instance-profile Name=ManagedInstance \
                                                      --key-name administrator \
                                                      --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Core-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_core_nat_sg_id],SubnetId=$global_core_public_subneta_id" \
                                                      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Core-NAT-Instance},{Key=Hostname,Value=cmlue1cnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                      --query 'Instances[0].InstanceId' \
                                                      --profile $profile --region us-east-1 --output text)
  echo "global_core_nat_instance_id=$global_core_nat_instance_id"

  aws ec2 modify-instance-attribute --instance-id $global_core_nat_instance_id \
                                    --no-source-dest-check \
                                    --profile $profile --region us-east-1 --output text

  global_core_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $global_core_nat_instance_id \
                                                               --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                               --profile $profile --region us-east-1 --output text)
  echo "global_core_nat_instance_eni_id=$global_core_nat_instance_eni_id"

  global_core_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $global_core_nat_instance_id \
                                                                   --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                   --profile $profile --region us-east-1 --output text)
  echo "global_core_nat_instance_private_ip=$global_core_nat_instance_private_ip"
fi

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
global_core_private_rtba_id=$(aws ec2 create-route-table --vpc-id $global_core_vpc_id \
                                                         --query 'RouteTable.RouteTableId' \
                                                         --profile $profile --region us-east-1 --output text)
echo "global_core_private_rtba_id=$global_core_private_rtba_id"

aws ec2 create-tags --resources $global_core_private_rtba_id \
                    --tags Key=Name,Value=Core-PrivateRouteTableA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

if [ $use_ngw = 1 ]; then
  aws ec2 create-route --route-table-id $global_core_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $global_core_ngwa_id \
                       --profile $profile --region us-east-1 --output text
else
  aws ec2 create-route --route-table-id $global_core_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $global_core_nat_instance_eni_id \
                       --profile $profile --region us-east-1 --output text
fi

aws ec2 associate-route-table --route-table-id $global_core_private_rtba_id --subnet-id $global_core_application_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_private_rtba_id --subnet-id $global_core_database_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_private_rtba_id --subnet-id $global_core_management_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_private_rtba_id --subnet-id $global_core_gateway_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_private_rtba_id --subnet-id $global_core_endpoint_subneta_id \
                              --profile $profile --region us-east-1 --output text

global_core_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $global_core_vpc_id \
                                                         --query 'RouteTable.RouteTableId' \
                                                         --profile $profile --region us-east-1 --output text)
echo "global_core_private_rtbb_id=$global_core_private_rtbb_id"

aws ec2 create-tags --resources $global_core_private_rtbb_id \
                    --tags Key=Name,Value=Core-PrivateRouteTableB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then global_core_ngw_id=$global_core_ngwb_id; else global_core_ngw_id=$global_core_ngwa_id; fi
  aws ec2 create-route --route-table-id $global_core_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $global_core_ngw_id \
                       --profile $profile --region us-east-1 --output text
else
  aws ec2 create-route --route-table-id $global_core_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $global_core_nat_instance_eni_id \
                       --profile $profile --region us-east-1 --output text
fi

aws ec2 associate-route-table --route-table-id $global_core_private_rtbb_id --subnet-id $global_core_application_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_private_rtbb_id --subnet-id $global_core_database_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_private_rtbb_id --subnet-id $global_core_management_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_private_rtbb_id --subnet-id $global_core_gateway_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_private_rtbb_id --subnet-id $global_core_endpoint_subnetb_id \
                              --profile $profile --region us-east-1 --output text

global_core_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $global_core_vpc_id \
                                                         --query 'RouteTable.RouteTableId' \
                                                         --profile $profile --region us-east-1 --output text)
echo "global_core_private_rtbc_id=$global_core_private_rtbc_id"

aws ec2 create-tags --resources $global_core_private_rtbc_id \
                    --tags Key=Name,Value=Core-PrivateRouteTableC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then global_core_ngw_id=$global_core_ngwc_id; else global_core_ngw_id=$global_core_ngwa_id; fi
  aws ec2 create-route --route-table-id $global_core_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $global_core_ngw_id \
                       --profile $profile --region us-east-1 --output text
else
  aws ec2 create-route --route-table-id $global_core_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $global_core_nat_instance_eni_id \
                       --profile $profile --region us-east-1 --output text
fi

aws ec2 associate-route-table --route-table-id $global_core_private_rtbc_id --subnet-id $global_core_application_subnetc_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_private_rtbc_id --subnet-id $global_core_database_subnetc_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_private_rtbc_id --subnet-id $global_core_management_subnetc_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_private_rtbc_id --subnet-id $global_core_gateway_subnetc_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_core_private_rtbc_id --subnet-id $global_core_endpoint_subnetc_id \
                              --profile $profile --region us-east-1 --output text

# Create VPC Endpoint Security Group
global_core_vpce_sg_id=$(aws ec2 create-security-group --group-name Core-VPCEndpointSecurityGroup \
                                                       --description Core-VPCEndpointSecurityGroup \
                                                       --vpc-id $global_core_vpc_id \
                                                       --query 'GroupId' \
                                                       --profile $profile --region us-east-1 --output text)
echo "global_core_vpce_sg_id=$global_core_vpce_sg_id"

aws ec2 create-tags --resources $global_core_vpce_sg_id \
                    --tags Key=Name,Value=Core-VPCEndpointSecurityGroup \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_core_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$global_core_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_core_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$global_core_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

# Create VPC Endpoints for SSM and SSMMessages
global_core_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $global_core_vpc_id \
                                                      --vpc-endpoint-type Interface \
                                                      --service-name com.amazonaws.us-east-1.ssm \
                                                      --private-dns-enabled \
                                                      --security-group-ids $global_core_vpce_sg_id \
                                                      --subnet-ids $global_core_endpoint_subneta_id $global_core_endpoint_subnetb_id $global_core_endpoint_subnetc_id \
                                                      --client-token $(date +%s) \
                                                      --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Core-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                      --query 'VpcEndpoint.VpcEndpointId' \
                                                      --profile $profile --region us-east-1 --output text)
echo "global_core_ssm_vpce_id=$global_core_ssm_vpce_id"

global_core_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $global_core_vpc_id \
                                                       --vpc-endpoint-type Interface \
                                                       --service-name com.amazonaws.us-east-1.ssmmessages \
                                                       --private-dns-enabled \
                                                       --security-group-ids $global_core_vpce_sg_id \
                                                       --subnet-ids $global_core_endpoint_subneta_id $global_core_endpoint_subnetb_id $global_core_endpoint_subnetc_id \
                                                       --client-token $(date +%s) \
                                                       --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Core-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                       --query 'VpcEndpoint.VpcEndpointId' \
                                                       --profile $profile --region us-east-1 --output text)
echo "global_core_ssmm_vpce_id=$global_core_ssmm_vpce_id"

# TODO: Test these additional Endpoints and then replicate for other VPCs
# Create VPC Endpoint for CloudFormation
global_core_cloudformation_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $global_core_vpc_id \
                                                                 --vpc-endpoint-type Interface \
                                                                 --service-name com.amazonaws.us-east-1.cloudformation \
                                                                 --private-dns-enabled \
                                                                 --security-group-ids $global_core_vpce_sg_id \
                                                                 --subnet-ids $global_core_endpoint_subneta_id $global_core_endpoint_subnetb_id $global_core_endpoint_subnetc_id \
                                                                 --client-token $(date +%s) \
                                                                 --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Core-CloudFormationVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                 --query 'VpcEndpoint.VpcEndpointId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "global_core_cloudformation_vpce_id=$global_core_cloudformation_vpce_id"

# Create VPC Endpoint for S3
global_core_s3_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $global_core_vpc_id \
                                                     --vpc-endpoint-type Gateway \
                                                     --service-name com.amazonaws.us-east-1.s3 \
                                                     --private-dns-enabled \
                                                     --route-table-ids $global_core_private_rtba_id $global_core_private_rtbb_id $global_core_private_rtbc_id \
                                                     --client-token $(date +%s) \
                                                     --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Core-S3VpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                     --query 'VpcEndpoint.VpcEndpointId' \
                                                     --profile $profile --region us-east-1 --output text)
echo "global_core_s3_vpce_id=$core_s3_vpce_id"


## Global Log VPC #####################################################################################################
echo "log_account_id=$log_account_id"

profile=$log_profile

# Create VPC
global_log_vpc_id=$(aws ec2 create-vpc --cidr-block $global_log_vpc_cidr \
                                       --query 'Vpc.VpcId' \
                                       --profile $profile --region us-east-1 --output text)
echo "global_log_vpc_id=$global_log_vpc_id"

aws ec2 create-tags --resources $global_log_vpc_id \
                    --tags Key=Name,Value=Log-VPC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $global_log_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $global_log_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-1 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Log/Global" \
                          --profile $profile --region us-east-1 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $global_log_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-1:$log_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Log/Global" \
                         --deliver-logs-permission-arn "arn:aws:iam::$log_account_id:role/FlowLog" \
                         --profile $profile --region us-east-1 --output text

# Create Internet Gateway & Attach
global_log_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                    --profile $profile --region us-east-1 --output text)
echo "global_log_igw_id=$global_log_igw_id"

aws ec2 create-tags --resources $global_log_igw_id \
                    --tags Key=Name,Value=Log-InternetGateway \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 attach-internet-gateway --vpc-id $global_log_vpc_id \
                                --internet-gateway-id $global_log_igw_id \
                                --profile $profile --region us-east-1 --output text

# Create Private Hosted Zone
global_log_private_hostedzone_id=$(aws route53 create-hosted-zone --name $global_log_private_domain \
                                                                  --vpc VPCRegion=us-east-1,VPCId=$global_log_vpc_id \
                                                                  --hosted-zone-config Comment="Private Zone for $global_log_private_domain",PrivateZone=true \
                                                                  --caller-reference $(date +%s) \
                                                                  --query 'HostedZone.Id' \
                                                                  --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "global_log_private_hostedzone_id=$global_log_private_hostedzone_id"

# Create DHCP Options Set
global_log_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$global_log_private_domain]" \
                                                                       "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                 --query 'DhcpOptions.DhcpOptionsId' \
                                                 --profile $profile --region us-east-1 --output text)
echo "global_log_dopt_id=$global_log_dopt_id"

aws ec2 create-tags --resources $global_log_dopt_id \
                    --tags Key=Name,Value=Log-DHCPOptions \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 associate-dhcp-options --vpc-id $global_log_vpc_id \
                               --dhcp-options-id $global_log_dopt_id \
                               --profile $profile --region us-east-1 --output text

# Create Public Subnet A
global_log_public_subneta_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                     --cidr-block $global_log_subnet_publica_cidr \
                                                     --availability-zone us-east-1a \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-1 --output text)
echo "global_log_public_subneta_id=$global_log_public_subneta_id"

aws ec2 create-tags --resources $global_log_public_subneta_id \
                    --tags Key=Name,Value=Log-PublicSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Public Subnet B
global_log_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                     --cidr-block $global_log_subnet_publicb_cidr \
                                                     --availability-zone us-east-1b \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-1 --output text)
echo "global_log_public_subnetb_id=$global_log_public_subnetb_id"

aws ec2 create-tags --resources $global_log_public_subnetb_id \
                    --tags Key=Name,Value=Log-PublicSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Public Subnet C
global_log_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                     --cidr-block $global_log_subnet_publicc_cidr \
                                                     --availability-zone us-east-1c \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-1 --output text)
echo "global_log_public_subnetc_id=$global_log_public_subnetc_id"

aws ec2 create-tags --resources $global_log_public_subnetc_id \
                    --tags Key=Name,Value=Log-PublicSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Web Subnet A
global_log_web_subneta_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                  --cidr-block $global_log_subnet_weba_cidr \
                                                  --availability-zone us-east-1a \
                                                  --query 'Subnet.SubnetId' \
                                                  --profile $profile --region us-east-1 --output text)
echo "global_log_web_subneta_id=$global_log_web_subneta_id"

aws ec2 create-tags --resources $global_log_web_subneta_id \
                    --tags Key=Name,Value=Log-WebSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Web Subnet B
global_log_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                  --cidr-block $global_log_subnet_webb_cidr \
                                                  --availability-zone us-east-1b \
                                                  --query 'Subnet.SubnetId' \
                                                  --profile $profile --region us-east-1 --output text)
echo "global_log_web_subnetb_id=$global_log_web_subnetb_id"

aws ec2 create-tags --resources $global_log_web_subnetb_id \
                    --tags Key=Name,Value=Log-WebSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Web Subnet C
global_log_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                  --cidr-block $global_log_subnet_webc_cidr \
                                                  --availability-zone us-east-1c \
                                                  --query 'Subnet.SubnetId' \
                                                  --profile $profile --region us-east-1 --output text)
echo "global_log_web_subnetc_id=$global_log_web_subnetc_id"

aws ec2 create-tags --resources $global_log_web_subnetc_id \
                    --tags Key=Name,Value=Log-WebSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Application Subnet A
global_log_application_subneta_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                          --cidr-block $global_log_subnet_applicationa_cidr \
                                                          --availability-zone us-east-1a \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-1 --output text)
echo "global_log_application_subneta_id=$global_log_application_subneta_id"

aws ec2 create-tags --resources $global_log_application_subneta_id \
                    --tags Key=Name,Value=Log-ApplicationSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Application Subnet B
global_log_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                          --cidr-block $global_log_subnet_applicationb_cidr \
                                                          --availability-zone us-east-1b \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-1 --output text)
echo "global_log_application_subnetb_id=$global_log_application_subnetb_id"

aws ec2 create-tags --resources $global_log_application_subnetb_id \
                    --tags Key=Name,Value=Log-ApplicationSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Application Subnet C
global_log_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                          --cidr-block $global_log_subnet_applicationc_cidr \
                                                          --availability-zone us-east-1c \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-1 --output text)
echo "global_log_application_subnetc_id=$global_log_application_subnetc_id"

aws ec2 create-tags --resources $global_log_application_subnetc_id \
                    --tags Key=Name,Value=Log-ApplicationSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Database Subnet A
global_log_database_subneta_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                       --cidr-block $global_log_subnet_databasea_cidr \
                                                       --availability-zone us-east-1a \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-1 --output text)
echo "global_log_database_subneta_id=$global_log_database_subneta_id"

aws ec2 create-tags --resources $global_log_database_subneta_id \
                    --tags Key=Name,Value=Log-DatabaseSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Database Subnet B
global_log_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                       --cidr-block $global_log_subnet_databaseb_cidr \
                                                       --availability-zone us-east-1b \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-1 --output text)
echo "global_log_database_subnetb_id=$global_log_database_subnetb_id"

aws ec2 create-tags --resources $global_log_database_subnetb_id \
                    --tags Key=Name,Value=Log-DatabaseSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Database Subnet C
global_log_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                       --cidr-block $global_log_subnet_databasec_cidr \
                                                       --availability-zone us-east-1c \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-1 --output text)
echo "global_log_database_subnetc_id=$global_log_database_subnetc_id"

aws ec2 create-tags --resources $global_log_database_subnetc_id \
                    --tags Key=Name,Value=Log-DatabaseSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Management Subnet A
global_log_management_subneta_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                         --cidr-block $global_log_subnet_managementa_cidr \
                                                         --availability-zone us-east-1a \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-1 --output text)
echo "global_log_management_subneta_id=$global_log_management_subneta_id"

aws ec2 create-tags --resources $global_log_management_subneta_id \
                    --tags Key=Name,Value=Log-ManagementSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Management Subnet B
global_log_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                         --cidr-block $global_log_subnet_managementb_cidr \
                                                         --availability-zone us-east-1b \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-1 --output text)
echo "global_log_management_subnetb_id=$global_log_management_subnetb_id"

aws ec2 create-tags --resources $global_log_management_subnetb_id \
                    --tags Key=Name,Value=Log-ManagementSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Management Subnet C
global_log_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                         --cidr-block $global_log_subnet_managementc_cidr \
                                                         --availability-zone us-east-1c \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-1 --output text)
echo "global_log_management_subnetc_id=$global_log_management_subnetc_id"

aws ec2 create-tags --resources $global_log_management_subnetc_id \
                    --tags Key=Name,Value=Log-ManagementSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Gateway Subnet A
global_log_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                      --cidr-block $global_log_subnet_gatewaya_cidr \
                                                      --availability-zone us-east-1a \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-1 --output text)
echo "global_log_gateway_subneta_id=$global_log_gateway_subneta_id"

aws ec2 create-tags --resources $global_log_gateway_subneta_id \
                    --tags Key=Name,Value=Log-GatewaySubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Gateway Subnet B
global_log_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                      --cidr-block $global_log_subnet_gatewayb_cidr \
                                                      --availability-zone us-east-1b \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-1 --output text)
echo "global_log_gateway_subnetb_id=$global_log_gateway_subnetb_id"

aws ec2 create-tags --resources $global_log_gateway_subnetb_id \
                    --tags Key=Name,Value=Log-GatewaySubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Gateway Subnet C
global_log_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                      --cidr-block $global_log_subnet_gatewayc_cidr \
                                                      --availability-zone us-east-1c \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-1 --output text)
echo "global_log_gateway_subnetc_id=$global_log_gateway_subnetc_id"

aws ec2 create-tags --resources $global_log_gateway_subnetc_id \
                    --tags Key=Name,Value=Log-GatewaySubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Endpoint Subnet A
global_log_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                       --cidr-block $global_log_subnet_endpointa_cidr \
                                                       --availability-zone us-east-1a \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-1 --output text)
echo "global_log_endpoint_subneta_id=$global_log_endpoint_subneta_id"

aws ec2 create-tags --resources $global_log_endpoint_subneta_id \
                    --tags Key=Name,Value=Log-EndpointSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Endpoint Subnet B
global_log_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                       --cidr-block $global_log_subnet_endpointb_cidr \
                                                       --availability-zone us-east-1b \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-1 --output text)
echo "global_log_endpoint_subnetb_id=$global_log_endpoint_subnetb_id"

aws ec2 create-tags --resources $global_log_endpoint_subnetb_id \
                    --tags Key=Name,Value=Log-EndpointSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Endpoint Subnet C
global_log_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $global_log_vpc_id \
                                                       --cidr-block $global_log_subnet_endpointc_cidr \
                                                       --availability-zone us-east-1c \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-1 --output text)
echo "global_log_endpoint_subnetc_id=$global_log_endpoint_subnetc_id"

aws ec2 create-tags --resources $global_log_endpoint_subnetc_id \
                    --tags Key=Name,Value=Log-EndpointSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
global_log_public_rtb_id=$(aws ec2 create-route-table --vpc-id $global_log_vpc_id \
                                                      --query 'RouteTable.RouteTableId' \
                                                      --profile $profile --region us-east-1 --output text)
echo "global_log_public_rtb_id=$global_log_public_rtb_id"

aws ec2 create-tags --resources $global_log_public_rtb_id \
                    --tags Key=Name,Value=Log-PublicRouteTable \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 create-route --route-table-id $global_log_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $global_log_igw_id \
                     --profile $profile --region us-east-1 --output text

aws ec2 associate-route-table --route-table-id $global_log_public_rtb_id --subnet-id $global_log_public_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_public_rtb_id --subnet-id $global_log_public_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_public_rtb_id --subnet-id $global_log_public_subnetc_id \
                              --profile $profile --region us-east-1 --output text

aws ec2 associate-route-table --route-table-id $global_log_public_rtb_id --subnet-id $global_log_web_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_public_rtb_id --subnet-id $global_log_web_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_public_rtb_id --subnet-id $global_log_web_subnetc_id \
                              --profile $profile --region us-east-1 --output text

# Create NAT Gateways
if [ $use_ngw = 1 ]; then
  global_log_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                 --query 'AllocationId' \
                                                 --profile $profile --region us-east-1 --output text)
  echo "global_log_ngw_eipa=$global_log_ngw_eipa"

  aws ec2 create-tags --resources $global_log_ngw_eipa \
                      --tags Key=Name,Value=Log-NAT-EIPA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-1 --output text

  global_log_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $global_log_ngw_eipa \
                                                  --subnet-id $global_log_public_subneta_id \
                                                  --client-token $(date +%s) \
                                                  --query 'NatGateway.NatGatewayId' \
                                                  --profile $profile --region us-east-1 --output text)
  echo "global_log_ngwa_id=$global_log_ngwa_id"

  aws ec2 create-tags --resources $global_log_ngwa_id \
                      --tags Key=Name,Value=Log-NAT-GatewayA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-1 --output text

  if [ $ha_ngw = 1 ]; then
    global_log_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                   --query 'AllocationId' \
                                                   --profile $profile --region us-east-1 --output text)
    echo "global_log_ngw_eipb=$global_log_ngw_eipb"

    aws ec2 create-tags --resources $global_log_ngw_eipb \
                        --tags Key=Name,Value=Log-NAT-EIPB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Log \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-1 --output text

    global_log_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $global_log_ngw_eipb \
                                                    --subnet-id $global_log_public_subnetb_id \
                                                    --client-token $(date +%s) \
                                                    --query 'NatGateway.NatGatewayId' \
                                                    --profile $profile --region us-east-1 --output text)
    echo "global_log_ngwb_id=$global_log_ngwb_id"

    aws ec2 create-tags --resources $global_log_ngwb_id \
                        --tags Key=Name,Value=Log-NAT-GatewayB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Log \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-1 --output text

    global_log_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                   --query 'AllocationId' \
                                                   --profile $profile --region us-east-1 --output text)
    echo "global_log_ngw_eipc=$global_log_ngw_eipc"

    aws ec2 create-tags --resources $global_log_ngw_eipc \
                        --tags Key=Name,Value=Log-NAT-EIPC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Log \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-1 --output text

    global_log_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $global_log_ngw_eipc \
                                                    --subnet-id $global_log_public_subnetc_id \
                                                    --client-token $(date +%s) \
                                                    --query 'NatGateway.NatGatewayId' \
                                                    --profile $profile --region us-east-1 --output text)
    echo "global_log_ngwc_id=$global_log_ngwc_id"

    aws ec2 create-tags --resources $global_log_ngwc_id \
                        --tags Key=Name,Value=Log-NAT-GatewayC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Log \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-1 --output text
  fi
else
  # Create NAT Security Group
  global_log_nat_sg_id=$(aws ec2 create-security-group --group-name Log-NAT-InstanceSecurityGroup \
                                                       --description Log-NAT-InstanceSecurityGroup \
                                                       --vpc-id $global_log_vpc_id \
                                                       --query 'GroupId' \
                                                       --profile $profile --region us-east-1 --output text)
  echo "global_log_nat_sg_id=$global_log_nat_sg_id"

  aws ec2 create-tags --resources $global_log_nat_sg_id \
                      --tags Key=Name,Value=Log-NAT-InstanceSecurityGroup \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Utility,Value=NAT \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-1 --output text

  aws ec2 authorize-security-group-ingress --group-id $global_log_nat_sg_id \
                                           --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$global_log_vpc_cidr,Description=\"VPC (All)\"}]" \
                                           --profile $profile --region us-east-1 --output text

  # Create NAT Instance
  global_log_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                     --instance-type t3a.nano \
                                                     --iam-instance-profile Name=ManagedInstance \
                                                     --key-name administrator \
                                                     --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Log-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$global_log_nat_sg_id],SubnetId=$global_log_public_subneta_id" \
                                                     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Log-NAT-Instance},{Key=Hostname,Value=cmlue1lnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                     --query 'Instances[0].InstanceId' \
                                                     --profile $profile --region us-east-1 --output text)
  echo "global_log_nat_instance_id=$global_log_nat_instance_id"

  aws ec2 modify-instance-attribute --instance-id $global_log_nat_instance_id \
                                    --no-source-dest-check \
                                    --profile $profile --region us-east-1 --output text

  global_log_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $global_log_nat_instance_id \
                                                              --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                              --profile $profile --region us-east-1 --output text)
  echo "global_log_nat_instance_eni_id=$global_log_nat_instance_eni_id"

  global_log_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $global_log_nat_instance_id \
                                                                  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                  --profile $profile --region us-east-1 --output text)
  echo "global_log_nat_instance_private_ip=$global_log_nat_instance_private_ip"
fi

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
global_log_private_rtba_id=$(aws ec2 create-route-table --vpc-id $global_log_vpc_id \
                                                        --query 'RouteTable.RouteTableId' \
                                                        --profile $profile --region us-east-1 --output text)
echo "global_log_private_rtba_id=$global_log_private_rtba_id"

aws ec2 create-tags --resources $global_log_private_rtba_id \
                    --tags Key=Name,Value=Log-PrivateRouteTableA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

if [ $use_ngw = 1 ]; then
  aws ec2 create-route --route-table-id $global_log_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $global_log_ngwa_id \
                       --profile $profile --region us-east-1 --output text
else
  aws ec2 create-route --route-table-id $global_log_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $global_log_nat_instance_eni_id \
                       --profile $profile --region us-east-1 --output text
fi

aws ec2 associate-route-table --route-table-id $global_log_private_rtba_id --subnet-id $global_log_application_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_private_rtba_id --subnet-id $global_log_database_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_private_rtba_id --subnet-id $global_log_management_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_private_rtba_id --subnet-id $global_log_gateway_subneta_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_private_rtba_id --subnet-id $global_log_endpoint_subneta_id \
                              --profile $profile --region us-east-1 --output text

global_log_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $global_log_vpc_id \
                                                        --query 'RouteTable.RouteTableId' \
                                                        --profile $profile --region us-east-1 --output text)
echo "global_log_private_rtbb_id=$global_log_private_rtbb_id"

aws ec2 create-tags --resources $global_log_private_rtbb_id \
                    --tags Key=Name,Value=Log-PrivateRouteTableB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then global_log_ngw_id=$global_log_ngwb_id; else global_log_ngw_id=$global_log_ngwa_id; fi
  aws ec2 create-route --route-table-id $global_log_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $global_log_ngw_id \
                       --profile $profile --region us-east-1 --output text
else
  aws ec2 create-route --route-table-id $global_log_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $global_log_nat_instance_eni_id \
                       --profile $profile --region us-east-1 --output text
fi

aws ec2 associate-route-table --route-table-id $global_log_private_rtbb_id --subnet-id $global_log_application_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_private_rtbb_id --subnet-id $global_log_database_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_private_rtbb_id --subnet-id $global_log_management_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_private_rtbb_id --subnet-id $global_log_gateway_subnetb_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_private_rtbb_id --subnet-id $global_log_endpoint_subnetb_id \
                              --profile $profile --region us-east-1 --output text

global_log_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $global_log_vpc_id \
                                                        --query 'RouteTable.RouteTableId' \
                                                        --profile $profile --region us-east-1 --output text)
echo "global_log_private_rtbc_id=$global_log_private_rtbc_id"

aws ec2 create-tags --resources $global_log_private_rtbc_id \
                    --tags Key=Name,Value=Log-PrivateRouteTableC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then global_log_ngw_id=$global_log_ngwc_id; else global_log_ngw_id=$global_log_ngwa_id; fi
  aws ec2 create-route --route-table-id $global_log_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $global_log_ngw_id \
                       --profile $profile --region us-east-1 --output text
else
  aws ec2 create-route --route-table-id $global_log_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $global_log_nat_instance_eni_id \
                       --profile $profile --region us-east-1 --output text
fi

aws ec2 associate-route-table --route-table-id $global_log_private_rtbc_id --subnet-id $global_log_application_subnetc_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_private_rtbc_id --subnet-id $global_log_database_subnetc_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_private_rtbc_id --subnet-id $global_log_management_subnetc_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_private_rtbc_id --subnet-id $global_log_gateway_subnetc_id \
                              --profile $profile --region us-east-1 --output text
aws ec2 associate-route-table --route-table-id $global_log_private_rtbc_id --subnet-id $global_log_endpoint_subnetc_id \
                              --profile $profile --region us-east-1 --output text

# Create VPC Endpoint Security Group
global_log_vpce_sg_id=$(aws ec2 create-security-group --group-name Log-VPCEndpointSecurityGroup \
                                                      --description Log-VPCEndpointSecurityGroup \
                                                      --vpc-id $global_log_vpc_id \
                                                      --query 'GroupId' \
                                                      --profile $profile --region us-east-1 --output text)
echo "global_log_vpce_sg_id=$global_log_vpce_sg_id"

aws ec2 create-tags --resources $global_log_vpce_sg_id \
                    --tags Key=Name,Value=Log-VPCEndpointSecurityGroup \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_log_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$global_log_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

aws ec2 authorize-security-group-ingress --group-id $global_log_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$global_log_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-1 --output text

# Create VPC Endpoints for SSM and SSMMessages
global_log_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $global_log_vpc_id \
                                                     --vpc-endpoint-type Interface \
                                                     --service-name com.amazonaws.us-east-1.ssm \
                                                     --private-dns-enabled \
                                                     --security-group-ids $global_log_vpce_sg_id \
                                                     --subnet-ids $global_log_endpoint_subneta_id $global_log_endpoint_subnetb_id $global_log_endpoint_subnetc_id \
                                                     --client-token $(date +%s) \
                                                     --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Log-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                     --query 'VpcEndpoint.VpcEndpointId' \
                                                     --profile $profile --region us-east-1 --output text)
echo "global_log_ssm_vpce_id=$global_log_ssm_vpce_id"

global_log_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $global_log_vpc_id \
                                                      --vpc-endpoint-type Interface \
                                                      --service-name com.amazonaws.us-east-1.ssmmessages \
                                                      --private-dns-enabled \
                                                      --security-group-ids $global_log_vpce_sg_id \
                                                      --subnet-ids $global_log_endpoint_subneta_id $global_log_endpoint_subnetb_id $global_log_endpoint_subnetc_id \
                                                      --client-token $(date +%s) \
                                                      --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Log-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                      --query 'VpcEndpoint.VpcEndpointId' \
                                                      --profile $profile --region us-east-1 --output text)
echo "global_log_ssmm_vpce_id=$global_log_ssmm_vpce_id"


## Ohio Management VPC ################################################################################################
echo "management_account_id=$management_account_id"

profile=$management_profile

# Create VPC
ohio_management_vpc_id=$(aws ec2 create-vpc --cidr-block $ohio_management_vpc_cidr \
                                            --query 'Vpc.VpcId' \
                                            --profile $profile --region us-east-2 --output text)
echo "ohio_management_vpc_id=$ohio_management_vpc_id"

aws ec2 create-tags --resources $ohio_management_vpc_id \
                    --tags Key=Name,Value=Management-VPC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $ohio_management_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $ohio_management_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-2 --output text

# Note VPC Flow Log Role Already exists - created for Virginia above

aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Management" \
                          --profile $profile --region us-east-2 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $ohio_management_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-2:$management_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Management" \
                         --deliver-logs-permission-arn "arn:aws:iam::$management_account_id:role/FlowLog" \
                         --profile $profile --region us-east-2 --output text

# Create Internet Gateway & Attach
ohio_management_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "ohio_management_igw_id=$ohio_management_igw_id"

aws ec2 create-tags --resources $ohio_management_igw_id \
                    --tags Key=Name,Value=Management-InternetGateway \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 attach-internet-gateway --vpc-id $ohio_management_vpc_id \
                                --internet-gateway-id $ohio_management_igw_id \
                                --profile $profile --region us-east-2 --output text

# Create Private Hosted Zone
ohio_management_private_hostedzone_id=$(aws route53 create-hosted-zone --name $ohio_management_public_domain \
                                                                       --vpc VPCRegion=us-east-2,VPCId=$ohio_management_vpc_id \
                                                                       --hosted-zone-config Comment="Private Zone for $ohio_management_public_domain",PrivateZone=true \
                                                                       --caller-reference $(date +%s) \
                                                                       --query 'HostedZone.Id' \
                                                                       --profile $profile --region us-east-2 --output text | cut -f3 -d /)
echo "ohio_management_private_hostedzone_id=$ohio_management_private_hostedzone_id"

# Create DHCP Options Set
ohio_management_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$ohio_management_public_domain]" \
                                                                            "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                      --query 'DhcpOptions.DhcpOptionsId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "ohio_management_dopt_id=$ohio_management_dopt_id"

aws ec2 create-tags --resources $ohio_management_dopt_id \
                    --tags Key=Name,Value=Management-DHCPOptions \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 associate-dhcp-options --vpc-id $ohio_management_vpc_id \
                               --dhcp-options-id $ohio_management_dopt_id \
                               --profile $profile --region us-east-2 --output text

# Create Public Subnet A
ohio_management_public_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                          --cidr-block $ohio_management_subnet_publica_cidr \
                                                          --availability-zone us-east-2a \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "ohio_management_public_subneta_id=$ohio_management_public_subneta_id"

aws ec2 create-tags --resources $ohio_management_public_subneta_id \
                    --tags Key=Name,Value=Management-PublicSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet B
ohio_management_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                          --cidr-block $ohio_management_subnet_publicb_cidr \
                                                          --availability-zone us-east-2b \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "ohio_management_public_subnetb_id=$ohio_management_public_subnetb_id"

aws ec2 create-tags --resources $ohio_management_public_subnetb_id \
                    --tags Key=Name,Value=Management-PublicSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet C
ohio_management_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                          --cidr-block $ohio_management_subnet_publicc_cidr \
                                                          --availability-zone us-east-2c \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "ohio_management_public_subnetc_id=$ohio_management_public_subnetc_id"

aws ec2 create-tags --resources $ohio_management_public_subnetc_id \
                    --tags Key=Name,Value=Management-PublicSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet A
ohio_management_web_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                       --cidr-block $ohio_management_subnet_weba_cidr \
                                                       --availability-zone us-east-2a \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "ohio_management_web_subneta_id=$ohio_management_web_subneta_id"

aws ec2 create-tags --resources $ohio_management_web_subneta_id \
                    --tags Key=Name,Value=Management-WebSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet B
ohio_management_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                       --cidr-block $ohio_management_subnet_webb_cidr \
                                                       --availability-zone us-east-2b \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "ohio_management_web_subnetb_id=$ohio_management_web_subnetb_id"

aws ec2 create-tags --resources $ohio_management_web_subnetb_id \
                    --tags Key=Name,Value=Management-WebSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet C
ohio_management_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                       --cidr-block $ohio_management_subnet_webc_cidr \
                                                       --availability-zone us-east-2c \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "ohio_management_web_subnetc_id=$ohio_management_web_subnetc_id"

aws ec2 create-tags --resources $ohio_management_web_subnetc_id \
                    --tags Key=Name,Value=Management-WebSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet A
ohio_management_application_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                               --cidr-block $ohio_management_subnet_applicationa_cidr \
                                                               --availability-zone us-east-2a \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "ohio_management_application_subneta_id=$ohio_management_application_subneta_id"

aws ec2 create-tags --resources $ohio_management_application_subneta_id \
                    --tags Key=Name,Value=Management-ApplicationSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet B
ohio_management_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                               --cidr-block $ohio_management_subnet_applicationb_cidr \
                                                               --availability-zone us-east-2b \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "ohio_management_application_subnetb_id=$ohio_management_application_subnetb_id"

aws ec2 create-tags --resources $ohio_management_application_subnetb_id \
                    --tags Key=Name,Value=Management-ApplicationSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet C
ohio_management_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                               --cidr-block $ohio_management_subnet_applicationc_cidr \
                                                               --availability-zone us-east-2c \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "ohio_management_application_subnetc_id=$ohio_management_application_subnetc_id"

aws ec2 create-tags --resources $ohio_management_application_subnetc_id \
                    --tags Key=Name,Value=Management-ApplicationSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet A
ohio_management_database_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                            --cidr-block $ohio_management_subnet_databasea_cidr \
                                                            --availability-zone us-east-2a \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_management_database_subneta_id=$ohio_management_database_subneta_id"

aws ec2 create-tags --resources $ohio_management_database_subneta_id \
                    --tags Key=Name,Value=Management-DatabaseSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet B
ohio_management_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                            --cidr-block $ohio_management_subnet_databaseb_cidr \
                                                            --availability-zone us-east-2b \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_management_database_subnetb_id=$ohio_management_database_subnetb_id"

aws ec2 create-tags --resources $ohio_management_database_subnetb_id \
                    --tags Key=Name,Value=Management-DatabaseSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet C
ohio_management_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                            --cidr-block $ohio_management_subnet_databasec_cidr \
                                                            --availability-zone us-east-2c \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_management_database_subnetc_id=$ohio_management_database_subnetc_id"

aws ec2 create-tags --resources $ohio_management_database_subnetc_id \
                    --tags Key=Name,Value=Management-DatabaseSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Directory Subnet A
ohio_management_directory_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                            --cidr-block $ohio_management_subnet_directorya_cidr \
                                                            --availability-zone us-east-2a \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_management_directory_subneta_id=$ohio_management_directory_subneta_id"

aws ec2 create-tags --resources $ohio_management_directory_subneta_id \
                    --tags Key=Name,Value=Management-DirectorySubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Directory Subnet B
ohio_management_directory_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                            --cidr-block $ohio_management_subnet_directoryb_cidr \
                                                            --availability-zone us-east-2b \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_management_directory_subnetb_id=$ohio_management_directory_subnetb_id"

aws ec2 create-tags --resources $ohio_management_directory_subnetb_id \
                    --tags Key=Name,Value=Management-DirectorySubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Directory Subnet C
ohio_management_directory_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                            --cidr-block $ohio_management_subnet_directoryc_cidr \
                                                            --availability-zone us-east-2c \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_management_directory_subnetc_id=$ohio_management_directory_subnetc_id"

aws ec2 create-tags --resources $ohio_management_directory_subnetc_id \
                    --tags Key=Name,Value=Management-DirectorySubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet A
ohio_management_management_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                              --cidr-block $ohio_management_subnet_managementa_cidr \
                                                              --availability-zone us-east-2a \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "ohio_management_management_subneta_id=$ohio_management_management_subneta_id"

aws ec2 create-tags --resources $ohio_management_management_subneta_id \
                    --tags Key=Name,Value=Management-ManagementSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet B
ohio_management_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                              --cidr-block $ohio_management_subnet_managementb_cidr \
                                                              --availability-zone us-east-2b \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "ohio_management_management_subnetb_id=$ohio_management_management_subnetb_id"

aws ec2 create-tags --resources $ohio_management_management_subnetb_id \
                    --tags Key=Name,Value=Management-ManagementSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet C
ohio_management_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                              --cidr-block $ohio_management_subnet_managementc_cidr \
                                                              --availability-zone us-east-2c \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "ohio_management_management_subnetc_id=$ohio_management_management_subnetc_id"

aws ec2 create-tags --resources $ohio_management_management_subnetc_id \
                    --tags Key=Name,Value=Management-ManagementSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet A
ohio_management_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                           --cidr-block $ohio_management_subnet_gatewaya_cidr \
                                                           --availability-zone us-east-2a \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "ohio_management_gateway_subneta_id=$ohio_management_gateway_subneta_id"

aws ec2 create-tags --resources $ohio_management_gateway_subneta_id \
                    --tags Key=Name,Value=Management-GatewaySubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet B
ohio_management_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                           --cidr-block $ohio_management_subnet_gatewayb_cidr \
                                                           --availability-zone us-east-2b \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "ohio_management_gateway_subnetb_id=$ohio_management_gateway_subnetb_id"

aws ec2 create-tags --resources $ohio_management_gateway_subnetb_id \
                    --tags Key=Name,Value=Management-GatewaySubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet C
ohio_management_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                           --cidr-block $ohio_management_subnet_gatewayc_cidr \
                                                           --availability-zone us-east-2c \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "ohio_management_gateway_subnetc_id=$ohio_management_gateway_subnetc_id"

aws ec2 create-tags --resources $ohio_management_gateway_subnetc_id \
                    --tags Key=Name,Value=Management-GatewaySubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet A
ohio_management_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                            --cidr-block $ohio_management_subnet_endpointa_cidr \
                                                            --availability-zone us-east-2a \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_management_endpoint_subneta_id=$ohio_management_endpoint_subneta_id"

aws ec2 create-tags --resources $ohio_management_endpoint_subneta_id \
                    --tags Key=Name,Value=Management-EndpointSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet B
ohio_management_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                            --cidr-block $ohio_management_subnet_endpointb_cidr \
                                                            --availability-zone us-east-2b \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_management_endpoint_subnetb_id=$ohio_management_endpoint_subnetb_id"

aws ec2 create-tags --resources $ohio_management_endpoint_subnetb_id \
                    --tags Key=Name,Value=Management-EndpointSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet C
ohio_management_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_management_vpc_id \
                                                            --cidr-block $ohio_management_subnet_endpointc_cidr \
                                                            --availability-zone us-east-2c \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_management_endpoint_subnetc_id=$ohio_management_endpoint_subnetc_id"

aws ec2 create-tags --resources $ohio_management_endpoint_subnetc_id \
                    --tags Key=Name,Value=Management-EndpointSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
ohio_management_public_rtb_id=$(aws ec2 create-route-table --vpc-id $ohio_management_vpc_id \
                                                           --query 'RouteTable.RouteTableId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "ohio_management_public_rtb_id=$ohio_management_public_rtb_id"

aws ec2 create-tags --resources $ohio_management_public_rtb_id \
                    --tags Key=Name,Value=Management-PublicRouteTable \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $ohio_management_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $ohio_management_igw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $ohio_management_public_rtb_id --subnet-id $ohio_management_public_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_public_rtb_id --subnet-id $ohio_management_public_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_public_rtb_id --subnet-id $ohio_management_public_subnetc_id \
                              --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $ohio_management_public_rtb_id --subnet-id $ohio_management_web_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_public_rtb_id --subnet-id $ohio_management_web_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_public_rtb_id --subnet-id $ohio_management_web_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create NAT Gateways
if [ $use_ngw = 1 ]; then
  ohio_management_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                      --query 'AllocationId' \
                                                      --profile $profile --region us-east-2 --output text)
  echo "ohio_management_ngw_eipa=$ohio_management_ngw_eipa"

  aws ec2 create-tags --resources $ohio_management_ngw_eipa \
                      --tags Key=Name,Value=Management-NAT-EIPA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  ohio_management_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_management_ngw_eipa \
                                                      --subnet-id $ohio_management_public_subneta_id \
                                                      --client-token $(date +%s) \
                                                      --query 'NatGateway.NatGatewayId' \
                                                      --profile $profile --region us-east-2 --output text)
  echo "ohio_management_ngwa_id=$ohio_management_ngwa_id"

  aws ec2 create-tags --resources $ohio_management_ngwa_id \
                      --tags Key=Name,Value=Management-NAT-GatewayA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  if [ $ha_ngw = 1 ]; then
    ohio_management_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                        --query 'AllocationId' \
                                                        --profile $profile --region us-east-2 --output text)
    echo "ohio_management_ngw_eipb=$ohio_management_ngw_eipb"

    aws ec2 create-tags --resources $ohio_management_ngw_eipb \
                        --tags Key=Name,Value=Management-NAT-EIPB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    ohio_management_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_management_ngw_eipb \
                                                         --subnet-id $ohio_management_public_subnetb_id \
                                                         --client-token $(date +%s) \
                                                         --query 'NatGateway.NatGatewayId' \
                                                         --profile $profile --region us-east-2 --output text)
    echo "ohio_management_ngwb_id=$ohio_management_ngwb_id"

    aws ec2 create-tags --resources $ohio_management_ngwb_id \
                        --tags Key=Name,Value=Management-NAT-GatewayB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    ohio_management_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                        --query 'AllocationId' \
                                                        --profile $profile --region us-east-2 --output text)
    echo "ohio_management_ngw_eipc=$ohio_management_ngw_eipc"

    aws ec2 create-tags --resources $ohio_management_ngw_eipc \
                        --tags Key=Name,Value=Management-NAT-EIPC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    ohio_management_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_management_ngw_eipc \
                                                         --subnet-id $ohio_management_public_subnetc_id \
                                                         --client-token $(date +%s) \
                                                         --query 'NatGateway.NatGatewayId' \
                                                         --profile $profile --region us-east-2 --output text)
    echo "ohio_management_ngwc_id=$ohio_management_ngwc_id"

    aws ec2 create-tags --resources $ohio_management_ngwc_id \
                        --tags Key=Name,Value=Management-NAT-GatewayC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text
  fi
else
  # Create NAT Security Group
  ohio_management_nat_sg_id=$(aws ec2 create-security-group --group-name Management-NAT-InstanceSecurityGroup \
                                                            --description Management-NAT-InstanceSecurityGroup \
                                                            --vpc-id $ohio_management_vpc_id \
                                                            --query 'GroupId' \
                                                            --profile $profile --region us-east-2 --output text)
  echo "ohio_management_nat_sg_id=$ohio_management_nat_sg_id"

  aws ec2 create-tags --resources $ohio_management_nat_sg_id \
                      --tags Key=Name,Value=Management-NAT-InstanceSecurityGroup \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Utility,Value=NAT \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  aws ec2 authorize-security-group-ingress --group-id $ohio_management_nat_sg_id \
                                           --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$ohio_management_vpc_cidr,Description=\"VPC (All)\"}]" \
                                           --profile $profile --region us-east-2 --output text

  # Create NAT Instance
  ohio_management_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                          --instance-type t3a.nano \
                                                          --iam-instance-profile Name=ManagedInstance \
                                                          --key-name administrator \
                                                          --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Management-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_management_nat_sg_id],SubnetId=$ohio_management_public_subneta_id" \
                                                          --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Management-NAT-Instance},{Key=Hostname,Value=cmlue2mnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                          --query 'Instances[0].InstanceId' \
                                                          --profile $profile --region us-east-2 --output text)
  echo "ohio_management_nat_instance_id=$ohio_management_nat_instance_id"

  aws ec2 modify-instance-attribute --instance-id $ohio_management_nat_instance_id \
                                    --no-source-dest-check \
                                    --profile $profile --region us-east-2 --output text

  ohio_management_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $ohio_management_nat_instance_id \
                                                                   --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                   --profile $profile --region us-east-2 --output text)
  echo "ohio_management_nat_instance_eni_id=$ohio_management_nat_instance_eni_id"

  ohio_management_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_management_nat_instance_id \
                                                                       --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                       --profile $profile --region us-east-2 --output text)
  echo "ohio_management_nat_instance_private_ip=$ohio_management_nat_instance_private_ip"
fi

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
ohio_management_private_rtba_id=$(aws ec2 create-route-table --vpc-id $ohio_management_vpc_id \
                                                             --query 'RouteTable.RouteTableId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "ohio_management_private_rtba_id=$ohio_management_private_rtba_id"

aws ec2 create-tags --resources $ohio_management_private_rtba_id \
                    --tags Key=Name,Value=Management-PrivateRouteTableA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

if [ $use_ngw = 1 ]; then
  aws ec2 create-route --route-table-id $ohio_management_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ohio_management_ngwa_id \
                       --profile $profile --region us-east-2 --output text
else
  aws ec2 create-route --route-table-id $ohio_management_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ohio_management_nat_instance_eni_id \
                       --profile $profile --region us-east-2 --output text
fi

aws ec2 associate-route-table --route-table-id $ohio_management_private_rtba_id --subnet-id $ohio_management_application_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtba_id --subnet-id $ohio_management_database_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtba_id --subnet-id $ohio_management_directory_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtba_id --subnet-id $ohio_management_management_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtba_id --subnet-id $ohio_management_gateway_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtba_id --subnet-id $ohio_management_endpoint_subneta_id \
                              --profile $profile --region us-east-2 --output text

ohio_management_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $ohio_management_vpc_id \
                                                             --query 'RouteTable.RouteTableId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "ohio_management_private_rtbb_id=$ohio_management_private_rtbb_id"

aws ec2 create-tags --resources $ohio_management_private_rtbb_id \
                    --tags Key=Name,Value=Management-PrivateRouteTableB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then ohio_management_ngw_id=$ohio_management_ngwb_id; else ohio_management_ngw_id=$ohio_management_ngwa_id; fi
  aws ec2 create-route --route-table-id $ohio_management_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ohio_management_ngw_id \
                       --profile $profile --region us-east-2 --output text
else
  aws ec2 create-route --route-table-id $ohio_management_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ohio_management_nat_instance_eni_id \
                       --profile $profile --region us-east-2 --output text
fi

aws ec2 associate-route-table --route-table-id $ohio_management_private_rtbb_id --subnet-id $ohio_management_application_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtbb_id --subnet-id $ohio_management_database_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtbb_id --subnet-id $ohio_management_directory_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtbb_id --subnet-id $ohio_management_management_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtbb_id --subnet-id $ohio_management_gateway_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtbb_id --subnet-id $ohio_management_endpoint_subnetb_id \
                              --profile $profile --region us-east-2 --output text

ohio_management_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $ohio_management_vpc_id \
                                                             --query 'RouteTable.RouteTableId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "ohio_management_private_rtbc_id=$ohio_management_private_rtbc_id"

aws ec2 create-tags --resources $ohio_management_private_rtbc_id \
                    --tags Key=Name,Value=Management-PrivateRouteTableC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then ohio_management_ngw_id=$ohio_management_ngwc_id; else ohio_management_ngw_id=$ohio_management_ngwa_id; fi
  aws ec2 create-route --route-table-id $ohio_management_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ohio_management_ngw_id \
                       --profile $profile --region us-east-2 --output text
else
  aws ec2 create-route --route-table-id $ohio_management_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ohio_management_nat_instance_eni_id \
                       --profile $profile --region us-east-2 --output text
fi

aws ec2 associate-route-table --route-table-id $ohio_management_private_rtbc_id --subnet-id $ohio_management_application_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtbc_id --subnet-id $ohio_management_database_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtbc_id --subnet-id $ohio_management_directory_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtbc_id --subnet-id $ohio_management_management_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtbc_id --subnet-id $ohio_management_gateway_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_management_private_rtbc_id --subnet-id $ohio_management_endpoint_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create VPC Endpoint Security Group
ohio_management_vpce_sg_id=$(aws ec2 create-security-group --group-name Management-VPCEndpointSecurityGroup \
                                                           --description Management-VPCEndpointSecurityGroup \
                                                           --vpc-id $ohio_management_vpc_id \
                                                           --query 'GroupId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "ohio_management_vpce_sg_id=$ohio_management_vpce_sg_id"

aws ec2 create-tags --resources $ohio_management_vpce_sg_id \
                    --tags Key=Name,Value=Management-VPCEndpointSecurityGroup \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_management_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ohio_management_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_management_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ohio_management_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create VPC Endpoints for SSM and SSMMessages
ohio_management_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ohio_management_vpc_id \
                                                          --vpc-endpoint-type Interface \
                                                          --service-name com.amazonaws.us-east-2.ssm \
                                                          --private-dns-enabled \
                                                          --security-group-ids $ohio_management_vpce_sg_id \
                                                          --subnet-ids $ohio_management_endpoint_subneta_id $ohio_management_endpoint_subnetb_id $ohio_management_endpoint_subnetc_id \
                                                          --client-token $(date +%s) \
                                                          --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Management-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                          --query 'VpcEndpoint.VpcEndpointId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "ohio_management_ssm_vpce_id=$ohio_management_ssm_vpce_id"

ohio_management_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ohio_management_vpc_id \
                                                           --vpc-endpoint-type Interface \
                                                           --service-name com.amazonaws.us-east-2.ssmmessages \
                                                           --private-dns-enabled \
                                                           --security-group-ids $ohio_management_vpce_sg_id \
                                                           --subnet-ids $ohio_management_endpoint_subneta_id $ohio_management_endpoint_subnetb_id $ohio_management_endpoint_subnetc_id \
                                                           --client-token $(date +%s) \
                                                           --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Management-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                           --query 'VpcEndpoint.VpcEndpointId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "ohio_management_ssmm_vpce_id=$ohio_management_ssmm_vpce_id"


## Ohio Core VPC ######################################################################################################
echo "core_account_id=$core_account_id"

profile=$core_profile

# Create VPC
ohio_core_vpc_id=$(aws ec2 create-vpc --cidr-block $ohio_core_vpc_cidr \
                                      --query 'Vpc.VpcId' \
                                      --profile $profile --region us-east-2 --output text)
echo "ohio_core_vpc_id=$ohio_core_vpc_id"

aws ec2 create-tags --resources $ohio_core_vpc_id \
                    --tags Key=Name,Value=Core-VPC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $ohio_core_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $ohio_core_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-2 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Core" \
                          --profile $profile --region us-east-2 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $ohio_core_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-2:$core_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Core" \
                         --deliver-logs-permission-arn "arn:aws:iam::$core_account_id:role/FlowLog" \
                         --profile $profile --region us-east-2 --output text

# Create Internet Gateway & Attach
ohio_core_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "ohio_core_igw_id=$ohio_core_igw_id"

aws ec2 create-tags --resources $ohio_core_igw_id \
                    --tags Key=Name,Value=Core-InternetGateway \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 attach-internet-gateway --vpc-id $ohio_core_vpc_id \
                                --internet-gateway-id $ohio_core_igw_id \
                                --profile $profile --region us-east-2 --output text

# Create Private Hosted Zone
ohio_core_private_hostedzone_id=$(aws route53 create-hosted-zone --name $ohio_core_private_domain \
                                                                 --vpc VPCRegion=us-east-2,VPCId=$ohio_core_vpc_id \
                                                                 --hosted-zone-config Comment="Private Zone for $ohio_core_private_domain",PrivateZone=true \
                                                                 --caller-reference $(date +%s) \
                                                                 --query 'HostedZone.Id' \
                                                                 --profile $profile --region us-east-2 --output text | cut -f3 -d /)
echo "ohio_core_private_hostedzone_id=$ohio_core_private_hostedzone_id"

# Create DHCP Options Set
ohio_core_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$ohio_core_private_domain]" \
                                                                      "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                --query 'DhcpOptions.DhcpOptionsId' \
                                                --profile $profile --region us-east-2 --output text)
echo "ohio_core_dopt_id=$ohio_core_dopt_id"

aws ec2 create-tags --resources $ohio_core_dopt_id \
                    --tags Key=Name,Value=Core-DHCPOptions \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 associate-dhcp-options --vpc-id $ohio_core_vpc_id \
                               --dhcp-options-id $ohio_core_dopt_id \
                               --profile $profile --region us-east-2 --output text

# Create Public Subnet A
ohio_core_public_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                    --cidr-block $ohio_core_subnet_publica_cidr \
                                                    --availability-zone us-east-2a \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_core_public_subneta_id=$ohio_core_public_subneta_id"

aws ec2 create-tags --resources $ohio_core_public_subneta_id \
                    --tags Key=Name,Value=Core-PublicSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet B
ohio_core_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                    --cidr-block $ohio_core_subnet_publicb_cidr \
                                                    --availability-zone us-east-2b \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_core_public_subnetb_id=$ohio_core_public_subnetb_id"

aws ec2 create-tags --resources $ohio_core_public_subnetb_id \
                    --tags Key=Name,Value=Core-PublicSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet C
ohio_core_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                    --cidr-block $ohio_core_subnet_publicc_cidr \
                                                    --availability-zone us-east-2c \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_core_public_subnetc_id=$ohio_core_public_subnetc_id"

aws ec2 create-tags --resources $ohio_core_public_subnetc_id \
                    --tags Key=Name,Value=Core-PublicSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet A
ohio_core_web_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                 --cidr-block $ohio_core_subnet_weba_cidr \
                                                 --availability-zone us-east-2a \
                                                 --query 'Subnet.SubnetId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "ohio_core_web_subneta_id=$ohio_core_web_subneta_id"

aws ec2 create-tags --resources $ohio_core_web_subneta_id \
                    --tags Key=Name,Value=Core-WebSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet B
ohio_core_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                 --cidr-block $ohio_core_subnet_webb_cidr \
                                                 --availability-zone us-east-2b \
                                                 --query 'Subnet.SubnetId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "ohio_core_web_subnetb_id=$ohio_core_web_subnetb_id"

aws ec2 create-tags --resources $ohio_core_web_subnetb_id \
                    --tags Key=Name,Value=Core-WebSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet C
ohio_core_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                 --cidr-block $ohio_core_subnet_webc_cidr \
                                                 --availability-zone us-east-2c \
                                                 --query 'Subnet.SubnetId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "ohio_core_web_subnetc_id=$ohio_core_web_subnetc_id"

aws ec2 create-tags --resources $ohio_core_web_subnetc_id \
                    --tags Key=Name,Value=Core-WebSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet A
ohio_core_application_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                         --cidr-block $ohio_core_subnet_applicationa_cidr \
                                                         --availability-zone us-east-2a \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "ohio_core_application_subneta_id=$ohio_core_application_subneta_id"

aws ec2 create-tags --resources $ohio_core_application_subneta_id \
                    --tags Key=Name,Value=Core-ApplicationSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet B
ohio_core_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                         --cidr-block $ohio_core_subnet_applicationb_cidr \
                                                         --availability-zone us-east-2b \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "ohio_core_application_subnetb_id=$ohio_core_application_subnetb_id"

aws ec2 create-tags --resources $ohio_core_application_subnetb_id \
                    --tags Key=Name,Value=Core-ApplicationSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet C
ohio_core_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                         --cidr-block $ohio_core_subnet_applicationc_cidr \
                                                         --availability-zone us-east-2c \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "ohio_core_application_subnetc_id=$ohio_core_application_subnetc_id"

aws ec2 create-tags --resources $ohio_core_application_subnetc_id \
                    --tags Key=Name,Value=Core-ApplicationSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet A
ohio_core_database_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                      --cidr-block $ohio_core_subnet_databasea_cidr \
                                                      --availability-zone us-east-2a \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "ohio_core_database_subneta_id=$ohio_core_database_subneta_id"

aws ec2 create-tags --resources $ohio_core_database_subneta_id \
                    --tags Key=Name,Value=Core-DatabaseSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet B
ohio_core_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                      --cidr-block $ohio_core_subnet_databaseb_cidr \
                                                      --availability-zone us-east-2b \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "ohio_core_database_subnetb_id=$ohio_core_database_subnetb_id"

aws ec2 create-tags --resources $ohio_core_database_subnetb_id \
                    --tags Key=Name,Value=Core-DatabaseSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet C
ohio_core_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                      --cidr-block $ohio_core_subnet_databasec_cidr \
                                                      --availability-zone us-east-2c \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "ohio_core_database_subnetc_id=$ohio_core_database_subnetc_id"

aws ec2 create-tags --resources $ohio_core_database_subnetc_id \
                    --tags Key=Name,Value=Core-DatabaseSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet A
ohio_core_management_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                        --cidr-block $ohio_core_subnet_managementa_cidr \
                                                        --availability-zone us-east-2a \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-2 --output text)
echo "ohio_core_management_subneta_id=$ohio_core_management_subneta_id"

aws ec2 create-tags --resources $ohio_core_management_subneta_id \
                    --tags Key=Name,Value=Core-ManagementSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet B
ohio_core_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                        --cidr-block $ohio_core_subnet_managementb_cidr \
                                                        --availability-zone us-east-2b \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-2 --output text)
echo "ohio_core_management_subnetb_id=$ohio_core_management_subnetb_id"

aws ec2 create-tags --resources $ohio_core_management_subnetb_id \
                    --tags Key=Name,Value=Core-ManagementSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet C
ohio_core_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                        --cidr-block $ohio_core_subnet_managementc_cidr \
                                                        --availability-zone us-east-2c \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-2 --output text)
echo "ohio_core_management_subnetc_id=$ohio_core_management_subnetc_id"

aws ec2 create-tags --resources $ohio_core_management_subnetc_id \
                    --tags Key=Name,Value=Core-ManagementSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet A
ohio_core_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                     --cidr-block $ohio_core_subnet_gatewaya_cidr \
                                                     --availability-zone us-east-2a \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_core_gateway_subneta_id=$ohio_core_gateway_subneta_id"

aws ec2 create-tags --resources $ohio_core_gateway_subneta_id \
                    --tags Key=Name,Value=Core-GatewaySubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet B
ohio_core_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                     --cidr-block $ohio_core_subnet_gatewayb_cidr \
                                                     --availability-zone us-east-2b \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_core_gateway_subnetb_id=$ohio_core_gateway_subnetb_id"

aws ec2 create-tags --resources $ohio_core_gateway_subnetb_id \
                    --tags Key=Name,Value=Core-GatewaySubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet C
ohio_core_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                     --cidr-block $ohio_core_subnet_gatewayc_cidr \
                                                     --availability-zone us-east-2c \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_core_gateway_subnetc_id=$ohio_core_gateway_subnetc_id"

aws ec2 create-tags --resources $ohio_core_gateway_subnetc_id \
                    --tags Key=Name,Value=Core-GatewaySubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet A
ohio_core_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                      --cidr-block $ohio_core_subnet_endpointa_cidr \
                                                      --availability-zone us-east-2a \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "ohio_core_endpoint_subneta_id=$ohio_core_endpoint_subneta_id"

aws ec2 create-tags --resources $ohio_core_endpoint_subneta_id \
                    --tags Key=Name,Value=Core-EndpointSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet B
ohio_core_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                      --cidr-block $ohio_core_subnet_endpointb_cidr \
                                                      --availability-zone us-east-2b \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "ohio_core_endpoint_subnetb_id=$ohio_core_endpoint_subnetb_id"

aws ec2 create-tags --resources $ohio_core_endpoint_subnetb_id \
                    --tags Key=Name,Value=Core-EndpointSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet C
ohio_core_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_core_vpc_id \
                                                      --cidr-block $ohio_core_subnet_endpointc_cidr \
                                                      --availability-zone us-east-2c \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "ohio_core_endpoint_subnetc_id=$ohio_core_endpoint_subnetc_id"

aws ec2 create-tags --resources $ohio_core_endpoint_subnetc_id \
                    --tags Key=Name,Value=Core-EndpointSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
ohio_core_public_rtb_id=$(aws ec2 create-route-table --vpc-id $ohio_core_vpc_id \
                                                     --query 'RouteTable.RouteTableId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_core_public_rtb_id=$ohio_core_public_rtb_id"

aws ec2 create-tags --resources $ohio_core_public_rtb_id \
                    --tags Key=Name,Value=Core-PublicRouteTable \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $ohio_core_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $ohio_core_igw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $ohio_core_public_rtb_id --subnet-id $ohio_core_public_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_public_rtb_id --subnet-id $ohio_core_public_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_public_rtb_id --subnet-id $ohio_core_public_subnetc_id \
                              --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $ohio_core_public_rtb_id --subnet-id $ohio_core_web_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_public_rtb_id --subnet-id $ohio_core_web_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_public_rtb_id --subnet-id $ohio_core_web_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create NAT Gateways
if [ $use_ngw = 1 ]; then
  ohio_core_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                --query 'AllocationId' \
                                                --profile $profile --region us-east-2 --output text)
  echo "ohio_core_ngw_eipa=$ohio_core_ngw_eipa"

  aws ec2 create-tags --resources $ohio_core_ngw_eipa \
                      --tags Key=Name,Value=Core-NAT-EIPA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  ohio_core_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_core_ngw_eipa \
                                                 --subnet-id $ohio_core_public_subneta_id \
                                                 --client-token $(date +%s) \
                                                 --query 'NatGateway.NatGatewayId' \
                                                 --profile $profile --region us-east-2 --output text)
  echo "ohio_core_ngwa_id=$ohio_core_ngwa_id"

  aws ec2 create-tags --resources $ohio_core_ngwa_id \
                      --tags Key=Name,Value=Core-NAT-GatewayA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  if [ $ha_ngw = 1 ]; then
    ohio_core_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                  --query 'AllocationId' \
                                                  --profile $profile --region us-east-2 --output text)
    echo "ohio_core_ngw_eipb=$ohio_core_ngw_eipb"

    aws ec2 create-tags --resources $ohio_core_ngw_eipb \
                        --tags Key=Name,Value=Core-NAT-EIPB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    ohio_core_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_core_ngw_eipb \
                                                   --subnet-id $ohio_core_public_subnetb_id \
                                                   --client-token $(date +%s) \
                                                   --query 'NatGateway.NatGatewayId' \
                                                   --profile $profile --region us-east-2 --output text)
    echo "ohio_core_ngwb_id=$ohio_core_ngwb_id"

    aws ec2 create-tags --resources $ohio_core_ngwb_id \
                        --tags Key=Name,Value=Core-NAT-GatewayB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    ohio_core_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                  --query 'AllocationId' \
                                                  --profile $profile --region us-east-2 --output text)
    echo "ohio_core_ngw_eipc=$ohio_core_ngw_eipc"

    aws ec2 create-tags --resources $ohio_core_ngw_eipc \
                        --tags Key=Name,Value=Core-NAT-EIPC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    ohio_core_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_core_ngw_eipc \
                                                   --subnet-id $ohio_core_public_subnetc_id \
                                                   --client-token $(date +%s) \
                                                   --query 'NatGateway.NatGatewayId' \
                                                   --profile $profile --region us-east-2 --output text)
    echo "ohio_core_ngwc_id=$ohio_core_ngwc_id"

    aws ec2 create-tags --resources $ohio_core_ngwc_id \
                        --tags Key=Name,Value=Core-NAT-GatewayC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text
  fi
else
  # Create NAT Security Group
  ohio_core_nat_sg_id=$(aws ec2 create-security-group --group-name Core-NAT-InstanceSecurityGroup \
                                                      --description Core-NAT-InstanceSecurityGroup \
                                                      --vpc-id $ohio_core_vpc_id \
                                                      --query 'GroupId' \
                                                      --profile $profile --region us-east-2 --output text)
  echo "ohio_core_nat_sg_id=$ohio_core_nat_sg_id"

  aws ec2 create-tags --resources $ohio_core_nat_sg_id \
                      --tags Key=Name,Value=Core-NAT-InstanceSecurityGroup \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Utility,Value=NAT \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  aws ec2 authorize-security-group-ingress --group-id $ohio_core_nat_sg_id \
                                           --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$ohio_core_vpc_cidr,Description=\"VPC (All)\"}]" \
                                           --profile $profile --region us-east-2 --output text

  # Create NAT Instance
  ohio_core_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                    --instance-type t3a.nano \
                                                    --iam-instance-profile Name=ManagedInstance \
                                                    --key-name administrator \
                                                    --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Core-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_core_nat_sg_id],SubnetId=$ohio_core_public_subneta_id" \
                                                    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Core-NAT-Instance},{Key=Hostname,Value=cmlue2cnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                    --query 'Instances[0].InstanceId' \
                                                    --profile $profile --region us-east-2 --output text)
  echo "ohio_core_nat_instance_id=$ohio_core_nat_instance_id"

  aws ec2 modify-instance-attribute --instance-id $ohio_core_nat_instance_id \
                                    --no-source-dest-check \
                                    --profile $profile --region us-east-2 --output text

  ohio_core_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $ohio_core_nat_instance_id \
                                                             --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                             --profile $profile --region us-east-2 --output text)
  echo "ohio_core_nat_instance_eni_id=$ohio_core_nat_instance_eni_id"

  ohio_core_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_core_nat_instance_id \
                                                                 --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                 --profile $profile --region us-east-2 --output text)
  echo "ohio_core_nat_instance_private_ip=$ohio_core_nat_instance_private_ip"
fi

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
ohio_core_private_rtba_id=$(aws ec2 create-route-table --vpc-id $ohio_core_vpc_id \
                                                       --query 'RouteTable.RouteTableId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "ohio_core_private_rtba_id=$ohio_core_private_rtba_id"

aws ec2 create-tags --resources $ohio_core_private_rtba_id \
                    --tags Key=Name,Value=Core-PrivateRouteTableA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

if [ $use_ngw = 1 ]; then
  aws ec2 create-route --route-table-id $ohio_core_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ohio_core_ngwa_id \
                       --profile $profile --region us-east-2 --output text
else
  aws ec2 create-route --route-table-id $ohio_core_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ohio_core_nat_instance_eni_id \
                       --profile $profile --region us-east-2 --output text
fi

aws ec2 associate-route-table --route-table-id $ohio_core_private_rtba_id --subnet-id $ohio_core_application_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_private_rtba_id --subnet-id $ohio_core_database_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_private_rtba_id --subnet-id $ohio_core_management_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_private_rtba_id --subnet-id $ohio_core_gateway_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_private_rtba_id --subnet-id $ohio_core_endpoint_subneta_id \
                              --profile $profile --region us-east-2 --output text

ohio_core_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $ohio_core_vpc_id \
                                                       --query 'RouteTable.RouteTableId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "ohio_core_private_rtbb_id=$ohio_core_private_rtbb_id"

aws ec2 create-tags --resources $ohio_core_private_rtbb_id \
                    --tags Key=Name,Value=Core-PrivateRouteTableB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then ohio_core_ngw_id=$ohio_core_ngwb_id; else ohio_core_ngw_id=$ohio_core_ngwa_id; fi
  aws ec2 create-route --route-table-id $ohio_core_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ohio_core_ngw_id \
                       --profile $profile --region us-east-2 --output text
else
  aws ec2 create-route --route-table-id $ohio_core_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ohio_core_nat_instance_eni_id \
                       --profile $profile --region us-east-2 --output text
fi

aws ec2 associate-route-table --route-table-id $ohio_core_private_rtbb_id --subnet-id $ohio_core_application_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_private_rtbb_id --subnet-id $ohio_core_database_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_private_rtbb_id --subnet-id $ohio_core_management_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_private_rtbb_id --subnet-id $ohio_core_gateway_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_private_rtbb_id --subnet-id $ohio_core_endpoint_subnetb_id \
                              --profile $profile --region us-east-2 --output text

ohio_core_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $ohio_core_vpc_id \
                                                       --query 'RouteTable.RouteTableId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "ohio_core_private_rtbc_id=$ohio_core_private_rtbc_id"

aws ec2 create-tags --resources $ohio_core_private_rtbc_id \
                    --tags Key=Name,Value=Core-PrivateRouteTableC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then ohio_core_ngw_id=$ohio_core_ngwc_id; else ohio_core_ngw_id=$ohio_core_ngwa_id; fi
  aws ec2 create-route --route-table-id $ohio_core_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ohio_core_ngw_id \
                       --profile $profile --region us-east-2 --output text
else
  aws ec2 create-route --route-table-id $ohio_core_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ohio_core_nat_instance_eni_id \
                       --profile $profile --region us-east-2 --output text
fi

aws ec2 associate-route-table --route-table-id $ohio_core_private_rtbc_id --subnet-id $ohio_core_application_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_private_rtbc_id --subnet-id $ohio_core_database_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_private_rtbc_id --subnet-id $ohio_core_management_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_private_rtbc_id --subnet-id $ohio_core_gateway_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_core_private_rtbc_id --subnet-id $ohio_core_endpoint_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create VPC Endpoint Security Group
ohio_core_vpce_sg_id=$(aws ec2 create-security-group --group-name Core-VPCEndpointSecurityGroup \
                                                     --description Core-VPCEndpointSecurityGroup \
                                                     --vpc-id $ohio_core_vpc_id \
                                                     --query 'GroupId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_core_vpce_sg_id=$ohio_core_vpce_sg_id"

aws ec2 create-tags --resources $ohio_core_vpce_sg_id \
                    --tags Key=Name,Value=Core-VPCEndpointSecurityGroup \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_core_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ohio_core_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_core_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ohio_core_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create VPC Endpoints for SSM and SSMMessages
ohio_core_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ohio_core_vpc_id \
                                                    --vpc-endpoint-type Interface \
                                                    --service-name com.amazonaws.us-east-2.ssm \
                                                    --private-dns-enabled \
                                                    --security-group-ids $ohio_core_vpce_sg_id \
                                                    --subnet-ids $ohio_core_endpoint_subneta_id $ohio_core_endpoint_subnetb_id $ohio_core_endpoint_subnetc_id \
                                                    --client-token $(date +%s) \
                                                    --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Core-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                    --query 'VpcEndpoint.VpcEndpointId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_core_ssm_vpce_id=$ohio_core_ssm_vpce_id"

ohio_core_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ohio_core_vpc_id \
                                                     --vpc-endpoint-type Interface \
                                                     --service-name com.amazonaws.us-east-2.ssmmessages \
                                                     --private-dns-enabled \
                                                     --security-group-ids $ohio_core_vpce_sg_id \
                                                     --subnet-ids $ohio_core_endpoint_subneta_id $ohio_core_endpoint_subnetb_id $ohio_core_endpoint_subnetc_id \
                                                     --client-token $(date +%s) \
                                                     --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Core-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                     --query 'VpcEndpoint.VpcEndpointId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_core_ssmm_vpce_id=$ohio_core_ssmm_vpce_id"


## Ohio Log VPC #######################################################################################################
echo "log_account_id=$log_account_id"

profile=$log_profile

# Create VPC
ohio_log_vpc_id=$(aws ec2 create-vpc --cidr-block $ohio_log_vpc_cidr \
                                     --query 'Vpc.VpcId' \
                                     --profile $profile --region us-east-2 --output text)
echo "ohio_log_vpc_id=$ohio_log_vpc_id"

aws ec2 create-tags --resources $ohio_log_vpc_id \
                    --tags Key=Name,Value=Log-VPC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $ohio_log_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $ohio_log_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-2 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Log" \
                          --profile $profile --region us-east-2 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $ohio_log_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-2:$log_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Log" \
                         --deliver-logs-permission-arn "arn:aws:iam::$log_account_id:role/FlowLog" \
                         --profile $profile --region us-east-2 --output text

# Create Internet Gateway & Attach
ohio_log_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "ohio_log_igw_id=$ohio_log_igw_id"

aws ec2 create-tags --resources $ohio_log_igw_id \
                    --tags Key=Name,Value=Log-InternetGateway \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 attach-internet-gateway --vpc-id $ohio_log_vpc_id \
                                --internet-gateway-id $ohio_log_igw_id \
                                --profile $profile --region us-east-2 --output text

# Create Private Hosted Zone
ohio_log_private_hostedzone_id=$(aws route53 create-hosted-zone --name $ohio_log_private_domain \
                                                                --vpc VPCRegion=us-east-2,VPCId=$ohio_log_vpc_id \
                                                                --hosted-zone-config Comment="Private Zone for $ohio_log_private_domain",PrivateZone=true \
                                                                --caller-reference $(date +%s) \
                                                                --query 'HostedZone.Id' \
                                                                --profile $profile --region us-east-2 --output text | cut -f3 -d /)
echo "ohio_log_private_hostedzone_id=$ohio_log_private_hostedzone_id"

# Create DHCP Options Set
ohio_log_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$ohio_log_private_domain]" \
                                                                     "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                               --query 'DhcpOptions.DhcpOptionsId' \
                                               --profile $profile --region us-east-2 --output text)
echo "ohio_log_dopt_id=$ohio_log_dopt_id"

aws ec2 create-tags --resources $ohio_log_dopt_id \
                    --tags Key=Name,Value=Log-DHCPOptions \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 associate-dhcp-options --vpc-id $ohio_log_vpc_id \
                               --dhcp-options-id $ohio_log_dopt_id \
                               --profile $profile --region us-east-2 --output text

# Create Public Subnet A
ohio_log_public_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                   --cidr-block $ohio_log_subnet_publica_cidr \
                                                   --availability-zone us-east-2a \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "ohio_log_public_subneta_id=$ohio_log_public_subneta_id"

aws ec2 create-tags --resources $ohio_log_public_subneta_id \
                    --tags Key=Name,Value=Log-PublicSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet B
ohio_log_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                   --cidr-block $ohio_log_subnet_publicb_cidr \
                                                   --availability-zone us-east-2b \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "ohio_log_public_subnetb_id=$ohio_log_public_subnetb_id"

aws ec2 create-tags --resources $ohio_log_public_subnetb_id \
                    --tags Key=Name,Value=Log-PublicSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet C
ohio_log_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                   --cidr-block $ohio_log_subnet_publicc_cidr \
                                                   --availability-zone us-east-2c \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "ohio_log_public_subnetc_id=$ohio_log_public_subnetc_id"

aws ec2 create-tags --resources $ohio_log_public_subnetc_id \
                    --tags Key=Name,Value=Log-PublicSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet A
ohio_log_web_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                --cidr-block $ohio_log_subnet_weba_cidr \
                                                --availability-zone us-east-2a \
                                                --query 'Subnet.SubnetId' \
                                                --profile $profile --region us-east-2 --output text)
echo "ohio_log_web_subneta_id=$ohio_log_web_subneta_id"

aws ec2 create-tags --resources $ohio_log_web_subneta_id \
                    --tags Key=Name,Value=Log-WebSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet B
ohio_log_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                --cidr-block $ohio_log_subnet_webb_cidr \
                                                --availability-zone us-east-2b \
                                                --query 'Subnet.SubnetId' \
                                                --profile $profile --region us-east-2 --output text)
echo "ohio_log_web_subnetb_id=$ohio_log_web_subnetb_id"

aws ec2 create-tags --resources $ohio_log_web_subnetb_id \
                    --tags Key=Name,Value=Log-WebSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet C
ohio_log_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                --cidr-block $ohio_log_subnet_webc_cidr \
                                                --availability-zone us-east-2c \
                                                --query 'Subnet.SubnetId' \
                                                --profile $profile --region us-east-2 --output text)
echo "ohio_log_web_subnetc_id=$ohio_log_web_subnetc_id"

aws ec2 create-tags --resources $ohio_log_web_subnetc_id \
                    --tags Key=Name,Value=Log-WebSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet A
ohio_log_application_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                        --cidr-block $ohio_log_subnet_applicationa_cidr \
                                                        --availability-zone us-east-2a \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-2 --output text)
echo "ohio_log_application_subneta_id=$ohio_log_application_subneta_id"

aws ec2 create-tags --resources $ohio_log_application_subneta_id \
                    --tags Key=Name,Value=Log-ApplicationSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet B
ohio_log_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                        --cidr-block $ohio_log_subnet_applicationb_cidr \
                                                        --availability-zone us-east-2b \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-2 --output text)
echo "ohio_log_application_subnetb_id=$ohio_log_application_subnetb_id"

aws ec2 create-tags --resources $ohio_log_application_subnetb_id \
                    --tags Key=Name,Value=Log-ApplicationSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet C
ohio_log_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                        --cidr-block $ohio_log_subnet_applicationc_cidr \
                                                        --availability-zone us-east-2c \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region us-east-2 --output text)
echo "ohio_log_application_subnetc_id=$ohio_log_application_subnetc_id"

aws ec2 create-tags --resources $ohio_log_application_subnetc_id \
                    --tags Key=Name,Value=Log-ApplicationSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet A
ohio_log_database_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                     --cidr-block $ohio_log_subnet_databasea_cidr \
                                                     --availability-zone us-east-2a \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_log_database_subneta_id=$ohio_log_database_subneta_id"

aws ec2 create-tags --resources $ohio_log_database_subneta_id \
                    --tags Key=Name,Value=Log-DatabaseSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet B
ohio_log_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                     --cidr-block $ohio_log_subnet_databaseb_cidr \
                                                     --availability-zone us-east-2b \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_log_database_subnetb_id=$ohio_log_database_subnetb_id"

aws ec2 create-tags --resources $ohio_log_database_subnetb_id \
                    --tags Key=Name,Value=Log-DatabaseSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet C
ohio_log_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                     --cidr-block $ohio_log_subnet_databasec_cidr \
                                                     --availability-zone us-east-2c \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_log_database_subnetc_id=$ohio_log_database_subnetc_id"

aws ec2 create-tags --resources $ohio_log_database_subnetc_id \
                    --tags Key=Name,Value=Log-DatabaseSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet A
ohio_log_management_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                       --cidr-block $ohio_log_subnet_managementa_cidr \
                                                       --availability-zone us-east-2a \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "ohio_log_management_subneta_id=$ohio_log_management_subneta_id"

aws ec2 create-tags --resources $ohio_log_management_subneta_id \
                    --tags Key=Name,Value=Log-ManagementSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet B
ohio_log_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                       --cidr-block $ohio_log_subnet_managementb_cidr \
                                                       --availability-zone us-east-2b \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "ohio_log_management_subnetb_id=$ohio_log_management_subnetb_id"

aws ec2 create-tags --resources $ohio_log_management_subnetb_id \
                    --tags Key=Name,Value=Log-ManagementSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet C
ohio_log_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                       --cidr-block $ohio_log_subnet_managementc_cidr \
                                                       --availability-zone us-east-2c \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "ohio_log_management_subnetc_id=$ohio_log_management_subnetc_id"

aws ec2 create-tags --resources $ohio_log_management_subnetc_id \
                    --tags Key=Name,Value=Log-ManagementSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet A
ohio_log_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                    --cidr-block $ohio_log_subnet_gatewaya_cidr \
                                                    --availability-zone us-east-2a \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_log_gateway_subneta_id=$ohio_log_gateway_subneta_id"

aws ec2 create-tags --resources $ohio_log_gateway_subneta_id \
                    --tags Key=Name,Value=Log-GatewaySubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet B
ohio_log_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                    --cidr-block $ohio_log_subnet_gatewayb_cidr \
                                                    --availability-zone us-east-2b \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_log_gateway_subnetb_id=$ohio_log_gateway_subnetb_id"

aws ec2 create-tags --resources $ohio_log_gateway_subnetb_id \
                    --tags Key=Name,Value=Log-GatewaySubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet C
ohio_log_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                    --cidr-block $ohio_log_subnet_gatewayc_cidr \
                                                    --availability-zone us-east-2c \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_log_gateway_subnetc_id=$ohio_log_gateway_subnetc_id"

aws ec2 create-tags --resources $ohio_log_gateway_subnetc_id \
                    --tags Key=Name,Value=Log-GatewaySubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet A
ohio_log_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                     --cidr-block $ohio_log_subnet_endpointa_cidr \
                                                     --availability-zone us-east-2a \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_log_endpoint_subneta_id=$ohio_log_endpoint_subneta_id"

aws ec2 create-tags --resources $ohio_log_endpoint_subneta_id \
                    --tags Key=Name,Value=Log-EndpointSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet B
ohio_log_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                     --cidr-block $ohio_log_subnet_endpointb_cidr \
                                                     --availability-zone us-east-2b \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_log_endpoint_subnetb_id=$ohio_log_endpoint_subnetb_id"

aws ec2 create-tags --resources $ohio_log_endpoint_subnetb_id \
                    --tags Key=Name,Value=Log-EndpointSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet C
ohio_log_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $ohio_log_vpc_id \
                                                     --cidr-block $ohio_log_subnet_endpointc_cidr \
                                                     --availability-zone us-east-2c \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_log_endpoint_subnetc_id=$ohio_log_endpoint_subnetc_id"

aws ec2 create-tags --resources $ohio_log_endpoint_subnetc_id \
                    --tags Key=Name,Value=Log-EndpointSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
ohio_log_public_rtb_id=$(aws ec2 create-route-table --vpc-id $ohio_log_vpc_id \
                                                    --query 'RouteTable.RouteTableId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_log_public_rtb_id=$ohio_log_public_rtb_id"

aws ec2 create-tags --resources $ohio_log_public_rtb_id \
                    --tags Key=Name,Value=Log-PublicRouteTable \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $ohio_log_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $ohio_log_igw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $ohio_log_public_rtb_id --subnet-id $ohio_log_public_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_public_rtb_id --subnet-id $ohio_log_public_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_public_rtb_id --subnet-id $ohio_log_public_subnetc_id \
                              --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $ohio_log_public_rtb_id --subnet-id $ohio_log_web_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_public_rtb_id --subnet-id $ohio_log_web_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_public_rtb_id --subnet-id $ohio_log_web_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create NAT Gateways
if [ $use_ngw = 1 ]; then
  ohio_log_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                               --query 'AllocationId' \
                                               --profile $profile --region us-east-2 --output text)
  echo "ohio_log_ngw_eipa=$ohio_log_ngw_eipa"

  aws ec2 create-tags --resources $ohio_log_ngw_eipa \
                      --tags Key=Name,Value=Log-NAT-EIPA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  ohio_log_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_log_ngw_eipa \
                                                --subnet-id $ohio_log_public_subneta_id \
                                                --client-token $(date +%s) \
                                                --query 'NatGateway.NatGatewayId' \
                                                --profile $profile --region us-east-2 --output text)
  echo "ohio_log_ngwa_id=$ohio_log_ngwa_id"

  aws ec2 create-tags --resources $ohio_log_ngwa_id \
                      --tags Key=Name,Value=Log-NAT-GatewayA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  if [ $ha_ngw = 1 ]; then
    ohio_log_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                 --query 'AllocationId' \
                                                 --profile $profile --region us-east-2 --output text)
    echo "ohio_log_ngw_eipb=$ohio_log_ngw_eipb"

    aws ec2 create-tags --resources $ohio_log_ngw_eipb \
                        --tags Key=Name,Value=Log-NAT-EIPB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Log \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    ohio_log_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_log_ngw_eipb \
                                                  --subnet-id $ohio_log_public_subnetb_id \
                                                  --client-token $(date +%s) \
                                                  --query 'NatGateway.NatGatewayId' \
                                                  --profile $profile --region us-east-2 --output text)
    echo "ohio_log_ngwb_id=$ohio_log_ngwb_id"

    aws ec2 create-tags --resources $ohio_log_ngwb_id \
                        --tags Key=Name,Value=Log-NAT-GatewayB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Log \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    ohio_log_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                 --query 'AllocationId' \
                                                 --profile $profile --region us-east-2 --output text)
    echo "ohio_log_ngw_eipc=$ohio_log_ngw_eipc"

    aws ec2 create-tags --resources $ohio_log_ngw_eipc \
                        --tags Key=Name,Value=Log-NAT-EIPC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Log \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    ohio_log_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $ohio_log_ngw_eipc \
                                                  --subnet-id $ohio_log_public_subnetc_id \
                                                  --client-token $(date +%s) \
                                                  --query 'NatGateway.NatGatewayId' \
                                                  --profile $profile --region us-east-2 --output text)
    echo "ohio_log_ngwc_id=$ohio_log_ngwc_id"

    aws ec2 create-tags --resources $ohio_log_ngwc_id \
                        --tags Key=Name,Value=Log-NAT-GatewayC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Log \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text
  fi
else
  # Create NAT Security Group
  ohio_log_nat_sg_id=$(aws ec2 create-security-group --group-name Log-NAT-InstanceSecurityGroup \
                                                     --description Log-NAT-InstanceSecurityGroup \
                                                     --vpc-id $ohio_log_vpc_id \
                                                     --query 'GroupId' \
                                                     --profile $profile --region us-east-2 --output text)
  echo "ohio_log_nat_sg_id=$ohio_log_nat_sg_id"

  aws ec2 create-tags --resources $ohio_log_nat_sg_id \
                      --tags Key=Name,Value=Log-NAT-InstanceSecurityGroup \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Utility,Value=NAT \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  aws ec2 authorize-security-group-ingress --group-id $ohio_log_nat_sg_id \
                                           --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$ohio_log_vpc_cidr,Description=\"VPC (All)\"}]" \
                                           --profile $profile --region us-east-2 --output text

  # Create NAT Instance
  ohio_log_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                   --instance-type t3a.nano \
                                                   --iam-instance-profile Name=ManagedInstance \
                                                   --key-name administrator \
                                                   --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Log-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ohio_log_nat_sg_id],SubnetId=$ohio_log_public_subneta_id" \
                                                   --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Log-NAT-Instance},{Key=Hostname,Value=cmlue2lnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                   --query 'Instances[0].InstanceId' \
                                                   --profile $profile --region us-east-2 --output text)
  echo "ohio_log_nat_instance_id=$ohio_log_nat_instance_id"

  aws ec2 modify-instance-attribute --instance-id $ohio_log_nat_instance_id \
                                    --no-source-dest-check \
                                    --profile $profile --region us-east-2 --output text

  ohio_log_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $ohio_log_nat_instance_id \
                                                            --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                            --profile $profile --region us-east-2 --output text)
  echo "ohio_log_nat_instance_eni_id=$ohio_log_nat_instance_eni_id"

  ohio_log_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $ohio_log_nat_instance_id \
                                                                --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                --profile $profile --region us-east-2 --output text)
  echo "ohio_log_nat_instance_private_ip=$ohio_log_nat_instance_private_ip"
fi

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
ohio_log_private_rtba_id=$(aws ec2 create-route-table --vpc-id $ohio_log_vpc_id \
                                                      --query 'RouteTable.RouteTableId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "ohio_log_private_rtba_id=$ohio_log_private_rtba_id"

aws ec2 create-tags --resources $ohio_log_private_rtba_id \
                    --tags Key=Name,Value=Log-PrivateRouteTableA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

if [ $use_ngw = 1 ]; then
  aws ec2 create-route --route-table-id $ohio_log_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ohio_log_ngwa_id \
                       --profile $profile --region us-east-2 --output text
else
  aws ec2 create-route --route-table-id $ohio_log_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ohio_log_nat_instance_eni_id \
                       --profile $profile --region us-east-2 --output text
fi

aws ec2 associate-route-table --route-table-id $ohio_log_private_rtba_id --subnet-id $ohio_log_application_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_private_rtba_id --subnet-id $ohio_log_database_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_private_rtba_id --subnet-id $ohio_log_management_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_private_rtba_id --subnet-id $ohio_log_gateway_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_private_rtba_id --subnet-id $ohio_log_endpoint_subneta_id \
                              --profile $profile --region us-east-2 --output text

ohio_log_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $ohio_log_vpc_id \
                                                      --query 'RouteTable.RouteTableId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "ohio_log_private_rtbb_id=$ohio_log_private_rtbb_id"

aws ec2 create-tags --resources $ohio_log_private_rtbb_id \
                    --tags Key=Name,Value=Log-PrivateRouteTableB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then ohio_log_ngw_id=$ohio_log_ngwb_id; else ohio_log_ngw_id=$ohio_log_ngwa_id; fi
  aws ec2 create-route --route-table-id $ohio_log_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ohio_log_ngw_id \
                       --profile $profile --region us-east-2 --output text
else
  aws ec2 create-route --route-table-id $ohio_log_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ohio_log_nat_instance_eni_id \
                       --profile $profile --region us-east-2 --output text
fi

aws ec2 associate-route-table --route-table-id $ohio_log_private_rtbb_id --subnet-id $ohio_log_application_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_private_rtbb_id --subnet-id $ohio_log_database_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_private_rtbb_id --subnet-id $ohio_log_management_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_private_rtbb_id --subnet-id $ohio_log_gateway_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_private_rtbb_id --subnet-id $ohio_log_endpoint_subnetb_id \
                              --profile $profile --region us-east-2 --output text

ohio_log_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $ohio_log_vpc_id \
                                                      --query 'RouteTable.RouteTableId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "ohio_log_private_rtbc_id=$ohio_log_private_rtbc_id"

aws ec2 create-tags --resources $ohio_log_private_rtbc_id \
                    --tags Key=Name,Value=Log-PrivateRouteTableC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then ohio_log_ngw_id=$ohio_log_ngwc_id; else ohio_log_ngw_id=$ohio_log_ngwa_id; fi
  aws ec2 create-route --route-table-id $ohio_log_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ohio_log_ngw_id \
                       --profile $profile --region us-east-2 --output text
else
  aws ec2 create-route --route-table-id $ohio_log_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ohio_log_nat_instance_eni_id \
                       --profile $profile --region us-east-2 --output text
fi

aws ec2 associate-route-table --route-table-id $ohio_log_private_rtbc_id --subnet-id $ohio_log_application_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_private_rtbc_id --subnet-id $ohio_log_database_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_private_rtbc_id --subnet-id $ohio_log_management_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_private_rtbc_id --subnet-id $ohio_log_gateway_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $ohio_log_private_rtbc_id --subnet-id $ohio_log_endpoint_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create VPC Endpoint Security Group
ohio_log_vpce_sg_id=$(aws ec2 create-security-group --group-name Log-VPCEndpointSecurityGroup \
                                                    --description Log-VPCEndpointSecurityGroup \
                                                    --vpc-id $ohio_log_vpc_id \
                                                    --query 'GroupId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_log_vpce_sg_id=$ohio_log_vpce_sg_id"

aws ec2 create-tags --resources $ohio_log_vpce_sg_id \
                    --tags Key=Name,Value=Log-VPCEndpointSecurityGroup \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_log_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ohio_log_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $ohio_log_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ohio_log_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create VPC Endpoints for SSM and SSMMessages
ohio_log_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ohio_log_vpc_id \
                                                   --vpc-endpoint-type Interface \
                                                   --service-name com.amazonaws.us-east-2.ssm \
                                                   --private-dns-enabled \
                                                   --security-group-ids $ohio_log_vpce_sg_id \
                                                   --subnet-ids $ohio_log_endpoint_subneta_id $ohio_log_endpoint_subnetb_id $ohio_log_endpoint_subnetc_id \
                                                   --client-token $(date +%s) \
                                                   --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Log-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                   --query 'VpcEndpoint.VpcEndpointId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "ohio_log_ssm_vpce_id=$ohio_log_ssm_vpce_id"

ohio_log_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ohio_log_vpc_id \
                                                    --vpc-endpoint-type Interface \
                                                    --service-name com.amazonaws.us-east-2.ssmmessages \
                                                    --private-dns-enabled \
                                                    --security-group-ids $ohio_log_vpce_sg_id \
                                                    --subnet-ids $ohio_log_endpoint_subneta_id $ohio_log_endpoint_subnetb_id $ohio_log_endpoint_subnetc_id \
                                                    --client-token $(date +%s) \
                                                    --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Log-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                    --query 'VpcEndpoint.VpcEndpointId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_log_ssmm_vpce_id=$ohio_log_ssmm_vpce_id"


## Alfa Ohio Production VPC ###########################################################################################
echo "production_account_id=$production_account_id"

profile=$production_profile

# Create VPC
alfa_ohio_production_vpc_id=$(aws ec2 create-vpc --cidr-block $alfa_ohio_production_vpc_cidr \
                                                 --query 'Vpc.VpcId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_vpc_id=$alfa_ohio_production_vpc_id"

aws ec2 create-tags --resources $alfa_ohio_production_vpc_id \
                    --tags Key=Name,Value=Alfa-Production-VPC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $alfa_ohio_production_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $alfa_ohio_production_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-2 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Production/Alfa" \
                          --profile $profile --region us-east-2 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $alfa_ohio_production_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-2:$production_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Production/Alfa" \
                         --deliver-logs-permission-arn "arn:aws:iam::$production_account_id:role/FlowLog" \
                         --profile $profile --region us-east-2 --output text

# Create Internet Gateway & Attach
alfa_ohio_production_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_igw_id=$alfa_ohio_production_igw_id"

aws ec2 create-tags --resources $alfa_ohio_production_igw_id \
                    --tags Key=Name,Value=Alfa-Production-InternetGateway \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 attach-internet-gateway --vpc-id $alfa_ohio_production_vpc_id \
                                --internet-gateway-id $alfa_ohio_production_igw_id \
                                --profile $profile --region us-east-2 --output text

# Create Private Hosted Zone
alfa_ohio_production_private_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_ohio_production_private_domain \
                                                                            --vpc VPCRegion=us-east-2,VPCId=$alfa_ohio_production_vpc_id \
                                                                            --hosted-zone-config Comment="Private Zone for $alfa_ohio_production_private_domain",PrivateZone=true \
                                                                            --caller-reference $(date +%s) \
                                                                            --query 'HostedZone.Id' \
                                                                            --profile $profile --region us-east-2 --output text | cut -f3 -d /)
echo "alfa_ohio_production_private_hostedzone_id=$alfa_ohio_production_private_hostedzone_id"

# Create DHCP Options Set
alfa_ohio_production_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$alfa_ohio_production_private_domain]" \
                                                                                 "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                           --query 'DhcpOptions.DhcpOptionsId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_dopt_id=$alfa_ohio_production_dopt_id"

aws ec2 create-tags --resources $alfa_ohio_production_dopt_id \
                    --tags Key=Name,Value=Alfa-Production-DHCPOptions \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 associate-dhcp-options --vpc-id $alfa_ohio_production_vpc_id \
                               --dhcp-options-id $alfa_ohio_production_dopt_id \
                               --profile $profile --region us-east-2 --output text

# Create Public Subnet A
alfa_ohio_production_public_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                               --cidr-block $alfa_ohio_production_subnet_publica_cidr \
                                                               --availability-zone us-east-2a \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_public_subneta_id=$alfa_ohio_production_public_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_production_public_subneta_id \
                    --tags Key=Name,Value=Alfa-Production-PublicSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet B
alfa_ohio_production_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                               --cidr-block $alfa_ohio_production_subnet_publicb_cidr \
                                                               --availability-zone us-east-2b \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_public_subnetb_id=$alfa_ohio_production_public_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_production_public_subnetb_id \
                    --tags Key=Name,Value=Alfa-Production-PublicSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet C
alfa_ohio_production_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                               --cidr-block $alfa_ohio_production_subnet_publicc_cidr \
                                                               --availability-zone us-east-2c \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_public_subnetc_id=$alfa_ohio_production_public_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_production_public_subnetc_id \
                    --tags Key=Name,Value=Alfa-Production-PublicSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet A
alfa_ohio_production_web_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                            --cidr-block $alfa_ohio_production_subnet_weba_cidr \
                                                            --availability-zone us-east-2a \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_web_subneta_id=$alfa_ohio_production_web_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_production_web_subneta_id \
                    --tags Key=Name,Value=Alfa-Production-WebSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet B
alfa_ohio_production_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                            --cidr-block $alfa_ohio_production_subnet_webb_cidr \
                                                            --availability-zone us-east-2b \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_web_subnetb_id=$alfa_ohio_production_web_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_production_web_subnetb_id \
                    --tags Key=Name,Value=Alfa-Production-WebSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet C
alfa_ohio_production_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                            --cidr-block $alfa_ohio_production_subnet_webc_cidr \
                                                            --availability-zone us-east-2c \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_web_subnetc_id=$alfa_ohio_production_web_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_production_web_subnetc_id \
                    --tags Key=Name,Value=Alfa-Production-WebSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet A
alfa_ohio_production_application_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                    --cidr-block $alfa_ohio_production_subnet_applicationa_cidr \
                                                                    --availability-zone us-east-2a \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_application_subneta_id=$alfa_ohio_production_application_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_production_application_subneta_id \
                    --tags Key=Name,Value=Alfa-Production-ApplicationSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet B
alfa_ohio_production_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                    --cidr-block $alfa_ohio_production_subnet_applicationb_cidr \
                                                                    --availability-zone us-east-2b \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_application_subnetb_id=$alfa_ohio_production_application_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_production_application_subnetb_id \
                    --tags Key=Name,Value=Alfa-Production-ApplicationSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet C
alfa_ohio_production_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                    --cidr-block $alfa_ohio_production_subnet_applicationc_cidr \
                                                                    --availability-zone us-east-2c \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_application_subnetc_id=$alfa_ohio_production_application_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_production_application_subnetc_id \
                    --tags Key=Name,Value=Alfa-Production-ApplicationSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet A
alfa_ohio_production_database_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                 --cidr-block $alfa_ohio_production_subnet_databasea_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_database_subneta_id=$alfa_ohio_production_database_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_production_database_subneta_id \
                    --tags Key=Name,Value=Alfa-Production-DatabaseSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet B
alfa_ohio_production_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                 --cidr-block $alfa_ohio_production_subnet_databaseb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_database_subnetb_id=$alfa_ohio_production_database_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_production_database_subnetb_id \
                    --tags Key=Name,Value=Alfa-Production-DatabaseSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet C
alfa_ohio_production_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                 --cidr-block $alfa_ohio_production_subnet_databasec_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_database_subnetc_id=$alfa_ohio_production_database_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_production_database_subnetc_id \
                    --tags Key=Name,Value=Alfa-Production-DatabaseSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet A
alfa_ohio_production_management_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                   --cidr-block $alfa_ohio_production_subnet_managementa_cidr \
                                                                   --availability-zone us-east-2a \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_management_subneta_id=$alfa_ohio_production_management_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_production_management_subneta_id \
                    --tags Key=Name,Value=Alfa-Production-ManagementSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet B
alfa_ohio_production_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                   --cidr-block $alfa_ohio_production_subnet_managementb_cidr \
                                                                   --availability-zone us-east-2b \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_management_subnetb_id=$alfa_ohio_production_management_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_production_management_subnetb_id \
                    --tags Key=Name,Value=Alfa-Production-ManagementSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet C
alfa_ohio_production_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                   --cidr-block $alfa_ohio_production_subnet_managementc_cidr \
                                                                   --availability-zone us-east-2c \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_management_subnetc_id=$alfa_ohio_production_management_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_production_management_subnetc_id \
                    --tags Key=Name,Value=Alfa-Production-ManagementSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet A
alfa_ohio_production_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                --cidr-block $alfa_ohio_production_subnet_gatewaya_cidr \
                                                                --availability-zone us-east-2a \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_gateway_subneta_id=$alfa_ohio_production_gateway_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_production_gateway_subneta_id \
                    --tags Key=Name,Value=Alfa-Production-GatewaySubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet B
alfa_ohio_production_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                --cidr-block $alfa_ohio_production_subnet_gatewayb_cidr \
                                                                --availability-zone us-east-2b \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_gateway_subnetb_id=$alfa_ohio_production_gateway_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_production_gateway_subnetb_id \
                    --tags Key=Name,Value=Alfa-Production-GatewaySubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet C
alfa_ohio_production_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                --cidr-block $alfa_ohio_production_subnet_gatewayc_cidr \
                                                                --availability-zone us-east-2c \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_gateway_subnetc_id=$alfa_ohio_production_gateway_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_production_gateway_subnetc_id \
                    --tags Key=Name,Value=Alfa-Production-GatewaySubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet A
alfa_ohio_production_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                 --cidr-block $alfa_ohio_production_subnet_endpointa_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_endpoint_subneta_id=$alfa_ohio_production_endpoint_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_production_endpoint_subneta_id \
                    --tags Key=Name,Value=Alfa-Production-EndpointSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet B
alfa_ohio_production_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                 --cidr-block $alfa_ohio_production_subnet_endpointb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_endpoint_subnetb_id=$alfa_ohio_production_endpoint_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_production_endpoint_subnetb_id \
                    --tags Key=Name,Value=Alfa-Production-EndpointSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet C
alfa_ohio_production_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_production_vpc_id \
                                                                 --cidr-block $alfa_ohio_production_subnet_endpointc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_endpoint_subnetc_id=$alfa_ohio_production_endpoint_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_production_endpoint_subnetc_id \
                    --tags Key=Name,Value=Alfa-Production-EndpointSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
alfa_ohio_production_public_rtb_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_production_vpc_id \
                                                                --query 'RouteTable.RouteTableId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_public_rtb_id=$alfa_ohio_production_public_rtb_id"

aws ec2 create-tags --resources $alfa_ohio_production_public_rtb_id \
                    --tags Key=Name,Value=Alfa-Production-PublicRouteTable \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_production_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $alfa_ohio_production_igw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_ohio_production_public_rtb_id --subnet-id $alfa_ohio_production_public_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_public_rtb_id --subnet-id $alfa_ohio_production_public_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_public_rtb_id --subnet-id $alfa_ohio_production_public_subnetc_id \
                              --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_ohio_production_public_rtb_id --subnet-id $alfa_ohio_production_web_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_public_rtb_id --subnet-id $alfa_ohio_production_web_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_public_rtb_id --subnet-id $alfa_ohio_production_web_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create NAT Gateways
if [ $use_ngw = 1 ]; then
  alfa_ohio_production_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                           --query 'AllocationId' \
                                                           --profile $profile --region us-east-2 --output text)
  echo "alfa_ohio_production_ngw_eipa=$alfa_ohio_production_ngw_eipa"

  aws ec2 create-tags --resources $alfa_ohio_production_ngw_eipa \
                      --tags Key=Name,Value=Alfa-Production-NAT-EIPA \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Production \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  alfa_ohio_production_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_ohio_production_ngw_eipa \
                                                            --subnet-id $alfa_ohio_production_public_subneta_id \
                                                            --client-token $(date +%s) \
                                                            --query 'NatGateway.NatGatewayId' \
                                                            --profile $profile --region us-east-2 --output text)
  echo "alfa_ohio_production_ngwa_id=$alfa_ohio_production_ngwa_id"

  aws ec2 create-tags --resources $alfa_ohio_production_ngwa_id \
                      --tags Key=Name,Value=Alfa-Production-NAT-GatewayA \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Production \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  if [ $ha_ngw = 1 ]; then
    alfa_ohio_production_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                             --query 'AllocationId' \
                                                             --profile $profile --region us-east-2 --output text)
    echo "alfa_ohio_production_ngw_eipb=$alfa_ohio_production_ngw_eipb"

    aws ec2 create-tags --resources $alfa_ohio_production_ngw_eipb \
                        --tags Key=Name,Value=Alfa-Production-NAT-EIPB \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Production \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    alfa_ohio_production_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_ohio_production_ngw_eipb \
                                                              --subnet-id $alfa_ohio_production_public_subnetb_id \
                                                              --client-token $(date +%s) \
                                                              --query 'NatGateway.NatGatewayId' \
                                                              --profile $profile --region us-east-2 --output text)
    echo "alfa_ohio_production_ngwb_id=$alfa_ohio_production_ngwb_id"

    aws ec2 create-tags --resources $alfa_ohio_production_ngwb_id \
                        --tags Key=Name,Value=Alfa-Production-NAT-GatewayB \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Production \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    alfa_ohio_production_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                             --query 'AllocationId' \
                                                             --profile $profile --region us-east-2 --output text)
    echo "alfa_ohio_production_ngw_eipc=$alfa_ohio_production_ngw_eipc"

    aws ec2 create-tags --resources $alfa_ohio_production_ngw_eipc \
                        --tags Key=Name,Value=Alfa-Production-NAT-EIPC \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Production \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    alfa_ohio_production_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_ohio_production_ngw_eipc \
                                                              --subnet-id $alfa_ohio_production_public_subnetc_id \
                                                              --client-token $(date +%s) \
                                                              --query 'NatGateway.NatGatewayId' \
                                                              --profile $profile --region us-east-2 --output text)
    echo "alfa_ohio_production_ngwc_id=$alfa_ohio_production_ngwc_id"

    aws ec2 create-tags --resources $alfa_ohio_production_ngwc_id \
                        --tags Key=Name,Value=Alfa-Production-NAT-GatewayC \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Production \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text
  fi
else
  # Create NAT Security Group
  alfa_ohio_production_nat_sg_id=$(aws ec2 create-security-group --group-name Alfa-Production-NAT-InstanceSecurityGroup \
                                                                 --description Alfa-Production-NAT-InstanceSecurityGroup \
                                                                 --vpc-id $alfa_ohio_production_vpc_id \
                                                                 --query 'GroupId' \
                                                                 --profile $profile --region us-east-2 --output text)
  echo "alfa_ohio_production_nat_sg_id=$alfa_ohio_production_nat_sg_id"

  aws ec2 create-tags --resources $alfa_ohio_production_nat_sg_id \
                      --tags Key=Name,Value=Alfa-Production-NAT-InstanceSecurityGroup \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Production \
                             Key=Utility,Value=NAT \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_nat_sg_id \
                                           --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$alfa_ohio_production_vpc_cidr,Description=\"VPC (All)\"}]" \
                                           --profile $profile --region us-east-2 --output text

  # Create NAT Instance
  alfa_ohio_production_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                               --instance-type t3a.nano \
                                                               --iam-instance-profile Name=ManagedInstance \
                                                               --key-name administrator \
                                                               --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Alfa-Production-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_production_nat_sg_id],SubnetId=$alfa_ohio_production_public_subneta_id" \
                                                               --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Production-NAT-Instance},{Key=Hostname,Value=alfue2pnat01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                               --query 'Instances[0].InstanceId' \
                                                               --profile $profile --region us-east-2 --output text)
  echo "alfa_ohio_production_nat_instance_id=$alfa_ohio_production_nat_instance_id"

  aws ec2 modify-instance-attribute --instance-id $alfa_ohio_production_nat_instance_id \
                                    --no-source-dest-check \
                                    --profile $profile --region us-east-2 --output text

  alfa_ohio_production_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $alfa_ohio_production_nat_instance_id \
                                                                        --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                        --profile $profile --region us-east-2 --output text)
  echo "alfa_ohio_production_nat_instance_eni_id=$alfa_ohio_production_nat_instance_eni_id"

  alfa_ohio_production_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_production_nat_instance_id \
                                                                            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                            --profile $profile --region us-east-2 --output text)
  echo "alfa_ohio_production_nat_instance_private_ip=$alfa_ohio_production_nat_instance_private_ip"
fi

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
alfa_ohio_production_private_rtba_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_production_vpc_id \
                                                                  --query 'RouteTable.RouteTableId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_private_rtba_id=$alfa_ohio_production_private_rtba_id"

aws ec2 create-tags --resources $alfa_ohio_production_private_rtba_id \
                    --tags Key=Name,Value=Alfa-Production-PrivateRouteTableA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

if [ $use_ngw = 1 ]; then
  aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $alfa_ohio_production_ngwa_id \
                       --profile $profile --region us-east-2 --output text
else
  aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $alfa_ohio_production_nat_instance_eni_id \
                       --profile $profile --region us-east-2 --output text
fi

aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtba_id --subnet-id $alfa_ohio_production_application_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtba_id --subnet-id $alfa_ohio_production_database_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtba_id --subnet-id $alfa_ohio_production_management_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtba_id --subnet-id $alfa_ohio_production_gateway_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtba_id --subnet-id $alfa_ohio_production_endpoint_subneta_id \
                              --profile $profile --region us-east-2 --output text

alfa_ohio_production_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_production_vpc_id \
                                                                  --query 'RouteTable.RouteTableId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_private_rtbb_id=$alfa_ohio_production_private_rtbb_id"

aws ec2 create-tags --resources $alfa_ohio_production_private_rtbb_id \
                    --tags Key=Name,Value=Alfa-Production-PrivateRouteTableB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then alfa_ohio_production_ngw_id=$alfa_ohio_production_ngwb_id; else alfa_ohio_production_ngw_id=$alfa_ohio_production_ngwa_id; fi
  aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $alfa_ohio_production_ngw_id \
                       --profile $profile --region us-east-2 --output text
else
  aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $alfa_ohio_production_nat_instance_eni_id \
                       --profile $profile --region us-east-2 --output text
fi

aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtbb_id --subnet-id $alfa_ohio_production_application_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtbb_id --subnet-id $alfa_ohio_production_database_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtbb_id --subnet-id $alfa_ohio_production_management_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtbb_id --subnet-id $alfa_ohio_production_gateway_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtbb_id --subnet-id $alfa_ohio_production_endpoint_subnetb_id \
                              --profile $profile --region us-east-2 --output text

alfa_ohio_production_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_production_vpc_id \
                                                                  --query 'RouteTable.RouteTableId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_private_rtbc_id=$alfa_ohio_production_private_rtbc_id"

aws ec2 create-tags --resources $alfa_ohio_production_private_rtbc_id \
                    --tags Key=Name,Value=Alfa-Production-PrivateRouteTableC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then alfa_ohio_production_ngw_id=$alfa_ohio_production_ngwc_id; else alfa_ohio_production_ngw_id=$alfa_ohio_production_ngwa_id; fi
  aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $alfa_ohio_production_ngw_id \
                       --profile $profile --region us-east-2 --output text
else
  aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $alfa_ohio_production_nat_instance_eni_id \
                       --profile $profile --region us-east-2 --output text
fi

aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtbc_id --subnet-id $alfa_ohio_production_application_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtbc_id --subnet-id $alfa_ohio_production_database_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtbc_id --subnet-id $alfa_ohio_production_management_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtbc_id --subnet-id $alfa_ohio_production_gateway_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_production_private_rtbc_id --subnet-id $alfa_ohio_production_endpoint_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create VPC Endpoint Security Group
alfa_ohio_production_vpce_sg_id=$(aws ec2 create-security-group --group-name Alfa-Production-VPCEndpointSecurityGroup \
                                                                --description Alfa-Production-VPCEndpointSecurityGroup \
                                                                --vpc-id $alfa_ohio_production_vpc_id \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_vpce_sg_id=$alfa_ohio_production_vpce_sg_id"

aws ec2 create-tags --resources $alfa_ohio_production_vpce_sg_id \
                    --tags Key=Name,Value=Alfa-Production-VPCEndpointSecurityGroup \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_ohio_production_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_ohio_production_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create VPC Endpoints for SSM and SSMMessages
alfa_ohio_production_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_ohio_production_vpc_id \
                                                               --vpc-endpoint-type Interface \
                                                               --service-name com.amazonaws.us-east-2.ssm \
                                                               --private-dns-enabled \
                                                               --security-group-ids $alfa_ohio_production_vpce_sg_id \
                                                               --subnet-ids $alfa_ohio_production_endpoint_subneta_id $alfa_ohio_production_endpoint_subnetb_id $alfa_ohio_production_endpoint_subnetc_id \
                                                               --client-token $(date +%s) \
                                                               --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Production-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                               --query 'VpcEndpoint.VpcEndpointId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_ssm_vpce_id=$alfa_ohio_production_ssm_vpce_id"

alfa_ohio_production_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_ohio_production_vpc_id \
                                                                --vpc-endpoint-type Interface \
                                                                --service-name com.amazonaws.us-east-2.ssmmessages \
                                                                --private-dns-enabled \
                                                                --security-group-ids $alfa_ohio_production_vpce_sg_id \
                                                                --subnet-ids $alfa_ohio_production_endpoint_subneta_id $alfa_ohio_production_endpoint_subnetb_id $alfa_ohio_production_endpoint_subnetc_id \
                                                                --client-token $(date +%s) \
                                                                --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Production-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                --query 'VpcEndpoint.VpcEndpointId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_production_ssmm_vpce_id=$alfa_ohio_production_ssmm_vpce_id"


## Alfa Ohio Testing VPC ##############################################################################################
echo "testing_account_id=$testing_account_id"

profile=$testing_profile

# Create VPC
alfa_ohio_testing_vpc_id=$(aws ec2 create-vpc --cidr-block $alfa_ohio_testing_vpc_cidr \
                                              --query 'Vpc.VpcId' \
                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_vpc_id=$alfa_ohio_testing_vpc_id"

aws ec2 create-tags --resources $alfa_ohio_testing_vpc_id \
                    --tags Key=Name,Value=Alfa-Testing-VPC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $alfa_ohio_testing_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $alfa_ohio_testing_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-2 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Testing/Alfa" \
                          --profile $profile --region us-east-2 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $alfa_ohio_testing_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-2:$testing_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Testing/Alfa" \
                         --deliver-logs-permission-arn "arn:aws:iam::$testing_account_id:role/FlowLog" \
                         --profile $profile --region us-east-2 --output text

# Create Internet Gateway & Attach
alfa_ohio_testing_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_igw_id=$alfa_ohio_testing_igw_id"

aws ec2 create-tags --resources $alfa_ohio_testing_igw_id \
                    --tags Key=Name,Value=Alfa-Testing-InternetGateway \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 attach-internet-gateway --vpc-id $alfa_ohio_testing_vpc_id \
                                --internet-gateway-id $alfa_ohio_testing_igw_id \
                                --profile $profile --region us-east-2 --output text

# Create Private Hosted Zone
alfa_ohio_testing_private_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_ohio_testing_private_domain \
                                                                         --vpc VPCRegion=us-east-2,VPCId=$alfa_ohio_testing_vpc_id \
                                                                         --hosted-zone-config Comment="Private Zone for $alfa_ohio_testing_private_domain",PrivateZone=true \
                                                                         --caller-reference $(date +%s) \
                                                                         --query 'HostedZone.Id' \
                                                                         --profile $profile --region us-east-2 --output text | cut -f3 -d /)
echo "alfa_ohio_testing_private_hostedzone_id=$alfa_ohio_testing_private_hostedzone_id"

# Create DHCP Options Set
alfa_ohio_testing_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$alfa_ohio_testing_private_domain]" \
                                                                              "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                        --query 'DhcpOptions.DhcpOptionsId' \
                                                        --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_dopt_id=$alfa_ohio_testing_dopt_id"

aws ec2 create-tags --resources $alfa_ohio_testing_dopt_id \
                    --tags Key=Name,Value=Alfa-Testing-DHCPOptions \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 associate-dhcp-options --vpc-id $alfa_ohio_testing_vpc_id \
                               --dhcp-options-id $alfa_ohio_testing_dopt_id \
                               --profile $profile --region us-east-2 --output text

# Create Public Subnet A
alfa_ohio_testing_public_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                            --cidr-block $alfa_ohio_testing_subnet_publica_cidr \
                                                            --availability-zone us-east-2a \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_public_subneta_id=$alfa_ohio_testing_public_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_testing_public_subneta_id \
                    --tags Key=Name,Value=Alfa-Testing-PublicSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet B
alfa_ohio_testing_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                            --cidr-block $alfa_ohio_testing_subnet_publicb_cidr \
                                                            --availability-zone us-east-2b \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_public_subnetb_id=$alfa_ohio_testing_public_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_testing_public_subnetb_id \
                    --tags Key=Name,Value=Alfa-Testing-PublicSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet C
alfa_ohio_testing_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                            --cidr-block $alfa_ohio_testing_subnet_publicc_cidr \
                                                            --availability-zone us-east-2c \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_public_subnetc_id=$alfa_ohio_testing_public_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_testing_public_subnetc_id \
                    --tags Key=Name,Value=Alfa-Testing-PublicSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet A
alfa_ohio_testing_web_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                         --cidr-block $alfa_ohio_testing_subnet_weba_cidr \
                                                         --availability-zone us-east-2a \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_web_subneta_id=$alfa_ohio_testing_web_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_testing_web_subneta_id \
                    --tags Key=Name,Value=Alfa-Testing-WebSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet B
alfa_ohio_testing_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                         --cidr-block $alfa_ohio_testing_subnet_webb_cidr \
                                                         --availability-zone us-east-2b \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_web_subnetb_id=$alfa_ohio_testing_web_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_testing_web_subnetb_id \
                    --tags Key=Name,Value=Alfa-Testing-WebSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet C
alfa_ohio_testing_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                         --cidr-block $alfa_ohio_testing_subnet_webc_cidr \
                                                         --availability-zone us-east-2c \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_web_subnetc_id=$alfa_ohio_testing_web_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_testing_web_subnetc_id \
                    --tags Key=Name,Value=Alfa-Testing-WebSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet A
alfa_ohio_testing_application_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --cidr-block $alfa_ohio_testing_subnet_applicationa_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_application_subneta_id=$alfa_ohio_testing_application_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_testing_application_subneta_id \
                    --tags Key=Name,Value=Alfa-Testing-ApplicationSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet B
alfa_ohio_testing_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --cidr-block $alfa_ohio_testing_subnet_applicationb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_application_subnetb_id=$alfa_ohio_testing_application_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_testing_application_subnetb_id \
                    --tags Key=Name,Value=Alfa-Testing-ApplicationSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet C
alfa_ohio_testing_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                 --cidr-block $alfa_ohio_testing_subnet_applicationc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_application_subnetc_id=$alfa_ohio_testing_application_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_testing_application_subnetc_id \
                    --tags Key=Name,Value=Alfa-Testing-ApplicationSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet A
alfa_ohio_testing_database_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                              --cidr-block $alfa_ohio_testing_subnet_databasea_cidr \
                                                              --availability-zone us-east-2a \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_database_subneta_id=$alfa_ohio_testing_database_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_testing_database_subneta_id \
                    --tags Key=Name,Value=Alfa-Testing-DatabaseSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet B
alfa_ohio_testing_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                              --cidr-block $alfa_ohio_testing_subnet_databaseb_cidr \
                                                              --availability-zone us-east-2b \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_database_subnetb_id=$alfa_ohio_testing_database_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_testing_database_subnetb_id \
                    --tags Key=Name,Value=Alfa-Testing-DatabaseSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet C
alfa_ohio_testing_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                              --cidr-block $alfa_ohio_testing_subnet_databasec_cidr \
                                                              --availability-zone us-east-2c \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_database_subnetc_id=$alfa_ohio_testing_database_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_testing_database_subnetc_id \
                    --tags Key=Name,Value=Alfa-Testing-DatabaseSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet A
alfa_ohio_testing_management_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                --cidr-block $alfa_ohio_testing_subnet_managementa_cidr \
                                                                --availability-zone us-east-2a \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_management_subneta_id=$alfa_ohio_testing_management_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_testing_management_subneta_id \
                    --tags Key=Name,Value=Alfa-Testing-ManagementSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet B
alfa_ohio_testing_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                --cidr-block $alfa_ohio_testing_subnet_managementb_cidr \
                                                                --availability-zone us-east-2b \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_management_subnetb_id=$alfa_ohio_testing_management_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_testing_management_subnetb_id \
                    --tags Key=Name,Value=Alfa-Testing-ManagementSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet C
alfa_ohio_testing_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                                --cidr-block $alfa_ohio_testing_subnet_managementc_cidr \
                                                                --availability-zone us-east-2c \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_management_subnetc_id=$alfa_ohio_testing_management_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_testing_management_subnetc_id \
                    --tags Key=Name,Value=Alfa-Testing-ManagementSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet A
alfa_ohio_testing_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                             --cidr-block $alfa_ohio_testing_subnet_gatewaya_cidr \
                                                             --availability-zone us-east-2a \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_gateway_subneta_id=$alfa_ohio_testing_gateway_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_testing_gateway_subneta_id \
                    --tags Key=Name,Value=Alfa-Testing-GatewaySubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet B
alfa_ohio_testing_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                             --cidr-block $alfa_ohio_testing_subnet_gatewayb_cidr \
                                                             --availability-zone us-east-2b \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_gateway_subnetb_id=$alfa_ohio_testing_gateway_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_testing_gateway_subnetb_id \
                    --tags Key=Name,Value=Alfa-Testing-GatewaySubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet C
alfa_ohio_testing_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                             --cidr-block $alfa_ohio_testing_subnet_gatewayc_cidr \
                                                             --availability-zone us-east-2c \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_gateway_subnetc_id=$alfa_ohio_testing_gateway_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_testing_gateway_subnetc_id \
                    --tags Key=Name,Value=Alfa-Testing-GatewaySubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endopint Subnet A
alfa_ohio_testing_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                              --cidr-block $alfa_ohio_testing_subnet_endpointa_cidr \
                                                              --availability-zone us-east-2a \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_endpoint_subneta_id=$alfa_ohio_testing_endpoint_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_testing_endpoint_subneta_id \
                    --tags Key=Name,Value=Alfa-Testing-EndpointSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet B
alfa_ohio_testing_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                              --cidr-block $alfa_ohio_testing_subnet_endpointb_cidr \
                                                              --availability-zone us-east-2b \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_endpoint_subnetb_id=$alfa_ohio_testing_endpoint_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_testing_endpoint_subnetb_id \
                    --tags Key=Name,Value=Alfa-Testing-EndpointSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet C
alfa_ohio_testing_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_testing_vpc_id \
                                                              --cidr-block $alfa_ohio_testing_subnet_endpointc_cidr \
                                                              --availability-zone us-east-2c \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_endpoint_subnetc_id=$alfa_ohio_testing_endpoint_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_testing_endpoint_subnetc_id \
                    --tags Key=Name,Value=Alfa-Testing-EndpointSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
alfa_ohio_testing_public_rtb_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_testing_vpc_id \
                                                             --query 'RouteTable.RouteTableId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_public_rtb_id=$alfa_ohio_testing_public_rtb_id"

aws ec2 create-tags --resources $alfa_ohio_testing_public_rtb_id \
                    --tags Key=Name,Value=Alfa-Testing-PublicRouteTable \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

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

aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_web_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_web_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_public_rtb_id --subnet-id $alfa_ohio_testing_web_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create NAT Security Group
alfa_ohio_testing_nat_sg_id=$(aws ec2 create-security-group --group-name Alfa-Testing-NAT-InstanceSecurityGroup \
                                                            --description Alfa-Testing-NAT-InstanceSecurityGroup \
                                                            --vpc-id $alfa_ohio_testing_vpc_id \
                                                            --query 'GroupId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_nat_sg_id=$alfa_ohio_testing_nat_sg_id"

aws ec2 create-tags --resources $alfa_ohio_testing_nat_sg_id \
                    --tags Key=Name,Value=Alfa-Testing-NAT-InstanceSecurityGroup \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Utility,Value=NAT \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_nat_sg_id \
                                         --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$alfa_ohio_testing_vpc_cidr,Description=\"VPC (All)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create NAT Instance
alfa_ohio_testing_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                          --instance-type t3a.nano \
                                                          --iam-instance-profile Name=ManagedInstance \
                                                          --key-name administrator \
                                                          --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Alfa-Testing-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_testing_nat_sg_id],SubnetId=$alfa_ohio_testing_public_subneta_id" \
                                                          --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Testing-NAT-Instance},{Key=Hostname,Value=alfue2tnat01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                          --query 'Instances[0].InstanceId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_nat_instance_id=$alfa_ohio_testing_nat_instance_id"

aws ec2 modify-instance-attribute --instance-id $alfa_ohio_testing_nat_instance_id \
                                  --no-source-dest-check \
                                  --profile $profile --region us-east-2 --output text

alfa_ohio_testing_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $alfa_ohio_testing_nat_instance_id \
                                                                   --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_nat_instance_eni_id=$alfa_ohio_testing_nat_instance_eni_id"

alfa_ohio_testing_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_testing_nat_instance_id \
                                                                       --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                       --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_nat_instance_private_ip=$alfa_ohio_testing_nat_instance_private_ip"

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
alfa_ohio_testing_private_rtba_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_testing_vpc_id \
                                                               --query 'RouteTable.RouteTableId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_private_rtba_id=$alfa_ohio_testing_private_rtba_id"

aws ec2 create-tags --resources $alfa_ohio_testing_private_rtba_id \
                    --tags Key=Name,Value=Alfa-Testing-PrivateRouteTableA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtba_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $alfa_ohio_testing_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_application_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_database_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_management_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_gateway_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtba_id --subnet-id $alfa_ohio_testing_endpoint_subneta_id \
                              --profile $profile --region us-east-2 --output text

alfa_ohio_testing_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_testing_vpc_id \
                                                               --query 'RouteTable.RouteTableId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_private_rtbb_id=$alfa_ohio_testing_private_rtbb_id"

aws ec2 create-tags --resources $alfa_ohio_testing_private_rtbb_id \
                    --tags Key=Name,Value=Alfa-Testing-PrivateRouteTableB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $alfa_ohio_testing_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_application_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_database_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_management_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_gateway_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbb_id --subnet-id $alfa_ohio_testing_endpoint_subnetb_id \
                              --profile $profile --region us-east-2 --output text

alfa_ohio_testing_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_testing_vpc_id \
                                                               --query 'RouteTable.RouteTableId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_private_rtbc_id=$alfa_ohio_testing_private_rtbc_id"

aws ec2 create-tags --resources $alfa_ohio_testing_private_rtbc_id \
                    --tags Key=Name,Value=Alfa-Testing-PrivateRouteTableC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbc_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $alfa_ohio_testing_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_application_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_database_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_management_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_gateway_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_testing_private_rtbc_id --subnet-id $alfa_ohio_testing_endpoint_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create VPC Endpoint Security Group
alfa_ohio_testing_vpce_sg_id=$(aws ec2 create-security-group --group-name Alfa-Testing-VPCEndpointSecurityGroup \
                                                             --description Alfa-Testing-VPCEndpointSecurityGroup \
                                                             --vpc-id $alfa_ohio_testing_vpc_id \
                                                             --query 'GroupId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_vpce_sg_id=$alfa_ohio_testing_vpce_sg_id"

aws ec2 create-tags --resources $alfa_ohio_testing_vpce_sg_id \
                    --tags Key=Name,Value=Alfa-Testing-VPCEndpointSecurityGroup \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_ohio_testing_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_testing_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_ohio_testing_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create VPC Endpoints for SSM and SSMMessages
alfa_ohio_testing_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_ohio_testing_vpc_id \
                                                            --vpc-endpoint-type Interface \
                                                            --service-name com.amazonaws.us-east-2.ssm \
                                                            --private-dns-enabled \
                                                            --security-group-ids $alfa_ohio_testing_vpce_sg_id \
                                                            --subnet-ids $alfa_ohio_testing_endpoint_subneta_id $alfa_ohio_testing_endpoint_subnetb_id $alfa_ohio_testing_endpoint_subnetc_id \
                                                            --client-token $(date +%s) \
                                                            --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Testing-SSMVpcEndpoint},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                            --query 'VpcEndpoint.VpcEndpointId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_ssm_vpce_id=$alfa_ohio_testing_ssm_vpce_id"

alfa_ohio_testing_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_ohio_testing_vpc_id \
                                                             --vpc-endpoint-type Interface \
                                                             --service-name com.amazonaws.us-east-2.ssmmessages \
                                                             --private-dns-enabled \
                                                             --security-group-ids $alfa_ohio_testing_vpce_sg_id \
                                                             --subnet-ids $alfa_ohio_testing_endpoint_subneta_id $alfa_ohio_testing_endpoint_subnetb_id $alfa_ohio_testing_endpoint_subnetc_id \
                                                             --client-token $(date +%s) \
                                                             --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Testing-SSMMessagesVpcEndpoint},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                             --query 'VpcEndpoint.VpcEndpointId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_ssmm_vpce_id=$alfa_ohio_testing_ssmm_vpce_id"


## Alfa Ohio Development VPC ##########################################################################################
echo "development_account_id=$development_account_id"

profile=$development_profile

# Create VPC
alfa_ohio_development_vpc_id=$(aws ec2 create-vpc --cidr-block $alfa_ohio_development_vpc_cidr \
                                                  --query 'Vpc.VpcId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_vpc_id=$alfa_ohio_development_vpc_id"

aws ec2 create-tags --resources $alfa_ohio_development_vpc_id \
                    --tags Key=Name,Value=Alfa-Development-VPC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $alfa_ohio_development_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $alfa_ohio_development_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-2 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Development/Alfa" \
                          --profile $profile --region us-east-2 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $alfa_ohio_development_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-2:$alfa_ohio_development_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Development/Alfa" \
                         --deliver-logs-permission-arn "arn:aws:iam::$alfa_ohio_development_account_id:role/FlowLog" \
                         --profile $profile --region us-east-2 --output text

# Create Internet Gateway & Attach
alfa_ohio_development_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_igw_id=$alfa_ohio_development_igw_id"

aws ec2 create-tags --resources $alfa_ohio_development_igw_id \
                    --tags Key=Name,Value=Alfa-Development-InternetGateway \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 attach-internet-gateway --vpc-id $alfa_ohio_development_vpc_id \
                                --internet-gateway-id $alfa_ohio_development_igw_id \
                                --profile $profile --region us-east-2 --output text

# Create Private Hosted Zone
alfa_ohio_development_private_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_ohio_development_private_domain \
                                                                             --vpc VPCRegion=us-east-2,VPCId=$alfa_ohio_development_vpc_id \
                                                                             --hosted-zone-config Comment="Private Zone for $alfa_ohio_development_private_domain",PrivateZone=true \
                                                                             --caller-reference $(date +%s) \
                                                                             --query 'HostedZone.Id' \
                                                                             --profile $profile --region us-east-2 --output text | cut -f3 -d /)
echo "alfa_ohio_development_private_hostedzone_id=$alfa_ohio_development_private_hostedzone_id"

# Create DHCP Options Set
alfa_ohio_development_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$alfa_ohio_development_private_domain]" \
                                                                                  "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                            --query 'DhcpOptions.DhcpOptionsId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_dopt_id=$alfa_ohio_development_dopt_id"

aws ec2 create-tags --resources $alfa_ohio_development_dopt_id \
                    --tags Key=Name,Value=Alfa-Development-DHCPOptions \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 associate-dhcp-options --vpc-id $alfa_ohio_development_vpc_id \
                               --dhcp-options-id $alfa_ohio_development_dopt_id \
                               --profile $profile --region us-east-2 --output text

# Create Public Subnet A
alfa_ohio_development_public_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                --cidr-block $alfa_ohio_development_subnet_publica_cidr \
                                                                --availability-zone us-east-2a \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_public_subneta_id=$alfa_ohio_development_public_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_development_public_subneta_id \
                    --tags Key=Name,Value=Alfa-Development-PublicSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet B
alfa_ohio_development_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                --cidr-block $alfa_ohio_development_subnet_publicb_cidr \
                                                                --availability-zone us-east-2b \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_public_subnetb_id=$alfa_ohio_development_public_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_development_public_subnetb_id \
                    --tags Key=Name,Value=Alfa-Development-PublicSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet C
alfa_ohio_development_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                --cidr-block $alfa_ohio_development_subnet_publicc_cidr \
                                                                --availability-zone us-east-2c \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_public_subnetc_id=$alfa_ohio_development_public_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_development_public_subnetc_id \
                    --tags Key=Name,Value=Alfa-Development-PublicSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet A
alfa_ohio_development_web_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                             --cidr-block $alfa_ohio_development_subnet_weba_cidr \
                                                             --availability-zone us-east-2a \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_web_subneta_id=$alfa_ohio_development_web_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_development_web_subneta_id \
                    --tags Key=Name,Value=Alfa-Development-WebSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet B
alfa_ohio_development_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                             --cidr-block $alfa_ohio_development_subnet_webb_cidr \
                                                             --availability-zone us-east-2b \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_web_subnetb_id=$alfa_ohio_development_web_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_development_web_subnetb_id \
                    --tags Key=Name,Value=Alfa-Development-WebSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet C
alfa_ohio_development_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                             --cidr-block $alfa_ohio_development_subnet_webc_cidr \
                                                             --availability-zone us-east-2c \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_web_subnetc_id=$alfa_ohio_development_web_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_development_web_subnetc_id \
                    --tags Key=Name,Value=Alfa-Development-WebSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet A
alfa_ohio_development_application_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                     --cidr-block $alfa_ohio_development_subnet_applicationa_cidr \
                                                                     --availability-zone us-east-2a \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_application_subneta_id=$alfa_ohio_development_application_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_development_application_subneta_id \
                    --tags Key=Name,Value=Alfa-Development-ApplicationSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet B
alfa_ohio_development_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                     --cidr-block $alfa_ohio_development_subnet_applicationb_cidr \
                                                                     --availability-zone us-east-2b \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_application_subnetb_id=$alfa_ohio_development_application_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_development_application_subnetb_id \
                    --tags Key=Name,Value=Alfa-Development-ApplicationSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet C
alfa_ohio_development_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                     --cidr-block $alfa_ohio_development_subnet_applicationc_cidr \
                                                                     --availability-zone us-east-2c \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_application_subnetc_id=$alfa_ohio_development_application_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_development_application_subnetc_id \
                    --tags Key=Name,Value=Alfa-Development-ApplicationSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet A
alfa_ohio_development_database_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                  --cidr-block $alfa_ohio_development_subnet_databasea_cidr \
                                                                  --availability-zone us-east-2a \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_database_subneta_id=$alfa_ohio_development_database_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_development_database_subneta_id \
                    --tags Key=Name,Value=Alfa-Development-DatabaseSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet B
alfa_ohio_development_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                  --cidr-block $alfa_ohio_development_subnet_databaseb_cidr \
                                                                  --availability-zone us-east-2b \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_database_subnetb_id=$alfa_ohio_development_database_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_development_database_subnetb_id \
                    --tags Key=Name,Value=Alfa-Development-DatabaseSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet C
alfa_ohio_development_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                  --cidr-block $alfa_ohio_development_subnet_databasec_cidr \
                                                                  --availability-zone us-east-2c \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_database_subnetc_id=$alfa_ohio_development_database_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_development_database_subnetc_id \
                    --tags Key=Name,Value=Alfa-Development-DatabaseSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet A
alfa_ohio_development_management_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                    --cidr-block $alfa_ohio_development_subnet_managementa_cidr \
                                                                    --availability-zone us-east-2a \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_management_subneta_id=$alfa_ohio_development_management_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_development_management_subneta_id \
                    --tags Key=Name,Value=Alfa-Development-ManagementSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet B
alfa_ohio_development_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                    --cidr-block $alfa_ohio_development_subnet_managementb_cidr \
                                                                    --availability-zone us-east-2b \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_management_subnetb_id=$alfa_ohio_development_management_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_development_management_subnetb_id \
                    --tags Key=Name,Value=Alfa-Development-ManagementSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet C
alfa_ohio_development_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                    --cidr-block $alfa_ohio_development_subnet_managementc_cidr \
                                                                    --availability-zone us-east-2c \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_management_subnetc_id=$alfa_ohio_development_management_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_development_management_subnetc_id \
                    --tags Key=Name,Value=Alfa-Development-ManagementSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet A
alfa_ohio_development_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                 --cidr-block $alfa_ohio_development_subnet_gatewaya_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_gateway_subneta_id=$alfa_ohio_development_gateway_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_development_gateway_subneta_id \
                    --tags Key=Name,Value=Alfa-Development-GatewaySubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet B
alfa_ohio_development_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                 --cidr-block $alfa_ohio_development_subnet_gatewayb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_gateway_subnetb_id=$alfa_ohio_development_gateway_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_development_gateway_subnetb_id \
                    --tags Key=Name,Value=Alfa-Development-GatewaySubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet C
alfa_ohio_development_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                 --cidr-block $alfa_ohio_development_subnet_gatewayc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_gateway_subnetc_id=$alfa_ohio_development_gateway_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_development_gateway_subnetc_id \
                    --tags Key=Name,Value=Alfa-Development-GatewaySubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet A
alfa_ohio_development_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                  --cidr-block $alfa_ohio_development_subnet_endpointa_cidr \
                                                                  --availability-zone us-east-2a \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_endpoint_subneta_id=$alfa_ohio_development_endpoint_subneta_id"

aws ec2 create-tags --resources $alfa_ohio_development_endpoint_subneta_id \
                    --tags Key=Name,Value=Alfa-Development-EndpointSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet B
alfa_ohio_development_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                  --cidr-block $alfa_ohio_development_subnet_endpointb_cidr \
                                                                  --availability-zone us-east-2b \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_endpoint_subnetb_id=$alfa_ohio_development_endpoint_subnetb_id"

aws ec2 create-tags --resources $alfa_ohio_development_endpoint_subnetb_id \
                    --tags Key=Name,Value=Alfa-Development-EndpointSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet C
alfa_ohio_development_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ohio_development_vpc_id \
                                                                  --cidr-block $alfa_ohio_development_subnet_endpointc_cidr \
                                                                  --availability-zone us-east-2c \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_endpoint_subnetc_id=$alfa_ohio_development_endpoint_subnetc_id"

aws ec2 create-tags --resources $alfa_ohio_development_endpoint_subnetc_id \
                    --tags Key=Name,Value=Alfa-Development-EndpointSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
alfa_ohio_development_public_rtb_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_development_vpc_id \
                                                                 --query 'RouteTable.RouteTableId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_public_rtb_id=$alfa_ohio_development_public_rtb_id"

aws ec2 create-tags --resources $alfa_ohio_development_public_rtb_id \
                    --tags Key=Name,Value=Alfa-Development-PublicRouteTable \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_development_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $alfa_ohio_development_igw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_ohio_development_public_rtb_id --subnet-id $alfa_ohio_development_public_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_public_rtb_id --subnet-id $alfa_ohio_development_public_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_public_rtb_id --subnet-id $alfa_ohio_development_public_subnetc_id \
                              --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_ohio_development_public_rtb_id --subnet-id $alfa_ohio_development_web_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_public_rtb_id --subnet-id $alfa_ohio_development_web_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_public_rtb_id --subnet-id $alfa_ohio_development_web_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create NAT Security Group
alfa_ohio_development_nat_sg_id=$(aws ec2 create-security-group --group-name Alfa-Development-NAT-InstanceSecurityGroup \
                                                                --description Alfa-Development-NAT-InstanceSecurityGroup \
                                                                --vpc-id $alfa_ohio_development_vpc_id \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_nat_sg_id=$alfa_ohio_development_nat_sg_id"

aws ec2 create-tags --resources $alfa_ohio_development_nat_sg_id \
                    --tags Key=Name,Value=Alfa-Development-NAT-InstanceSecurityGroup \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Utility,Value=NAT \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_nat_sg_id \
                                         --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$alfa_ohio_development_vpc_cidr,Description=\"VPC (All)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create NAT Instance
alfa_ohio_development_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                              --instance-type t3a.nano \
                                                              --iam-instance-profile Name=ManagedInstance \
                                                              --key-name administrator \
                                                              --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Alfa-Development-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ohio_development_nat_sg_id],SubnetId=$alfa_ohio_development_public_subneta_id" \
                                                              --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Development-NAT-Instance},{Key=Hostname,Value=alfue2dnat01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Development},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                              --query 'Instances[0].InstanceId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_nat_instance_id=$alfa_ohio_development_nat_instance_id"

aws ec2 modify-instance-attribute --instance-id $alfa_ohio_development_nat_instance_id \
                                  --no-source-dest-check \
                                  --profile $profile --region us-east-2 --output text

alfa_ohio_development_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $alfa_ohio_development_nat_instance_id \
                                                                       --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                       --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_nat_instance_eni_id=$alfa_ohio_development_nat_instance_eni_id"

alfa_ohio_development_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ohio_development_nat_instance_id \
                                                                           --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_nat_instance_private_ip=$alfa_ohio_development_nat_instance_private_ip"

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
alfa_ohio_development_private_rtba_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_development_vpc_id \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_private_rtba_id=$alfa_ohio_development_private_rtba_id"

aws ec2 create-tags --resources $alfa_ohio_development_private_rtba_id \
                    --tags Key=Name,Value=Alfa-Development-PrivateRouteTableA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtba_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $alfa_ohio_development_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtba_id --subnet-id $alfa_ohio_development_application_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtba_id --subnet-id $alfa_ohio_development_database_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtba_id --subnet-id $alfa_ohio_development_management_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtba_id --subnet-id $alfa_ohio_development_gateway_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtba_id --subnet-id $alfa_ohio_development_endpoint_subneta_id \
                              --profile $profile --region us-east-2 --output text

alfa_ohio_development_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_development_vpc_id \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_private_rtbb_id=$alfa_ohio_development_private_rtbb_id"

aws ec2 create-tags --resources $alfa_ohio_development_private_rtbb_id \
                    --tags Key=Name,Value=Alfa-Development-PrivateRouteTableB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtbb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $alfa_ohio_development_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtbb_id --subnet-id $alfa_ohio_development_application_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtbb_id --subnet-id $alfa_ohio_development_database_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtbb_id --subnet-id $alfa_ohio_development_management_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtbb_id --subnet-id $alfa_ohio_development_gateway_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtbb_id --subnet-id $alfa_ohio_development_endpoint_subnetb_id \
                              --profile $profile --region us-east-2 --output text

alfa_ohio_development_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $alfa_ohio_development_vpc_id \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_private_rtbc_id=$alfa_ohio_development_private_rtbc_id"

aws ec2 create-tags --resources $alfa_ohio_development_private_rtbc_id \
                    --tags Key=Name,Value=Alfa-Development-PrivateRouteTableC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtbc_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $alfa_ohio_development_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtbc_id --subnet-id $alfa_ohio_development_application_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtbc_id --subnet-id $alfa_ohio_development_database_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtbc_id --subnet-id $alfa_ohio_development_management_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtbc_id --subnet-id $alfa_ohio_development_gateway_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_ohio_development_private_rtbc_id --subnet-id $alfa_ohio_development_endpoint_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create VPC Endpoint Security Group
alfa_ohio_development_vpce_sg_id=$(aws ec2 create-security-group --group-name Alfa-Development-VPCEndpointSecurityGroup \
                                                                 --description Alfa-Development-VPCEndpointSecurityGroup \
                                                                 --vpc-id $alfa_ohio_development_vpc_id \
                                                                 --query 'GroupId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_vpce_sg_id=$alfa_ohio_development_vpce_sg_id"

aws ec2 create-tags --resources $alfa_ohio_development_vpce_sg_id \
                    --tags Key=Name,Value=Alfa-Development-VPCEndpointSecurityGroup \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_ohio_development_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_development_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_ohio_development_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create VPC Endpoints for SSM and SSMMessages
alfa_ohio_development_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_ohio_development_vpc_id \
                                                                --vpc-endpoint-type Interface \
                                                                --service-name com.amazonaws.us-east-2.ssm \
                                                                --private-dns-enabled \
                                                                --security-group-ids $alfa_ohio_development_vpce_sg_id \
                                                                --subnet-ids $alfa_ohio_development_endpoint_subneta_id $alfa_ohio_development_endpoint_subnetb_id $alfa_ohio_development_endpoint_subnetc_id \
                                                                --client-token $(date +%s) \
                                                                --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Development-SSMVpcEndpoint},{Key=Company,Value=Alfa},{Key=Environment,Value=Development},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                --query 'VpcEndpoint.VpcEndpointId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_ssm_vpce_id=$alfa_ohio_development_ssm_vpce_id"

alfa_ohio_development_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_ohio_development_vpc_id \
                                                                 --vpc-endpoint-type Interface \
                                                                 --service-name com.amazonaws.us-east-2.ssmmessages \
                                                                 --private-dns-enabled \
                                                                 --security-group-ids $alfa_ohio_development_vpce_sg_id \
                                                                 --subnet-ids $alfa_ohio_development_endpoint_subneta_id $alfa_ohio_development_endpoint_subnetb_id $alfa_ohio_development_endpoint_subnetc_id \
                                                                 --client-token $(date +%s) \
                                                                 --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Development-SSMMessagesVpcEndpoint},{Key=Company,Value=Alfa},{Key=Environment,Value=Development},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                 --query 'VpcEndpoint.VpcEndpointId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_ssmm_vpce_id=$alfa_ohio_development_ssmm_vpce_id"


## Zulu Ohio Production VPC ###########################################################################################
echo "production_account_id=$production_account_id"

profile=$production_profile

# Create VPC
zulu_ohio_production_vpc_id=$(aws ec2 create-vpc --cidr-block $zulu_ohio_production_vpc_cidr \
                                                 --query 'Vpc.VpcId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_vpc_id=$zulu_ohio_production_vpc_id"

aws ec2 create-tags --resources $zulu_ohio_production_vpc_id \
                    --tags Key=Name,Value=Zulu-Production-VPC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $zulu_ohio_production_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $zulu_ohio_production_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-2 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Production/Zulu" \
                          --profile $profile --region us-east-2 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $zulu_ohio_production_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-2:$production_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Production/Zulu" \
                         --deliver-logs-permission-arn "arn:aws:iam::$production_account_id:role/FlowLog" \
                         --profile $profile --region us-east-2 --output text

# Create Internet Gateway & Attach
zulu_ohio_production_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_igw_id=$zulu_ohio_production_igw_id"

aws ec2 create-tags --resources $zulu_ohio_production_igw_id \
                    --tags Key=Name,Value=Zulu-Production-InternetGateway \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 attach-internet-gateway --vpc-id $zulu_ohio_production_vpc_id \
                                --internet-gateway-id $zulu_ohio_production_igw_id \
                                --profile $profile --region us-east-2 --output text

# Create Private Hosted Zone
zulu_ohio_production_private_hostedzone_id=$(aws route53 create-hosted-zone --name $zulu_ohio_production_private_domain \
                                                                            --vpc VPCRegion=us-east-2,VPCId=$zulu_ohio_production_vpc_id \
                                                                            --hosted-zone-config Comment="Private Zone for $zulu_ohio_production_private_domain",PrivateZone=true \
                                                                            --caller-reference $(date +%s) \
                                                                            --query 'HostedZone.Id' \
                                                                            --profile $profile --region us-east-2 --output text | cut -f3 -d /)
echo "zulu_ohio_production_private_hostedzone_id=$zulu_ohio_production_private_hostedzone_id"

# Create DHCP Options Set
zulu_ohio_production_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$zulu_ohio_production_private_domain]" \
                                                                                 "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                           --query 'DhcpOptions.DhcpOptionsId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_dopt_id=$zulu_ohio_production_dopt_id"

aws ec2 create-tags --resources $zulu_ohio_production_dopt_id \
                    --tags Key=Name,Value=Zulu-Production-DHCPOptions \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 associate-dhcp-options --vpc-id $zulu_ohio_production_vpc_id \
                               --dhcp-options-id $zulu_ohio_production_dopt_id \
                               --profile $profile --region us-east-2 --output text

# Create Public Subnet A
zulu_ohio_production_public_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                               --cidr-block $zulu_ohio_production_subnet_publica_cidr \
                                                               --availability-zone us-east-2a \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_public_subneta_id=$zulu_ohio_production_public_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_production_public_subneta_id \
                    --tags Key=Name,Value=Zulu-Production-PublicSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet B
zulu_ohio_production_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                               --cidr-block $zulu_ohio_production_subnet_publicb_cidr \
                                                               --availability-zone us-east-2b \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_public_subnetb_id=$zulu_ohio_production_public_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_production_public_subnetb_id \
                    --tags Key=Name,Value=Zulu-Production-PublicSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet C
zulu_ohio_production_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                               --cidr-block $zulu_ohio_production_subnet_publicc_cidr \
                                                               --availability-zone us-east-2c \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_public_subnetc_id=$zulu_ohio_production_public_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_production_public_subnetc_id \
                    --tags Key=Name,Value=Zulu-Production-PublicSubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet A
zulu_ohio_production_web_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                            --cidr-block $zulu_ohio_production_subnet_weba_cidr \
                                                            --availability-zone us-east-2a \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_web_subneta_id=$zulu_ohio_production_web_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_production_web_subneta_id \
                    --tags Key=Name,Value=Zulu-Production-WebSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet B
zulu_ohio_production_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                            --cidr-block $zulu_ohio_production_subnet_webb_cidr \
                                                            --availability-zone us-east-2b \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_web_subnetb_id=$zulu_ohio_production_web_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_production_web_subnetb_id \
                    --tags Key=Name,Value=Zulu-Production-WebSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet C
zulu_ohio_production_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                            --cidr-block $zulu_ohio_production_subnet_webc_cidr \
                                                            --availability-zone us-east-2c \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_web_subnetc_id=$zulu_ohio_production_web_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_production_web_subnetc_id \
                    --tags Key=Name,Value=Zulu-Production-WebSubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet A
zulu_ohio_production_application_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --cidr-block $zulu_ohio_production_subnet_applicationa_cidr \
                                                                    --availability-zone us-east-2a \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_application_subneta_id=$zulu_ohio_production_application_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_production_application_subneta_id \
                    --tags Key=Name,Value=Zulu-Production-ApplicationSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet B
zulu_ohio_production_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --cidr-block $zulu_ohio_production_subnet_applicationb_cidr \
                                                                    --availability-zone us-east-2b \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_application_subnetb_id=$zulu_ohio_production_application_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_production_application_subnetb_id \
                    --tags Key=Name,Value=Zulu-Production-ApplicationSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet C
zulu_ohio_production_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                    --cidr-block $zulu_ohio_production_subnet_applicationc_cidr \
                                                                    --availability-zone us-east-2c \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_application_subnetc_id=$zulu_ohio_production_application_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_production_application_subnetc_id \
                    --tags Key=Name,Value=Zulu-Production-ApplicationSubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet A
zulu_ohio_production_database_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                 --cidr-block $zulu_ohio_production_subnet_databasea_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_database_subneta_id=$zulu_ohio_production_database_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_production_database_subneta_id \
                    --tags Key=Name,Value=Zulu-Production-DatabaseSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet B
zulu_ohio_production_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                 --cidr-block $zulu_ohio_production_subnet_databaseb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_database_subnetb_id=$zulu_ohio_production_database_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_production_database_subnetb_id \
                    --tags Key=Name,Value=Zulu-Production-DatabaseSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet C
zulu_ohio_production_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                 --cidr-block $zulu_ohio_production_subnet_databasec_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_database_subnetc_id=$zulu_ohio_production_database_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_production_database_subnetc_id \
                    --tags Key=Name,Value=Zulu-Production-DatabaseSubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet A
zulu_ohio_production_management_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                   --cidr-block $zulu_ohio_production_subnet_managementa_cidr \
                                                                   --availability-zone us-east-2a \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_management_subneta_id=$zulu_ohio_production_management_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_production_management_subneta_id \
                    --tags Key=Name,Value=Zulu-Production-ManagementSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet B
zulu_ohio_production_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                   --cidr-block $zulu_ohio_production_subnet_managementb_cidr \
                                                                   --availability-zone us-east-2b \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_management_subnetb_id=$zulu_ohio_production_management_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_production_management_subnetb_id \
                    --tags Key=Name,Value=Zulu-Production-ManagementSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet C
zulu_ohio_production_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                   --cidr-block $zulu_ohio_production_subnet_managementc_cidr \
                                                                   --availability-zone us-east-2c \
                                                                   --query 'Subnet.SubnetId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_management_subnetc_id=$zulu_ohio_production_management_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_production_management_subnetc_id \
                    --tags Key=Name,Value=Zulu-Production-ManagementSubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet A
zulu_ohio_production_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                --cidr-block $zulu_ohio_production_subnet_gatewaya_cidr \
                                                                --availability-zone us-east-2a \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_gateway_subneta_id=$zulu_ohio_production_gateway_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_production_gateway_subneta_id \
                    --tags Key=Name,Value=Zulu-Production-GatewaySubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet B
zulu_ohio_production_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                --cidr-block $zulu_ohio_production_subnet_gatewayb_cidr \
                                                                --availability-zone us-east-2b \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_gateway_subnetb_id=$zulu_ohio_production_gateway_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_production_gateway_subnetb_id \
                    --tags Key=Name,Value=Zulu-Production-GatewaySubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet C
zulu_ohio_production_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                --cidr-block $zulu_ohio_production_subnet_gatewayc_cidr \
                                                                --availability-zone us-east-2c \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_gateway_subnetc_id=$zulu_ohio_production_gateway_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_production_gateway_subnetc_id \
                    --tags Key=Name,Value=Zulu-Production-GatewaySubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet A
zulu_ohio_production_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                 --cidr-block $zulu_ohio_production_subnet_endpointa_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_endpoint_subneta_id=$zulu_ohio_production_endpoint_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_production_endpoint_subneta_id \
                    --tags Key=Name,Value=Zulu-Production-EndpointSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet B
zulu_ohio_production_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                 --cidr-block $zulu_ohio_production_subnet_endpointb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_endpoint_subnetb_id=$zulu_ohio_production_endpoint_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_production_endpoint_subnetb_id \
                    --tags Key=Name,Value=Zulu-Production-EndpointSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet C
zulu_ohio_production_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_production_vpc_id \
                                                                 --cidr-block $zulu_ohio_production_subnet_endpointc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_endpoint_subnetc_id=$zulu_ohio_production_endpoint_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_production_endpoint_subnetc_id \
                    --tags Key=Name,Value=Zulu-Production-EndpointSubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
zulu_ohio_production_public_rtb_id=$(aws ec2 create-route-table --vpc-id $zulu_ohio_production_vpc_id \
                                                                --query 'RouteTable.RouteTableId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_public_rtb_id=$zulu_ohio_production_public_rtb_id"

aws ec2 create-tags --resources $zulu_ohio_production_public_rtb_id \
                    --tags Key=Name,Value=Zulu-Production-PublicRouteTable \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

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

aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_web_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_web_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_public_rtb_id --subnet-id $zulu_ohio_production_web_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create NAT Gateways
if [ $use_ngw = 1 ]; then
  zulu_ohio_production_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                           --query 'AllocationId' \
                                                           --profile $profile --region us-east-2 --output text)
  echo "zulu_ohio_production_ngw_eipa=$zulu_ohio_production_ngw_eipa"

  aws ec2 create-tags --resources $zulu_ohio_production_ngw_eipa \
                      --tags Key=Name,Value=Zulu-Production-NAT-EIPA \
                             Key=Company,Value=Zulu \
                             Key=Environment,Value=Production \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  zulu_ohio_production_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $zulu_ohio_production_ngw_eipa \
                                                            --subnet-id $zulu_ohio_production_public_subneta_id \
                                                            --client-token $(date +%s) \
                                                            --query 'NatGateway.NatGatewayId' \
                                                            --profile $profile --region us-east-2 --output text)
  echo "zulu_ohio_production_ngwa_id=$zulu_ohio_production_ngwa_id"

  aws ec2 create-tags --resources $zulu_ohio_production_ngwa_id \
                      --tags Key=Name,Value=Zulu-Production-NAT-GatewayA \
                             Key=Company,Value=Zulu \
                             Key=Environment,Value=Production \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  if [ $ha_ngw = 1 ]; then
    zulu_ohio_production_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                             --query 'AllocationId' \
                                                             --profile $profile --region us-east-2 --output text)
    echo "zulu_ohio_production_ngw_eipb=$zulu_ohio_production_ngw_eipb"

    aws ec2 create-tags --resources $zulu_ohio_production_ngw_eipb \
                        --tags Key=Name,Value=Zulu-Production-NAT-EIPB \
                               Key=Company,Value=Zulu \
                               Key=Environment,Value=Production \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    zulu_ohio_production_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $zulu_ohio_production_ngw_eipb \
                                                              --subnet-id $zulu_ohio_production_public_subnetb_id \
                                                              --client-token $(date +%s) \
                                                              --query 'NatGateway.NatGatewayId' \
                                                              --profile $profile --region us-east-2 --output text)
    echo "zulu_ohio_production_ngwb_id=$zulu_ohio_production_ngwb_id"

    aws ec2 create-tags --resources $zulu_ohio_production_ngwb_id \
                        --tags Key=Name,Value=Zulu-Production-NAT-GatewayB \
                               Key=Company,Value=Zulu \
                               Key=Environment,Value=Production \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    zulu_ohio_production_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                             --query 'AllocationId' \
                                                             --profile $profile --region us-east-2 --output text)
    echo "zulu_ohio_production_ngw_eipc=$zulu_ohio_production_ngw_eipc"

    aws ec2 create-tags --resources $zulu_ohio_production_ngw_eipc \
                        --tags Key=Name,Value=Zulu-Production-NAT-EIPC \
                               Key=Company,Value=Zulu \
                               Key=Environment,Value=Production \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text

    zulu_ohio_production_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $zulu_ohio_production_ngw_eipc \
                                                              --subnet-id $zulu_ohio_production_public_subnetc_id \
                                                              --client-token $(date +%s) \
                                                              --query 'NatGateway.NatGatewayId' \
                                                              --profile $profile --region us-east-2 --output text)
    echo "zulu_ohio_production_ngwc_id=$zulu_ohio_production_ngwc_id"

    aws ec2 create-tags --resources $zulu_ohio_production_ngwc_id \
                        --tags Key=Name,Value=Zulu-Production-NAT-GatewayC \
                               Key=Company,Value=Zulu \
                               Key=Environment,Value=Production \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region us-east-2 --output text
  fi
else
  # Create NAT Security Group
  zulu_ohio_production_nat_sg_id=$(aws ec2 create-security-group --group-name Zulu-Production-NAT-InstanceSecurityGroup \
                                                                 --description Zulu-Production-NAT-InstanceSecurityGroup \
                                                                 --vpc-id $zulu_ohio_production_vpc_id \
                                                                 --query 'GroupId' \
                                                                 --profile $profile --region us-east-2 --output text)
  echo "zulu_ohio_production_nat_sg_id=$zulu_ohio_production_nat_sg_id"

  aws ec2 create-tags --resources $zulu_ohio_production_nat_sg_id \
                      --tags Key=Name,Value=Zulu-Production-NAT-InstanceSecurityGroup \
                             Key=Company,Value=Zulu \
                             Key=Environment,Value=Production \
                             Key=Utility,Value=NAT \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region us-east-2 --output text

  aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_nat_sg_id \
                                           --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$zulu_ohio_production_vpc_cidr,Description=\"VPC (All)\"}]" \
                                           --profile $profile --region us-east-2 --output text

  # Create NAT Instance
  zulu_ohio_production_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                               --instance-type t3a.nano \
                                                               --iam-instance-profile Name=ManagedInstance \
                                                               --key-name administrator \
                                                               --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Zulu-Production-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_ohio_production_nat_sg_id],SubnetId=$zulu_ohio_production_public_subneta_id" \
                                                               --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Production-NAT-Instance},{Key=Hostname,Value=zulue2pnat01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                               --query 'Instances[0].InstanceId' \
                                                               --profile $profile --region us-east-2 --output text)
  echo "zulu_ohio_production_nat_instance_id=$zulu_ohio_production_nat_instance_id"

  aws ec2 modify-instance-attribute --instance-id $zulu_ohio_production_nat_instance_id \
                                    --no-source-dest-check \
                                    --profile $profile --region us-east-2 --output text

  zulu_ohio_production_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $zulu_ohio_production_nat_instance_id \
                                                                        --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                        --profile $profile --region us-east-2 --output text)
  echo "zulu_ohio_production_nat_instance_eni_id=$zulu_ohio_production_nat_instance_eni_id"

  zulu_ohio_production_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_ohio_production_nat_instance_id \
                                                                            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                            --profile $profile --region us-east-2 --output text)
  echo "zulu_ohio_production_nat_instance_private_ip=$zulu_ohio_production_nat_instance_private_ip"
fi

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
zulu_ohio_production_private_rtba_id=$(aws ec2 create-route-table --vpc-id $zulu_ohio_production_vpc_id \
                                                                  --query 'RouteTable.RouteTableId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_private_rtba_id=$zulu_ohio_production_private_rtba_id"

aws ec2 create-tags --resources $zulu_ohio_production_private_rtba_id \
                    --tags Key=Name,Value=Zulu-Production-PrivateRouteTableA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

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
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_database_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_management_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_gateway_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtba_id --subnet-id $zulu_ohio_production_endpoint_subneta_id \
                              --profile $profile --region us-east-2 --output text

zulu_ohio_production_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $zulu_ohio_production_vpc_id \
                                                                  --query 'RouteTable.RouteTableId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_private_rtbb_id=$zulu_ohio_production_private_rtbb_id"

aws ec2 create-tags --resources $zulu_ohio_production_private_rtbb_id \
                    --tags Key=Name,Value=Zulu-Production-PrivateRouteTableB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

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
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_database_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_management_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_gateway_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbb_id --subnet-id $zulu_ohio_production_endpoint_subnetb_id \
                              --profile $profile --region us-east-2 --output text

zulu_ohio_production_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $zulu_ohio_production_vpc_id \
                                                                  --query 'RouteTable.RouteTableId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_private_rtbc_id=$zulu_ohio_production_private_rtbc_id"

aws ec2 create-tags --resources $zulu_ohio_production_private_rtbc_id \
                    --tags Key=Name,Value=Zulu-Production-PrivateRouteTableC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

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
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_database_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_management_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_gateway_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_production_private_rtbc_id --subnet-id $zulu_ohio_production_endpoint_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create VPC Endpoint Security Group
zulu_ohio_production_vpce_sg_id=$(aws ec2 create-security-group --group-name Zulu-Production-VPCEndpointSecurityGroup \
                                                                --description Zulu-Production-VPCEndpointSecurityGroup \
                                                                --vpc-id $zulu_ohio_production_vpc_id \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_vpce_sg_id=$zulu_ohio_production_vpce_sg_id"

aws ec2 create-tags --resources $zulu_ohio_production_vpce_sg_id \
                    --tags Key=Name,Value=Zulu-Production-VPCEndpointSecurityGroup \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$zulu_ohio_production_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_production_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$zulu_ohio_production_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create VPC Endpoints for SSM and SSMMessages
zulu_ohio_production_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $zulu_ohio_production_vpc_id \
                                                               --vpc-endpoint-type Interface \
                                                               --service-name com.amazonaws.us-east-2.ssm \
                                                               --private-dns-enabled \
                                                               --security-group-ids $zulu_ohio_production_vpce_sg_id \
                                                               --subnet-ids $zulu_ohio_production_endpoint_subneta_id $zulu_ohio_production_endpoint_subnetb_id $zulu_ohio_production_endpoint_subnetc_id \
                                                               --client-token $(date +%s) \
                                                               --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Zulu-Production-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                               --query 'VpcEndpoint.VpcEndpointId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_ssm_vpce_id=$zulu_ohio_production_ssm_vpce_id"

zulu_ohio_production_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $zulu_ohio_production_vpc_id \
                                                                --vpc-endpoint-type Interface \
                                                                --service-name com.amazonaws.us-east-2.ssmmessages \
                                                                --private-dns-enabled \
                                                                --security-group-ids $zulu_ohio_production_vpce_sg_id \
                                                                --subnet-ids $zulu_ohio_production_endpoint_subneta_id $zulu_ohio_production_endpoint_subnetb_id $zulu_ohio_production_endpoint_subnetc_id \
                                                                --client-token $(date +%s) \
                                                                --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Zulu-Production-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Production},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                --query 'VpcEndpoint.VpcEndpointId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_production_ssmm_vpce_id=$zulu_ohio_production_ssmm_vpce_id"


## Zulu Ohio Development VPC ##########################################################################################
echo "development_account_id=$development_account_id"

profile=$development_profile

# Create VPC
zulu_ohio_development_vpc_id=$(aws ec2 create-vpc --cidr-block $zulu_ohio_development_vpc_cidr \
                                                  --query 'Vpc.VpcId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_vpc_id=$zulu_ohio_development_vpc_id"

aws ec2 create-tags --resources $zulu_ohio_development_vpc_id \
                    --tags Key=Name,Value=Zulu-Development-VPC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $zulu_ohio_development_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $zulu_ohio_development_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-2 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Development/Zulu" \
                          --profile $profile --region us-east-2 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $zulu_ohio_development_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-2:$development_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Development/Zulu" \
                         --deliver-logs-permission-arn "arn:aws:iam::$development_account_id:role/FlowLog" \
                         --profile $profile --region us-east-2 --output text

# Create Internet Gateway & Attach
zulu_ohio_development_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_igw_id=$zulu_ohio_development_igw_id"

aws ec2 create-tags --resources $zulu_ohio_development_igw_id \
                    --tags Key=Name,Value=Zulu-Development-InternetGateway \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 attach-internet-gateway --vpc-id $zulu_ohio_development_vpc_id \
                                --internet-gateway-id $zulu_ohio_development_igw_id \
                                --profile $profile --region us-east-2 --output text

# Create Private Hosted Zone
zulu_ohio_development_private_hostedzone_id=$(aws route53 create-hosted-zone --name $zulu_ohio_development_private_domain \
                                                                             --vpc VPCRegion=us-east-2,VPCId=$zulu_ohio_development_vpc_id \
                                                                             --hosted-zone-config Comment="Private Zone for $zulu_ohio_development_private_domain",PrivateZone=true \
                                                                             --caller-reference $(date +%s) \
                                                                             --query 'HostedZone.Id' \
                                                                             --profile $profile --region us-east-2 --output text | cut -f3 -d /)
echo "zulu_ohio_development_private_hostedzone_id=$zulu_ohio_development_private_hostedzone_id"

# Create DHCP Options Set
zulu_ohio_development_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$zulu_ohio_development_private_domain]" \
                                                                                  "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                            --query 'DhcpOptions.DhcpOptionsId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_dopt_id=$zulu_ohio_development_dopt_id"

aws ec2 create-tags --resources $zulu_ohio_development_dopt_id \
                    --tags Key=Name,Value=Zulu-Development-DHCPOptions \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 associate-dhcp-options --vpc-id $zulu_ohio_development_vpc_id \
                               --dhcp-options-id $zulu_ohio_development_dopt_id \
                               --profile $profile --region us-east-2 --output text

# Create Public Subnet A
zulu_ohio_development_public_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                --cidr-block $zulu_ohio_development_subnet_publica_cidr \
                                                                --availability-zone us-east-2a \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_public_subneta_id=$zulu_ohio_development_public_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_development_public_subneta_id \
                    --tags Key=Name,Value=Zulu-Development-PublicSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet B
zulu_ohio_development_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                --cidr-block $zulu_ohio_development_subnet_publicb_cidr \
                                                                --availability-zone us-east-2b \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_public_subnetb_id=$zulu_ohio_development_public_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_development_public_subnetb_id \
                    --tags Key=Name,Value=Zulu-Development-PublicSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet C
zulu_ohio_development_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                --cidr-block $zulu_ohio_development_subnet_publicc_cidr \
                                                                --availability-zone us-east-2c \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_public_subnetc_id=$zulu_ohio_development_public_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_development_public_subnetc_id \
                    --tags Key=Name,Value=Zulu-Development-PublicSubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet A
zulu_ohio_development_web_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                             --cidr-block $zulu_ohio_development_subnet_weba_cidr \
                                                             --availability-zone us-east-2a \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_web_subneta_id=$zulu_ohio_development_web_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_development_web_subneta_id \
                    --tags Key=Name,Value=Zulu-Development-WebSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet B
zulu_ohio_development_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                             --cidr-block $zulu_ohio_development_subnet_webb_cidr \
                                                             --availability-zone us-east-2b \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_web_subnetb_id=$zulu_ohio_development_web_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_development_web_subnetb_id \
                    --tags Key=Name,Value=Zulu-Development-WebSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Web Subnet C
zulu_ohio_development_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                             --cidr-block $zulu_ohio_development_subnet_webc_cidr \
                                                             --availability-zone us-east-2c \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_web_subnetc_id=$zulu_ohio_development_web_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_development_web_subnetc_id \
                    --tags Key=Name,Value=Zulu-Development-WebSubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet A
zulu_ohio_development_application_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                     --cidr-block $zulu_ohio_development_subnet_applicationa_cidr \
                                                                     --availability-zone us-east-2a \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_application_subneta_id=$zulu_ohio_development_application_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_development_application_subneta_id \
                    --tags Key=Name,Value=Zulu-Development-ApplicationSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet B
zulu_ohio_development_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                     --cidr-block $zulu_ohio_development_subnet_applicationb_cidr \
                                                                     --availability-zone us-east-2b \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_application_subnetb_id=$zulu_ohio_development_application_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_development_application_subnetb_id \
                    --tags Key=Name,Value=Zulu-Development-ApplicationSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Application Subnet C
zulu_ohio_development_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                     --cidr-block $zulu_ohio_development_subnet_applicationc_cidr \
                                                                     --availability-zone us-east-2c \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_application_subnetc_id=$zulu_ohio_development_application_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_development_application_subnetc_id \
                    --tags Key=Name,Value=Zulu-Development-ApplicationSubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet A
zulu_ohio_development_database_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                  --cidr-block $zulu_ohio_development_subnet_databasea_cidr \
                                                                  --availability-zone us-east-2a \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_database_subneta_id=$zulu_ohio_development_database_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_development_database_subneta_id \
                    --tags Key=Name,Value=Zulu-Development-DatabaseSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet B
zulu_ohio_development_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                  --cidr-block $zulu_ohio_development_subnet_databaseb_cidr \
                                                                  --availability-zone us-east-2b \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_database_subnetb_id=$zulu_ohio_development_database_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_development_database_subnetb_id \
                    --tags Key=Name,Value=Zulu-Development-DatabaseSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Database Subnet C
zulu_ohio_development_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                  --cidr-block $zulu_ohio_development_subnet_databasec_cidr \
                                                                  --availability-zone us-east-2c \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_database_subnetc_id=$zulu_ohio_development_database_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_development_database_subnetc_id \
                    --tags Key=Name,Value=Zulu-Development-DatabaseSubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet A
zulu_ohio_development_management_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                    --cidr-block $zulu_ohio_development_subnet_managementa_cidr \
                                                                    --availability-zone us-east-2a \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_management_subneta_id=$zulu_ohio_development_management_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_development_management_subneta_id \
                    --tags Key=Name,Value=Zulu-Development-ManagementSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet B
zulu_ohio_development_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                    --cidr-block $zulu_ohio_development_subnet_managementb_cidr \
                                                                    --availability-zone us-east-2b \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_management_subnetb_id=$zulu_ohio_development_management_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_development_management_subnetb_id \
                    --tags Key=Name,Value=Zulu-Development-ManagementSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet C
zulu_ohio_development_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                    --cidr-block $zulu_ohio_development_subnet_managementc_cidr \
                                                                    --availability-zone us-east-2c \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_management_subnetc_id=$zulu_ohio_development_management_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_development_management_subnetc_id \
                    --tags Key=Name,Value=Zulu-Development-ManagementSubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet A
zulu_ohio_development_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                 --cidr-block $zulu_ohio_development_subnet_gatewaya_cidr \
                                                                 --availability-zone us-east-2a \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_gateway_subneta_id=$zulu_ohio_development_gateway_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_development_gateway_subneta_id \
                    --tags Key=Name,Value=Zulu-Development-GatewaySubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet B
zulu_ohio_development_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                 --cidr-block $zulu_ohio_development_subnet_gatewayb_cidr \
                                                                 --availability-zone us-east-2b \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_gateway_subnetb_id=$zulu_ohio_development_gateway_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_development_gateway_subnetb_id \
                    --tags Key=Name,Value=Zulu-Development-GatewaySubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet C
zulu_ohio_development_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                 --cidr-block $zulu_ohio_development_subnet_gatewayc_cidr \
                                                                 --availability-zone us-east-2c \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_gateway_subnetc_id=$zulu_ohio_development_gateway_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_development_gateway_subnetc_id \
                    --tags Key=Name,Value=Zulu-Development-GatewaySubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet A
zulu_ohio_development_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                  --cidr-block $zulu_ohio_development_subnet_endpointa_cidr \
                                                                  --availability-zone us-east-2a \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_endpoint_subneta_id=$zulu_ohio_development_endpoint_subneta_id"

aws ec2 create-tags --resources $zulu_ohio_development_endpoint_subneta_id \
                    --tags Key=Name,Value=Zulu-Development-EndpointSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet B
zulu_ohio_development_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                  --cidr-block $zulu_ohio_development_subnet_endpointb_cidr \
                                                                  --availability-zone us-east-2b \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_endpoint_subnetb_id=$zulu_ohio_development_endpoint_subnetb_id"

aws ec2 create-tags --resources $zulu_ohio_development_endpoint_subnetb_id \
                    --tags Key=Name,Value=Zulu-Development-EndpointSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet C
zulu_ohio_development_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $zulu_ohio_development_vpc_id \
                                                                  --cidr-block $zulu_ohio_development_subnet_endpointc_cidr \
                                                                  --availability-zone us-east-2c \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_endpoint_subnetc_id=$zulu_ohio_development_endpoint_subnetc_id"

aws ec2 create-tags --resources $zulu_ohio_development_endpoint_subnetc_id \
                    --tags Key=Name,Value=Zulu-Development-EndpointSubnetC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
zulu_ohio_development_public_rtb_id=$(aws ec2 create-route-table --vpc-id $zulu_ohio_development_vpc_id \
                                                                 --query 'RouteTable.RouteTableId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_public_rtb_id=$zulu_ohio_development_public_rtb_id"

aws ec2 create-tags --resources $zulu_ohio_development_public_rtb_id \
                    --tags Key=Name,Value=Zulu-Development-PublicRouteTable \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_ohio_development_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $zulu_ohio_development_igw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $zulu_ohio_development_public_rtb_id --subnet-id $zulu_ohio_development_public_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_public_rtb_id --subnet-id $zulu_ohio_development_public_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_public_rtb_id --subnet-id $zulu_ohio_development_public_subnetc_id \
                              --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $zulu_ohio_development_public_rtb_id --subnet-id $zulu_ohio_development_web_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_public_rtb_id --subnet-id $zulu_ohio_development_web_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_public_rtb_id --subnet-id $zulu_ohio_development_web_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create NAT Security Group
zulu_ohio_development_nat_sg_id=$(aws ec2 create-security-group --group-name Zulu-Development-NAT-InstanceSecurityGroup \
                                                                --description Zulu-Development-NAT-InstanceSecurityGroup \
                                                                --vpc-id $zulu_ohio_development_vpc_id \
                                                                --query 'GroupId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_nat_sg_id=$zulu_ohio_development_nat_sg_id"

aws ec2 create-tags --resources $zulu_ohio_development_nat_sg_id \
                    --tags Key=Name,Value=Zulu-Development-NAT-InstanceSecurityGroup \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Utility,Value=NAT \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_nat_sg_id \
                                         --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$zulu_ohio_development_vpc_cidr,Description=\"VPC (All)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create NAT Instance
zulu_ohio_development_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                              --instance-type t3a.nano \
                                                              --iam-instance-profile Name=ManagedInstance \
                                                              --key-name administrator \
                                                              --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Zulu-Development-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_ohio_development_nat_sg_id],SubnetId=$zulu_ohio_development_public_subneta_id" \
                                                              --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Development-NAT-Instance},{Key=Hostname,Value=zulue2dnat01a},{Key=Company,Value=Zulu},{Key=Environment,Value=Development},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                              --query 'Instances[0].InstanceId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_nat_instance_id=$zulu_ohio_development_nat_instance_id"

aws ec2 modify-instance-attribute --instance-id $zulu_ohio_development_nat_instance_id \
                                  --no-source-dest-check \
                                  --profile $profile --region us-east-2 --output text

zulu_ohio_development_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $zulu_ohio_development_nat_instance_id \
                                                                       --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                       --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_nat_instance_eni_id=$zulu_ohio_development_nat_instance_eni_id"

zulu_ohio_development_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_ohio_development_nat_instance_id \
                                                                           --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_nat_instance_private_ip=$zulu_ohio_development_nat_instance_private_ip"

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
zulu_ohio_development_private_rtba_id=$(aws ec2 create-route-table --vpc-id $zulu_ohio_development_vpc_id \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_private_rtba_id=$zulu_ohio_development_private_rtba_id"

aws ec2 create-tags --resources $zulu_ohio_development_private_rtba_id \
                    --tags Key=Name,Value=Zulu-Development-PrivateRouteTableA \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_ohio_development_private_rtba_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $zulu_ohio_development_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtba_id --subnet-id $zulu_ohio_development_application_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtba_id --subnet-id $zulu_ohio_development_database_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtba_id --subnet-id $zulu_ohio_development_management_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtba_id --subnet-id $zulu_ohio_development_gateway_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtba_id --subnet-id $zulu_ohio_development_endpoint_subneta_id \
                              --profile $profile --region us-east-2 --output text

zulu_ohio_development_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $zulu_ohio_development_vpc_id \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_private_rtbb_id=$zulu_ohio_development_private_rtbb_id"

aws ec2 create-tags --resources $zulu_ohio_development_private_rtbb_id \
                    --tags Key=Name,Value=Zulu-Development-PrivateRouteTableB \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_ohio_development_private_rtbb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $zulu_ohio_development_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtbb_id --subnet-id $zulu_ohio_development_application_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtbb_id --subnet-id $zulu_ohio_development_database_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtbb_id --subnet-id $zulu_ohio_development_management_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtbb_id --subnet-id $zulu_ohio_development_gateway_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtbb_id --subnet-id $zulu_ohio_development_endpoint_subnetb_id \
                              --profile $profile --region us-east-2 --output text

zulu_ohio_development_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $zulu_ohio_development_vpc_id \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_private_rtbc_id=$zulu_ohio_development_private_rtbc_id"

aws ec2 create-tags --resources $zulu_ohio_development_private_rtbc_id \
                    --tags Key=Name,Value=Zulu-Development-PrivateRouteTableC \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_ohio_development_private_rtbc_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $zulu_ohio_development_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtbc_id --subnet-id $zulu_ohio_development_application_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtbc_id --subnet-id $zulu_ohio_development_database_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtbc_id --subnet-id $zulu_ohio_development_management_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtbc_id --subnet-id $zulu_ohio_development_gateway_subnetc_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_ohio_development_private_rtbc_id --subnet-id $zulu_ohio_development_endpoint_subnetc_id \
                              --profile $profile --region us-east-2 --output text

# Create VPC Endpoint Security Group
zulu_ohio_development_vpce_sg_id=$(aws ec2 create-security-group --group-name Zulu-Development-VPCEndpointSecurityGroup \
                                                                 --description Zulu-Development-VPCEndpointSecurityGroup \
                                                                 --vpc-id $zulu_ohio_development_vpc_id \
                                                                 --query 'GroupId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_vpce_sg_id=$zulu_ohio_development_vpce_sg_id"

aws ec2 create-tags --resources $zulu_ohio_development_vpce_sg_id \
                    --tags Key=Name,Value=Zulu-Development-VPCEndpointSecurityGroup \
                           Key=Company,Value=Zulu \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$zulu_ohio_development_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_ohio_development_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$zulu_ohio_development_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create VPC Endpoints for SSM and SSMMessages
zulu_ohio_development_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $zulu_ohio_development_vpc_id \
                                                                --vpc-endpoint-type Interface \
                                                                --service-name com.amazonaws.us-east-2.ssm \
                                                                --private-dns-enabled \
                                                                --security-group-ids $zulu_ohio_development_vpce_sg_id \
                                                                --subnet-ids $zulu_ohio_development_endpoint_subneta_id $zulu_ohio_development_endpoint_subnetb_id $zulu_ohio_development_endpoint_subnetc_id \
                                                                --client-token $(date +%s) \
                                                                --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Zulu-Development-SSMVpcEndpoint},{Key=Company,Value=Zulu},{Key=Environment,Value=Development},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                --query 'VpcEndpoint.VpcEndpointId' \
                                                                --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_ssm_vpce_id=$zulu_ohio_development_ssm_vpce_id"

zulu_ohio_development_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $zulu_ohio_development_vpc_id \
                                                                 --vpc-endpoint-type Interface \
                                                                 --service-name com.amazonaws.us-east-2.ssmmessages \
                                                                 --private-dns-enabled \
                                                                 --security-group-ids $zulu_ohio_development_vpce_sg_id \
                                                                 --subnet-ids $zulu_ohio_development_endpoint_subneta_id $zulu_ohio_development_endpoint_subnetb_id $zulu_ohio_development_endpoint_subnetc_id \
                                                                 --client-token $(date +%s) \
                                                                 --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Zulu-Development-SSMMessagesVpcEndpoint},{Key=Company,Value=Zulu},{Key=Environment,Value=Development},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                 --query 'VpcEndpoint.VpcEndpointId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_development_ssmm_vpce_id=$zulu_ohio_development_ssmm_vpce_id"


## Ireland Management VPC #############################################################################################
echo "management_account_id=$management_account_id"

profile=$management_profile

# Create VPC
ireland_management_vpc_id=$(aws ec2 create-vpc --cidr-block $ireland_management_vpc_cidr \
                                               --query 'Vpc.VpcId' \
                                               --profile $profile --region eu-west-1 --output text)
echo "ireland_management_vpc_id=$ireland_management_vpc_id"

aws ec2 create-tags --resources $ireland_management_vpc_id \
                    --tags Key=Name,Value=Management-VPC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $ireland_management_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region eu-west-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $ireland_management_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region eu-west-1 --output text

# Note VPC Flow Log Role Already exists - created for Virginia above

aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Management" \
                          --profile $profile --region eu-west-1 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $ireland_management_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:eu-west-1:$management_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Management" \
                         --deliver-logs-permission-arn "arn:aws:iam::$management_account_id:role/FlowLog" \
                         --profile $profile --region eu-west-1 --output text

# Create Internet Gateway & Attach
ireland_management_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                            --profile $profile --region eu-west-1 --output text)
echo "ireland_management_igw_id=$ireland_management_igw_id"

aws ec2 create-tags --resources $ireland_management_igw_id \
                    --tags Key=Name,Value=Management-InternetGateway \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 attach-internet-gateway --vpc-id $ireland_management_vpc_id \
                                --internet-gateway-id $ireland_management_igw_id \
                                --profile $profile --region eu-west-1 --output text

# Create Private Hosted Zone
ireland_management_private_hostedzone_id=$(aws route53 create-hosted-zone --name $ireland_management_public_domain \
                                                                          --vpc VPCRegion=eu-west-1,VPCId=$ireland_management_vpc_id \
                                                                          --hosted-zone-config Comment="Private Zone for $ireland_management_public_domain",PrivateZone=true \
                                                                          --caller-reference $(date +%s) \
                                                                          --query 'HostedZone.Id' \
                                                                          --profile $profile --region eu-west-1 --output text | cut -f3 -d /)
echo "ireland_management_private_hostedzone_id=$ireland_management_private_hostedzone_id"

# Create DHCP Options Set
ireland_management_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$ireland_management_public_domain]" \
                                                                               "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                         --query 'DhcpOptions.DhcpOptionsId' \
                                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_management_dopt_id=$ireland_management_dopt_id"

aws ec2 create-tags --resources $ireland_management_dopt_id \
                    --tags Key=Name,Value=Management-DHCPOptions \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 associate-dhcp-options --vpc-id $ireland_management_vpc_id \
                               --dhcp-options-id $ireland_management_dopt_id \
                               --profile $profile --region eu-west-1 --output text

# Create Public Subnet A
ireland_management_public_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                             --cidr-block $ireland_management_subnet_publica_cidr \
                                                             --availability-zone eu-west-1a \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region eu-west-1 --output text)
echo "ireland_management_public_subneta_id=$ireland_management_public_subneta_id"

aws ec2 create-tags --resources $ireland_management_public_subneta_id \
                    --tags Key=Name,Value=Management-PublicSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Public Subnet B
ireland_management_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                             --cidr-block $ireland_management_subnet_publicb_cidr \
                                                             --availability-zone eu-west-1b \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region eu-west-1 --output text)
echo "ireland_management_public_subnetb_id=$ireland_management_public_subnetb_id"

aws ec2 create-tags --resources $ireland_management_public_subnetb_id \
                    --tags Key=Name,Value=Management-PublicSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Public Subnet C
ireland_management_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                             --cidr-block $ireland_management_subnet_publicc_cidr \
                                                             --availability-zone eu-west-1c \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region eu-west-1 --output text)
echo "ireland_management_public_subnetc_id=$ireland_management_public_subnetc_id"

aws ec2 create-tags --resources $ireland_management_public_subnetc_id \
                    --tags Key=Name,Value=Management-PublicSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Web Subnet A
ireland_management_web_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                          --cidr-block $ireland_management_subnet_weba_cidr \
                                                          --availability-zone eu-west-1a \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region eu-west-1 --output text)
echo "ireland_management_web_subneta_id=$ireland_management_web_subneta_id"

aws ec2 create-tags --resources $ireland_management_web_subneta_id \
                    --tags Key=Name,Value=Management-WebSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Web Subnet B
ireland_management_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                          --cidr-block $ireland_management_subnet_webb_cidr \
                                                          --availability-zone eu-west-1b \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region eu-west-1 --output text)
echo "ireland_management_web_subnetb_id=$ireland_management_web_subnetb_id"

aws ec2 create-tags --resources $ireland_management_web_subnetb_id \
                    --tags Key=Name,Value=Management-WebSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Web Subnet C
ireland_management_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                          --cidr-block $ireland_management_subnet_webc_cidr \
                                                          --availability-zone eu-west-1c \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region eu-west-1 --output text)
echo "ireland_management_web_subnetc_id=$ireland_management_web_subnetc_id"

aws ec2 create-tags --resources $ireland_management_web_subnetc_id \
                    --tags Key=Name,Value=Management-WebSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Application Subnet A
ireland_management_application_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                                  --cidr-block $ireland_management_subnet_applicationa_cidr \
                                                                  --availability-zone eu-west-1a \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "ireland_management_application_subneta_id=$ireland_management_application_subneta_id"

aws ec2 create-tags --resources $ireland_management_application_subneta_id \
                    --tags Key=Name,Value=Management-ApplicationSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Application Subnet B
ireland_management_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                                  --cidr-block $ireland_management_subnet_applicationb_cidr \
                                                                  --availability-zone eu-west-1b \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "ireland_management_application_subnetb_id=$ireland_management_application_subnetb_id"

aws ec2 create-tags --resources $ireland_management_application_subnetb_id \
                    --tags Key=Name,Value=Management-ApplicationSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Application Subnet C
ireland_management_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                                  --cidr-block $ireland_management_subnet_applicationc_cidr \
                                                                  --availability-zone eu-west-1c \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "ireland_management_application_subnetc_id=$ireland_management_application_subnetc_id"

aws ec2 create-tags --resources $ireland_management_application_subnetc_id \
                    --tags Key=Name,Value=Management-ApplicationSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Database Subnet A
ireland_management_database_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                               --cidr-block $ireland_management_subnet_databasea_cidr \
                                                               --availability-zone eu-west-1a \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region eu-west-1 --output text)
echo "ireland_management_database_subneta_id=$ireland_management_database_subneta_id"

aws ec2 create-tags --resources $ireland_management_database_subneta_id \
                    --tags Key=Name,Value=Management-DatabaseSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Database Subnet B
ireland_management_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                               --cidr-block $ireland_management_subnet_databaseb_cidr \
                                                               --availability-zone eu-west-1b \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region eu-west-1 --output text)
echo "ireland_management_database_subnetb_id=$ireland_management_database_subnetb_id"

aws ec2 create-tags --resources $ireland_management_database_subnetb_id \
                    --tags Key=Name,Value=Management-DatabaseSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Database Subnet C
ireland_management_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                               --cidr-block $ireland_management_subnet_databasec_cidr \
                                                               --availability-zone eu-west-1c \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region eu-west-1 --output text)
echo "ireland_management_database_subnetc_id=$ireland_management_database_subnetc_id"

aws ec2 create-tags --resources $ireland_management_database_subnetc_id \
                    --tags Key=Name,Value=Management-DatabaseSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Directory Subnet A
ireland_management_directory_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                            --cidr-block $ireland_management_subnet_directorya_cidr \
                                                            --availability-zone eu-west-1a \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region eu-west-1 --output text)
echo "ireland_management_directory_subneta_id=$ireland_management_directory_subneta_id"

aws ec2 create-tags --resources $ireland_management_directory_subneta_id \
                    --tags Key=Name,Value=Management-DirectorySubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Directory Subnet B
ireland_management_directory_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                            --cidr-block $ireland_management_subnet_directoryb_cidr \
                                                            --availability-zone eu-west-1b \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region eu-west-1 --output text)
echo "ireland_management_directory_subnetb_id=$ireland_management_directory_subnetb_id"

aws ec2 create-tags --resources $ireland_management_directory_subnetb_id \
                    --tags Key=Name,Value=Management-DirectorySubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Directory Subnet C
ireland_management_directory_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                            --cidr-block $ireland_management_subnet_directoryc_cidr \
                                                            --availability-zone eu-west-1c \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region eu-west-1 --output text)
echo "ireland_management_directory_subnetc_id=$ireland_management_directory_subnetc_id"

aws ec2 create-tags --resources $ireland_management_directory_subnetc_id \
                    --tags Key=Name,Value=Management-DirectorySubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Management Subnet A
ireland_management_management_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                                 --cidr-block $ireland_management_subnet_managementa_cidr \
                                                                 --availability-zone eu-west-1a \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "ireland_management_management_subneta_id=$ireland_management_management_subneta_id"

aws ec2 create-tags --resources $ireland_management_management_subneta_id \
                    --tags Key=Name,Value=Management-ManagementSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Management Subnet B
ireland_management_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                                 --cidr-block $ireland_management_subnet_managementb_cidr \
                                                                 --availability-zone eu-west-1b \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "ireland_management_management_subnetb_id=$ireland_management_management_subnetb_id"

aws ec2 create-tags --resources $ireland_management_management_subnetb_id \
                    --tags Key=Name,Value=Management-ManagementSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Management Subnet C
ireland_management_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                                 --cidr-block $ireland_management_subnet_managementc_cidr \
                                                                 --availability-zone eu-west-1c \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "ireland_management_management_subnetc_id=$ireland_management_management_subnetc_id"

aws ec2 create-tags --resources $ireland_management_management_subnetc_id \
                    --tags Key=Name,Value=Management-ManagementSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Gateway Subnet A
ireland_management_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                              --cidr-block $ireland_management_subnet_gatewaya_cidr \
                                                              --availability-zone eu-west-1a \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region eu-west-1 --output text)
echo "ireland_management_gateway_subneta_id=$ireland_management_gateway_subneta_id"

aws ec2 create-tags --resources $ireland_management_gateway_subneta_id \
                    --tags Key=Name,Value=Management-GatewaySubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Gateway Subnet B
ireland_management_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                              --cidr-block $ireland_management_subnet_gatewayb_cidr \
                                                              --availability-zone eu-west-1b \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region eu-west-1 --output text)
echo "ireland_management_gateway_subnetb_id=$ireland_management_gateway_subnetb_id"

aws ec2 create-tags --resources $ireland_management_gateway_subnetb_id \
                    --tags Key=Name,Value=Management-GatewaySubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Gateway Subnet C
ireland_management_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                              --cidr-block $ireland_management_subnet_gatewayc_cidr \
                                                              --availability-zone eu-west-1c \
                                                              --query 'Subnet.SubnetId' \
                                                              --profile $profile --region eu-west-1 --output text)
echo "ireland_management_gateway_subnetc_id=$ireland_management_gateway_subnetc_id"

aws ec2 create-tags --resources $ireland_management_gateway_subnetc_id \
                    --tags Key=Name,Value=Management-GatewaySubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Endpoint Subnet A
ireland_management_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                               --cidr-block $ireland_management_subnet_endpointa_cidr \
                                                               --availability-zone eu-west-1a \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region eu-west-1 --output text)
echo "ireland_management_endpoint_subneta_id=$ireland_management_endpoint_subneta_id"

aws ec2 create-tags --resources $ireland_management_endpoint_subneta_id \
                    --tags Key=Name,Value=Management-EndpointSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Endpoint Subnet B
ireland_management_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                               --cidr-block $ireland_management_subnet_endpointb_cidr \
                                                               --availability-zone eu-west-1b \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region eu-west-1 --output text)
echo "ireland_management_endpoint_subnetb_id=$ireland_management_endpoint_subnetb_id"

aws ec2 create-tags --resources $ireland_management_endpoint_subnetb_id \
                    --tags Key=Name,Value=Management-EndpointSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Endpoint Subnet C
ireland_management_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_management_vpc_id \
                                                               --cidr-block $ireland_management_subnet_endpointc_cidr \
                                                               --availability-zone eu-west-1c \
                                                               --query 'Subnet.SubnetId' \
                                                               --profile $profile --region eu-west-1 --output text)
echo "ireland_management_endpoint_subnetc_id=$ireland_management_endpoint_subnetc_id"

aws ec2 create-tags --resources $ireland_management_endpoint_subnetc_id \
                    --tags Key=Name,Value=Management-EndpointSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
ireland_management_public_rtb_id=$(aws ec2 create-route-table --vpc-id $ireland_management_vpc_id \
                                                              --query 'RouteTable.RouteTableId' \
                                                              --profile $profile --region eu-west-1 --output text)
echo "ireland_management_public_rtb_id=$ireland_management_public_rtb_id"

aws ec2 create-tags --resources $ireland_management_public_rtb_id \
                    --tags Key=Name,Value=Management-PublicRouteTable \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $ireland_management_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $ireland_management_igw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 associate-route-table --route-table-id $ireland_management_public_rtb_id --subnet-id $ireland_management_public_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_public_rtb_id --subnet-id $ireland_management_public_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_public_rtb_id --subnet-id $ireland_management_public_subnetc_id \
                              --profile $profile --region eu-west-1 --output text

aws ec2 associate-route-table --route-table-id $ireland_management_public_rtb_id --subnet-id $ireland_management_web_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_public_rtb_id --subnet-id $ireland_management_web_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_public_rtb_id --subnet-id $ireland_management_web_subnetc_id \
                              --profile $profile --region eu-west-1 --output text

# Create NAT Gateways
if [ $use_ngw = 1 ]; then
  ireland_management_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                         --query 'AllocationId' \
                                                         --profile $profile --region eu-west-1 --output text)
  echo "ireland_management_ngw_eipa=$ireland_management_ngw_eipa"

  aws ec2 create-tags --resources $ireland_management_ngw_eipa \
                      --tags Key=Name,Value=Management-NAT-EIPA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region eu-west-1 --output text

  ireland_management_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $ireland_management_ngw_eipa \
                                                          --subnet-id $ireland_management_public_subneta_id \
                                                          --client-token $(date +%s) \
                                                          --query 'NatGateway.NatGatewayId' \
                                                          --profile $profile --region eu-west-1 --output text)
  echo "ireland_management_ngwa_id=$ireland_management_ngwa_id"

  aws ec2 create-tags --resources $ireland_management_ngwa_id \
                      --tags Key=Name,Value=Management-NAT-GatewayA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region eu-west-1 --output text

  if [ $ha_ngw = 1 ]; then
    ireland_management_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                           --query 'AllocationId' \
                                                           --profile $profile --region eu-west-1 --output text)
    echo "ireland_management_ngw_eipb=$ireland_management_ngw_eipb"

    aws ec2 create-tags --resources $ireland_management_ngw_eipb \
                        --tags Key=Name,Value=Management-NAT-EIPB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text

    ireland_management_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $ireland_management_ngw_eipb \
                                                            --subnet-id $ireland_management_public_subnetb_id \
                                                            --client-token $(date +%s) \
                                                            --query 'NatGateway.NatGatewayId' \
                                                            --profile $profile --region eu-west-1 --output text)
    echo "ireland_management_ngwb_id=$ireland_management_ngwb_id"

    aws ec2 create-tags --resources $ireland_management_ngwb_id \
                        --tags Key=Name,Value=Management-NAT-GatewayB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text

    ireland_management_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                           --query 'AllocationId' \
                                                           --profile $profile --region eu-west-1 --output text)
    echo "ireland_management_ngw_eipc=$ireland_management_ngw_eipc"

    aws ec2 create-tags --resources $ireland_management_ngw_eipc \
                        --tags Key=Name,Value=Management-NAT-EIPC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text

    ireland_management_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $ireland_management_ngw_eipc \
                                                            --subnet-id $ireland_management_public_subnetc_id \
                                                            --client-token $(date +%s) \
                                                            --query 'NatGateway.NatGatewayId' \
                                                            --profile $profile --region eu-west-1 --output text)
    echo "ireland_management_ngwc_id=$ireland_management_ngwc_id"

    aws ec2 create-tags --resources $ireland_management_ngwc_id \
                        --tags Key=Name,Value=Management-NAT-GatewayC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Management \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text
  fi
else
  # Create NAT Security Group
  ireland_management_nat_sg_id=$(aws ec2 create-security-group --group-name Management-NAT-InstanceSecurityGroup \
                                                               --description Management-NAT-InstanceSecurityGroup \
                                                               --vpc-id $ireland_management_vpc_id \
                                                               --query 'GroupId' \
                                                               --profile $profile --region eu-west-1 --output text)
  echo "ireland_management_nat_sg_id=$ireland_management_nat_sg_id"

  aws ec2 create-tags --resources $ireland_management_nat_sg_id \
                      --tags Key=Name,Value=Management-NAT-InstanceSecurityGroup \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Utility,Value=NAT \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region eu-west-1 --output text

  aws ec2 authorize-security-group-ingress --group-id $ireland_management_nat_sg_id \
                                           --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$ireland_management_vpc_cidr,Description=\"VPC (All)\"}]" \
                                           --profile $profile --region eu-west-1 --output text

  # Create NAT Instance
  ireland_management_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                             --instance-type t3a.nano \
                                                             --iam-instance-profile Name=ManagedInstance \
                                                             --key-name administrator \
                                                             --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Management-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ireland_management_nat_sg_id],SubnetId=$ireland_management_public_subneta_id" \
                                                             --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Management-NAT-Instance},{Key=Hostname,Value=cmlew1mnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                             --query 'Instances[0].InstanceId' \
                                                             --profile $profile --region eu-west-1 --output text)
  echo "ireland_management_nat_instance_id=$ireland_management_nat_instance_id"

  aws ec2 modify-instance-attribute --instance-id $ireland_management_nat_instance_id \
                                    --no-source-dest-check \
                                    --profile $profile --region eu-west-1 --output text

  ireland_management_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $ireland_management_nat_instance_id \
                                                                      --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                      --profile $profile --region eu-west-1 --output text)
  echo "ireland_management_nat_instance_eni_id=$ireland_management_nat_instance_eni_id"

  ireland_management_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $ireland_management_nat_instance_id \
                                                                          --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                          --profile $profile --region eu-west-1 --output text)
  echo "ireland_management_nat_instance_private_ip=$ireland_management_nat_instance_private_ip"
fi

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
ireland_management_private_rtba_id=$(aws ec2 create-route-table --vpc-id $ireland_management_vpc_id \
                                                                --query 'RouteTable.RouteTableId' \
                                                                --profile $profile --region eu-west-1 --output text)
echo "ireland_management_private_rtba_id=$ireland_management_private_rtba_id"

aws ec2 create-tags --resources $ireland_management_private_rtba_id \
                    --tags Key=Name,Value=Management-PrivateRouteTableA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

if [ $use_ngw = 1 ]; then
  aws ec2 create-route --route-table-id $ireland_management_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ireland_management_ngwa_id \
                       --profile $profile --region eu-west-1 --output text
else
  aws ec2 create-route --route-table-id $ireland_management_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ireland_management_nat_instance_eni_id \
                       --profile $profile --region eu-west-1 --output text
fi

aws ec2 associate-route-table --route-table-id $ireland_management_private_rtba_id --subnet-id $ireland_management_application_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtba_id --subnet-id $ireland_management_database_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtba_id --subnet-id $ireland_management_directory_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtba_id --subnet-id $ireland_management_management_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtba_id --subnet-id $ireland_management_gateway_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtba_id --subnet-id $ireland_management_endpoint_subneta_id \
                              --profile $profile --region eu-west-1 --output text

ireland_management_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $ireland_management_vpc_id \
                                                                --query 'RouteTable.RouteTableId' \
                                                                --profile $profile --region eu-west-1 --output text)
echo "ireland_management_private_rtbb_id=$ireland_management_private_rtbb_id"

aws ec2 create-tags --resources $ireland_management_private_rtbb_id \
                    --tags Key=Name,Value=Management-PrivateRouteTableB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then ireland_management_ngw_id=$ireland_management_ngwb_id; else ireland_management_ngw_id=$ireland_management_ngwa_id; fi
  aws ec2 create-route --route-table-id $ireland_management_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ireland_management_ngw_id \
                       --profile $profile --region eu-west-1 --output text
else
  aws ec2 create-route --route-table-id $ireland_management_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ireland_management_nat_instance_eni_id \
                       --profile $profile --region eu-west-1 --output text
fi

aws ec2 associate-route-table --route-table-id $ireland_management_private_rtbb_id --subnet-id $ireland_management_application_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtbb_id --subnet-id $ireland_management_database_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtbb_id --subnet-id $ireland_management_directory_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtbb_id --subnet-id $ireland_management_management_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtbb_id --subnet-id $ireland_management_gateway_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtbb_id --subnet-id $ireland_management_endpoint_subnetb_id \
                              --profile $profile --region eu-west-1 --output text

ireland_management_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $ireland_management_vpc_id \
                                                                --query 'RouteTable.RouteTableId' \
                                                                --profile $profile --region eu-west-1 --output text)
echo "ireland_management_private_rtbc_id=$ireland_management_private_rtbc_id"

aws ec2 create-tags --resources $ireland_management_private_rtbc_id \
                    --tags Key=Name,Value=Management-PrivateRouteTableC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then ireland_management_ngw_id=$ireland_management_ngwc_id; else ireland_management_ngw_id=$ireland_management_ngwa_id; fi
  aws ec2 create-route --route-table-id $ireland_management_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ireland_management_ngw_id \
                       --profile $profile --region eu-west-1 --output text
else
  aws ec2 create-route --route-table-id $ireland_management_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ireland_management_nat_instance_eni_id \
                       --profile $profile --region eu-west-1 --output text
fi

aws ec2 associate-route-table --route-table-id $ireland_management_private_rtbc_id --subnet-id $ireland_management_application_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtbc_id --subnet-id $ireland_management_database_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtbc_id --subnet-id $ireland_management_directory_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtbc_id --subnet-id $ireland_management_management_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtbc_id --subnet-id $ireland_management_gateway_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_management_private_rtbc_id --subnet-id $ireland_management_endpoint_subnetc_id \
                              --profile $profile --region eu-west-1 --output text

# Create VPC Endpoint Security Group
ireland_management_vpce_sg_id=$(aws ec2 create-security-group --group-name Management-VPCEndpointSecurityGroup \
                                                              --description Management-VPCEndpointSecurityGroup \
                                                              --vpc-id $ireland_management_vpc_id \
                                                              --query 'GroupId' \
                                                              --profile $profile --region eu-west-1 --output text)
echo "ireland_management_vpce_sg_id=$ireland_management_vpce_sg_id"

aws ec2 create-tags --resources $ireland_management_vpce_sg_id \
                    --tags Key=Name,Value=Management-VPCEndpointSecurityGroup \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_management_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ireland_management_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_management_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ireland_management_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create VPC Endpoints for SSM and SSMMessages
ireland_management_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ireland_management_vpc_id \
                                                             --vpc-endpoint-type Interface \
                                                             --service-name com.amazonaws.eu-west-1.ssm \
                                                             --private-dns-enabled \
                                                             --security-group-ids $ireland_management_vpce_sg_id \
                                                             --subnet-ids $ireland_management_endpoint_subneta_id $ireland_management_endpoint_subnetb_id $ireland_management_endpoint_subnetc_id \
                                                             --client-token $(date +%s) \
                                                             --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Management-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                             --query 'VpcEndpoint.VpcEndpointId' \
                                                             --profile $profile --region eu-west-1 --output text)
echo "ireland_management_ssm_vpce_id=$ireland_management_ssm_vpce_id"

ireland_management_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ireland_management_vpc_id \
                                                              --vpc-endpoint-type Interface \
                                                              --service-name com.amazonaws.eu-west-1.ssmmessages \
                                                              --private-dns-enabled \
                                                              --security-group-ids $ireland_management_vpce_sg_id \
                                                              --subnet-ids $ireland_management_endpoint_subneta_id $ireland_management_endpoint_subnetb_id $ireland_management_endpoint_subnetc_id \
                                                              --client-token $(date +%s) \
                                                              --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Management-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                              --query 'VpcEndpoint.VpcEndpointId' \
                                                              --profile $profile --region eu-west-1 --output text)
echo "ireland_management_ssmm_vpce_id=$ireland_management_ssmm_vpce_id"


## Ireland Core VPC ###################################################################################################
echo "core_account_id=$core_account_id"

profile=$core_profile

# Create VPC
ireland_core_vpc_id=$(aws ec2 create-vpc --cidr-block $ireland_core_vpc_cidr \
                                         --query 'Vpc.VpcId' \
                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_core_vpc_id=$ireland_core_vpc_id"

aws ec2 create-tags --resources $ireland_core_vpc_id \
                    --tags Key=Name,Value=Core-VPC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $ireland_core_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region eu-west-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $ireland_core_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region eu-west-1 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Core" \
                          --profile $profile --region eu-west-1 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $ireland_core_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:eu-west-1:$core_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Core" \
                         --deliver-logs-permission-arn "arn:aws:iam::$core_account_id:role/FlowLog" \
                         --profile $profile --region eu-west-1 --output text

# Create Internet Gateway & Attach
ireland_core_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                      --profile $profile --region eu-west-1 --output text)
echo "ireland_core_igw_id=$ireland_core_igw_id"

aws ec2 create-tags --resources $ireland_core_igw_id \
                    --tags Key=Name,Value=Core-InternetGateway \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 attach-internet-gateway --vpc-id $ireland_core_vpc_id \
                                --internet-gateway-id $ireland_core_igw_id \
                                --profile $profile --region eu-west-1 --output text

# Create Private Hosted Zone
ireland_core_private_hostedzone_id=$(aws route53 create-hosted-zone --name $ireland_core_private_domain \
                                                                    --vpc VPCRegion=eu-west-1,VPCId=$ireland_core_vpc_id \
                                                                    --hosted-zone-config Comment="Private Zone for $ireland_core_private_domain",PrivateZone=true \
                                                                    --caller-reference $(date +%s) \
                                                                    --query 'HostedZone.Id' \
                                                                    --profile $profile --region eu-west-1 --output text | cut -f3 -d /)
echo "ireland_core_private_hostedzone_id=$ireland_core_private_hostedzone_id"

# Create DHCP Options Set
ireland_core_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$ireland_core_private_domain]" \
                                                                         "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                   --query 'DhcpOptions.DhcpOptionsId' \
                                                   --profile $profile --region eu-west-1 --output text)
echo "ireland_core_dopt_id=$ireland_core_dopt_id"

aws ec2 create-tags --resources $ireland_core_dopt_id \
                    --tags Key=Name,Value=Core-DHCPOptions \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 associate-dhcp-options --vpc-id $ireland_core_vpc_id \
                               --dhcp-options-id $ireland_core_dopt_id \
                               --profile $profile --region eu-west-1 --output text

# Create Public Subnet A
ireland_core_public_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                       --cidr-block $ireland_core_subnet_publica_cidr \
                                                       --availability-zone eu-west-1a \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_core_public_subneta_id=$ireland_core_public_subneta_id"

aws ec2 create-tags --resources $ireland_core_public_subneta_id \
                    --tags Key=Name,Value=Core-PublicSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Public Subnet B
ireland_core_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                       --cidr-block $ireland_core_subnet_publicb_cidr \
                                                       --availability-zone eu-west-1b \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_core_public_subnetb_id=$ireland_core_public_subnetb_id"

aws ec2 create-tags --resources $ireland_core_public_subnetb_id \
                    --tags Key=Name,Value=Core-PublicSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Public Subnet C
ireland_core_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                       --cidr-block $ireland_core_subnet_publicc_cidr \
                                                       --availability-zone eu-west-1c \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_core_public_subnetc_id=$ireland_core_public_subnetc_id"

aws ec2 create-tags --resources $ireland_core_public_subnetc_id \
                    --tags Key=Name,Value=Core-PublicSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Web Subnet A
ireland_core_web_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                    --cidr-block $ireland_core_subnet_weba_cidr \
                                                    --availability-zone eu-west-1a \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region eu-west-1 --output text)
echo "ireland_core_web_subneta_id=$ireland_core_web_subneta_id"

aws ec2 create-tags --resources $ireland_core_web_subneta_id \
                    --tags Key=Name,Value=Core-WebSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Web Subnet B
ireland_core_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                    --cidr-block $ireland_core_subnet_webb_cidr \
                                                    --availability-zone eu-west-1b \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region eu-west-1 --output text)
echo "ireland_core_web_subnetb_id=$ireland_core_web_subnetb_id"

aws ec2 create-tags --resources $ireland_core_web_subnetb_id \
                    --tags Key=Name,Value=Core-WebSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Web Subnet C
ireland_core_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                    --cidr-block $ireland_core_subnet_webc_cidr \
                                                    --availability-zone eu-west-1c \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region eu-west-1 --output text)
echo "ireland_core_web_subnetc_id=$ireland_core_web_subnetc_id"

aws ec2 create-tags --resources $ireland_core_web_subnetc_id \
                    --tags Key=Name,Value=Core-WebSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Application Subnet A
ireland_core_application_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                            --cidr-block $ireland_core_subnet_applicationa_cidr \
                                                            --availability-zone eu-west-1a \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region eu-west-1 --output text)
echo "ireland_core_application_subneta_id=$ireland_core_application_subneta_id"

aws ec2 create-tags --resources $ireland_core_application_subneta_id \
                    --tags Key=Name,Value=Core-ApplicationSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Application Subnet B
ireland_core_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                            --cidr-block $ireland_core_subnet_applicationb_cidr \
                                                            --availability-zone eu-west-1b \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region eu-west-1 --output text)
echo "ireland_core_application_subnetb_id=$ireland_core_application_subnetb_id"

aws ec2 create-tags --resources $ireland_core_application_subnetb_id \
                    --tags Key=Name,Value=Core-ApplicationSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Application Subnet C
ireland_core_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                            --cidr-block $ireland_core_subnet_applicationc_cidr \
                                                            --availability-zone eu-west-1c \
                                                            --query 'Subnet.SubnetId' \
                                                            --profile $profile --region eu-west-1 --output text)
echo "ireland_core_application_subnetc_id=$ireland_core_application_subnetc_id"

aws ec2 create-tags --resources $ireland_core_application_subnetc_id \
                    --tags Key=Name,Value=Core-ApplicationSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Database Subnet A
ireland_core_database_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                         --cidr-block $ireland_core_subnet_databasea_cidr \
                                                         --availability-zone eu-west-1a \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_core_database_subneta_id=$ireland_core_database_subneta_id"

aws ec2 create-tags --resources $ireland_core_database_subneta_id \
                    --tags Key=Name,Value=Core-DatabaseSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Database Subnet B
ireland_core_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                         --cidr-block $ireland_core_subnet_databaseb_cidr \
                                                         --availability-zone eu-west-1b \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_core_database_subnetb_id=$ireland_core_database_subnetb_id"

aws ec2 create-tags --resources $ireland_core_database_subnetb_id \
                    --tags Key=Name,Value=Core-DatabaseSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Database Subnet C
ireland_core_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                         --cidr-block $ireland_core_subnet_databasec_cidr \
                                                         --availability-zone eu-west-1c \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_core_database_subnetc_id=$ireland_core_database_subnetc_id"

aws ec2 create-tags --resources $ireland_core_database_subnetc_id \
                    --tags Key=Name,Value=Core-DatabaseSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Management Subnet A
ireland_core_management_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                           --cidr-block $ireland_core_subnet_managementa_cidr \
                                                           --availability-zone eu-west-1a \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region eu-west-1 --output text)
echo "ireland_core_management_subneta_id=$ireland_core_management_subneta_id"

aws ec2 create-tags --resources $ireland_core_management_subneta_id \
                    --tags Key=Name,Value=Core-ManagementSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Management Subnet B
ireland_core_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                           --cidr-block $ireland_core_subnet_managementb_cidr \
                                                           --availability-zone eu-west-1b \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region eu-west-1 --output text)
echo "ireland_core_management_subnetb_id=$ireland_core_management_subnetb_id"

aws ec2 create-tags --resources $ireland_core_management_subnetb_id \
                    --tags Key=Name,Value=Core-ManagementSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Management Subnet C
ireland_core_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                           --cidr-block $ireland_core_subnet_managementc_cidr \
                                                           --availability-zone eu-west-1c \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region eu-west-1 --output text)
echo "ireland_core_management_subnetc_id=$ireland_core_management_subnetc_id"

aws ec2 create-tags --resources $ireland_core_management_subnetc_id \
                    --tags Key=Name,Value=Core-ManagementSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Gateway Subnet A
ireland_core_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                        --cidr-block $ireland_core_subnet_gatewaya_cidr \
                                                        --availability-zone eu-west-1a \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_core_gateway_subneta_id=$ireland_core_gateway_subneta_id"

aws ec2 create-tags --resources $ireland_core_gateway_subneta_id \
                    --tags Key=Name,Value=Core-GatewaySubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Gateway Subnet B
ireland_core_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                        --cidr-block $ireland_core_subnet_gatewayb_cidr \
                                                        --availability-zone eu-west-1b \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_core_gateway_subnetb_id=$ireland_core_gateway_subnetb_id"

aws ec2 create-tags --resources $ireland_core_gateway_subnetb_id \
                    --tags Key=Name,Value=Core-GatewaySubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Gateway Subnet C
ireland_core_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                        --cidr-block $ireland_core_subnet_gatewayc_cidr \
                                                        --availability-zone eu-west-1c \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_core_gateway_subnetc_id=$ireland_core_gateway_subnetc_id"

aws ec2 create-tags --resources $ireland_core_gateway_subnetc_id \
                    --tags Key=Name,Value=Core-GatewaySubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Endpoint Subnet A
ireland_core_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                         --cidr-block $ireland_core_subnet_endpointa_cidr \
                                                         --availability-zone eu-west-1a \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_core_endpoint_subneta_id=$ireland_core_endpoint_subneta_id"

aws ec2 create-tags --resources $ireland_core_endpoint_subneta_id \
                    --tags Key=Name,Value=Core-EndpointSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Endpoint Subnet B
ireland_core_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                         --cidr-block $ireland_core_subnet_endpointb_cidr \
                                                         --availability-zone eu-west-1b \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_core_endpoint_subnetb_id=$ireland_core_endpoint_subnetb_id"

aws ec2 create-tags --resources $ireland_core_endpoint_subnetb_id \
                    --tags Key=Name,Value=Core-EndpointSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Endpoint Subnet C
ireland_core_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_core_vpc_id \
                                                         --cidr-block $ireland_core_subnet_endpointc_cidr \
                                                         --availability-zone eu-west-1c \
                                                         --query 'Subnet.SubnetId' \
                                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_core_endpoint_subnetc_id=$ireland_core_endpoint_subnetc_id"

aws ec2 create-tags --resources $ireland_core_endpoint_subnetc_id \
                    --tags Key=Name,Value=Core-EndpointSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
ireland_core_public_rtb_id=$(aws ec2 create-route-table --vpc-id $ireland_core_vpc_id \
                                                        --query 'RouteTable.RouteTableId' \
                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_core_public_rtb_id=$ireland_core_public_rtb_id"

aws ec2 create-tags --resources $ireland_core_public_rtb_id \
                    --tags Key=Name,Value=Core-PublicRouteTable \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $ireland_core_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $ireland_core_igw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 associate-route-table --route-table-id $ireland_core_public_rtb_id --subnet-id $ireland_core_public_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_public_rtb_id --subnet-id $ireland_core_public_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_public_rtb_id --subnet-id $ireland_core_public_subnetc_id \
                              --profile $profile --region eu-west-1 --output text

aws ec2 associate-route-table --route-table-id $ireland_core_public_rtb_id --subnet-id $ireland_core_web_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_public_rtb_id --subnet-id $ireland_core_web_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_public_rtb_id --subnet-id $ireland_core_web_subnetc_id \
                              --profile $profile --region eu-west-1 --output text

# Create NAT Gateways
if [ $use_ngw = 1 ]; then
  ireland_core_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                   --query 'AllocationId' \
                                                   --profile $profile --region eu-west-1 --output text)
  echo "ireland_core_ngw_eipa=$ireland_core_ngw_eipa"

  aws ec2 create-tags --resources $ireland_core_ngw_eipa \
                      --tags Key=Name,Value=Core-NAT-EIPA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region eu-west-1 --output text

  ireland_core_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $ireland_core_ngw_eipa \
                                                    --subnet-id $ireland_core_public_subneta_id \
                                                    --client-token $(date +%s) \
                                                    --query 'NatGateway.NatGatewayId' \
                                                    --profile $profile --region eu-west-1 --output text)
  echo "ireland_core_ngwa_id=$ireland_core_ngwa_id"

  aws ec2 create-tags --resources $ireland_core_ngwa_id \
                      --tags Key=Name,Value=Core-NAT-GatewayA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region eu-west-1 --output text

  if [ $ha_ngw = 1 ]; then
    ireland_core_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                     --query 'AllocationId' \
                                                     --profile $profile --region eu-west-1 --output text)
    echo "ireland_core_ngw_eipb=$ireland_core_ngw_eipb"

    aws ec2 create-tags --resources $ireland_core_ngw_eipb \
                        --tags Key=Name,Value=Core-NAT-EIPB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text

    ireland_core_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $ireland_core_ngw_eipb \
                                                      --subnet-id $ireland_core_public_subnetb_id \
                                                      --client-token $(date +%s) \
                                                      --query 'NatGateway.NatGatewayId' \
                                                      --profile $profile --region eu-west-1 --output text)
    echo "ireland_core_ngwb_id=$ireland_core_ngwb_id"

    aws ec2 create-tags --resources $ireland_core_ngwb_id \
                        --tags Key=Name,Value=Core-NAT-GatewayB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text

    ireland_core_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                     --query 'AllocationId' \
                                                     --profile $profile --region eu-west-1 --output text)
    echo "ireland_core_ngw_eipc=$ireland_core_ngw_eipc"

    aws ec2 create-tags --resources $ireland_core_ngw_eipc \
                        --tags Key=Name,Value=Core-NAT-EIPC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text

    ireland_core_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $ireland_core_ngw_eipc \
                                                      --subnet-id $ireland_core_public_subnetc_id \
                                                      --client-token $(date +%s) \
                                                      --query 'NatGateway.NatGatewayId' \
                                                      --profile $profile --region eu-west-1 --output text)
    echo "ireland_core_ngwc_id=$ireland_core_ngwc_id"

    aws ec2 create-tags --resources $ireland_core_ngwc_id \
                        --tags Key=Name,Value=Core-NAT-GatewayC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Core \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text
  fi
else
  # Create NAT Security Group
  ireland_core_nat_sg_id=$(aws ec2 create-security-group --group-name Core-NAT-InstanceSecurityGroup \
                                                         --description Core-NAT-InstanceSecurityGroup \
                                                         --vpc-id $ireland_core_vpc_id \
                                                         --query 'GroupId' \
                                                         --profile $profile --region eu-west-1 --output text)
  echo "ireland_core_nat_sg_id=$ireland_core_nat_sg_id"

  aws ec2 create-tags --resources $ireland_core_nat_sg_id \
                      --tags Key=Name,Value=Core-NAT-InstanceSecurityGroup \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Utility,Value=NAT \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region eu-west-1 --output text

  aws ec2 authorize-security-group-ingress --group-id $ireland_core_nat_sg_id \
                                           --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$ireland_core_vpc_cidr,Description=\"VPC (All)\"}]" \
                                           --profile $profile --region eu-west-1 --output text

  # Create NAT Instance
  ireland_core_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                       --instance-type t3a.nano \
                                                       --iam-instance-profile Name=ManagedInstance \
                                                       --key-name administrator \
                                                       --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Core-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ireland_core_nat_sg_id],SubnetId=$ireland_core_public_subneta_id" \
                                                       --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Core-NAT-Instance},{Key=Hostname,Value=cmlew1cnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                       --query 'Instances[0].InstanceId' \
                                                       --profile $profile --region eu-west-1 --output text)
  echo "ireland_core_nat_instance_id=$ireland_core_nat_instance_id"

  aws ec2 modify-instance-attribute --instance-id $ireland_core_nat_instance_id \
                                    --no-source-dest-check \
                                    --profile $profile --region eu-west-1 --output text

  ireland_core_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $ireland_core_nat_instance_id \
                                                                --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                --profile $profile --region eu-west-1 --output text)
  echo "ireland_core_nat_instance_eni_id=$ireland_core_nat_instance_eni_id"

  ireland_core_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $ireland_core_nat_instance_id \
                                                                    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                    --profile $profile --region eu-west-1 --output text)
  echo "ireland_core_nat_instance_private_ip=$ireland_core_nat_instance_private_ip"
fi

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
ireland_core_private_rtba_id=$(aws ec2 create-route-table --vpc-id $ireland_core_vpc_id \
                                                          --query 'RouteTable.RouteTableId' \
                                                          --profile $profile --region eu-west-1 --output text)
echo "ireland_core_private_rtba_id=$ireland_core_private_rtba_id"

aws ec2 create-tags --resources $ireland_core_private_rtba_id \
                    --tags Key=Name,Value=Core-PrivateRouteTableA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

if [ $use_ngw = 1 ]; then
  aws ec2 create-route --route-table-id $ireland_core_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ireland_core_ngwa_id \
                       --profile $profile --region eu-west-1 --output text
else
  aws ec2 create-route --route-table-id $ireland_core_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ireland_core_nat_instance_eni_id \
                       --profile $profile --region eu-west-1 --output text
fi

aws ec2 associate-route-table --route-table-id $ireland_core_private_rtba_id --subnet-id $ireland_core_application_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_private_rtba_id --subnet-id $ireland_core_database_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_private_rtba_id --subnet-id $ireland_core_management_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_private_rtba_id --subnet-id $ireland_core_gateway_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_private_rtba_id --subnet-id $ireland_core_endpoint_subneta_id \
                              --profile $profile --region eu-west-1 --output text

ireland_core_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $ireland_core_vpc_id \
                                                          --query 'RouteTable.RouteTableId' \
                                                          --profile $profile --region eu-west-1 --output text)
echo "ireland_core_private_rtbb_id=$ireland_core_private_rtbb_id"

aws ec2 create-tags --resources $ireland_core_private_rtbb_id \
                    --tags Key=Name,Value=Core-PrivateRouteTableB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then ireland_core_ngw_id=$ireland_core_ngwb_id; else ireland_core_ngw_id=$ireland_core_ngwa_id; fi
  aws ec2 create-route --route-table-id $ireland_core_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ireland_core_ngw_id \
                       --profile $profile --region eu-west-1 --output text
else
  aws ec2 create-route --route-table-id $ireland_core_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ireland_core_nat_instance_eni_id \
                       --profile $profile --region eu-west-1 --output text
fi

aws ec2 associate-route-table --route-table-id $ireland_core_private_rtbb_id --subnet-id $ireland_core_application_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_private_rtbb_id --subnet-id $ireland_core_database_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_private_rtbb_id --subnet-id $ireland_core_management_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_private_rtbb_id --subnet-id $ireland_core_gateway_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_private_rtbb_id --subnet-id $ireland_core_endpoint_subnetb_id \
                              --profile $profile --region eu-west-1 --output text

ireland_core_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $ireland_core_vpc_id \
                                                          --query 'RouteTable.RouteTableId' \
                                                          --profile $profile --region eu-west-1 --output text)
echo "ireland_core_private_rtbc_id=$ireland_core_private_rtbc_id"

aws ec2 create-tags --resources $ireland_core_private_rtbc_id \
                    --tags Key=Name,Value=Core-PrivateRouteTableC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then ireland_core_ngw_id=$ireland_core_ngwc_id; else ireland_core_ngw_id=$ireland_core_ngwa_id; fi
  aws ec2 create-route --route-table-id $ireland_core_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ireland_core_ngw_id \
                       --profile $profile --region eu-west-1 --output text
else
  aws ec2 create-route --route-table-id $ireland_core_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ireland_core_nat_instance_eni_id \
                       --profile $profile --region eu-west-1 --output text
fi

aws ec2 associate-route-table --route-table-id $ireland_core_private_rtbc_id --subnet-id $ireland_core_application_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_private_rtbc_id --subnet-id $ireland_core_database_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_private_rtbc_id --subnet-id $ireland_core_management_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_private_rtbc_id --subnet-id $ireland_core_gateway_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_core_private_rtbc_id --subnet-id $ireland_core_endpoint_subnetc_id \
                              --profile $profile --region eu-west-1 --output text

# Create VPC Endpoint Security Group
ireland_core_vpce_sg_id=$(aws ec2 create-security-group --group-name Core-VPCEndpointSecurityGroup \
                                                        --description Core-VPCEndpointSecurityGroup \
                                                        --vpc-id $ireland_core_vpc_id \
                                                        --query 'GroupId' \
                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_core_vpce_sg_id=$ireland_core_vpce_sg_id"

aws ec2 create-tags --resources $ireland_core_vpce_sg_id \
                    --tags Key=Name,Value=Core-VPCEndpointSecurityGroup \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_core_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ireland_core_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_core_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ireland_core_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create VPC Endpoints for SSM and SSMMessages
ireland_core_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ireland_core_vpc_id \
                                                       --vpc-endpoint-type Interface \
                                                       --service-name com.amazonaws.eu-west-1.ssm \
                                                       --private-dns-enabled \
                                                       --security-group-ids $ireland_core_vpce_sg_id \
                                                       --subnet-ids $ireland_core_endpoint_subneta_id $ireland_core_endpoint_subnetb_id $ireland_core_endpoint_subnetc_id \
                                                       --client-token $(date +%s) \
                                                       --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Core-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                       --query 'VpcEndpoint.VpcEndpointId' \
                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_core_ssm_vpce_id=$ireland_core_ssm_vpce_id"

ireland_core_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ireland_core_vpc_id \
                                                        --vpc-endpoint-type Interface \
                                                        --service-name com.amazonaws.eu-west-1.ssmmessages \
                                                        --private-dns-enabled \
                                                        --security-group-ids $ireland_core_vpce_sg_id \
                                                        --subnet-ids $ireland_core_endpoint_subneta_id $ireland_core_endpoint_subnetb_id $ireland_core_endpoint_subnetc_id \
                                                        --client-token $(date +%s) \
                                                        --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Core-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                        --query 'VpcEndpoint.VpcEndpointId' \
                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_core_ssmm_vpce_id=$ireland_core_ssmm_vpce_id"


## Ireland Log VPC ####################################################################################################
echo "log_account_id=$log_account_id"

profile=$log_profile

# Create VPC
ireland_log_vpc_id=$(aws ec2 create-vpc --cidr-block $ireland_log_vpc_cidr \
                                        --query 'Vpc.VpcId' \
                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_log_vpc_id=$ireland_log_vpc_id"

aws ec2 create-tags --resources $ireland_log_vpc_id \
                    --tags Key=Name,Value=Log-VPC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $ireland_log_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region eu-west-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $ireland_log_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region eu-west-1 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Log" \
                          --profile $profile --region eu-west-1 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $ireland_log_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:eu-west-1:$log_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Log" \
                         --deliver-logs-permission-arn "arn:aws:iam::$log_account_id:role/FlowLog" \
                         --profile $profile --region eu-west-1 --output text

# Create Internet Gateway & Attach
ireland_log_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                     --profile $profile --region eu-west-1 --output text)
echo "ireland_log_igw_id=$ireland_log_igw_id"

aws ec2 create-tags --resources $ireland_log_igw_id \
                    --tags Key=Name,Value=Log-InternetGateway \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 attach-internet-gateway --vpc-id $ireland_log_vpc_id \
                                --internet-gateway-id $ireland_log_igw_id \
                                --profile $profile --region eu-west-1 --output text

# Create Private Hosted Zone
ireland_log_private_hostedzone_id=$(aws route53 create-hosted-zone --name $ireland_log_private_domain \
                                                                   --vpc VPCRegion=eu-west-1,VPCId=$ireland_log_vpc_id \
                                                                   --hosted-zone-config Comment="Private Zone for $ireland_log_private_domain",PrivateZone=true \
                                                                   --caller-reference $(date +%s) \
                                                                   --query 'HostedZone.Id' \
                                                                   --profile $profile --region eu-west-1 --output text | cut -f3 -d /)
echo "ireland_log_private_hostedzone_id=$ireland_log_private_hostedzone_id"

# Create DHCP Options Set
ireland_log_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$ireland_log_private_domain]" \
                                                                        "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                  --query 'DhcpOptions.DhcpOptionsId' \
                                                  --profile $profile --region eu-west-1 --output text)
echo "ireland_log_dopt_id=$ireland_log_dopt_id"

aws ec2 create-tags --resources $ireland_log_dopt_id \
                    --tags Key=Name,Value=Log-DHCPOptions \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 associate-dhcp-options --vpc-id $ireland_log_vpc_id \
                               --dhcp-options-id $ireland_log_dopt_id \
                               --profile $profile --region eu-west-1 --output text

# Create Public Subnet A
ireland_log_public_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                      --cidr-block $ireland_log_subnet_publica_cidr \
                                                      --availability-zone eu-west-1a \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region eu-west-1 --output text)
echo "ireland_log_public_subneta_id=$ireland_log_public_subneta_id"

aws ec2 create-tags --resources $ireland_log_public_subneta_id \
                    --tags Key=Name,Value=Log-PublicSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Public Subnet B
ireland_log_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                      --cidr-block $ireland_log_subnet_publicb_cidr \
                                                      --availability-zone eu-west-1b \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region eu-west-1 --output text)
echo "ireland_log_public_subnetb_id=$ireland_log_public_subnetb_id"

aws ec2 create-tags --resources $ireland_log_public_subnetb_id \
                    --tags Key=Name,Value=Log-PublicSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Public Subnet C
ireland_log_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                      --cidr-block $ireland_log_subnet_publicc_cidr \
                                                      --availability-zone eu-west-1c \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region eu-west-1 --output text)
echo "ireland_log_public_subnetc_id=$ireland_log_public_subnetc_id"

aws ec2 create-tags --resources $ireland_log_public_subnetc_id \
                    --tags Key=Name,Value=Log-PublicSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Web Subnet A
ireland_log_web_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                   --cidr-block $ireland_log_subnet_weba_cidr \
                                                   --availability-zone eu-west-1a \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region eu-west-1 --output text)
echo "ireland_log_web_subneta_id=$ireland_log_web_subneta_id"

aws ec2 create-tags --resources $ireland_log_web_subneta_id \
                    --tags Key=Name,Value=Log-WebSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Web Subnet B
ireland_log_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                   --cidr-block $ireland_log_subnet_webb_cidr \
                                                   --availability-zone eu-west-1b \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region eu-west-1 --output text)
echo "ireland_log_web_subnetb_id=$ireland_log_web_subnetb_id"

aws ec2 create-tags --resources $ireland_log_web_subnetb_id \
                    --tags Key=Name,Value=Log-WebSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Web Subnet C
ireland_log_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                   --cidr-block $ireland_log_subnet_webc_cidr \
                                                   --availability-zone eu-west-1c \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region eu-west-1 --output text)
echo "ireland_log_web_subnetc_id=$ireland_log_web_subnetc_id"

aws ec2 create-tags --resources $ireland_log_web_subnetc_id \
                    --tags Key=Name,Value=Log-WebSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Application Subnet A
ireland_log_application_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                           --cidr-block $ireland_log_subnet_applicationa_cidr \
                                                           --availability-zone eu-west-1a \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region eu-west-1 --output text)
echo "ireland_log_application_subneta_id=$ireland_log_application_subneta_id"

aws ec2 create-tags --resources $ireland_log_application_subneta_id \
                    --tags Key=Name,Value=Log-ApplicationSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Application Subnet B
ireland_log_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                           --cidr-block $ireland_log_subnet_applicationb_cidr \
                                                           --availability-zone eu-west-1b \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region eu-west-1 --output text)
echo "ireland_log_application_subnetb_id=$ireland_log_application_subnetb_id"

aws ec2 create-tags --resources $ireland_log_application_subnetb_id \
                    --tags Key=Name,Value=Log-ApplicationSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Application Subnet C
ireland_log_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                           --cidr-block $ireland_log_subnet_applicationc_cidr \
                                                           --availability-zone eu-west-1c \
                                                           --query 'Subnet.SubnetId' \
                                                           --profile $profile --region eu-west-1 --output text)
echo "ireland_log_application_subnetc_id=$ireland_log_application_subnetc_id"

aws ec2 create-tags --resources $ireland_log_application_subnetc_id \
                    --tags Key=Name,Value=Log-ApplicationSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Database Subnet A
ireland_log_database_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                        --cidr-block $ireland_log_subnet_databasea_cidr \
                                                        --availability-zone eu-west-1a \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_log_database_subneta_id=$ireland_log_database_subneta_id"

aws ec2 create-tags --resources $ireland_log_database_subneta_id \
                    --tags Key=Name,Value=Log-DatabaseSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Database Subnet B
ireland_log_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                        --cidr-block $ireland_log_subnet_databaseb_cidr \
                                                        --availability-zone eu-west-1b \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_log_database_subnetb_id=$ireland_log_database_subnetb_id"

aws ec2 create-tags --resources $ireland_log_database_subnetb_id \
                    --tags Key=Name,Value=Log-DatabaseSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Database Subnet C
ireland_log_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                        --cidr-block $ireland_log_subnet_databasec_cidr \
                                                        --availability-zone eu-west-1c \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_log_database_subnetc_id=$ireland_log_database_subnetc_id"

aws ec2 create-tags --resources $ireland_log_database_subnetc_id \
                    --tags Key=Name,Value=Log-DatabaseSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Management Subnet A
ireland_log_management_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                          --cidr-block $ireland_log_subnet_managementa_cidr \
                                                          --availability-zone eu-west-1a \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region eu-west-1 --output text)
echo "ireland_log_management_subneta_id=$ireland_log_management_subneta_id"

aws ec2 create-tags --resources $ireland_log_management_subneta_id \
                    --tags Key=Name,Value=Log-ManagementSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Management Subnet B
ireland_log_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                          --cidr-block $ireland_log_subnet_managementb_cidr \
                                                          --availability-zone eu-west-1b \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region eu-west-1 --output text)
echo "ireland_log_management_subnetb_id=$ireland_log_management_subnetb_id"

aws ec2 create-tags --resources $ireland_log_management_subnetb_id \
                    --tags Key=Name,Value=Log-ManagementSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Management Subnet C
ireland_log_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                          --cidr-block $ireland_log_subnet_managementc_cidr \
                                                          --availability-zone eu-west-1c \
                                                          --query 'Subnet.SubnetId' \
                                                          --profile $profile --region eu-west-1 --output text)
echo "ireland_log_management_subnetc_id=$ireland_log_management_subnetc_id"

aws ec2 create-tags --resources $ireland_log_management_subnetc_id \
                    --tags Key=Name,Value=Log-ManagementSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Gateway Subnet A
ireland_log_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                       --cidr-block $ireland_log_subnet_gatewaya_cidr \
                                                       --availability-zone eu-west-1a \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_log_gateway_subneta_id=$ireland_log_gateway_subneta_id"

aws ec2 create-tags --resources $ireland_log_gateway_subneta_id \
                    --tags Key=Name,Value=Log-GatewaySubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Gateway Subnet B
ireland_log_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                       --cidr-block $ireland_log_subnet_gatewayb_cidr \
                                                       --availability-zone eu-west-1b \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_log_gateway_subnetb_id=$ireland_log_gateway_subnetb_id"

aws ec2 create-tags --resources $ireland_log_gateway_subnetb_id \
                    --tags Key=Name,Value=Log-GatewaySubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Gateway Subnet C
ireland_log_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                       --cidr-block $ireland_log_subnet_gatewayc_cidr \
                                                       --availability-zone eu-west-1c \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_log_gateway_subnetc_id=$ireland_log_gateway_subnetc_id"

aws ec2 create-tags --resources $ireland_log_gateway_subnetc_id \
                    --tags Key=Name,Value=Log-GatewaySubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Endpoint Subnet A
ireland_log_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                        --cidr-block $ireland_log_subnet_endpointa_cidr \
                                                        --availability-zone eu-west-1a \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_log_endpoint_subneta_id=$ireland_log_endpoint_subneta_id"

aws ec2 create-tags --resources $ireland_log_endpoint_subneta_id \
                    --tags Key=Name,Value=Log-EndpointSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Endpoint Subnet B
ireland_log_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                        --cidr-block $ireland_log_subnet_endpointb_cidr \
                                                        --availability-zone eu-west-1b \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_log_endpoint_subnetb_id=$ireland_log_endpoint_subnetb_id"

aws ec2 create-tags --resources $ireland_log_endpoint_subnetb_id \
                    --tags Key=Name,Value=Log-EndpointSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Endpoint Subnet C
ireland_log_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $ireland_log_vpc_id \
                                                        --cidr-block $ireland_log_subnet_endpointc_cidr \
                                                        --availability-zone eu-west-1c \
                                                        --query 'Subnet.SubnetId' \
                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_log_endpoint_subnetc_id=$ireland_log_endpoint_subnetc_id"

aws ec2 create-tags --resources $ireland_log_endpoint_subnetc_id \
                    --tags Key=Name,Value=Log-EndpointSubnetC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
ireland_log_public_rtb_id=$(aws ec2 create-route-table --vpc-id $ireland_log_vpc_id \
                                                       --query 'RouteTable.RouteTableId' \
                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_log_public_rtb_id=$ireland_log_public_rtb_id"

aws ec2 create-tags --resources $ireland_log_public_rtb_id \
                    --tags Key=Name,Value=Log-PublicRouteTable \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $ireland_log_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $ireland_log_igw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 associate-route-table --route-table-id $ireland_log_public_rtb_id --subnet-id $ireland_log_public_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_public_rtb_id --subnet-id $ireland_log_public_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_public_rtb_id --subnet-id $ireland_log_public_subnetc_id \
                              --profile $profile --region eu-west-1 --output text

aws ec2 associate-route-table --route-table-id $ireland_log_public_rtb_id --subnet-id $ireland_log_web_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_public_rtb_id --subnet-id $ireland_log_web_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_public_rtb_id --subnet-id $ireland_log_web_subnetc_id \
                              --profile $profile --region eu-west-1 --output text

# Create NAT Gateways
if [ $use_ngw = 1 ]; then
  ireland_log_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                  --query 'AllocationId' \
                                                  --profile $profile --region eu-west-1 --output text)
  echo "ireland_log_ngw_eipa=$ireland_log_ngw_eipa"

  aws ec2 create-tags --resources $ireland_log_ngw_eipa \
                      --tags Key=Name,Value=Log-NAT-EIPA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region eu-west-1 --output text

  ireland_log_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $ireland_log_ngw_eipa \
                                                   --subnet-id $ireland_log_public_subneta_id \
                                                   --client-token $(date +%s) \
                                                   --query 'NatGateway.NatGatewayId' \
                                                   --profile $profile --region eu-west-1 --output text)
  echo "ireland_log_ngwa_id=$ireland_log_ngwa_id"

  aws ec2 create-tags --resources $ireland_log_ngwa_id \
                      --tags Key=Name,Value=Log-NAT-GatewayA \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region eu-west-1 --output text

  if [ $ha_ngw = 1 ]; then
    ireland_log_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                    --query 'AllocationId' \
                                                    --profile $profile --region eu-west-1 --output text)
    echo "ireland_log_ngw_eipb=$ireland_log_ngw_eipb"

    aws ec2 create-tags --resources $ireland_log_ngw_eipb \
                        --tags Key=Name,Value=Log-NAT-EIPB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Log \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text

    ireland_log_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $ireland_log_ngw_eipb \
                                                     --subnet-id $ireland_log_public_subnetb_id \
                                                     --client-token $(date +%s) \
                                                     --query 'NatGateway.NatGatewayId' \
                                                     --profile $profile --region eu-west-1 --output text)
    echo "ireland_log_ngwb_id=$ireland_log_ngwb_id"

    aws ec2 create-tags --resources $ireland_log_ngwb_id \
                        --tags Key=Name,Value=Log-NAT-GatewayB \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Log \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text

    ireland_log_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                    --query 'AllocationId' \
                                                    --profile $profile --region eu-west-1 --output text)
    echo "ireland_log_ngw_eipc=$ireland_log_ngw_eipc"

    aws ec2 create-tags --resources $ireland_log_ngw_eipc \
                        --tags Key=Name,Value=Log-NAT-EIPC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Log \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text

    ireland_log_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $ireland_log_ngw_eipc \
                                                     --subnet-id $ireland_log_public_subnetc_id \
                                                     --client-token $(date +%s) \
                                                     --query 'NatGateway.NatGatewayId' \
                                                     --profile $profile --region eu-west-1 --output text)
    echo "ireland_log_ngwc_id=$ireland_log_ngwc_id"

    aws ec2 create-tags --resources $ireland_log_ngwc_id \
                        --tags Key=Name,Value=Log-NAT-GatewayC \
                               Key=Company,Value=CaMeLz \
                               Key=Environment,Value=Log \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text
  fi
else
  # Create NAT Security Group
  ireland_log_nat_sg_id=$(aws ec2 create-security-group --group-name Log-NAT-InstanceSecurityGroup \
                                                        --description Log-NAT-InstanceSecurityGroup \
                                                        --vpc-id $ireland_log_vpc_id \
                                                        --query 'GroupId' \
                                                        --profile $profile --region eu-west-1 --output text)
  echo "ireland_log_nat_sg_id=$ireland_log_nat_sg_id"

  aws ec2 create-tags --resources $ireland_log_nat_sg_id \
                      --tags Key=Name,Value=Log-NAT-InstanceSecurityGroup \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Utility,Value=NAT \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region eu-west-1 --output text

  aws ec2 authorize-security-group-ingress --group-id $ireland_log_nat_sg_id \
                                           --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$ireland_log_vpc_cidr,Description=\"VPC (All)\"}]" \
                                           --profile $profile --region eu-west-1 --output text

  # Create NAT Instance
  ireland_log_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                      --instance-type t3a.nano \
                                                      --iam-instance-profile Name=ManagedInstance \
                                                      --key-name administrator \
                                                      --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Log-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$ireland_log_nat_sg_id],SubnetId=$ireland_log_public_subneta_id" \
                                                      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Log-NAT-Instance},{Key=Hostname,Value=cmlew1lnat01a},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                      --query 'Instances[0].InstanceId' \
                                                      --profile $profile --region eu-west-1 --output text)
  echo "ireland_log_nat_instance_id=$ireland_log_nat_instance_id"

  aws ec2 modify-instance-attribute --instance-id $ireland_log_nat_instance_id \
                                    --no-source-dest-check \
                                    --profile $profile --region eu-west-1 --output text

  ireland_log_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $ireland_log_nat_instance_id \
                                                               --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                               --profile $profile --region eu-west-1 --output text)
  echo "ireland_log_nat_instance_eni_id=$ireland_log_nat_instance_eni_id"

  ireland_log_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $ireland_log_nat_instance_id \
                                                                   --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                   --profile $profile --region eu-west-1 --output text)
  echo "ireland_log_nat_instance_private_ip=$ireland_log_nat_instance_private_ip"
fi

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
ireland_log_private_rtba_id=$(aws ec2 create-route-table --vpc-id $ireland_log_vpc_id \
                                                         --query 'RouteTable.RouteTableId' \
                                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_log_private_rtba_id=$ireland_log_private_rtba_id"

aws ec2 create-tags --resources $ireland_log_private_rtba_id \
                    --tags Key=Name,Value=Log-PrivateRouteTableA \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

if [ $use_ngw = 1 ]; then
  aws ec2 create-route --route-table-id $ireland_log_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ireland_log_ngwa_id \
                       --profile $profile --region eu-west-1 --output text
else
  aws ec2 create-route --route-table-id $ireland_log_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ireland_log_nat_instance_eni_id \
                       --profile $profile --region eu-west-1 --output text
fi

aws ec2 associate-route-table --route-table-id $ireland_log_private_rtba_id --subnet-id $ireland_log_application_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_private_rtba_id --subnet-id $ireland_log_database_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_private_rtba_id --subnet-id $ireland_log_management_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_private_rtba_id --subnet-id $ireland_log_gateway_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_private_rtba_id --subnet-id $ireland_log_endpoint_subneta_id \
                              --profile $profile --region eu-west-1 --output text

ireland_log_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $ireland_log_vpc_id \
                                                         --query 'RouteTable.RouteTableId' \
                                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_log_private_rtbb_id=$ireland_log_private_rtbb_id"

aws ec2 create-tags --resources $ireland_log_private_rtbb_id \
                    --tags Key=Name,Value=Log-PrivateRouteTableB \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then ireland_log_ngw_id=$ireland_log_ngwb_id; else ireland_log_ngw_id=$ireland_log_ngwa_id; fi
  aws ec2 create-route --route-table-id $ireland_log_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ireland_log_ngw_id \
                       --profile $profile --region eu-west-1 --output text
else
  aws ec2 create-route --route-table-id $ireland_log_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ireland_log_nat_instance_eni_id \
                       --profile $profile --region eu-west-1 --output text
fi

aws ec2 associate-route-table --route-table-id $ireland_log_private_rtbb_id --subnet-id $ireland_log_application_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_private_rtbb_id --subnet-id $ireland_log_database_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_private_rtbb_id --subnet-id $ireland_log_management_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_private_rtbb_id --subnet-id $ireland_log_gateway_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_private_rtbb_id --subnet-id $ireland_log_endpoint_subnetb_id \
                              --profile $profile --region eu-west-1 --output text

ireland_log_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $ireland_log_vpc_id \
                                                         --query 'RouteTable.RouteTableId' \
                                                         --profile $profile --region eu-west-1 --output text)
echo "ireland_log_private_rtbc_id=$ireland_log_private_rtbc_id"

aws ec2 create-tags --resources $ireland_log_private_rtbc_id \
                    --tags Key=Name,Value=Log-PrivateRouteTableC \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then ireland_log_ngw_id=$ireland_log_ngwc_id; else ireland_log_ngw_id=$ireland_log_ngwa_id; fi
  aws ec2 create-route --route-table-id $ireland_log_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $ireland_log_ngw_id \
                       --profile $profile --region eu-west-1 --output text
else
  aws ec2 create-route --route-table-id $ireland_log_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $ireland_log_nat_instance_eni_id \
                       --profile $profile --region eu-west-1 --output text
fi

aws ec2 associate-route-table --route-table-id $ireland_log_private_rtbc_id --subnet-id $ireland_log_application_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_private_rtbc_id --subnet-id $ireland_log_database_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_private_rtbc_id --subnet-id $ireland_log_management_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_private_rtbc_id --subnet-id $ireland_log_gateway_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $ireland_log_private_rtbc_id --subnet-id $ireland_log_endpoint_subnetc_id \
                              --profile $profile --region eu-west-1 --output text

# Create VPC Endpoint Security Group
ireland_log_vpce_sg_id=$(aws ec2 create-security-group --group-name Log-VPCEndpointSecurityGroup \
                                                       --description Log-VPCEndpointSecurityGroup \
                                                       --vpc-id $ireland_log_vpc_id \
                                                       --query 'GroupId' \
                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_log_vpce_sg_id=$ireland_log_vpce_sg_id"

aws ec2 create-tags --resources $ireland_log_vpce_sg_id \
                    --tags Key=Name,Value=Log-VPCEndpointSecurityGroup \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_log_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ireland_log_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $ireland_log_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$ireland_log_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create VPC Endpoints for SSM and SSMMessages
ireland_log_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ireland_log_vpc_id \
                                                      --vpc-endpoint-type Interface \
                                                      --service-name com.amazonaws.eu-west-1.ssm \
                                                      --private-dns-enabled \
                                                      --security-group-ids $ireland_log_vpce_sg_id \
                                                      --subnet-ids $ireland_log_endpoint_subneta_id $ireland_log_endpoint_subnetb_id $ireland_log_endpoint_subnetc_id \
                                                      --client-token $(date +%s) \
                                                      --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Log-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                      --query 'VpcEndpoint.VpcEndpointId' \
                                                      --profile $profile --region eu-west-1 --output text)
echo "ireland_log_ssm_vpce_id=$ireland_log_ssm_vpce_id"

ireland_log_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $ireland_log_vpc_id \
                                                       --vpc-endpoint-type Interface \
                                                       --service-name com.amazonaws.eu-west-1.ssmmessages \
                                                       --private-dns-enabled \
                                                       --security-group-ids $ireland_log_vpce_sg_id \
                                                       --subnet-ids $ireland_log_endpoint_subneta_id $ireland_log_endpoint_subnetb_id $ireland_log_endpoint_subnetc_id \
                                                       --client-token $(date +%s) \
                                                       --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Log-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                       --query 'VpcEndpoint.VpcEndpointId' \
                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_log_ssmm_vpce_id=$ireland_log_ssmm_vpce_id"


## Alfa Ireland Recovery VPC ##########################################################################################
echo "recovery_account_id=$recovery_account_id"

profile=$recovery_profile

# Create VPC
alfa_ireland_recovery_vpc_id=$(aws ec2 create-vpc --cidr-block $alfa_ireland_recovery_vpc_cidr \
                                                  --query 'Vpc.VpcId' \
                                                  --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_vpc_id=$alfa_ireland_recovery_vpc_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_vpc_id \
                    --tags Key=Name,Value=Alfa-Recovery-VPC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $alfa_ireland_recovery_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region eu-west-1 --output text

aws ec2 modify-vpc-attribute --vpc-id $alfa_ireland_recovery_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region eu-west-1 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Recovery/Alfa" \
                          --profile $profile --region eu-west-1 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $alfa_ireland_recovery_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:eu-west-1:$recovery_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Recovery/Alfa" \
                         --deliver-logs-permission-arn "arn:aws:iam::$recovery_account_id:role/FlowLog" \
                         --profile $profile --region eu-west-1 --output text

# Create Internet Gateway & Attach
alfa_ireland_recovery_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                               --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_igw_id=$alfa_ireland_recovery_igw_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_igw_id \
                    --tags Key=Name,Value=Alfa-Recovery-InternetGateway \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 attach-internet-gateway --vpc-id $alfa_ireland_recovery_vpc_id \
                                --internet-gateway-id $alfa_ireland_recovery_igw_id \
                                --profile $profile --region eu-west-1 --output text

# Create Private Hosted Zone
alfa_ireland_recovery_private_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_ireland_recovery_private_domain \
                                                                             --vpc VPCRegion=eu-west-1,VPCId=$alfa_ireland_recovery_vpc_id \
                                                                             --hosted-zone-config Comment="Private Zone for $alfa_ireland_recovery_private_domain",PrivateZone=true \
                                                                             --caller-reference $(date +%s) \
                                                                             --query 'HostedZone.Id' \
                                                                             --profile $profile --region eu-west-1 --output text | cut -f3 -d /)
echo "alfa_ireland_recovery_private_hostedzone_id=$alfa_ireland_recovery_private_hostedzone_id"

# Create DHCP Options Set
alfa_ireland_recovery_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$alfa_ireland_recovery_private_domain]" \
                                                                                  "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                                            --query 'DhcpOptions.DhcpOptionsId' \
                                                            --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_dopt_id=$alfa_ireland_recovery_dopt_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_dopt_id \
                    --tags Key=Name,Value=Alfa-Recovery-DHCPOptions \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 associate-dhcp-options --vpc-id $alfa_ireland_recovery_vpc_id \
                               --dhcp-options-id $alfa_ireland_recovery_dopt_id \
                               --profile $profile --region eu-west-1 --output text

# Create Public Subnet A
alfa_ireland_recovery_public_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                --cidr-block $alfa_ireland_recovery_subnet_publica_cidr \
                                                                --availability-zone eu-west-1a \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_public_subneta_id=$alfa_ireland_recovery_public_subneta_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_public_subneta_id \
                    --tags Key=Name,Value=Alfa-Recovery-PublicSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Public Subnet B
alfa_ireland_recovery_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                --cidr-block $alfa_ireland_recovery_subnet_publicb_cidr \
                                                                --availability-zone eu-west-1b \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_public_subnetb_id=$alfa_ireland_recovery_public_subnetb_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_public_subnetb_id \
                    --tags Key=Name,Value=Alfa-Recovery-PublicSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Public Subnet C
alfa_ireland_recovery_public_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                --cidr-block $alfa_ireland_recovery_subnet_publicc_cidr \
                                                                --availability-zone eu-west-1c \
                                                                --query 'Subnet.SubnetId' \
                                                                --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_public_subnetc_id=$alfa_ireland_recovery_public_subnetc_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_public_subnetc_id \
                    --tags Key=Name,Value=Alfa-Recovery-PublicSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Web Subnet A
alfa_ireland_recovery_web_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                             --cidr-block $alfa_ireland_recovery_subnet_weba_cidr \
                                                             --availability-zone eu-west-1a \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_web_subneta_id=$alfa_ireland_recovery_web_subneta_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_web_subneta_id \
                    --tags Key=Name,Value=Alfa-Recovery-WebSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Web Subnet B
alfa_ireland_recovery_web_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                             --cidr-block $alfa_ireland_recovery_subnet_webb_cidr \
                                                             --availability-zone eu-west-1b \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_web_subnetb_id=$alfa_ireland_recovery_web_subnetb_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_web_subnetb_id \
                    --tags Key=Name,Value=Alfa-Recovery-WebSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Web Subnet C
alfa_ireland_recovery_web_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                             --cidr-block $alfa_ireland_recovery_subnet_webc_cidr \
                                                             --availability-zone eu-west-1c \
                                                             --query 'Subnet.SubnetId' \
                                                             --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_web_subnetc_id=$alfa_ireland_recovery_web_subnetc_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_web_subnetc_id \
                    --tags Key=Name,Value=Alfa-Recovery-WebSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Application Subnet A
alfa_ireland_recovery_application_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                     --cidr-block $alfa_ireland_recovery_subnet_applicationa_cidr \
                                                                     --availability-zone eu-west-1a \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_application_subneta_id=$alfa_ireland_recovery_application_subneta_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_application_subneta_id \
                    --tags Key=Name,Value=Alfa-Recovery-ApplicationSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Application Subnet B
alfa_ireland_recovery_application_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                     --cidr-block $alfa_ireland_recovery_subnet_applicationb_cidr \
                                                                     --availability-zone eu-west-1b \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_application_subnetb_id=$alfa_ireland_recovery_application_subnetb_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_application_subnetb_id \
                    --tags Key=Name,Value=Alfa-Recovery-ApplicationSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Application Subnet C
alfa_ireland_recovery_application_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                     --cidr-block $alfa_ireland_recovery_subnet_applicationc_cidr \
                                                                     --availability-zone eu-west-1c \
                                                                     --query 'Subnet.SubnetId' \
                                                                     --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_application_subnetc_id=$alfa_ireland_recovery_application_subnetc_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_application_subnetc_id \
                    --tags Key=Name,Value=Alfa-Recovery-ApplicationSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Database Subnet A
alfa_ireland_recovery_database_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                  --cidr-block $alfa_ireland_recovery_subnet_databasea_cidr \
                                                                  --availability-zone eu-west-1a \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_database_subneta_id=$alfa_ireland_recovery_database_subneta_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_database_subneta_id \
                    --tags Key=Name,Value=Alfa-Recovery-DatabaseSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Database Subnet B
alfa_ireland_recovery_database_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                  --cidr-block $alfa_ireland_recovery_subnet_databaseb_cidr \
                                                                  --availability-zone eu-west-1b \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_database_subnetb_id=$alfa_ireland_recovery_database_subnetb_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_database_subnetb_id \
                    --tags Key=Name,Value=Alfa-Recovery-DatabaseSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Database Subnet C
alfa_ireland_recovery_database_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                  --cidr-block $alfa_ireland_recovery_subnet_databasec_cidr \
                                                                  --availability-zone eu-west-1c \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_database_subnetc_id=$alfa_ireland_recovery_database_subnetc_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_database_subnetc_id \
                    --tags Key=Name,Value=Alfa-Recovery-DatabaseSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Management Subnet A
alfa_ireland_recovery_management_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                    --cidr-block $alfa_ireland_recovery_subnet_managementa_cidr \
                                                                    --availability-zone eu-west-1a \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_management_subneta_id=$alfa_ireland_recovery_management_subneta_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_management_subneta_id \
                    --tags Key=Name,Value=Alfa-Recovery-ManagementSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Management Subnet B
alfa_ireland_recovery_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                    --cidr-block $alfa_ireland_recovery_subnet_managementb_cidr \
                                                                    --availability-zone eu-west-1b \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_management_subnetb_id=$alfa_ireland_recovery_management_subnetb_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_management_subnetb_id \
                    --tags Key=Name,Value=Alfa-Recovery-ManagementSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Management Subnet C
alfa_ireland_recovery_management_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                    --cidr-block $alfa_ireland_recovery_subnet_managementc_cidr \
                                                                    --availability-zone eu-west-1c \
                                                                    --query 'Subnet.SubnetId' \
                                                                    --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_management_subnetc_id=$alfa_ireland_recovery_management_subnetc_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_management_subnetc_id \
                    --tags Key=Name,Value=Alfa-Recovery-ManagementSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Gateway Subnet A
alfa_ireland_recovery_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                 --cidr-block $alfa_ireland_recovery_subnet_gatewaya_cidr \
                                                                 --availability-zone eu-west-1a \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_gateway_subneta_id=$alfa_ireland_recovery_gateway_subneta_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_gateway_subneta_id \
                    --tags Key=Name,Value=Alfa-Recovery-GatewaySubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Gateway Subnet B
alfa_ireland_recovery_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                 --cidr-block $alfa_ireland_recovery_subnet_gatewayb_cidr \
                                                                 --availability-zone eu-west-1b \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_gateway_subnetb_id=$alfa_ireland_recovery_gateway_subnetb_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_gateway_subnetb_id \
                    --tags Key=Name,Value=Alfa-Recovery-GatewaySubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Gateway Subnet C
alfa_ireland_recovery_gateway_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                 --cidr-block $alfa_ireland_recovery_subnet_gatewayc_cidr \
                                                                 --availability-zone eu-west-1c \
                                                                 --query 'Subnet.SubnetId' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_gateway_subnetc_id=$alfa_ireland_recovery_gateway_subnetc_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_gateway_subnetc_id \
                    --tags Key=Name,Value=Alfa-Recovery-GatewaySubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Endpoint Subnet A
alfa_ireland_recovery_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                  --cidr-block $alfa_ireland_recovery_subnet_endpointa_cidr \
                                                                  --availability-zone eu-west-1a \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_endpoint_subneta_id=$alfa_ireland_recovery_endpoint_subneta_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_endpoint_subneta_id \
                    --tags Key=Name,Value=Alfa-Recovery-EndpointSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Endpoint Subnet B
alfa_ireland_recovery_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                  --cidr-block $alfa_ireland_recovery_subnet_endpointb_cidr \
                                                                  --availability-zone eu-west-1b \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_endpoint_subnetb_id=$alfa_ireland_recovery_endpoint_subnetb_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_endpoint_subnetb_id \
                    --tags Key=Name,Value=Alfa-Recovery-EndpointSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Endpoint Subnet C
alfa_ireland_recovery_endpoint_subnetc_id=$(aws ec2 create-subnet --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                  --cidr-block $alfa_ireland_recovery_subnet_endpointc_cidr \
                                                                  --availability-zone eu-west-1c \
                                                                  --query 'Subnet.SubnetId' \
                                                                  --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_endpoint_subnetc_id=$alfa_ireland_recovery_endpoint_subnetc_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_endpoint_subnetc_id \
                    --tags Key=Name,Value=Alfa-Recovery-EndpointSubnetC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
alfa_ireland_recovery_public_rtb_id=$(aws ec2 create-route-table --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                 --query 'RouteTable.RouteTableId' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_public_rtb_id=$alfa_ireland_recovery_public_rtb_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_public_rtb_id \
                    --tags Key=Name,Value=Alfa-Recovery-PublicRouteTable \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $alfa_ireland_recovery_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $alfa_ireland_recovery_igw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_public_rtb_id --subnet-id $alfa_ireland_recovery_public_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_public_rtb_id --subnet-id $alfa_ireland_recovery_public_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_public_rtb_id --subnet-id $alfa_ireland_recovery_public_subnetc_id \
                              --profile $profile --region eu-west-1 --output text

aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_public_rtb_id --subnet-id $alfa_ireland_recovery_web_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_public_rtb_id --subnet-id $alfa_ireland_recovery_web_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_public_rtb_id --subnet-id $alfa_ireland_recovery_web_subnetc_id \
                              --profile $profile --region eu-west-1 --output text

# Create NAT Gateways
if [ $use_ngw = 1 ]; then
  alfa_ireland_recovery_ngw_eipa=$(aws ec2 allocate-address --domain vpc \
                                                            --query 'AllocationId' \
                                                            --profile $profile --region eu-west-1 --output text)
  echo "alfa_ireland_recovery_ngw_eipa=$alfa_ireland_recovery_ngw_eipa"

  aws ec2 create-tags --resources $alfa_ireland_recovery_ngw_eipa \
                      --tags Key=Name,Value=Alfa-Recovery-NAT-EIPA \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Recovery \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region eu-west-1 --output text

  alfa_ireland_recovery_ngwa_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_ireland_recovery_ngw_eipa \
                                                             --subnet-id $alfa_ireland_recovery_public_subneta_id \
                                                             --client-token $(date +%s) \
                                                             --query 'NatGateway.NatGatewayId' \
                                                             --profile $profile --region eu-west-1 --output text)
  echo "alfa_ireland_recovery_ngwa_id=$alfa_ireland_recovery_ngwa_id"

  aws ec2 create-tags --resources $alfa_ireland_recovery_ngwa_id \
                      --tags Key=Name,Value=Alfa-Recovery-NAT-GatewayA \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Recovery \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region eu-west-1 --output text

  if [ $ha_ngw = 1 ]; then
    alfa_ireland_recovery_ngw_eipb=$(aws ec2 allocate-address --domain vpc \
                                                              --query 'AllocationId' \
                                                              --profile $profile --region eu-west-1 --output text)
    echo "alfa_ireland_recovery_ngw_eipb=$alfa_ireland_recovery_ngw_eipb"

    aws ec2 create-tags --resources $alfa_ireland_recovery_ngw_eipb \
                        --tags Key=Name,Value=Alfa-Recovery-NAT-EIPB \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Recovery \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text

    alfa_ireland_recovery_ngwb_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_ireland_recovery_ngw_eipb \
                                                               --subnet-id $alfa_ireland_recovery_public_subnetb_id \
                                                               --client-token $(date +%s) \
                                                               --query 'NatGateway.NatGatewayId' \
                                                               --profile $profile --region eu-west-1 --output text)
    echo "alfa_ireland_recovery_ngwb_id=$alfa_ireland_recovery_ngwb_id"

    aws ec2 create-tags --resources $alfa_ireland_recovery_ngwb_id \
                        --tags Key=Name,Value=Alfa-Recovery-NAT-GatewayB \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Recovery \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text

    alfa_ireland_recovery_ngw_eipc=$(aws ec2 allocate-address --domain vpc \
                                                              --query 'AllocationId' \
                                                              --profile $profile --region eu-west-1 --output text)
    echo "alfa_ireland_recovery_ngw_eipc=$alfa_ireland_recovery_ngw_eipc"

    aws ec2 create-tags --resources $alfa_ireland_recovery_ngw_eipc \
                        --tags Key=Name,Value=Alfa-Recovery-NAT-EIPC \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Recovery \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text

    alfa_ireland_recovery_ngwc_id=$(aws ec2 create-nat-gateway --allocation-id $alfa_ireland_recovery_ngw_eipc \
                                                               --subnet-id $alfa_ireland_recovery_public_subnetc_id \
                                                               --client-token $(date +%s) \
                                                               --query 'NatGateway.NatGatewayId' \
                                                               --profile $profile --region eu-west-1 --output text)
    echo "alfa_ireland_recovery_ngwc_id=$alfa_ireland_recovery_ngwc_id"

    aws ec2 create-tags --resources $alfa_ireland_recovery_ngwc_id \
                        --tags Key=Name,Value=Alfa-Recovery-NAT-GatewayC \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Recovery \
                               Key=Project,Value="CaMeLz4 POC" \
                               Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                        --profile $profile --region eu-west-1 --output text
  fi
else
  # Create NAT Security Group
  alfa_ireland_recovery_nat_sg_id=$(aws ec2 create-security-group --group-name Alfa-Recovery-NAT-InstanceSecurityGroup \
                                                                  --description Alfa-Recovery-NAT-InstanceSecurityGroup \
                                                                  --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                  --query 'GroupId' \
                                                                  --profile $profile --region eu-west-1 --output text)
  echo "alfa_ireland_recovery_nat_sg_id=$alfa_ireland_recovery_nat_sg_id"

  aws ec2 create-tags --resources $alfa_ireland_recovery_nat_sg_id \
                      --tags Key=Name,Value=Alfa-Recovery-NAT-InstanceSecurityGroup \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Recovery \
                             Key=Utility,Value=NAT \
                             Key=Project,Value="CaMeLz4 POC" \
                             Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                      --profile $profile --region eu-west-1 --output text

  aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_nat_sg_id \
                                           --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$alfa_ireland_recovery_vpc_cidr,Description=\"VPC (All)\"}]" \
                                           --profile $profile --region eu-west-1 --output text

  # Create NAT Instance
  alfa_ireland_recovery_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                                --instance-type t3a.nano \
                                                                --iam-instance-profile Name=ManagedInstance \
                                                                --key-name administrator \
                                                                --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Alfa-Recovery-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_ireland_recovery_nat_sg_id],SubnetId=$alfa_ireland_recovery_public_subneta_id" \
                                                                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Recovery-NAT-Instance},{Key=Hostname,Value=alfew1rnat01a},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                --query 'Instances[0].InstanceId' \
                                                                --profile $profile --region eu-west-1 --output text)
  echo "alfa_ireland_recovery_nat_instance_id=$alfa_ireland_recovery_nat_instance_id"

  aws ec2 modify-instance-attribute --instance-id $alfa_ireland_recovery_nat_instance_id \
                                    --no-source-dest-check \
                                    --profile $profile --region eu-west-1 --output text

  alfa_ireland_recovery_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $alfa_ireland_recovery_nat_instance_id \
                                                                         --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                                         --profile $profile --region eu-west-1 --output text)
  echo "alfa_ireland_recovery_nat_instance_eni_id=$alfa_ireland_recovery_nat_instance_eni_id"

  alfa_ireland_recovery_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_ireland_recovery_nat_instance_id \
                                                                             --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                                             --profile $profile --region eu-west-1 --output text)
  echo "alfa_ireland_recovery_nat_instance_private_ip=$alfa_ireland_recovery_nat_instance_private_ip"
fi

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
alfa_ireland_recovery_private_rtba_id=$(aws ec2 create-route-table --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_private_rtba_id=$alfa_ireland_recovery_private_rtba_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_private_rtba_id \
                    --tags Key=Name,Value=Alfa-Recovery-PrivateRouteTableA \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

if [ $use_ngw = 1 ]; then
  aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $alfa_ireland_recovery_ngwa_id \
                       --profile $profile --region eu-west-1 --output text
else
  aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtba_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $alfa_ireland_recovery_nat_instance_eni_id \
                       --profile $profile --region eu-west-1 --output text
fi

aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtba_id --subnet-id $alfa_ireland_recovery_application_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtba_id --subnet-id $alfa_ireland_recovery_database_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtba_id --subnet-id $alfa_ireland_recovery_management_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtba_id --subnet-id $alfa_ireland_recovery_gateway_subneta_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtba_id --subnet-id $alfa_ireland_recovery_endpoint_subneta_id \
                              --profile $profile --region eu-west-1 --output text

alfa_ireland_recovery_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_private_rtbb_id=$alfa_ireland_recovery_private_rtbb_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_private_rtbb_id \
                    --tags Key=Name,Value=Alfa-Recovery-PrivateRouteTableB \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then alfa_ireland_recovery_ngw_id=$alfa_ireland_recovery_ngwb_id; else alfa_ireland_recovery_ngw_id=$alfa_ireland_recovery_ngwa_id; fi
  aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $alfa_ireland_recovery_ngw_id \
                       --profile $profile --region eu-west-1 --output text
else
  aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtbb_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $alfa_ireland_recovery_nat_instance_eni_id \
                       --profile $profile --region eu-west-1 --output text
fi

aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtbb_id --subnet-id $alfa_ireland_recovery_application_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtbb_id --subnet-id $alfa_ireland_recovery_database_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtbb_id --subnet-id $alfa_ireland_recovery_management_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtbb_id --subnet-id $alfa_ireland_recovery_gateway_subnetb_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtbb_id --subnet-id $alfa_ireland_recovery_endpoint_subnetb_id \
                              --profile $profile --region eu-west-1 --output text

alfa_ireland_recovery_private_rtbc_id=$(aws ec2 create-route-table --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                   --query 'RouteTable.RouteTableId' \
                                                                   --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_private_rtbc_id=$alfa_ireland_recovery_private_rtbc_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_private_rtbc_id \
                    --tags Key=Name,Value=Alfa-Recovery-PrivateRouteTableC \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

if [ $use_ngw = 1 ]; then
  if [ $ha_ngw = 1 ]; then alfa_ireland_recovery_ngw_id=$alfa_ireland_recovery_ngwc_id; else alfa_ireland_recovery_ngw_id=$alfa_ireland_recovery_ngwa_id; fi
  aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --gateway-id $alfa_ireland_recovery_ngw_id \
                       --profile $profile --region eu-west-1 --output text
else
  aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtbc_id \
                       --destination-cidr-block '0.0.0.0/0' \
                       --network-interface-id $alfa_ireland_recovery_nat_instance_eni_id \
                       --profile $profile --region eu-west-1 --output text
fi

aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtbc_id --subnet-id $alfa_ireland_recovery_application_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtbc_id --subnet-id $alfa_ireland_recovery_database_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtbc_id --subnet-id $alfa_ireland_recovery_management_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtbc_id --subnet-id $alfa_ireland_recovery_gateway_subnetc_id \
                              --profile $profile --region eu-west-1 --output text
aws ec2 associate-route-table --route-table-id $alfa_ireland_recovery_private_rtbc_id --subnet-id $alfa_ireland_recovery_endpoint_subnetc_id \
                              --profile $profile --region eu-west-1 --output text

# Create VPC Endpoint Security Group
alfa_ireland_recovery_vpce_sg_id=$(aws ec2 create-security-group --group-name Alfa-Recovery-VPCEndpointSecurityGroup \
                                                                 --description Alfa-Recovery-VPCEndpointSecurityGroup \
                                                                 --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                 --query 'GroupId' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_vpce_sg_id=$alfa_ireland_recovery_vpce_sg_id"

aws ec2 create-tags --resources $alfa_ireland_recovery_vpce_sg_id \
                    --tags Key=Name,Value=Alfa-Recovery-VPCEndpointSecurityGroup \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Recovery \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_ireland_recovery_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_ireland_recovery_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_ireland_recovery_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region eu-west-1 --output text

# Create VPC Endpoints for SSM and SSMMessages
alfa_ireland_recovery_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                --vpc-endpoint-type Interface \
                                                                --service-name com.amazonaws.eu-west-1.ssm \
                                                                --private-dns-enabled \
                                                                --security-group-ids $alfa_ireland_recovery_vpce_sg_id \
                                                                --subnet-ids $alfa_ireland_recovery_endpoint_subneta_id $alfa_ireland_recovery_endpoint_subnetb_id $alfa_ireland_recovery_endpoint_subnetc_id \
                                                                --client-token $(date +%s) \
                                                                --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Recovery-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                --query 'VpcEndpoint.VpcEndpointId' \
                                                                --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_ssm_vpce_id=$alfa_ireland_recovery_ssm_vpce_id"

alfa_ireland_recovery_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                 --vpc-endpoint-type Interface \
                                                                 --service-name com.amazonaws.eu-west-1.ssmmessages \
                                                                 --private-dns-enabled \
                                                                 --security-group-ids $alfa_ireland_recovery_vpce_sg_id \
                                                                 --subnet-ids $alfa_ireland_recovery_endpoint_subneta_id $alfa_ireland_recovery_endpoint_subnetb_id $alfa_ireland_recovery_endpoint_subnetc_id \
                                                                 --client-token $(date +%s) \
                                                                 --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Recovery-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Recovery},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                 --query 'VpcEndpoint.VpcEndpointId' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_recovery_ssmm_vpce_id=$alfa_ireland_recovery_ssmm_vpce_id"


## Alfa LosAngeles VPC ################################################################################################
echo "management_account_id=$management_account_id"

profile=$management_profile

# Create VPC
alfa_lax_vpc_id=$(aws ec2 create-vpc --cidr-block $alfa_lax_vpc_cidr \
                                     --query 'Vpc.VpcId' \
                                     --profile $profile --region us-east-2 --output text)
echo "alfa_lax_vpc_id=$alfa_lax_vpc_id"

aws ec2 create-tags --resources $alfa_lax_vpc_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-VPC \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $alfa_lax_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $alfa_lax_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-2 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Alfa/LosAngeles" \
                          --profile $profile --region us-east-2 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $alfa_lax_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-2:$management_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Alfa/LosAngeles" \
                         --deliver-logs-permission-arn "arn:aws:iam::$management_account_id:role/FlowLog" \
                         --profile $profile --region us-east-2 --output text

# Create Internet Gateway & Attach
alfa_lax_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_lax_igw_id=$alfa_lax_igw_id"

aws ec2 create-tags --resources $alfa_lax_igw_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-InternetGateway \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 attach-internet-gateway --vpc-id $alfa_lax_vpc_id \
                                --internet-gateway-id $alfa_lax_igw_id \
                                --profile $profile --region us-east-2 --output text

# Create Private Hosted Zone
alfa_lax_private_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_lax_private_domain \
                                                                --vpc VPCRegion=us-east-2,VPCId=$alfa_lax_vpc_id \
                                                                --hosted-zone-config Comment="Private Zone for $alfa_lax_private_domain",PrivateZone=true \
                                                                --caller-reference $(date +%s) \
                                                                --query 'HostedZone.Id' \
                                                                --profile $profile --region us-east-2 --output text | cut -f3 -d /)
echo "alfa_lax_private_hostedzone_id=$alfa_lax_private_hostedzone_id"

# Create DHCP Options Set
alfa_lax_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$alfa_lax_private_domain]" \
                                                                     "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                               --query 'DhcpOptions.DhcpOptionsId' \
                                               --profile $profile --region us-east-2 --output text)
echo "alfa_lax_dopt_id=$alfa_lax_dopt_id"

aws ec2 create-tags --resources $alfa_lax_dopt_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-DHCPOptions \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 associate-dhcp-options --vpc-id $alfa_lax_vpc_id \
                               --dhcp-options-id $alfa_lax_dopt_id \
                               --profile $profile --region us-east-2 --output text

# Create Public Subnet A
alfa_lax_public_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_lax_vpc_id \
                                                   --cidr-block $alfa_lax_subnet_publica_cidr \
                                                   --availability-zone us-east-2a \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_lax_public_subneta_id=$alfa_lax_public_subneta_id"

aws ec2 create-tags --resources $alfa_lax_public_subneta_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-PublicSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet B
alfa_lax_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_lax_vpc_id \
                                                   --cidr-block $alfa_lax_subnet_publicb_cidr \
                                                   --availability-zone us-east-2b \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_lax_public_subnetb_id=$alfa_lax_public_subnetb_id"

aws ec2 create-tags --resources $alfa_lax_public_subnetb_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-PublicSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Private Subnet A
alfa_lax_private_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_lax_vpc_id \
                                                    --cidr-block $alfa_lax_subnet_privatea_cidr \
                                                    --availability-zone us-east-2a \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_lax_private_subneta_id=$alfa_lax_private_subneta_id"

aws ec2 create-tags --resources $alfa_lax_private_subneta_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-PrivateSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Private Subnet B
alfa_lax_private_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_lax_vpc_id \
                                                    --cidr-block $alfa_lax_subnet_privateb_cidr \
                                                    --availability-zone us-east-2b \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_lax_private_subnetb_id=$alfa_lax_private_subnetb_id"

aws ec2 create-tags --resources $alfa_lax_private_subnetb_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-PrivateSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet A
alfa_lax_management_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_lax_vpc_id \
                                                       --cidr-block $alfa_lax_subnet_managementa_cidr \
                                                       --availability-zone us-east-2a \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "alfa_lax_management_subneta_id=$alfa_lax_management_subneta_id"

aws ec2 create-tags --resources $alfa_lax_management_subneta_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-ManagementSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet B
alfa_lax_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_lax_vpc_id \
                                                       --cidr-block $alfa_lax_subnet_managementb_cidr \
                                                       --availability-zone us-east-2b \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "alfa_lax_management_subnetb_id=$alfa_lax_management_subnetb_id"

aws ec2 create-tags --resources $alfa_lax_management_subnetb_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-ManagementSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet A
alfa_lax_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_lax_vpc_id \
                                                    --cidr-block $alfa_lax_subnet_gatewaya_cidr \
                                                    --availability-zone us-east-2a \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_lax_gateway_subneta_id=$alfa_lax_gateway_subneta_id"

aws ec2 create-tags --resources $alfa_lax_gateway_subneta_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-GatewaySubnetA \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet B
alfa_lax_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_lax_vpc_id \
                                                    --cidr-block $alfa_lax_subnet_gatewayb_cidr \
                                                    --availability-zone us-east-2b \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_lax_gateway_subnetb_id=$alfa_lax_gateway_subnetb_id"

aws ec2 create-tags --resources $alfa_lax_gateway_subnetb_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-GatewaySubnetB \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet A
alfa_lax_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_lax_vpc_id \
                                                     --cidr-block $alfa_lax_subnet_endpointa_cidr \
                                                     --availability-zone us-east-2a \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "alfa_lax_endpoint_subneta_id=$alfa_lax_endpoint_subneta_id"

aws ec2 create-tags --resources $alfa_lax_endpoint_subneta_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-EndpointSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet B
alfa_lax_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_lax_vpc_id \
                                                     --cidr-block $alfa_lax_subnet_endpointb_cidr \
                                                     --availability-zone us-east-2b \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "alfa_lax_endpoint_subnetb_id=$alfa_lax_endpoint_subnetb_id"

aws ec2 create-tags --resources $alfa_lax_endpoint_subnetb_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-EndpointSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create CiscoCSR Security Group
alfa_lax_csr_sg_id=$(aws ec2 create-security-group --group-name Alfa-LosAngeles-CiscoCSR-InstanceSecurityGroup \
                                                   --description Alfa-LosAngeles-CiscoCSR-InstanceSecurityGroup \
                                                   --vpc-id $alfa_lax_vpc_id \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_lax_csr_sg_id=$alfa_lax_csr_sg_id"

aws ec2 create-tags --resources $alfa_lax_csr_sg_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-CiscoCSR-InstanceSecurityGroup \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Utility,Value=CiscoCSR \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_lax_csr_sg_id \
                                         --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"VPC (All)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_lax_csr_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_lax_csr_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create CiscoCSR EIP
alfa_lax_csr_eipa=$(aws ec2 allocate-address --domain vpc \
                                             --query 'AllocationId' \
                                             --profile $profile --region us-east-2 --output text)
echo "alfa_lax_csr_eipa=$alfa_lax_csr_eipa"

alfa_lax_csr_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_lax_csr_eipa \
                                                              --query 'Addresses[0].PublicIp' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_lax_csr_instancea_public_ip=$alfa_lax_csr_instancea_public_ip"

aws ec2 create-tags --resources $alfa_lax_csr_eipa \
                    --tags Key=Name,Value=Alfa-LosAngeles-CiscoCSR-EIPA \
                           Key=Hostname,Value=alflaxccsr01a \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Utility,Value=CiscoCSR \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create CiscoCSR Public Domain Name
tmpfile=$tmpdir/alfa-lax-csra-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alflaxccsr01a.$alfa_lax_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_lax_csr_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "csra.$alfa_lax_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alflaxccsr01a.$alfa_lax_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_lax_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

# Create CiscoCSR Instance
alfa_lax_csr_instancea_id=$(aws ec2 run-instances --image-id $ohio_csr_ami_id \
                                                  --instance-type t3.medium \
                                                  --iam-instance-profile Name=ManagedInstance \
                                                  --key-name administrator \
                                                  --network-interfaces "AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-LosAngeles-CiscoCSR-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_lax_csr_sg_id],SubnetId=$alfa_lax_public_subneta_id" \
                                                  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Alfa-LosAngeles-CiscoCSR-InstanceA},{Key=Hostname,Value=alflaxccsr01a},{Key=Company,Value=Alfa},{Key=Location,Value=LosAngeles},{Key=Utility,Value=CiscoCSR},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                  --query 'Instances[0].InstanceId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_lax_csr_instancea_id=$alfa_lax_csr_instancea_id"

aws ec2 modify-instance-attribute --instance-id $alfa_lax_csr_instancea_id \
                                  --no-source-dest-check \
                                  --profile $profile --region us-east-2 --output text

alfa_lax_csr_instancea_eni_id=$(aws ec2 describe-instances --instance-ids $alfa_lax_csr_instancea_id \
                                                           --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "alfa_lax_csr_instancea_eni_id=$alfa_lax_csr_instancea_eni_id"

alfa_lax_csr_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_lax_csr_instancea_id \
                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_lax_csr_instancea_private_ip=$alfa_lax_csr_instancea_private_ip"

# Create CiscoCSR Private Domain Name
tmpfile=$tmpdir/alfa-lax-csra-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alflaxccsr01a.$alfa_lax_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_lax_csr_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "csra.$alfa_lax_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alflaxccsr01a.$alfa_lax_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_lax_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $alfa_lax_csr_instancea_id --allocation-id $alfa_lax_csr_eipa \
                          --profile $profile --region us-east-2 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
alfa_lax_public_rtb_id=$(aws ec2 create-route-table --vpc-id $alfa_lax_vpc_id \
                                                    --query 'RouteTable.RouteTableId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_lax_public_rtb_id=$alfa_lax_public_rtb_id"

aws ec2 create-tags --resources $alfa_lax_public_rtb_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-PublicRouteTable \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_lax_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $alfa_lax_igw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_lax_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --network-interface-id $alfa_lax_csr_instancea_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_lax_public_rtb_id --subnet-id $alfa_lax_public_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_lax_public_rtb_id --subnet-id $alfa_lax_public_subnetb_id \
                              --profile $profile --region us-east-2 --output text

# Create NAT Security Group
alfa_lax_nat_sg_id=$(aws ec2 create-security-group --group-name Alfa-LosAngeles-NAT-InstanceSecurityGroup \
                                                   --description Alfa-LosAngeles-NAT-InstanceSecurityGroup \
                                                   --vpc-id $alfa_lax_vpc_id \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_lax_nat_sg_id=$alfa_lax_nat_sg_id"

aws ec2 create-tags --resources $alfa_lax_nat_sg_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-NAT-InstanceSecurityGroup \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Utility,Value=NAT \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_lax_nat_sg_id \
                                         --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"VPC (All)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create NAT Instance
alfa_lax_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                 --instance-type t3a.nano \
                                                 --iam-instance-profile Name=ManagedInstance \
                                                 --key-name administrator \
                                                 --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Alfa-LosAngeles-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_lax_nat_sg_id],SubnetId=$alfa_lax_public_subneta_id" \
                                                 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Alfa-LosAngeles-NAT-Instance},{Key=Hostname,Value=alflaxcnat01a},{Key=Company,Value=Alfa},{Key=Location,Value=LosAngeles},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                 --query 'Instances[0].InstanceId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_lax_nat_instance_id=$alfa_lax_nat_instance_id"

aws ec2 modify-instance-attribute --instance-id $alfa_lax_nat_instance_id \
                                  --no-source-dest-check \
                                  --profile $profile --region us-east-2 --output text

alfa_lax_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $alfa_lax_nat_instance_id \
                                                          --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "alfa_lax_nat_instance_eni_id=$alfa_lax_nat_instance_eni_id"

alfa_lax_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_lax_nat_instance_id \
                                                              --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_lax_nat_instance_private_ip=$alfa_lax_nat_instance_private_ip"

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
alfa_lax_private_rtba_id=$(aws ec2 create-route-table --vpc-id $alfa_lax_vpc_id \
                                                      --query 'RouteTable.RouteTableId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "alfa_lax_private_rtba_id=$alfa_lax_private_rtba_id"

aws ec2 create-tags --resources $alfa_lax_private_rtba_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-PrivateRouteTableA \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_lax_private_rtba_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $alfa_lax_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_lax_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --network-interface-id $alfa_lax_csr_instancea_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_lax_private_rtba_id --subnet-id $alfa_lax_private_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_lax_private_rtba_id --subnet-id $alfa_lax_management_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_lax_private_rtba_id --subnet-id $alfa_lax_gateway_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_lax_private_rtba_id --subnet-id $alfa_lax_endpoint_subneta_id \
                              --profile $profile --region us-east-2 --output text

alfa_lax_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $alfa_lax_vpc_id \
                                                      --query 'RouteTable.RouteTableId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "alfa_lax_private_rtbb_id=$alfa_lax_private_rtbb_id"

aws ec2 create-tags --resources $alfa_lax_private_rtbb_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-PrivateRouteTableB \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_lax_private_rtbb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $alfa_lax_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_lax_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --network-interface-id $alfa_lax_csr_instancea_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_lax_private_rtbb_id --subnet-id $alfa_lax_private_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_lax_private_rtbb_id --subnet-id $alfa_lax_management_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_lax_private_rtbb_id --subnet-id $alfa_lax_gateway_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_lax_private_rtbb_id --subnet-id $alfa_lax_endpoint_subnetb_id \
                              --profile $profile --region us-east-2 --output text

# Create VPC Endpoint Security Group
alfa_lax_vpce_sg_id=$(aws ec2 create-security-group --group-name Alfa-LosAngeles-VPCEndpointSecurityGroup \
                                                    --description Alfa-LosAngeles-VPCEndpointSecurityGroup \
                                                    --vpc-id $alfa_lax_vpc_id \
                                                    --query 'GroupId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_lax_vpce_sg_id=$alfa_lax_vpce_sg_id"

aws ec2 create-tags --resources $alfa_lax_vpce_sg_id \
                    --tags Key=Name,Value=Alfa-LosAngeles-VPCEndpointSecurityGroup \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_lax_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_lax_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_lax_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create VPC Endpoints for SSM and SSMMessages
alfa_lax_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_lax_vpc_id \
                                                   --vpc-endpoint-type Interface \
                                                   --service-name com.amazonaws.us-east-2.ssm \
                                                   --private-dns-enabled \
                                                   --security-group-ids $alfa_lax_vpce_sg_id \
                                                   --subnet-ids $alfa_lax_endpoint_subneta_id $alfa_lax_endpoint_subnetb_id \
                                                   --client-token $(date +%s) \
                                                   --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-LosAngeles-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                   --query 'VpcEndpoint.VpcEndpointId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_lax_ssm_vpce_id=$alfa_lax_ssm_vpce_id"

alfa_lax_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_lax_vpc_id \
                                                    --vpc-endpoint-type Interface \
                                                    --service-name com.amazonaws.us-east-2.ssmmessages \
                                                    --private-dns-enabled \
                                                    --security-group-ids $alfa_lax_vpce_sg_id \
                                                    --subnet-ids $alfa_lax_endpoint_subneta_id $alfa_lax_endpoint_subnetb_id \
                                                    --client-token $(date +%s) \
                                                    --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-LosAngeles-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                    --query 'VpcEndpoint.VpcEndpointId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_lax_ssmm_vpce_id=$alfa_lax_ssmm_vpce_id"


## Alfa Miami VPC #####################################################################################################
echo "management_account_id=$management_account_id"

profile=$management_profile

# Create VPC
alfa_mia_vpc_id=$(aws ec2 create-vpc --cidr-block $alfa_mia_vpc_cidr \
                                     --query 'Vpc.VpcId' \
                                     --profile $profile --region us-east-2 --output text)
echo "alfa_mia_vpc_id=$alfa_mia_vpc_id"

aws ec2 create-tags --resources $alfa_mia_vpc_id \
                    --tags Key=Name,Value=Alfa-Miami-VPC \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $alfa_mia_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $alfa_mia_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-2 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Alfa/Miami" \
                          --profile $profile --region us-east-2 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $alfa_mia_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-2:$management_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Alfa/Miami" \
                         --deliver-logs-permission-arn "arn:aws:iam::$management_account_id:role/FlowLog" \
                         --profile $profile --region us-east-2 --output text

# Create Internet Gateway & Attach
alfa_mia_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_mia_igw_id=$alfa_mia_igw_id"

aws ec2 create-tags --resources $alfa_mia_igw_id \
                    --tags Key=Name,Value=Alfa-Miami-InternetGateway \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 attach-internet-gateway --vpc-id $alfa_mia_vpc_id \
                                --internet-gateway-id $alfa_mia_igw_id \
                                --profile $profile --region us-east-2 --output text

# Create Private Hosted Zone
alfa_mia_private_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_mia_private_domain \
                                                                --vpc VPCRegion=us-east-2,VPCId=$alfa_mia_vpc_id \
                                                                --hosted-zone-config Comment="Private Zone for $alfa_mia_private_domain",PrivateZone=true \
                                                                --caller-reference $(date +%s) \
                                                                --query 'HostedZone.Id' \
                                                                --profile $profile --region us-east-2 --output text | cut -f3 -d /)
echo "alfa_mia_private_hostedzone_id=$alfa_mia_private_hostedzone_id"

# Create DHCP Options Set
alfa_mia_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$alfa_mia_private_domain]" \
                                                                     "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                               --query 'DhcpOptions.DhcpOptionsId' \
                                               --profile $profile --region us-east-2 --output text)
echo "alfa_mia_dopt_id=$alfa_mia_dopt_id"

aws ec2 create-tags --resources $alfa_mia_dopt_id \
                    --tags Key=Name,Value=Alfa-Miami-DHCPOptions \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 associate-dhcp-options --vpc-id $alfa_mia_vpc_id \
                               --dhcp-options-id $alfa_mia_dopt_id \
                               --profile $profile --region us-east-2 --output text

# Create Public Subnet A
alfa_mia_public_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_mia_vpc_id \
                                                   --cidr-block $alfa_mia_subnet_publica_cidr \
                                                   --availability-zone us-east-2a \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_mia_public_subneta_id=$alfa_mia_public_subneta_id"

aws ec2 create-tags --resources $alfa_mia_public_subneta_id \
                    --tags Key=Name,Value=Alfa-Miami-PublicSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet B
alfa_mia_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_mia_vpc_id \
                                                   --cidr-block $alfa_mia_subnet_publicb_cidr \
                                                   --availability-zone us-east-2b \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_mia_public_subnetb_id=$alfa_mia_public_subnetb_id"

aws ec2 create-tags --resources $alfa_mia_public_subnetb_id \
                    --tags Key=Name,Value=Alfa-Miami-PublicSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Private Subnet A
alfa_mia_private_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_mia_vpc_id \
                                                    --cidr-block $alfa_mia_subnet_privatea_cidr \
                                                    --availability-zone us-east-2a \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_mia_private_subneta_id=$alfa_mia_private_subneta_id"

aws ec2 create-tags --resources $alfa_mia_private_subneta_id \
                    --tags Key=Name,Value=Alfa-Miami-PrivateSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Private Subnet B
alfa_mia_private_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_mia_vpc_id \
                                                    --cidr-block $alfa_mia_subnet_privateb_cidr \
                                                    --availability-zone us-east-2b \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_mia_private_subnetb_id=$alfa_mia_private_subnetb_id"

aws ec2 create-tags --resources $alfa_mia_private_subnetb_id \
                    --tags Key=Name,Value=Alfa-Miami-PrivateSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet A
alfa_mia_management_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_mia_vpc_id \
                                                       --cidr-block $alfa_mia_subnet_managementa_cidr \
                                                       --availability-zone us-east-2a \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "alfa_mia_management_subneta_id=$alfa_mia_management_subneta_id"

aws ec2 create-tags --resources $alfa_mia_management_subneta_id \
                    --tags Key=Name,Value=Alfa-Miami-ManagementSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet B
alfa_mia_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_mia_vpc_id \
                                                       --cidr-block $alfa_mia_subnet_managementb_cidr \
                                                       --availability-zone us-east-2b \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "alfa_mia_management_subnetb_id=$alfa_mia_management_subnetb_id"

aws ec2 create-tags --resources $alfa_mia_management_subnetb_id \
                    --tags Key=Name,Value=Alfa-Miami-ManagementSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet A
alfa_mia_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_mia_vpc_id \
                                                    --cidr-block $alfa_mia_subnet_gatewaya_cidr \
                                                    --availability-zone us-east-2a \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_mia_gateway_subneta_id=$alfa_mia_gateway_subneta_id"

aws ec2 create-tags --resources $alfa_mia_gateway_subneta_id \
                    --tags Key=Name,Value=Alfa-Miami-GatewaySubnetA \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet B
alfa_mia_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_mia_vpc_id \
                                                    --cidr-block $alfa_mia_subnet_gatewayb_cidr \
                                                    --availability-zone us-east-2b \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_mia_gateway_subnetb_id=$alfa_mia_gateway_subnetb_id"

aws ec2 create-tags --resources $alfa_mia_gateway_subnetb_id \
                    --tags Key=Name,Value=Alfa-Miami-GatewaySubnetB \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet A
alfa_mia_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $alfa_mia_vpc_id \
                                                     --cidr-block $alfa_mia_subnet_endpointa_cidr \
                                                     --availability-zone us-east-2a \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "alfa_mia_endpoint_subneta_id=$alfa_mia_endpoint_subneta_id"

aws ec2 create-tags --resources $alfa_mia_endpoint_subneta_id \
                    --tags Key=Name,Value=Alfa-Miami-EndpointSubnetA \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet B
alfa_mia_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $alfa_mia_vpc_id \
                                                     --cidr-block $alfa_mia_subnet_endpointb_cidr \
                                                     --availability-zone us-east-2b \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "alfa_mia_endpoint_subnetb_id=$alfa_mia_endpoint_subnetb_id"

aws ec2 create-tags --resources $alfa_mia_endpoint_subnetb_id \
                    --tags Key=Name,Value=Alfa-Miami-EndpointSubnetB \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create CiscoCSR Security Group
alfa_mia_csr_sg_id=$(aws ec2 create-security-group --group-name Alfa-Miami-CiscoCSR-InstanceSecurityGroup \
                                                   --description Alfa-Miami-CiscoCSR-InstanceSecurityGroup \
                                                   --vpc-id $alfa_mia_vpc_id \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_mia_csr_sg_id=$alfa_mia_csr_sg_id"

aws ec2 create-tags --resources $alfa_mia_csr_sg_id \
                    --tags Key=Name,Value=Alfa-Miami-CiscoCSR-InstanceSecurityGroup \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Utility,Value=CiscoCSR \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_mia_csr_sg_id \
                                         --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"VPC (All)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_mia_csr_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_mia_csr_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create CiscoCSR EIP
alfa_mia_csr_eipa=$(aws ec2 allocate-address --domain vpc \
                                             --query 'AllocationId' \
                                             --profile $profile --region us-east-2 --output text)
echo "alfa_mia_csr_eipa=$alfa_mia_csr_eipa"

alfa_mia_csr_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $alfa_mia_csr_eipa \
                                                              --query 'Addresses[0].PublicIp' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_mia_csr_instancea_public_ip=$alfa_mia_csr_instancea_public_ip"

aws ec2 create-tags --resources $alfa_mia_csr_eipa \
                    --tags Key=Name,Value=Alfa-Miami-CiscoCSR-EIPA \
                           Key=Hostname,Value=alfmiaccsr01a \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Utility,Value=CiscoCSR \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create CiscoCSR Public Domain Name
tmpfile=$tmpdir/alfa-mia-csra-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfmiaccsr01a.$alfa_mia_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_mia_csr_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "csra.$alfa_mia_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfmiaccsr01a.$alfa_mia_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_mia_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

# Create CiscoCSR Instance
alfa_mia_csr_instancea_id=$(aws ec2 run-instances --image-id $ohio_csr_ami_id \
                                                  --instance-type t3.medium \
                                                  --iam-instance-profile Name=ManagedInstance \
                                                  --key-name administrator \
                                                  --network-interfaces "AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Alfa-Miami-CiscoCSR-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_mia_csr_sg_id],SubnetId=$alfa_mia_public_subneta_id" \
                                                  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Miami-CiscoCSR-InstanceA},{Key=Hostname,Value=alfmiaccsr01a},{Key=Company,Value=Alfa},{Key=Location,Value=Miami},{Key=Utility,Value=CiscoCSR},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                  --query 'Instances[0].InstanceId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_mia_csr_instancea_id=$alfa_mia_csr_instancea_id"

aws ec2 modify-instance-attribute --instance-id $alfa_mia_csr_instancea_id \
                                  --no-source-dest-check \
                                  --profile $profile --region us-east-2 --output text

alfa_mia_csr_instancea_eni_id=$(aws ec2 describe-instances --instance-ids $alfa_mia_csr_instancea_id \
                                                           --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "alfa_mia_csr_instancea_eni_id=$alfa_mia_csr_instancea_eni_id"

alfa_mia_csr_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_mia_csr_instancea_id \
                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_mia_csr_instancea_private_ip=$alfa_mia_csr_instancea_private_ip"

# Create CiscoCSR Private Domain Name
tmpfile=$tmpdir/alfa-mia-csra-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "alfmiaccsr01a.$alfa_mia_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$alfa_mia_csr_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "csra.$alfa_mia_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "alfmiaccsr01a.$alfa_mia_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $alfa_mia_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $alfa_mia_csr_instancea_id --allocation-id $alfa_mia_csr_eipa \
                          --profile $profile --region us-east-2 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
alfa_mia_public_rtb_id=$(aws ec2 create-route-table --vpc-id $alfa_mia_vpc_id \
                                                    --query 'RouteTable.RouteTableId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_mia_public_rtb_id=$alfa_mia_public_rtb_id"

aws ec2 create-tags --resources $alfa_mia_public_rtb_id \
                    --tags Key=Name,Value=Alfa-Miami-PublicRouteTable \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_mia_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $alfa_mia_igw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_mia_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --network-interface-id $alfa_mia_csr_instancea_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_mia_public_rtb_id --subnet-id $alfa_mia_public_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_mia_public_rtb_id --subnet-id $alfa_mia_public_subnetb_id \
                              --profile $profile --region us-east-2 --output text

# Create NAT Security Group
alfa_mia_nat_sg_id=$(aws ec2 create-security-group --group-name Alfa-Miami-NAT-InstanceSecurityGroup \
                                                   --description Alfa-Miami-NAT-InstanceSecurityGroup \
                                                   --vpc-id $alfa_mia_vpc_id \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_mia_nat_sg_id=$alfa_mia_nat_sg_id"

aws ec2 create-tags --resources $alfa_mia_nat_sg_id \
                    --tags Key=Name,Value=Alfa-Miami-NAT-InstanceSecurityGroup \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Utility,Value=NAT \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_mia_nat_sg_id \
                                         --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"VPC (All)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create NAT Instance
alfa_mia_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                 --instance-type t3a.nano \
                                                 --iam-instance-profile Name=ManagedInstance \
                                                 --key-name administrator \
                                                 --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Alfa-Miami-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$alfa_mia_nat_sg_id],SubnetId=$alfa_mia_public_subneta_id" \
                                                 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Alfa-Miami-NAT-Instance},{Key=Hostname,Value=alfmiacnat01a},{Key=Company,Value=Alfa},{Key=Location,Value=Miami},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                 --query 'Instances[0].InstanceId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "alfa_mia_nat_instance_id=$alfa_mia_nat_instance_id"

aws ec2 modify-instance-attribute --instance-id $alfa_mia_nat_instance_id \
                                  --no-source-dest-check \
                                  --profile $profile --region us-east-2 --output text

alfa_mia_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $alfa_mia_nat_instance_id \
                                                          --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "alfa_mia_nat_instance_eni_id=$alfa_mia_nat_instance_eni_id"

alfa_mia_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $alfa_mia_nat_instance_id \
                                                              --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                              --profile $profile --region us-east-2 --output text)
echo "alfa_mia_nat_instance_private_ip=$alfa_mia_nat_instance_private_ip"

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
alfa_mia_private_rtba_id=$(aws ec2 create-route-table --vpc-id $alfa_mia_vpc_id \
                                                      --query 'RouteTable.RouteTableId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "alfa_mia_private_rtba_id=$alfa_mia_private_rtba_id"

aws ec2 create-tags --resources $alfa_mia_private_rtba_id \
                    --tags Key=Name,Value=Alfa-Miami-PrivateRouteTableA \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_mia_private_rtba_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $alfa_mia_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_mia_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --network-interface-id $alfa_mia_csr_instancea_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_mia_private_rtba_id --subnet-id $alfa_mia_private_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_mia_private_rtba_id --subnet-id $alfa_mia_management_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_mia_private_rtba_id --subnet-id $alfa_mia_gateway_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_mia_private_rtba_id --subnet-id $alfa_mia_endpoint_subneta_id \
                              --profile $profile --region us-east-2 --output text

alfa_mia_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $alfa_mia_vpc_id \
                                                      --query 'RouteTable.RouteTableId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "alfa_mia_private_rtbb_id=$alfa_mia_private_rtbb_id"

aws ec2 create-tags --resources $alfa_mia_private_rtbb_id \
                    --tags Key=Name,Value=Alfa-Miami-PrivateRouteTableB \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_mia_private_rtbb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $alfa_mia_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_mia_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --network-interface-id $alfa_mia_csr_instancea_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $alfa_mia_private_rtbb_id --subnet-id $alfa_mia_private_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_mia_private_rtbb_id --subnet-id $alfa_mia_management_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_mia_private_rtbb_id --subnet-id $alfa_mia_gateway_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $alfa_mia_private_rtbb_id --subnet-id $alfa_mia_endpoint_subnetb_id \
                              --profile $profile --region us-east-2 --output text

# Create VPC Endpoint Security Group
alfa_mia_vpce_sg_id=$(aws ec2 create-security-group --group-name Alfa-Miami-VPCEndpointSecurityGroup \
                                                    --description Alfa-Miami-VPCEndpointSecurityGroup \
                                                    --vpc-id $alfa_mia_vpc_id \
                                                    --query 'GroupId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_mia_vpce_sg_id=$alfa_mia_vpce_sg_id"

aws ec2 create-tags --resources $alfa_mia_vpce_sg_id \
                    --tags Key=Name,Value=Alfa-Miami-VPCEndpointSecurityGroup \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_mia_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $alfa_mia_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$alfa_mia_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create VPC Endpoints for SSM and SSMMessages
alfa_mia_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_mia_vpc_id \
                                                   --vpc-endpoint-type Interface \
                                                   --service-name com.amazonaws.us-east-2.ssm \
                                                   --private-dns-enabled \
                                                   --security-group-ids $alfa_mia_vpce_sg_id \
                                                   --subnet-ids $alfa_mia_endpoint_subneta_id $alfa_mia_endpoint_subnetb_id \
                                                   --client-token $(date +%s) \
                                                   --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Miami-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                   --query 'VpcEndpoint.VpcEndpointId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_mia_ssm_vpce_id=$alfa_mia_ssm_vpce_id"

alfa_mia_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $alfa_mia_vpc_id \
                                                    --vpc-endpoint-type Interface \
                                                    --service-name com.amazonaws.us-east-2.ssmmessages \
                                                    --private-dns-enabled \
                                                    --security-group-ids $alfa_mia_vpce_sg_id \
                                                    --subnet-ids $alfa_mia_endpoint_subneta_id $alfa_mia_endpoint_subnetb_id \
                                                    --client-token $(date +%s) \
                                                    --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Alfa-Miami-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                    --query 'VpcEndpoint.VpcEndpointId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "alfa_mia_ssmm_vpce_id=$alfa_mia_ssmm_vpce_id"


## Zulu Dallas VPC ####################################################################################################
echo "management_account_id=$management_account_id"

profile=$management_profile

# Create VPC
zulu_dfw_vpc_id=$(aws ec2 create-vpc --cidr-block $zulu_dfw_vpc_cidr \
                                     --query 'Vpc.VpcId' \
                                     --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_vpc_id=$zulu_dfw_vpc_id"

aws ec2 create-tags --resources $zulu_dfw_vpc_id \
                    --tags Key=Name,Value=Zulu-Dallas-VPC \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $zulu_dfw_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $zulu_dfw_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-2 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/Zulu/Dallas" \
                          --profile $profile --region us-east-2 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $zulu_dfw_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-2:$management_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/Zulu/Dallas" \
                         --deliver-logs-permission-arn "arn:aws:iam::$management_account_id:role/FlowLog" \
                         --profile $profile --region us-east-2 --output text

# Create Internet Gateway & Attach
zulu_dfw_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_igw_id=$zulu_dfw_igw_id"

aws ec2 create-tags --resources $zulu_dfw_igw_id \
                    --tags Key=Name,Value=Zulu-Dallas-InternetGateway \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 attach-internet-gateway --vpc-id $zulu_dfw_vpc_id \
                                --internet-gateway-id $zulu_dfw_igw_id \
                                --profile $profile --region us-east-2 --output text

# Create Private Hosted Zone
zulu_dfw_private_hostedzone_id=$(aws route53 create-hosted-zone --name $zulu_dfw_private_domain \
                                                                --vpc VPCRegion=us-east-2,VPCId=$zulu_dfw_vpc_id \
                                                                --hosted-zone-config Comment="Private Zone for $zulu_dfw_private_domain",PrivateZone=true \
                                                                --caller-reference $(date +%s) \
                                                                --query 'HostedZone.Id' \
                                                                --profile $profile --region us-east-2 --output text | cut -f3 -d /)
echo "zulu_dfw_private_hostedzone_id=$zulu_dfw_private_hostedzone_id"

# Create DHCP Options Set
zulu_dfw_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$zulu_dfw_private_domain]" \
                                                                     "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                               --query 'DhcpOptions.DhcpOptionsId' \
                                               --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_dopt_id=$zulu_dfw_dopt_id"

aws ec2 create-tags --resources $zulu_dfw_dopt_id \
                    --tags Key=Name,Value=Zulu-Dallas-DHCPOptions \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 associate-dhcp-options --vpc-id $zulu_dfw_vpc_id \
                               --dhcp-options-id $zulu_dfw_dopt_id \
                               --profile $profile --region us-east-2 --output text

# Create Public Subnet A
zulu_dfw_public_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                   --cidr-block $zulu_dfw_subnet_publica_cidr \
                                                   --availability-zone us-east-2a \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_public_subneta_id=$zulu_dfw_public_subneta_id"

aws ec2 create-tags --resources $zulu_dfw_public_subneta_id \
                    --tags Key=Name,Value=Zulu-Dallas-PublicSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet B
zulu_dfw_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                   --cidr-block $zulu_dfw_subnet_publicb_cidr \
                                                   --availability-zone us-east-2b \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_public_subnetb_id=$zulu_dfw_public_subnetb_id"

aws ec2 create-tags --resources $zulu_dfw_public_subnetb_id \
                    --tags Key=Name,Value=Zulu-Dallas-PublicSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Private Subnet A
zulu_dfw_private_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                    --cidr-block $zulu_dfw_subnet_privatea_cidr \
                                                    --availability-zone us-east-2a \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_private_subneta_id=$zulu_dfw_private_subneta_id"

aws ec2 create-tags --resources $zulu_dfw_private_subneta_id \
                    --tags Key=Name,Value=Zulu-Dallas-PrivateSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Private Subnet B
zulu_dfw_private_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                    --cidr-block $zulu_dfw_subnet_privateb_cidr \
                                                    --availability-zone us-east-2b \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_private_subnetb_id=$zulu_dfw_private_subnetb_id"

aws ec2 create-tags --resources $zulu_dfw_private_subnetb_id \
                    --tags Key=Name,Value=Zulu-Dallas-PrivateSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet A
zulu_dfw_management_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                       --cidr-block $zulu_dfw_subnet_managementa_cidr \
                                                       --availability-zone us-east-2a \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_management_subneta_id=$zulu_dfw_management_subneta_id"

aws ec2 create-tags --resources $zulu_dfw_management_subneta_id \
                    --tags Key=Name,Value=Zulu-Dallas-ManagementSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet B
zulu_dfw_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                       --cidr-block $zulu_dfw_subnet_managementb_cidr \
                                                       --availability-zone us-east-2b \
                                                       --query 'Subnet.SubnetId' \
                                                       --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_management_subnetb_id=$zulu_dfw_management_subnetb_id"

aws ec2 create-tags --resources $zulu_dfw_management_subnetb_id \
                    --tags Key=Name,Value=Zulu-Dallas-ManagementSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet A
zulu_dfw_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                    --cidr-block $zulu_dfw_subnet_gatewaya_cidr \
                                                    --availability-zone us-east-2a \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_gateway_subneta_id=$zulu_dfw_gateway_subneta_id"

aws ec2 create-tags --resources $zulu_dfw_gateway_subneta_id \
                    --tags Key=Name,Value=Zulu-Dallas-GatewaySubnetA \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet B
zulu_dfw_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                    --cidr-block $zulu_dfw_subnet_gatewayb_cidr \
                                                    --availability-zone us-east-2b \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_gateway_subnetb_id=$zulu_dfw_gateway_subnetb_id"

aws ec2 create-tags --resources $zulu_dfw_gateway_subnetb_id \
                    --tags Key=Name,Value=Zulu-Dallas-GatewaySubnetB \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet A
zulu_dfw_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                     --cidr-block $zulu_dfw_subnet_endpointa_cidr \
                                                     --availability-zone us-east-2a \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_endpoint_subneta_id=$zulu_dfw_endpoint_subneta_id"

aws ec2 create-tags --resources $zulu_dfw_endpoint_subneta_id \
                    --tags Key=Name,Value=Zulu-Dallas-EndpointSubnetA \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet B
zulu_dfw_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $zulu_dfw_vpc_id \
                                                     --cidr-block $zulu_dfw_subnet_endpointb_cidr \
                                                     --availability-zone us-east-2b \
                                                     --query 'Subnet.SubnetId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_endpoint_subnetb_id=$zulu_dfw_endpoint_subnetb_id"

aws ec2 create-tags --resources $zulu_dfw_endpoint_subnetb_id \
                    --tags Key=Name,Value=Zulu-Dallas-EndpointSubnetB \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create CiscoCSR Security Group
zulu_dfw_csr_sg_id=$(aws ec2 create-security-group --group-name Zulu-Dallas-CiscoCSR-InstanceSecurityGroup \
                                                   --description Zulu-Dallas-CiscoCSR-InstanceSecurityGroup \
                                                   --vpc-id $zulu_dfw_vpc_id \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_csr_sg_id=$zulu_dfw_csr_sg_id"

aws ec2 create-tags --resources $zulu_dfw_csr_sg_id \
                    --tags Key=Name,Value=Zulu-Dallas-CiscoCSR-InstanceSecurityGroup \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Utility,Value=CiscoCSR \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_csr_sg_id \
                                         --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"VPC (All)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_csr_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_csr_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create CiscoCSR EIP
zulu_dfw_csr_eipa=$(aws ec2 allocate-address --domain vpc \
                                             --query 'AllocationId' \
                                             --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_csr_eipa=$zulu_dfw_csr_eipa"

zulu_dfw_csr_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $zulu_dfw_csr_eipa \
                                                              --query 'Addresses[0].PublicIp' \
                                                              --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_csr_instancea_public_ip=$zulu_dfw_csr_instancea_public_ip"

aws ec2 create-tags --resources $zulu_dfw_csr_eipa \
                    --tags Key=Name,Value=Zulu-Dallas-CiscoCSR-EIPA \
                           Key=Hostname,Value=zuldfwccsr01a \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Utility,Value=CiscoCSR \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create CiscoCSR Public Domain Name
tmpfile=$tmpdir/zulu-dfw-csra-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zuldfwccsr01a.$zulu_dfw_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_dfw_csr_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "csra.$zulu_dfw_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "zuldfwccsr01a.$zulu_dfw_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_dfw_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

# Create CiscoCSR Instance
zulu_dfw_csr_instancea_id=$(aws ec2 run-instances --image-id $ohio_csr_ami_id \
                                                  --instance-type t3.medium \
                                                  --iam-instance-profile Name=ManagedInstance \
                                                  --key-name administrator \
                                                  --network-interfaces "AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=Zulu-Dallas-CiscoCSR-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_dfw_csr_sg_id],SubnetId=$zulu_dfw_public_subneta_id" \
                                                  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Dallas-CiscoCSR-InstanceA},{Key=Hostname,Value=zuldfwccsr01a},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Utility,Value=CiscoCSR},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                  --query 'Instances[0].InstanceId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_csr_instancea_id=$zulu_dfw_csr_instancea_id"

aws ec2 modify-instance-attribute --instance-id $zulu_dfw_csr_instancea_id \
                                  --no-source-dest-check \
                                  --profile $profile --region us-east-2 --output text

zulu_dfw_csr_instancea_eni_id=$(aws ec2 describe-instances --instance-ids $zulu_dfw_csr_instancea_id \
                                                           --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_csr_instancea_eni_id=$zulu_dfw_csr_instancea_eni_id"

zulu_dfw_csr_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_dfw_csr_instancea_id \
                                                               --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_csr_instancea_private_ip=$zulu_dfw_csr_instancea_private_ip"

# Create CiscoCSR Private Domain Name
tmpfile=$tmpdir/zulu-dfw-csra-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "zuldfwccsr01a.$zulu_dfw_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$zulu_dfw_csr_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "csra.$zulu_dfw_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "zuldfwccsr01a.$zulu_dfw_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $zulu_dfw_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $zulu_dfw_csr_instancea_id --allocation-id $zulu_dfw_csr_eipa \
                          --profile $profile --region us-east-2 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
zulu_dfw_public_rtb_id=$(aws ec2 create-route-table --vpc-id $zulu_dfw_vpc_id \
                                                    --query 'RouteTable.RouteTableId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_public_rtb_id=$zulu_dfw_public_rtb_id"

aws ec2 create-tags --resources $zulu_dfw_public_rtb_id \
                    --tags Key=Name,Value=Zulu-Dallas-PublicRouteTable \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_dfw_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $zulu_dfw_igw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_dfw_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --network-interface-id $zulu_dfw_csr_instancea_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $zulu_dfw_public_rtb_id --subnet-id $zulu_dfw_public_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_dfw_public_rtb_id --subnet-id $zulu_dfw_public_subnetb_id \
                              --profile $profile --region us-east-2 --output text

# Create NAT Security Group
zulu_dfw_nat_sg_id=$(aws ec2 create-security-group --group-name Zulu-Dallas-NAT-InstanceSecurityGroup \
                                                   --description Zulu-Dallas-NAT-InstanceSecurityGroup \
                                                   --vpc-id $zulu_dfw_vpc_id \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_nat_sg_id=$zulu_dfw_nat_sg_id"

aws ec2 create-tags --resources $zulu_dfw_nat_sg_id \
                    --tags Key=Name,Value=Zulu-Dallas-NAT-InstanceSecurityGroup \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Utility,Value=NAT \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_nat_sg_id \
                                         --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"VPC (All)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create NAT Instance
zulu_dfw_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                 --instance-type t3a.nano \
                                                 --iam-instance-profile Name=ManagedInstance \
                                                 --key-name administrator \
                                                 --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=Zulu-Dallas-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$zulu_dfw_nat_sg_id],SubnetId=$zulu_dfw_public_subneta_id" \
                                                 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Zulu-Dallas-NAT-Instance},{Key=Hostname,Value=zuldfwcnat01a},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                 --query 'Instances[0].InstanceId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_nat_instance_id=$zulu_dfw_nat_instance_id"

aws ec2 modify-instance-attribute --instance-id $zulu_dfw_nat_instance_id \
                                  --no-source-dest-check \
                                  --profile $profile --region us-east-2 --output text

zulu_dfw_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $zulu_dfw_nat_instance_id \
                                                          --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_nat_instance_eni_id=$zulu_dfw_nat_instance_eni_id"

zulu_dfw_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $zulu_dfw_nat_instance_id \
                                                              --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                              --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_nat_instance_private_ip=$zulu_dfw_nat_instance_private_ip"

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
zulu_dfw_private_rtba_id=$(aws ec2 create-route-table --vpc-id $zulu_dfw_vpc_id \
                                                      --query 'RouteTable.RouteTableId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_private_rtba_id=$zulu_dfw_private_rtba_id"

aws ec2 create-tags --resources $zulu_dfw_private_rtba_id \
                    --tags Key=Name,Value=Zulu-Dallas-PrivateRouteTableA \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_dfw_private_rtba_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $zulu_dfw_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_dfw_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --network-interface-id $zulu_dfw_csr_instancea_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtba_id --subnet-id $zulu_dfw_private_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtba_id --subnet-id $zulu_dfw_management_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtba_id --subnet-id $zulu_dfw_gateway_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtba_id --subnet-id $zulu_dfw_endpoint_subneta_id \
                              --profile $profile --region us-east-2 --output text

zulu_dfw_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $zulu_dfw_vpc_id \
                                                      --query 'RouteTable.RouteTableId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_private_rtbb_id=$zulu_dfw_private_rtbb_id"

aws ec2 create-tags --resources $zulu_dfw_private_rtbb_id \
                    --tags Key=Name,Value=Zulu-Dallas-PrivateRouteTableB \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_dfw_private_rtbb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $zulu_dfw_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_dfw_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --network-interface-id $zulu_dfw_csr_instancea_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtbb_id --subnet-id $zulu_dfw_private_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtbb_id --subnet-id $zulu_dfw_management_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtbb_id --subnet-id $zulu_dfw_gateway_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $zulu_dfw_private_rtbb_id --subnet-id $zulu_dfw_endpoint_subnetb_id \
                              --profile $profile --region us-east-2 --output text

# Create VPC Endpoint Security Group
zulu_dfw_vpce_sg_id=$(aws ec2 create-security-group --group-name Zulu-Dallas-VPCEndpointSecurityGroup \
                                                    --description Zulu-Dallas-VPCEndpointSecurityGroup \
                                                    --vpc-id $zulu_dfw_vpc_id \
                                                    --query 'GroupId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_vpce_sg_id=$zulu_dfw_vpce_sg_id"

aws ec2 create-tags --resources $zulu_dfw_vpce_sg_id \
                    --tags Key=Name,Value=Zulu-Dallas-VPCEndpointSecurityGroup \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $zulu_dfw_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$zulu_dfw_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create VPC Endpoints for SSM and SSMMessages
zulu_dfw_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $zulu_dfw_vpc_id \
                                                   --vpc-endpoint-type Interface \
                                                   --service-name com.amazonaws.us-east-2.ssm \
                                                   --private-dns-enabled \
                                                   --security-group-ids $zulu_dfw_vpce_sg_id \
                                                   --subnet-ids $zulu_dfw_endpoint_subneta_id $zulu_dfw_endpoint_subnetb_id \
                                                   --client-token $(date +%s) \
                                                   --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Zulu-Dallas-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                   --query 'VpcEndpoint.VpcEndpointId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_ssm_vpce_id=$zulu_dfw_ssm_vpce_id"

zulu_dfw_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $zulu_dfw_vpc_id \
                                                    --vpc-endpoint-type Interface \
                                                    --service-name com.amazonaws.us-east-2.ssmmessages \
                                                    --private-dns-enabled \
                                                    --security-group-ids $zulu_dfw_vpce_sg_id \
                                                    --subnet-ids $zulu_dfw_endpoint_subneta_id $zulu_dfw_endpoint_subnetb_id \
                                                    --client-token $(date +%s) \
                                                    --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=Zulu-Dallas-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                    --query 'VpcEndpoint.VpcEndpointId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "zulu_dfw_ssmm_vpce_id=$zulu_dfw_ssmm_vpce_id"


## CaMeLz SantaBarbara VPC ###############################################################################################
echo "management_account_id=$management_account_id"

profile=$management_profile

# Create VPC
cml_sba_vpc_id=$(aws ec2 create-vpc --cidr-block $cml_sba_vpc_cidr \
                                    --query 'Vpc.VpcId' \
                                    --profile $profile --region us-east-2 --output text)
echo "cml_sba_vpc_id=$cml_sba_vpc_id"

aws ec2 create-tags --resources $cml_sba_vpc_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-VPC \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $cml_sba_vpc_id \
                             --enable-dns-support \
                             --profile $profile --region us-east-2 --output text

aws ec2 modify-vpc-attribute --vpc-id $cml_sba_vpc_id \
                             --enable-dns-hostnames \
                             --profile $profile --region us-east-2 --output text

# Create VPC Flow Log
aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/FlowLog/CaMeLz/SantaBarbara" \
                          --profile $profile --region us-east-2 --output text

aws ec2 create-flow-logs --resource-type VPC --resource-ids $cml_sba_vpc_id \
                         --traffic-type ALL \
                         --log-destination-type cloud-watch-logs \
                         --log-destination "arn:aws:logs:us-east-2:$management_account_id:log-group:/$company_name_lc/$system_name_lc/FlowLog/CaMeLz/SantaBarbara" \
                         --deliver-logs-permission-arn "arn:aws:iam::$management_account_id:role/FlowLog" \
                         --profile $profile --region us-east-2 --output text

# Create Internet Gateway & Attach
cml_sba_igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "cml_sba_igw_id=$cml_sba_igw_id"

aws ec2 create-tags --resources $cml_sba_igw_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-InternetGateway \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 attach-internet-gateway --vpc-id $cml_sba_vpc_id \
                                --internet-gateway-id $cml_sba_igw_id \
                                --profile $profile --region us-east-2 --output text

# Create Private Hosted Zone
cml_sba_private_hostedzone_id=$(aws route53 create-hosted-zone --name $cml_sba_private_domain \
                                                               --vpc VPCRegion=us-east-2,VPCId=$cml_sba_vpc_id \
                                                               --hosted-zone-config Comment="Private Zone for $cml_sba_private_domain",PrivateZone=true \
                                                               --caller-reference $(date +%s) \
                                                               --query 'HostedZone.Id' \
                                                               --profile $profile --region us-east-2 --output text | cut -f3 -d /)
echo "cml_sba_private_hostedzone_id=$cml_sba_private_hostedzone_id"

# Create DHCP Options Set
cml_sba_dopt_id=$(aws ec2 create-dhcp-options --dhcp-configurations "Key=domain-name,Values=[$cml_sba_private_domain]" \
                                                                    "Key=domain-name-servers,Values=[AmazonProvidedDNS]" \
                                              --query 'DhcpOptions.DhcpOptionsId' \
                                              --profile $profile --region us-east-2 --output text)
echo "cml_sba_dopt_id=$cml_sba_dopt_id"

aws ec2 create-tags --resources $cml_sba_dopt_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-DHCPOptions \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 associate-dhcp-options --vpc-id $cml_sba_vpc_id \
                               --dhcp-options-id $cml_sba_dopt_id \
                               --profile $profile --region us-east-2 --output text

# Create Public Subnet A
cml_sba_public_subneta_id=$(aws ec2 create-subnet --vpc-id $cml_sba_vpc_id \
                                                  --cidr-block $cml_sba_subnet_publica_cidr \
                                                  --availability-zone us-east-2a \
                                                  --query 'Subnet.SubnetId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "cml_sba_public_subneta_id=$cml_sba_public_subneta_id"

aws ec2 create-tags --resources $cml_sba_public_subneta_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-PublicSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Public Subnet B
cml_sba_public_subnetb_id=$(aws ec2 create-subnet --vpc-id $cml_sba_vpc_id \
                                                  --cidr-block $cml_sba_subnet_publicb_cidr \
                                                  --availability-zone us-east-2b \
                                                  --query 'Subnet.SubnetId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "cml_sba_public_subnetb_id=$cml_sba_public_subnetb_id"

aws ec2 create-tags --resources $cml_sba_public_subnetb_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-PublicSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Private Subnet A
cml_sba_private_subneta_id=$(aws ec2 create-subnet --vpc-id $cml_sba_vpc_id \
                                                   --cidr-block $cml_sba_subnet_privatea_cidr \
                                                   --availability-zone us-east-2a \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "cml_sba_private_subneta_id=$cml_sba_private_subneta_id"

aws ec2 create-tags --resources $cml_sba_private_subneta_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-PrivateSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Private Subnet B
cml_sba_private_subnetb_id=$(aws ec2 create-subnet --vpc-id $cml_sba_vpc_id \
                                                   --cidr-block $cml_sba_subnet_privateb_cidr \
                                                   --availability-zone us-east-2b \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "cml_sba_private_subnetb_id=$cml_sba_private_subnetb_id"

aws ec2 create-tags --resources $cml_sba_private_subnetb_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-PrivateSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet A
cml_sba_management_subneta_id=$(aws ec2 create-subnet --vpc-id $cml_sba_vpc_id \
                                                      --cidr-block $cml_sba_subnet_managementa_cidr \
                                                      --availability-zone us-east-2a \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "cml_sba_management_subneta_id=$cml_sba_management_subneta_id"

aws ec2 create-tags --resources $cml_sba_management_subneta_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-ManagementSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Management Subnet B
cml_sba_management_subnetb_id=$(aws ec2 create-subnet --vpc-id $cml_sba_vpc_id \
                                                      --cidr-block $cml_sba_subnet_managementb_cidr \
                                                      --availability-zone us-east-2b \
                                                      --query 'Subnet.SubnetId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "cml_sba_management_subnetb_id=$cml_sba_management_subnetb_id"

aws ec2 create-tags --resources $cml_sba_management_subnetb_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-ManagementSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet A
cml_sba_gateway_subneta_id=$(aws ec2 create-subnet --vpc-id $cml_sba_vpc_id \
                                                   --cidr-block $cml_sba_subnet_gatewaya_cidr \
                                                   --availability-zone us-east-2a \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "cml_sba_gateway_subneta_id=$cml_sba_gateway_subneta_id"

aws ec2 create-tags --resources $cml_sba_gateway_subneta_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-GatewaySubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Gateway Subnet B
cml_sba_gateway_subnetb_id=$(aws ec2 create-subnet --vpc-id $cml_sba_vpc_id \
                                                   --cidr-block $cml_sba_subnet_gatewayb_cidr \
                                                   --availability-zone us-east-2b \
                                                   --query 'Subnet.SubnetId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "cml_sba_gateway_subnetb_id=$cml_sba_gateway_subnetb_id"

aws ec2 create-tags --resources $cml_sba_gateway_subnetb_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-GatewaySubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet A
cml_sba_endpoint_subneta_id=$(aws ec2 create-subnet --vpc-id $cml_sba_vpc_id \
                                                    --cidr-block $cml_sba_subnet_endpointa_cidr \
                                                    --availability-zone us-east-2a \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "cml_sba_endpoint_subneta_id=$cml_sba_endpoint_subneta_id"

aws ec2 create-tags --resources $cml_sba_endpoint_subneta_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-EndpointSubnetA \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create Endpoint Subnet B
cml_sba_endpoint_subnetb_id=$(aws ec2 create-subnet --vpc-id $cml_sba_vpc_id \
                                                    --cidr-block $cml_sba_subnet_endpointb_cidr \
                                                    --availability-zone us-east-2b \
                                                    --query 'Subnet.SubnetId' \
                                                    --profile $profile --region us-east-2 --output text)
echo "cml_sba_endpoint_subnetb_id=$cml_sba_endpoint_subnetb_id"

aws ec2 create-tags --resources $cml_sba_endpoint_subnetb_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-EndpointSubnetB \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create CiscoCSR Security Group
cml_sba_csr_sg_id=$(aws ec2 create-security-group --group-name CaMeLz-SantaBarbara-CiscoCSR-InstanceSecurityGroup \
                                                  --description CaMeLz-SantaBarbara-CiscoCSR-InstanceSecurityGroup \
                                                  --vpc-id $cml_sba_vpc_id \
                                                  --query 'GroupId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "cml_sba_csr_sg_id=$cml_sba_csr_sg_id"

aws ec2 create-tags --resources $cml_sba_csr_sg_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-CiscoCSR-InstanceSecurityGroup \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Utility,Value=CiscoCSR \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $cml_sba_csr_sg_id \
                                         --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"VPC (All)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $cml_sba_csr_sg_id \
                                         --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (ICMP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $cml_sba_csr_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$mcrawford_home_public_cidr,Description=\"Home-MCrawford (SSH)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create CiscoCSR EIP
cml_sba_csr_eipa=$(aws ec2 allocate-address --domain vpc \
                                            --query 'AllocationId' \
                                            --profile $profile --region us-east-2 --output text)
echo "cml_sba_csr_eipa=$cml_sba_csr_eipa"

cml_sba_csr_instancea_public_ip=$(aws ec2 describe-addresses --allocation-ids $cml_sba_csr_eipa \
                                                             --query 'Addresses[0].PublicIp' \
                                                             --profile $profile --region us-east-2 --output text)
echo "cml_sba_csr_instancea_public_ip=$cml_sba_csr_instancea_public_ip"

aws ec2 create-tags --resources $cml_sba_csr_eipa \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-CiscoCSR-EIPA \
                           Key=Hostname,Value=cmlsbaccsr01a \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Utility,Value=CiscoCSR \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Create CiscoCSR Public Domain Name
tmpfile=$tmpdir/cml-sba-csra-public-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlsbaccsr01a.$cml_sba_public_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$cml_sba_csr_instancea_public_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "csra.$cml_sba_public_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlsbaccsr01a.$cml_sba_public_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $cml_sba_public_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

# Create CiscoCSR Instance
cml_sba_csr_instancea_id=$(aws ec2 run-instances --image-id $ohio_csr_ami_id \
                                                 --instance-type t3.medium \
                                                 --iam-instance-profile Name=ManagedInstance \
                                                 --key-name administrator \
                                                 --network-interfaces "AssociatePublicIpAddress=false,DeleteOnTermination=true,Description=CaMeLz-SantaBarbara-CiscoCSR-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$cml_sba_csr_sg_id],SubnetId=$cml_sba_public_subneta_id" \
                                                 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=CaMeLz-SantaBarbara-CiscoCSR-InstanceA},{Key=Hostname,Value=cmlsbaccsr01a},{Key=Company,Value=CaMeLz},{Key=Location,Value=SantaBarbara},{Key=Utility,Value=CiscoCSR},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                 --query 'Instances[0].InstanceId' \
                                                 --profile $profile --region us-east-2 --output text)
echo "cml_sba_csr_instancea_id=$cml_sba_csr_instancea_id"

aws ec2 modify-instance-attribute --instance-id $cml_sba_csr_instancea_id \
                                  --no-source-dest-check \
                                  --profile $profile --region us-east-2 --output text

cml_sba_csr_instancea_eni_id=$(aws ec2 describe-instances --instance-ids $cml_sba_csr_instancea_id \
                                                          --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "cml_sba_csr_instancea_eni_id=$cml_sba_csr_instancea_eni_id"

cml_sba_csr_instancea_private_ip=$(aws ec2 describe-instances --instance-ids $cml_sba_csr_instancea_id \
                                                              --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                              --profile $profile --region us-east-2 --output text)
echo "cml_sba_csr_instancea_private_ip=$cml_sba_csr_instancea_private_ip"

# Create CiscoCSR Private Domain Name
tmpfile=$tmpdir/cml-sba-csra-private-$$.json
cat > $tmpfile << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "cmlsbaccsr01a.$cml_sba_private_domain",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$cml_sba_csr_instancea_private_ip"}]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "csra.$cml_sba_private_domain",
      "Type": "CNAME",
      "TTL": 86400,
      "ResourceRecords": [{"Value": "cmlsbaccsr01a.$cml_sba_private_domain"}]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $cml_sba_private_hostedzone_id \
                                        --change-batch file://$tmpfile \
                                        --profile $profile --region us-east-2 --output text

aws ec2 associate-address --instance-id $cml_sba_csr_instancea_id --allocation-id $cml_sba_csr_eipa \
                          --profile $profile --region us-east-2 --output text

# Create Public Route Table, Default Route and Associate with Public Subnets
cml_sba_public_rtb_id=$(aws ec2 create-route-table --vpc-id $cml_sba_vpc_id \
                                                   --query 'RouteTable.RouteTableId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "cml_sba_public_rtb_id=$cml_sba_public_rtb_id"

aws ec2 create-tags --resources $cml_sba_public_rtb_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-PublicRouteTable \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $cml_sba_public_rtb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --gateway-id $cml_sba_igw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $cml_sba_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --network-interface-id $cml_sba_csr_instancea_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $cml_sba_public_rtb_id --subnet-id $cml_sba_public_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $cml_sba_public_rtb_id --subnet-id $cml_sba_public_subnetb_id \
                              --profile $profile --region us-east-2 --output text

# Create NAT Security Group
cml_sba_nat_sg_id=$(aws ec2 create-security-group --group-name CaMeLz-SantaBarbara-NAT-InstanceSecurityGroup \
                                                  --description CaMeLz-SantaBarbara-NAT-InstanceSecurityGroup \
                                                  --vpc-id $cml_sba_vpc_id \
                                                  --query 'GroupId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "cml_sba_nat_sg_id=$cml_sba_nat_sg_id"

aws ec2 create-tags --resources $cml_sba_nat_sg_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-NAT-InstanceSecurityGroup \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Utility,Value=NAT \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $cml_sba_nat_sg_id \
                                         --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"VPC (All)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create NAT Instance
cml_sba_nat_instance_id=$(aws ec2 run-instances --image-id $ohio_nat_ami_id \
                                                --instance-type t3a.nano \
                                                --iam-instance-profile Name=ManagedInstance \
                                                --key-name administrator \
                                                --network-interfaces "AssociatePublicIpAddress=true,DeleteOnTermination=true,Description=CaMeLz-SantaBarbara-NAT-NetworkInterfaceA-eth0,DeviceIndex=0,Groups=[$cml_sba_nat_sg_id],SubnetId=$cml_sba_public_subneta_id" \
                                                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=CaMeLz-SantaBarbara-NAT-Instance},{Key=Hostname,Value=cmlsbacnat01a},{Key=Company,Value=CaMeLz},{Key=Location,Value=SantaBarbara},{Key=Utility,Value=NAT},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                --query 'Instances[0].InstanceId' \
                                                --profile $profile --region us-east-2 --output text)
echo "cml_sba_nat_instance_id=$cml_sba_nat_instance_id"

aws ec2 modify-instance-attribute --instance-id $cml_sba_nat_instance_id \
                                  --no-source-dest-check \
                                  --profile $profile --region us-east-2 --output text

cml_sba_nat_instance_eni_id=$(aws ec2 describe-instances --instance-ids $cml_sba_nat_instance_id \
                                                         --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
                                                         --profile $profile --region us-east-2 --output text)
echo "cml_sba_nat_instance_eni_id=$cml_sba_nat_instance_eni_id"

cml_sba_nat_instance_private_ip=$(aws ec2 describe-instances --instance-ids $cml_sba_nat_instance_id \
                                                             --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                                                             --profile $profile --region us-east-2 --output text)
echo "cml_sba_nat_instance_private_ip=$cml_sba_nat_instance_private_ip"

# Create Private Route Table for Availability Zone A, Default Route and Associate with Private Subnets
cml_sba_private_rtba_id=$(aws ec2 create-route-table --vpc-id $cml_sba_vpc_id \
                                                     --query 'RouteTable.RouteTableId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "cml_sba_private_rtba_id=$cml_sba_private_rtba_id"

aws ec2 create-tags --resources $cml_sba_private_rtba_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-PrivateRouteTableA \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $cml_sba_private_rtba_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $cml_sba_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $cml_sba_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --network-interface-id $cml_sba_csr_instancea_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $cml_sba_private_rtba_id --subnet-id $cml_sba_private_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $cml_sba_private_rtba_id --subnet-id $cml_sba_management_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $cml_sba_private_rtba_id --subnet-id $cml_sba_gateway_subneta_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $cml_sba_private_rtba_id --subnet-id $cml_sba_endpoint_subneta_id \
                              --profile $profile --region us-east-2 --output text

cml_sba_private_rtbb_id=$(aws ec2 create-route-table --vpc-id $cml_sba_vpc_id \
                                                     --query 'RouteTable.RouteTableId' \
                                                     --profile $profile --region us-east-2 --output text)
echo "cml_sba_private_rtbb_id=$cml_sba_private_rtbb_id"

aws ec2 create-tags --resources $cml_sba_private_rtbb_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-PrivateRouteTableB \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $cml_sba_private_rtbb_id \
                     --destination-cidr-block '0.0.0.0/0' \
                     --network-interface-id $cml_sba_nat_instance_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $cml_sba_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --network-interface-id $cml_sba_csr_instancea_eni_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 associate-route-table --route-table-id $cml_sba_private_rtbb_id --subnet-id $cml_sba_private_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $cml_sba_private_rtbb_id --subnet-id $cml_sba_management_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $cml_sba_private_rtbb_id --subnet-id $cml_sba_gateway_subnetb_id \
                              --profile $profile --region us-east-2 --output text
aws ec2 associate-route-table --route-table-id $cml_sba_private_rtbb_id --subnet-id $cml_sba_endpoint_subnetb_id \
                              --profile $profile --region us-east-2 --output text

# Create VPC Endpoint Security Group
cml_sba_vpce_sg_id=$(aws ec2 create-security-group --group-name CaMeLz-SantaBarbara-VPCEndpointSecurityGroup \
                                                   --description CaMeLz-SantaBarbara-VPCEndpointSecurityGroup \
                                                   --vpc-id $cml_sba_vpc_id \
                                                   --query 'GroupId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "cml_sba_vpce_sg_id=$cml_sba_vpce_sg_id"

aws ec2 create-tags --resources $cml_sba_vpce_sg_id \
                    --tags Key=Name,Value=CaMeLz-SantaBarbara-VPCEndpointSecurityGroup \
                           Key=Company,Value=CaMeLz \
                           Key=Location,Value=SantaBarbara \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $cml_sba_vpce_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"VPC (All TCP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $cml_sba_vpce_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=0,ToPort=65535,IpRanges=[{CidrIp=$cml_sba_vpc_cidr,Description=\"VPC (All UDP)\"}]" \
                                         --profile $profile --region us-east-2 --output text

# Create VPC Endpoints for SSM and SSMMessages
cml_sba_ssm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $cml_sba_vpc_id \
                                                  --vpc-endpoint-type Interface \
                                                  --service-name com.amazonaws.us-east-2.ssm \
                                                  --private-dns-enabled \
                                                  --security-group-ids $cml_sba_vpce_sg_id \
                                                  --subnet-ids $cml_sba_endpoint_subneta_id $cml_sba_endpoint_subnetb_id \
                                                  --client-token $(date +%s) \
                                                  --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=CaMeLz-SantaBarbara-SSMVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                  --query 'VpcEndpoint.VpcEndpointId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "cml_sba_ssm_vpce_id=$cml_sba_ssm_vpce_id"

cml_sba_ssmm_vpce_id=$(aws ec2 create-vpc-endpoint --vpc-id $cml_sba_vpc_id \
                                                   --vpc-endpoint-type Interface \
                                                   --service-name com.amazonaws.us-east-2.ssmmessages \
                                                   --private-dns-enabled \
                                                   --security-group-ids $cml_sba_vpce_sg_id \
                                                   --subnet-ids $cml_sba_endpoint_subneta_id $cml_sba_endpoint_subnetb_id \
                                                   --client-token $(date +%s) \
                                                   --tag-specifications --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=CaMeLz-SantaBarbara-SSMMessagesVpcEndpoint},{Key=Company,Value=CaMeLz},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                   --query 'VpcEndpoint.VpcEndpointId' \
                                                   --profile $profile --region us-east-2 --output text)
echo "cml_sba_ssmm_vpce_id=$cml_sba_ssmm_vpce_id"
