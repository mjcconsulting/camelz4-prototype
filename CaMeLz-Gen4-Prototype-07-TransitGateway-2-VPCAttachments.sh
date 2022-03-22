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
## Transit Gateway VPC Attachments ####################################################################################
#######################################################################################################################

## Global Transit Gateway VPC Attachments #############################################################################

# Attach the Global Core VPC to the Global Core TransitGateway (direct)
profile=$core_profile

global_core_tgw_core_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $global_core_tgw_id \
                                                                                       --vpc-id $global_core_vpc_id \
                                                                                       --subnet-ids $global_core_gateway_subneta_id $global_core_gateway_subnetb_id $global_core_gateway_subnetc_id \
                                                                                       --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                       --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Core-CoreVpcTransitGatewayAttachment},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                       --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                       --profile $profile --region us-east-1 --output text)
echo "global_core_tgw_core_vpc_attachment_id=$global_core_tgw_core_vpc_attachment_id"


# Attach the Global Management VPC to the Global Core TransitGateway (via shared)
profile=$management_profile

global_core_tgw_management_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $global_core_tgw_id \
                                                                                             --vpc-id $global_management_vpc_id \
                                                                                             --subnet-ids $global_management_gateway_subneta_id $global_management_gateway_subnetb_id $global_management_gateway_subnetc_id \
                                                                                             --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                             --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Management-ManagementVpcTransitGatewayAttachment},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                             --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                             --profile $profile --region us-east-1 --output text)
echo "global_core_tgw_management_vpc_attachment_id=$global_core_tgw_management_vpc_attachment_id"

# We also need to tag the Attachment a second time once it shows up in the Core Account
profile=$core_profile

aws ec2 create-tags --resources $global_core_tgw_management_vpc_attachment_id \
                    --tags Key=Name,Value=Core-ManagementVpcTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-1 --output text


# Attach the Global Log VPC to the Global Core TransitGateway (via shared)
profile=$log_profile

global_core_tgw_log_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $global_core_tgw_id \
                                                                                      --vpc-id $global_log_vpc_id \
                                                                                      --subnet-ids $global_log_gateway_subneta_id $global_log_gateway_subnetb_id $global_log_gateway_subnetc_id \
                                                                                      --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                      --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Log-LogVpcTransitGatewayAttachment},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                      --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                      --profile $profile --region us-east-1 --output text)
echo "global_core_tgw_log_vpc_attachment_id=$global_core_tgw_log_vpc_attachment_id"

# We also need to tag the Attachment a second time once it shows up in the Core Account
profile=$core_profile

aws ec2 create-tags --resources $global_core_tgw_log_vpc_attachment_id \
                    --tags Key=Name,Value=Core-LogVpcTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value=CaMeLz-POC-4 \
                    --profile $profile --region us-east-1 --output text


## Ohio Transit Gateway VPC Attachments ###############################################################################

# Attach the Ohio Core VPC to the Ohio Core TransitGateway (direct)
profile=$core_profile

ohio_core_tgw_core_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $ohio_core_tgw_id \
                                                                                     --vpc-id $ohio_core_vpc_id \
                                                                                     --subnet-ids $ohio_core_gateway_subneta_id $ohio_core_gateway_subnetb_id $ohio_core_gateway_subnetc_id \
                                                                                     --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                     --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Core-CoreVpcTransitGatewayAttachment},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                     --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_core_vpc_attachment_id=$ohio_core_tgw_core_vpc_attachment_id"


# Attach the Ohio Management VPC to the Ohio Core TransitGateway (via shared)
profile=$management_profile

ohio_core_tgw_management_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $ohio_core_tgw_id \
                                                                                           --vpc-id $ohio_management_vpc_id \
                                                                                           --subnet-ids $ohio_management_gateway_subneta_id $ohio_management_gateway_subnetb_id $ohio_management_gateway_subnetc_id \
                                                                                           --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                           --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Management-ManagementVpcTransitGatewayAttachment},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                           --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                           --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_management_vpc_attachment_id=$ohio_core_tgw_management_vpc_attachment_id"

# We also need to tag the Attachment a second time once it shows up in the Core Account
profile=$core_profile

aws ec2 create-tags --resources $ohio_core_tgw_management_vpc_attachment_id \
                    --tags Key=Name,Value=Core-ManagementVpcTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value=CaMeLz-POC-4 \
                    --profile $profile --region us-east-2 --output text


# Attach the Ohio Log VPC to the Ohio Core TransitGateway (via shared)
profile=$log_profile

ohio_core_tgw_log_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $ohio_core_tgw_id \
                                                                                    --vpc-id $ohio_log_vpc_id \
                                                                                    --subnet-ids $ohio_log_gateway_subneta_id $ohio_log_gateway_subnetb_id $ohio_log_gateway_subnetc_id \
                                                                                    --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                    --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Log-LogVpcTransitGatewayAttachment},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                    --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                    --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_log_vpc_attachment_id=$ohio_core_tgw_log_vpc_attachment_id"

# We also need to tag the Attachment a second time once it shows up in the Core Account
profile=$core_profile

