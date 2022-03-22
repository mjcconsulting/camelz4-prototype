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
## Transit Gateway Route Tables - Default (Single) Route Table ########################################################
#######################################################################################################################

## Global Core Transit Gateway Default Route Table ####################################################################
profile=$core_profile

# Create Default Route Table
global_core_tgw_default_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $global_core_tgw_id \
                                                                            --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayDefaultRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                            --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                            --profile $profile --region us-east-1 --output text)
echo "global_core_tgw_default_rtb_id=$global_core_tgw_default_rtb_id"


## Ohio Core Transit Gateway Default Route Table ######################################################################
profile=$core_profile

# Create Default Route Table
ohio_core_tgw_default_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $ohio_core_tgw_id \
                                                                          --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayDefaultRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                          --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                          --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_default_rtb_id=$ohio_core_tgw_default_rtb_id"


## Ireland Core Transit Gateway Default Route Table ###################################################################
profile=$core_profile

# Create Default Route Table
ireland_core_tgw_default_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $ireland_core_tgw_id \
                                                                             --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayDefaultRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                             --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                             --profile $profile --region eu-west-1 --output text)
echo "ireland_core_tgw_default_rtb_id=$ireland_core_tgw_default_rtb_id"


#######################################################################################################################
## Transit Gateway Static Routes & Route Propagations - Default (Single) Route Table ##################################
#######################################################################################################################
## Note: Once we have the complexity of more Route Tables, it makes the most sense to define Route Propagations &    ##
##       Static Routes together for each Route Table.
## Note: We must create static routes between Transit Gateways Joined by Peering Connections.                        ##
##       The CaMeLz-Gen3-SubnetAllocations Spreadsheet contains the completely layout of all CIDRs, so look there for   ##
##       any new Regions.                                                                                            ##
##                                                                                                                   ##
##       Regions currently in use:                                                                                   ##
##       - Global:  10.0.0.0/12                                                                                      ##
##       - Ohio:    10.16.0.0/12                                                                                     ##
##       - Oregon:  10.32.0.0/12                                                                                     ##
##       - Ireland: 10.64.0.0/12                                                                                     ##
##                                                                                                                   ##
##       Data Centers will use:                                                                                      ##
##       - Client:  172.24.0.0/13                                                                                    ##
##                                                                                                                   ##
## Note: This prototype connects all Clients out of Ohio, so we can route the entire Client Block to Ohio's TGW.     ##
#######################################################################################################################

## Global Core Transit Gateway Default Route Table ####################################################################
profile=$core_profile

# Enable Propagations to Local Internal VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $global_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $global_core_tgw_management_vpc_attachment_id \
                                                       --profile $profile --region us-east-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $global_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $global_core_tgw_core_vpc_attachment_id \
                                                       --profile $profile --region us-east-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $global_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $global_core_tgw_log_vpc_attachment_id \
                                                       --profile $profile --region us-east-1 --output text

# Enable Propagations to Local Internal VPNs
# - Currently none

# Define Static Routes to Remote VPCs
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $global_core_tgw_default_rtb_id \
                                     --destination-cidr-block $ohio_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                     --profile $profile --region us-east-1 --output text
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $global_core_tgw_default_rtb_id \
                                     --destination-cidr-block $ireland_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region us-east-1 --output text

# Define Static Routes to Remote VPNs (Currently all VPNs terminate in Ohio)
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $global_core_tgw_default_rtb_id \
                                     --destination-cidr-block $client_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                     --profile $profile --region us-east-1 --output text


## Ohio Core Transit Gateway Default Route Table ######################################################################
profile=$core_profile

# Enable Propagations to Local Internal VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_management_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_core_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_log_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Enable Propagations to Local Alfa VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_production_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_testing_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_development_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Enable Propagations to Local Zulu VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_zulu_production_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_zulu_development_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Enable Propagations to Local Internal VPNs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_cml_sba_vpn_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Enable Propagations to Local Alfa VPNs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_lax_vpn_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_mia_vpn_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Enable Propagations to Local Zulu VPNs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_zulu_dfw_vpn_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Define Static Routes to Remote VPCs
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                     --destination-cidr-block $global_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                     --profile $profile --region us-east-2 --output text
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                     --destination-cidr-block $ireland_cidr \
                                     --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region us-east-2 --output text

# Define Static Routes to Remote VPNs
# - Currently none


## Ireland Core Transit Gateway Default Route Table ###################################################################
profile=$core_profile

# Enable Propagations to Local Internal VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_management_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_core_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_log_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text

# Enable Propagations to Local Alfa VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_default_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_alfa_recovery_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text

# Enable Propagations to Local Internal VPNs
# - Currently none

# Enable Propagations to Local Alfa VPNs
# - Currently none

# Define Static Routes to Remote VPCs
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_default_rtb_id \
                                     --destination-cidr-block $global_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region eu-west-1 --output text
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_default_rtb_id \
                                     --destination-cidr-block $ohio_cidr \
                                     --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region eu-west-1 --output text

# Define Static Routes to Remote VPNs (Currently all VPNs terminate in Ohio)
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_default_rtb_id \
                                     --destination-cidr-block $client_cidr \
                                     --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region eu-west-1 --output text


#######################################################################################################################
## Transit Gateway Route Table Associations - Default (Single) Route Table ############################################
#######################################################################################################################
## Note: This section is the only location where there's a conflict between simple and complex routing               ##
##       You can only associate a single routing table with each attachment, so you must pick one or the other       ##
#######################################################################################################################

## Global Core Transit Gateway Default Route Table Internal Associations ##############################################
profile=$core_profile

# Associate Default Route Table to Internal Peering Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_ohio_core_tgw_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-1 --output text)
if [ $current_rtb_id != $global_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                                --transit-gateway-route-table-id $global_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-1 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_ireland_core_tgw_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-1 --output text)
if [ $current_rtb_id != $global_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                                --transit-gateway-route-table-id $global_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-1 --output text
fi

# Associate Default Route Table to Internal VPC Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_management_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-1 --output text)
if [ $current_rtb_id != $global_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_management_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_management_vpc_attachment_id \
                                                --transit-gateway-route-table-id $global_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-1 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_core_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-1 --output text)
if [ $current_rtb_id != $global_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_core_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_core_vpc_attachment_id \
                                                --transit-gateway-route-table-id $global_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-1 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_log_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-1 --output text)
if [ $current_rtb_id != $global_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_log_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_log_vpc_attachment_id \
                                                --transit-gateway-route-table-id $global_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-1 --output text
fi

# Associate Default Route Table to Internal VPN Attachments
# - Note: Currently no VPNs terminate in Global


## Ohio Core Transit Gateway Default Route Table Internal Associations ################################################
profile=$core_profile

# Associate Default Route Table to Internal Peering Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_ohio_core_tgw_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

# Associate Default Route Table to Internal VPC Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_management_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_management_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_management_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_core_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_core_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_core_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_log_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_log_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_log_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

# Associate Default Route Table to Internal VPN Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_cml_sba_vpn_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_cml_sba_vpn_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_cml_sba_vpn_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

## Ohio Core Transit Gateway Default Route Table Client Associations ##################################################
profile=$core_profile

# Associate Default Route Table to Alfa VPC Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_alfa_production_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_production_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_production_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_alfa_testing_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_testing_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_testing_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_alfa_development_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_development_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_development_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

# Associate Default Route Table to Alfa VPN Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_alfa_lax_vpn_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_lax_vpn_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_lax_vpn_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_alfa_mia_vpn_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_mia_vpn_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_mia_vpn_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

# Associate Default Route Table to Zulu VPC Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_zulu_production_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_zulu_production_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_zulu_production_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_zulu_development_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_zulu_development_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_zulu_development_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

# Associate Default Route Table to Zulu VPN Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_zulu_dfw_vpn_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_zulu_dfw_vpn_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_zulu_dfw_vpn_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_default_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

## Ireland Core Transit Gateway Default Route Table Internal Associations #############################################
profile=$core_profile

# Associate Default Route Table to Internal Peering Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_ireland_core_tgw_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region eu-west-1 --output text)
if [ $current_rtb_id != $ireland_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region eu-west-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                                --transit-gateway-route-table-id $ireland_core_tgw_default_rtb_id \
                                                --profile $profile --region eu-west-1 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region eu-west-1 --output text)
if [ $current_rtb_id != $ireland_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region eu-west-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                                --transit-gateway-route-table-id $ireland_core_tgw_default_rtb_id \
                                                --profile $profile --region eu-west-1 --output text
fi

# Associate Default Route Table to Internal VPC Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ireland_core_tgw_management_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region eu-west-1 --output text)
if [ $current_rtb_id != $ireland_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_management_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region eu-west-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_management_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ireland_core_tgw_default_rtb_id \
                                                --profile $profile --region eu-west-1 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ireland_core_tgw_core_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region eu-west-1 --output text)
if [ $current_rtb_id != $ireland_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_core_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region eu-west-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_core_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ireland_core_tgw_default_rtb_id \
                                                --profile $profile --region eu-west-1 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ireland_core_tgw_log_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region eu-west-1 --output text)
if [ $current_rtb_id != $ireland_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_log_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region eu-west-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_log_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ireland_core_tgw_default_rtb_id \
                                                --profile $profile --region eu-west-1 --output text
fi

# Associate Default Route Table to Internal VPN Attachments
# - Note: Currently no VPNs terminate in Ireland


## Ireland Core Transit Gateway Default Route Table Client Associations ###############################################
profile=$core_profile

# Associate Default Route Table to Alfa VPC Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ireland_core_tgw_alfa_recovery_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region eu-west-1 --output text)
if [ $current_rtb_id != $ireland_core_tgw_default_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_alfa_recovery_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region eu-west-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_alfa_recovery_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ireland_core_tgw_default_rtb_id \
                                                --profile $profile --region eu-west-1 --output text
fi