aws ec2 create-tags --resources $ohio_core_tgw_log_vpc_attachment_id \
                    --tags Key=Name,Value=Core-LogVpcTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value=CaMeLz-POC-4 \
                    --profile $profile --region us-east-2 --output text


# Attach the Alfa Ohio Production VPC to the Ohio Core TransitGateway (via shared)
profile=$production_profile

ohio_core_tgw_alfa_production_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $ohio_core_tgw_id \
                                                                                                --vpc-id $alfa_ohio_production_vpc_id \
                                                                                                --subnet-ids $alfa_ohio_production_gateway_subneta_id $alfa_ohio_production_gateway_subnetb_id $alfa_ohio_production_gateway_subnetc_id \
                                                                                                --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                                --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Alfa-Production-AlfaProductionVpcTransitGatewayAttachment},{Key=Company,Value=Alfa},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                                --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                                --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_alfa_production_vpc_attachment_id=$ohio_core_tgw_alfa_production_vpc_attachment_id"

# We also need to tag the Attachment a second time once it shows up in the Core Account
profile=$core_profile

aws ec2 create-tags --resources $ohio_core_tgw_alfa_production_vpc_attachment_id \
                    --tags Key=Name,Value=Core-AlfaProductionVpcTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value=CaMeLz-POC-4 \
                    --profile $profile --region us-east-2 --output text


# Attach the Alfa Ohio Testing VPC to the Ohio Core TransitGateway (via shared)
profile=$testing_profile

ohio_core_tgw_alfa_testing_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $ohio_core_tgw_id \
                                                                                             --vpc-id $alfa_ohio_testing_vpc_id \
                                                                                             --subnet-ids $alfa_ohio_testing_gateway_subneta_id $alfa_ohio_testing_gateway_subnetb_id $alfa_ohio_testing_gateway_subnetc_id \
                                                                                             --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                             --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Alfa-Testing-AlfaTestingVpcTransitGatewayAttachment},{Key=Company,Value=Alfa},{Key=Environment,Value=Testing},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                             --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                             --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_alfa_testing_vpc_attachment_id=$ohio_core_tgw_alfa_testing_vpc_attachment_id"

# We also need to tag the Attachment a second time once it shows up in the Core Account
profile=$core_profile

aws ec2 create-tags --resources $ohio_core_tgw_alfa_testing_vpc_attachment_id \
                    --tags Key=Name,Value=Core-AlfaTestingVpcTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value=CaMeLz-POC-4 \
                    --profile $profile --region us-east-2 --output text


# Attach the Alfa Ohio Development VPC to the Ohio Core TransitGateway (via shared)
profile=$development_profile

ohio_core_tgw_alfa_development_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $ohio_core_tgw_id \
                                                                                                 --vpc-id $alfa_ohio_development_vpc_id \
                                                                                                 --subnet-ids $alfa_ohio_development_gateway_subneta_id $alfa_ohio_development_gateway_subnetb_id $alfa_ohio_development_gateway_subnetc_id \
                                                                                                 --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                                 --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Alfa-Development-AlfaDevelopmentVpcTransitGatewayAttachment},{Key=Company,Value=Alfa},{Key=Environment,Value=Development},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                                 --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                                 --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_alfa_development_vpc_attachment_id=$ohio_core_tgw_alfa_development_vpc_attachment_id"

# We also need to tag the Attachment a second time once it shows up in the Core Account
profile=$core_profile

aws ec2 create-tags --resources $ohio_core_tgw_alfa_development_vpc_attachment_id \
                    --tags Key=Name,Value=Core-AlfaDevelopmentVpcTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value=CaMeLz-POC-4 \
                    --profile $profile --region us-east-2 --output text


# Attach the Zulu Ohio Production VPC to the Ohio Core TransitGateway (via shared)
profile=$production_profile

ohio_core_tgw_zulu_production_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $ohio_core_tgw_id \
                                                                                                --vpc-id $zulu_ohio_production_vpc_id \
                                                                                                --subnet-ids $zulu_ohio_production_gateway_subneta_id $zulu_ohio_production_gateway_subnetb_id $zulu_ohio_production_gateway_subnetc_id \
                                                                                                --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                                --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Zulu-Production-ZuluProductionVpcTransitGatewayAttachment},{Key=Company,Value=Zulu},{Key=Environment,Value=Production},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                                --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                                --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_zulu_production_vpc_attachment_id=$ohio_core_tgw_zulu_production_vpc_attachment_id"

# We also need to tag the Attachment a second time once it shows up in the Core Account
profile=$core_profile

aws ec2 create-tags --resources $ohio_core_tgw_zulu_production_vpc_attachment_id \
                    --tags Key=Name,Value=Core-ZuluProductionVpcTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value=CaMeLz-POC-4 \
                    --profile $profile --region us-east-2 --output text


# Attach the Zulu Ohio Development VPC to the Ohio Core TransitGateway (via shared)
profile=$development_profile

ohio_core_tgw_zulu_development_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $ohio_core_tgw_id \
                                                                                                 --vpc-id $zulu_ohio_development_vpc_id \
                                                                                                 --subnet-ids $zulu_ohio_development_gateway_subneta_id $zulu_ohio_development_gateway_subnetb_id $zulu_ohio_development_gateway_subnetc_id \
                                                                                                 --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                                 --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Zulu-Development-ZuluDevelopmentVpcTransitGatewayAttachment},{Key=Company,Value=Zulu},{Key=Environment,Value=Development},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                                 --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                                 --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_zulu_development_vpc_attachment_id=$ohio_core_tgw_zulu_development_vpc_attachment_id"

# We also need to tag the Attachment a second time once it shows up in the Core Account
profile=$core_profile

aws ec2 create-tags --resources $ohio_core_tgw_zulu_development_vpc_attachment_id \
                    --tags Key=Name,Value=Core-ZuluDevelopmentVpcTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value=CaMeLz-POC-4 \
                    --profile $profile --region us-east-2 --output text


## Ireland Transit Gateway VPC Attachments ############################################################################

# Attach the Ireland Core VPC to the Ireland Core TransitGateway (direct)
profile=$core_profile

ireland_core_tgw_core_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $ireland_core_tgw_id \
                                                                                        --vpc-id $ireland_core_vpc_id \
                                                                                        --subnet-ids $ireland_core_gateway_subneta_id $ireland_core_gateway_subnetb_id $ireland_core_gateway_subnetc_id \
                                                                                        --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                        --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Core-CoreVpcTransitGatewayAttachment},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                        --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_core_tgw_core_vpc_attachment_id=$ireland_core_tgw_core_vpc_attachment_id"


# Attach the Ireland Management VPC to the Ireland Core TransitGateway (via shared)
profile=$management_profile

ireland_core_tgw_management_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $ireland_core_tgw_id \
                                                                                              --vpc-id $ireland_management_vpc_id \
                                                                                              --subnet-ids $ireland_management_gateway_subneta_id $ireland_management_gateway_subnetb_id $ireland_management_gateway_subnetc_id \
                                                                                              --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                              --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Management-ManagementVpcTransitGatewayAttachment},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Management},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                              --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                              --profile $profile --region eu-west-1 --output text)
echo "ireland_core_tgw_management_vpc_attachment_id=$ireland_core_tgw_management_vpc_attachment_id"

# We also need to tag the Attachment a second time once it shows up in the Core Account
profile=$core_profile

aws ec2 create-tags --resources $ireland_core_tgw_management_vpc_attachment_id \
                    --tags Key=Name,Value=Core-ManagementVpcTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value=CaMeLz-POC-4 \
                    --profile $profile --region eu-west-1 --output text


# Attach the Ireland Log VPC to the Ireland Core TransitGateway (via shared)
profile=$log_profile

ireland_core_tgw_log_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $ireland_core_tgw_id \
                                                                                       --vpc-id $ireland_log_vpc_id \
                                                                                       --subnet-ids $ireland_log_gateway_subneta_id $ireland_log_gateway_subnetb_id $ireland_log_gateway_subnetc_id \
                                                                                       --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                       --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Log-LogVpcTransitGatewayAttachment},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Log},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                       --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                       --profile $profile --region eu-west-1 --output text)
echo "ireland_core_tgw_log_vpc_attachment_id=$ireland_core_tgw_log_vpc_attachment_id"

# We also need to tag the Attachment a second time once it shows up in the Core Account
profile=$core_profile

aws ec2 create-tags --resources $ireland_core_tgw_log_vpc_attachment_id \
                    --tags Key=Name,Value=Core-LogVpcTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value=CaMeLz-POC-4 \
                    --profile $profile --region eu-west-1 --output text


# Attach the Alfa Ireland Recovery VPC to the Ireland Core TransitGateway (via shared)
profile=$recovery_profile

ireland_core_tgw_alfa_recovery_vpc_attachment_id=$(aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $ireland_core_tgw_id \
                                                                                                 --vpc-id $alfa_ireland_recovery_vpc_id \
                                                                                                 --subnet-ids $alfa_ireland_recovery_gateway_subneta_id $alfa_ireland_recovery_gateway_subnetb_id $alfa_ireland_recovery_gateway_subnetc_id \
                                                                                                 --options "DnsSupport=enable,Ipv6Support=disable" \
                                                                                                 --tag-specifications ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Alfa-Recovery-AlfaRecoveryVpcTransitGatewayAttachment},{Key=Company,Value=Alfa},{Key=Environment,Value=Recovery},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                                 --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' \
                                                                                                 --profile $profile --region eu-west-1 --output text)
echo "ireland_core_tgw_alfa_recovery_vpc_attachment_id=$ireland_core_tgw_alfa_recovery_vpc_attachment_id"

# We also need to tag the Attachment a second time once it shows up in the Core Account
profile=$core_profile

aws ec2 create-tags --resources $ireland_core_tgw_alfa_recovery_vpc_attachment_id \
                    --tags Key=Name,Value=Core-AlfaRecoveryVpcTransitGatewayAttachment \
                           Key=Company,Value=Alfa \
                           Key=Environment,Value=Core \
                           Key=Project,Value=CaMeLz-POC-4 \
                    --profile $profile --region eu-west-1 --output text
