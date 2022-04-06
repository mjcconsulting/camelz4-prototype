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
## Transit Gateway Route Tables - Multiple Internal and Client Route Tables ###########################################
#######################################################################################################################

## Global Core Transit Gateway Internal Route Tables ##################################################################
profile=$core_profile

# Create Internal VPC Route Table
global_core_tgw_internal_vpc_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $global_core_tgw_id \
                                                                                 --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayInternalVPCRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                 --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                                 --profile $profile --region us-east-1 --output text)
echo "global_core_tgw_internal_vpc_rtb_id=$global_core_tgw_internal_vpc_rtb_id"

# Create Internal VPN Route Table
global_core_tgw_internal_vpn_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $global_core_tgw_id \
                                                                                 --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayInternalVPNRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                 --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                                 --profile $profile --region us-east-1 --output text)
echo "global_core_tgw_internal_vpn_rtb_id=$global_core_tgw_internal_vpn_rtb_id"


## Ohio Core Transit Gateway Internal Route Tables ####################################################################
profile=$core_profile

# Create Internal VPC Route Table
ohio_core_tgw_internal_vpc_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $ohio_core_tgw_id \
                                                                               --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayInternalVPCRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                               --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                               --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_internal_vpc_rtb_id=$ohio_core_tgw_internal_vpc_rtb_id"

# Create Internal VPN Route Table
ohio_core_tgw_internal_vpn_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $ohio_core_tgw_id \
                                                                               --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayInternalVPNRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                               --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                               --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_internal_vpn_rtb_id=$ohio_core_tgw_internal_vpn_rtb_id"


## Ohio Core Transit Gateway Client Route Tables ######################################################################
profile=$core_profile

# Create Alfa VPC Route Table
ohio_core_tgw_alfa_vpc_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $ohio_core_tgw_id \
                                                                           --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayAlfaVPCRouteTable},{Key=Company,Value=Alfa},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                           --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_alfa_vpc_rtb_id=$ohio_core_tgw_alfa_vpc_rtb_id"

# Create Alfa VPN Route Table
ohio_core_tgw_alfa_vpn_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $ohio_core_tgw_id \
                                                                           --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayAlfaVPNRouteTable},{Key=Company,Value=Alfa},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                           --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_alfa_vpn_rtb_id=$ohio_core_tgw_alfa_vpn_rtb_id"

# Create Zulu VPC Route Table
ohio_core_tgw_zulu_vpc_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $ohio_core_tgw_id \
                                                                           --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayZuluVPCRouteTable},{Key=Company,Value=Zulu},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                           --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_zulu_vpc_rtb_id=$ohio_core_tgw_zulu_vpc_rtb_id"

# Create Zulu VPN Route Table
ohio_core_tgw_zulu_vpn_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $ohio_core_tgw_id \
                                                                           --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayZuluVPNRouteTable},{Key=Company,Value=Zulu},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                           --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                           --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_zulu_vpn_rtb_id=$ohio_core_tgw_zulu_vpn_rtb_id"


## Ireland Core Transit Gateway Internal Route Tables #################################################################
profile=$core_profile

# Create Internal VPC Route Table
ireland_core_tgw_internal_vpc_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $ireland_core_tgw_id \
                                                                                  --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayInternalVPCRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                  --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                                  --profile $profile --region eu-west-1 --output text)
echo "ireland_core_tgw_internal_vpc_rtb_id=$ireland_core_tgw_internal_vpc_rtb_id"

# Create Internal VPN Route Table
ireland_core_tgw_internal_vpn_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $ireland_core_tgw_id \
                                                                                  --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayInternalVPNRouteTable},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                                  --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                                  --profile $profile --region eu-west-1 --output text)
echo "ireland_core_tgw_internal_vpn_rtb_id=$ireland_core_tgw_internal_vpn_rtb_id"


## Ireland Core Transit Gateway Client Route Tables #################################################################
profile=$core_profile

# Create Alfa VPC Route Table
ireland_core_tgw_alfa_vpc_rtb_id=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $ireland_core_tgw_id \
                                                                              --tag-specifications ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=Core-TransitGatewayAlfaVPCRouteTable},{Key=Company,Value=Alfa},{Key=Environment,Value=Core},{Key=Project,Value=CaMeLz-POC-4}] \
                                                                              --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' \
                                                                              --profile $profile --region eu-west-1 --output text)
echo "ireland_core_tgw_alfa_vpc_rtb_id=$ireland_core_tgw_alfa_vpc_rtb_id"


#######################################################################################################################
## Transit Gateway Static Routes & Route Propagations - Multiple Internal and Client Route Tables #####################
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

## Global Core Transit Gateway Internal VPC Route Table ###############################################################
profile=$core_profile

# Enable Propagations to Local Internal VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $global_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $global_core_tgw_management_vpc_attachment_id \
                                                       --profile $profile --region us-east-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $global_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $global_core_tgw_core_vpc_attachment_id \
                                                       --profile $profile --region us-east-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $global_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $global_core_tgw_log_vpc_attachment_id \
                                                       --profile $profile --region us-east-1 --output text

# Enable Propagations to Local Internal VPNs
# - Currently none

# Define Static Routes to Remote VPCs
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $global_core_tgw_internal_vpc_rtb_id \
                                     --destination-cidr-block $ohio_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                     --profile $profile --region us-east-1 --output text
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $global_core_tgw_internal_vpc_rtb_id \
                                     --destination-cidr-block $ireland_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region us-east-1 --output text

# Define Static Routes to Remote VPNs (Currently all VPNs terminate in Ohio)
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $global_core_tgw_internal_vpc_rtb_id \
                                     --destination-cidr-block $client_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                     --profile $profile --region us-east-1 --output text


## Global Core Transit Gateway Internal VPN Route Table ###############################################################
#  - Note: This table is not yet in use, as there are no VPNs which terminate in Global currently
profile=$core_profile

# Enable Propagations to Local Internal VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $global_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $global_core_tgw_management_vpc_attachment_id \
                                                       --profile $profile --region us-east-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $global_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $global_core_tgw_core_vpc_attachment_id \
                                                       --profile $profile --region us-east-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $global_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $global_core_tgw_log_vpc_attachment_id \
                                                       --profile $profile --region us-east-1 --output text

# Define Static Routes to Remote VPCs
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $global_core_tgw_internal_vpn_rtb_id \
                                     --destination-cidr-block $ohio_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                     --profile $profile --region us-east-1 --output text
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $global_core_tgw_internal_vpn_rtb_id \
                                     --destination-cidr-block $ireland_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region us-east-1 --output text


## Ohio Core Transit Gateway Internal VPC Route Table #################################################################
profile=$core_profile

# Enable Propagations to Local Internal VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_management_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_core_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_log_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Enable Propagations to Local Alfa VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_production_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_testing_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_development_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Enable Propagations to Local Zulu VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_zulu_production_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_zulu_development_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Enable Propagations to Local Internal VPNs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_cml_sba_vpn_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Define Static Routes to Remote VPCs
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                     --destination-cidr-block $global_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                     --profile $profile --region us-east-2 --output text
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                     --destination-cidr-block $ireland_cidr \
                                     --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region us-east-2 --output text

# Define Static Routes to Remote VPNs
# - Currently none


## Ohio Core Transit Gateway Internal VPN Route Table #################################################################
profile=$core_profile

# Enable Propagations to Local Internal VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_management_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_core_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_log_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Enable Propagations to Local Alfa VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_production_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_testing_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_development_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Enable Propagations to Local Zulu VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_zulu_production_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_zulu_development_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Define Static Routes to Remote VPCs
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ohio_core_tgw_internal_vpn_rtb_id \
                                     --destination-cidr-block $global_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                     --profile $profile --region us-east-2 --output text
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ohio_core_tgw_internal_vpn_rtb_id \
                                     --destination-cidr-block $ireland_cidr \
                                     --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region us-east-2 --output text


## Ohio Core Transit Gateway Alfa VPC Route Table #####################################################################
profile=$core_profile

# Enable Propagations to Local Internal VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_management_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_core_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_log_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Enable Propagations to Local Alfa VPCs (Optional)
if [ $alfa_allow_interenvironment_routing = 1 ]; then
  aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpc_rtb_id \
                                                         --transit-gateway-attachment-id $ohio_core_tgw_alfa_production_vpc_attachment_id \
                                                         --profile $profile --region us-east-2 --output text
  aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpc_rtb_id \
                                                         --transit-gateway-attachment-id $ohio_core_tgw_alfa_testing_vpc_attachment_id \
                                                         --profile $profile --region us-east-2 --output text
  aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpc_rtb_id \
                                                         --transit-gateway-attachment-id $ohio_core_tgw_alfa_development_vpc_attachment_id \
                                                         --profile $profile --region us-east-2 --output text
fi

# Enable Propagations to Local Internal VPNs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_cml_sba_vpn_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Enable Propagations to Local Alfa VPNs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_lax_vpn_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_mia_vpn_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Define Static Routes to Remote Internal VPCs (NOT IMPLEMENTED AT THIS TIME)
# - Note: I don't think we need this, and probably shouldn't allow it

# Define Static Routes to Remote Alfa VPCs (Optional)
if [ $alfa_allow_interenvironment_routing = 1 ]; then
  aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpc_rtb_id \
                                       --destination-cidr-block $alfa_ireland_recovery_vpc_cidr \
                                       --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                       --profile $profile --region us-east-2 --output text
fi

# Define Static Routes to Remote Internal VPNs
# - Currently none

# Define Static Routes to Remote Alfa VPNs
# - Currently none


## Ohio Core Transit Gateway Alfa VPN Route Table #####################################################################
profile=$core_profile

# Enable Propagations to Local Alfa VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_production_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_testing_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_alfa_development_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Define Static Routes to Remote Alfa VPCs
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpn_rtb_id \
                                     --destination-cidr-block $alfa_ireland_recovery_vpc_cidr \
                                     --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region us-east-2 --output text


## Ohio Core Transit Gateway Zulu VPC Route Table #####################################################################
profile=$core_profile

# Enable Propagations to Local Internal VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_zulu_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_management_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_zulu_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_core_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_zulu_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_log_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Optionally Enable Propagations to Local Zulu VPCs
if [ $zulu_allow_interenvironment_routing = 1 ]; then
  aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_zulu_vpc_rtb_id \
                                                         --transit-gateway-attachment-id $ohio_core_tgw_zulu_production_vpc_attachment_id \
                                                         --profile $profile --region us-east-2 --output text
  aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_zulu_vpc_rtb_id \
                                                         --transit-gateway-attachment-id $ohio_core_tgw_zulu_development_vpc_attachment_id \
                                                         --profile $profile --region us-east-2 --output text
fi

# Enable Propagations to Local Internal VPNs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_zulu_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_cml_sba_vpn_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Enable Propagations to Local Zulu VPNs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_zulu_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_zulu_dfw_vpn_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Define Static Routes to Remote Internal VPCs (NOT IMPLEMENTED AT THIS TIME)
# - Note: I don't think we need this, and probably shouldn't allow it

# Define Static Routes to Remote Zulu VPCs (Optional)
# - Currently none

# Define Static Routes to Remote Internal VPNs
# - Currently none

# Define Static Routes to Remote Zulu VPNs
# - Currently none


## Ohio Core Transit Gateway Zulu VPN Route Table #####################################################################
profile=$core_profile

# Enable Propagations to Local Zulu VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_zulu_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_zulu_production_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ohio_core_tgw_zulu_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ohio_core_tgw_zulu_development_vpc_attachment_id \
                                                       --profile $profile --region us-east-2 --output text

# Define Static Routes to Remote Zulu VPCs
# - Currently none


## Ireland Core Transit Gateway Internal VPC Route Table ##############################################################
profile=$core_profile

# Enable Propagations to Local Internal VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_management_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_core_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_log_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text

# Enable Propagations to Local Alfa VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_internal_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_alfa_recovery_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text

# Enable Propagations to Local Internal VPNs
# - Currently none

# Define Static Routes to Remote VPCs
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_internal_vpc_rtb_id \
                                     --destination-cidr-block $global_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region eu-west-1 --output text
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_internal_vpc_rtb_id \
                                     --destination-cidr-block $ohio_cidr \
                                     --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region eu-west-1 --output text

# Define Static Routes to Remote VPNs (Currently all VPNs terminate in Ohio)
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_internal_vpc_rtb_id \
                                     --destination-cidr-block $client_cidr \
                                     --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region eu-west-1 --output text


## Ireland Core Transit Gateway Internal VPN Route Table ##############################################################
#  - Note: This table is not yet in use, as there are no VPNs which terminate in Ireland currently
profile=$core_profile

# Enable Propagations to Local Internal VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_management_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_core_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_log_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text

# Enable Propagations to Local Alfa VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_internal_vpn_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_alfa_recovery_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text

# Define Static Routes to Remote VPCs
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_internal_vpn_rtb_id \
                                     --destination-cidr-block $global_cidr \
                                     --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region eu-west-1 --output text
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_internal_vpn_rtb_id \
                                     --destination-cidr-block $ohio_cidr \
                                     --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region eu-west-1 --output text


## Ireland Core Transit Gateway Alfa VPC Route Table ##################################################################
profile=$core_profile

# Enable Propagations to Local Internal VPCs
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_alfa_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_management_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_alfa_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_core_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text
aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_alfa_vpc_rtb_id \
                                                       --transit-gateway-attachment-id $ireland_core_tgw_log_vpc_attachment_id \
                                                       --profile $profile --region eu-west-1 --output text

# Enable Propagations to Local Alfa VPCs (Optional)
if [ $alfa_allow_interenvironment_routing = 1 ]; then
  # Currently only one VPC attachment, so no inter-VPC routes needed, even if we wanted to enable this feature
  # - This is what we would do if we did want to do this
  #aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $ireland_core_tgw_alfa_vpc_rtb_id \
  #                                                       --transit-gateway-attachment-id $ireland_core_tgw_alfa_recovery_vpc_attachment_id \
  #                                                       --profile $profile --region eu-west-1 --output text
fi

# Enable Propagations to Local Internal VPNs
# - Currently none

# Enable Propagations to Local Alfa VPNs
# - Currently none

# Define Static Routes to Remote Internal VPCs (NOT IMPLEMENTED AT THIS TIME)
# - Note: I don't think we need this, and probably shouldn't allow it

# Define Static Routes to Remote Alfa VPCs (Optional)
if [ $alfa_allow_interenvironment_routing = 1 ]; then
  aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_alfa_vpc_rtb_id \
                                       --destination-cidr-block $alfa_ohio_production_vpc_cidr \
                                       --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                       --profile $profile --region eu-west-1 --output text
  aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_alfa_vpc_rtb_id \
                                       --destination-cidr-block $alfa_ohio_testing_vpc_cidr \
                                       --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                       --profile $profile --region eu-west-1 --output text
  aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_alfa_vpc_rtb_id \
                                       --destination-cidr-block $alfa_ohio_development_vpc_cidr \
                                       --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                       --profile $profile --region eu-west-1 --output text
fi

# Define Static Routes to Remote Internal VPNs
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_alfa_vpc_rtb_id \
                                     --destination-cidr-block $cml_sba_vpc_cidr \
                                     --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region eu-west-1 --output text

# Define Static Routes to Remote Alfa VPNs
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_alfa_vpc_rtb_id \
                                     --destination-cidr-block $alfa_lax_vpc_cidr \
                                     --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region eu-west-1 --output text
aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $ireland_core_tgw_alfa_vpc_rtb_id \
                                     --destination-cidr-block $alfa_mia_vpc_cidr \
                                     --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                     --profile $profile --region eu-west-1 --output text


#######################################################################################################################
## Transit Gateway Route Table Associations - Multiple Internal and Client Route Tables ###############################
#######################################################################################################################
## Note: This section is the only location where there's a conflict between simple and complex routing               ##
##       You can only associate a single routing table with each attachment, so you must pick one or the other       ##
## Note: So, to address this conflct, we must test if the correct table is associated, and if not disassociate any   ##
##       current route table before then associating the new route table                                             ##
#######################################################################################################################

## Global Core Transit Gateway Internal Route Table Associations ######################################################
profile=$core_profile

# Associate Internal VPC Route Table to Internal Peering Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_ohio_core_tgw_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-1 --output text)
if [ $current_rtb_id != $global_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                                --transit-gateway-route-table-id $global_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region us-east-1 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_ireland_core_tgw_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-1 --output text)
if [ $current_rtb_id != $global_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                                --transit-gateway-route-table-id $global_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region us-east-1 --output text
fi

# Associate Internal VPC Route Table to Internal VPC Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_management_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-1 --output text)
if [ $current_rtb_id != $global_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_management_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_management_vpc_attachment_id \
                                                --transit-gateway-route-table-id $global_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region us-east-1 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_core_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-1 --output text)
if [ $current_rtb_id != $global_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_core_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_core_vpc_attachment_id \
                                                --transit-gateway-route-table-id $global_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region us-east-1 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_log_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-1 --output text)
if [ $current_rtb_id != $global_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_log_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_log_vpc_attachment_id \
                                                --transit-gateway-route-table-id $global_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region us-east-1 --output text
fi

# Associate Internal VPN Route Table to Internal VPN Attachments
# - Note: Currently no VPNs terminate in Global


## Ohio Core Transit Gateway Internal Route Table Associations ########################################################
profile=$core_profile

# Associate Internal VPC Route Table to Internal Peering Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_ohio_core_tgw_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

# Associate Internal VPC Route Table to Internal VPC Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_management_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_management_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_management_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_core_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_core_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_core_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_log_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_log_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_log_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

# Associate Internal VPN Route Table to Internal VPN Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_cml_sba_vpn_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_internal_vpn_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_cml_sba_vpn_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_cml_sba_vpn_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_internal_vpn_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi


## Ohio Core Transit Gateway Client Route Table Associations ##########################################################
profile=$core_profile

# Associate Alfa VPC Route Table to Alfa VPC Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_alfa_production_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_alfa_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_production_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_production_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpc_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_alfa_testing_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_alfa_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_testing_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_testing_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpc_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_alfa_development_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_alfa_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_development_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_development_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpc_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

# Associate Alfa VPN Route Table to Alfa VPN Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_alfa_lax_vpn_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_alfa_vpn_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_lax_vpn_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_lax_vpn_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpn_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_alfa_mia_vpn_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_alfa_vpn_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_mia_vpn_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_alfa_mia_vpn_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_alfa_vpn_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

# Associate Zulu VPC Route Table to Zulu VPC Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_zulu_production_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_zulu_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_zulu_production_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_zulu_production_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_zulu_vpc_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_zulu_development_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_zulu_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_zulu_development_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_zulu_development_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_zulu_vpc_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi

# Associate Zulu VPN Route Table to Zulu VPN Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_zulu_dfw_vpn_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region us-east-2 --output text)
if [ $current_rtb_id != $ohio_core_tgw_zulu_vpn_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_zulu_dfw_vpn_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region us-east-2 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_zulu_dfw_vpn_attachment_id \
                                                --transit-gateway-route-table-id $ohio_core_tgw_zulu_vpn_rtb_id \
                                                --profile $profile --region us-east-2 --output text
fi


## Ireland Core Transit Gateway Internal Route Table Associations #####################################################
profile=$core_profile

# Associate Internal VPC Route Table to Internal Peering Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $global_core_tgw_ireland_core_tgw_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region eu-west-1 --output text)
if [ $current_rtb_id != $ireland_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region eu-west-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                                --transit-gateway-route-table-id $ireland_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region eu-west-1 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region eu-west-1 --output text)
if [ $current_rtb_id != $ireland_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region eu-west-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                                --transit-gateway-route-table-id $ireland_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region eu-west-1 --output text
fi

# Associate Internal VPC Route Table to Internal VPC Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ireland_core_tgw_management_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region eu-west-1 --output text)
if [ $current_rtb_id != $ireland_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_management_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region eu-west-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_management_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ireland_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region eu-west-1 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ireland_core_tgw_core_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region eu-west-1 --output text)
if [ $current_rtb_id != $ireland_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_core_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region eu-west-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_core_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ireland_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region eu-west-1 --output text
fi

current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ireland_core_tgw_log_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region eu-west-1 --output text)
if [ $current_rtb_id != $ireland_core_tgw_internal_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_log_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region eu-west-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_log_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ireland_core_tgw_internal_vpc_rtb_id \
                                                --profile $profile --region eu-west-1 --output text
fi

# Associate Internal VPN Route Table to Internal VPN Attachments
# - Note: Currently no VPNs terminate in Ireland


## Ireland Core Transit Gateway Client Route Table Associations #######################################################
profile=$core_profile

# Associate Alfa VPC Route Table to Alfa VPC Attachments
current_rtb_id=$(aws ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids $ireland_core_tgw_alfa_recovery_vpc_attachment_id \
                                                              --query 'TransitGatewayAttachments[0].Association.TransitGatewayRouteTableId' \
                                                              --profile $profile --region eu-west-1 --output text)
if [ $current_rtb_id != $ireland_core_tgw_alfa_vpc_rtb_id ]; then
  if [ $current_rtb_id != 'None' ]; then
    aws ec2 disassociate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_alfa_recovery_vpc_attachment_id \
                                                     --transit-gateway-route-table-id $current_rtb_id \
                                                     --profile $profile --region eu-west-1 --output text
    sleep 30
  fi
  aws ec2 associate-transit-gateway-route-table --transit-gateway-attachment-id $ireland_core_tgw_alfa_recovery_vpc_attachment_id \
                                                --transit-gateway-route-table-id $ireland_core_tgw_alfa_vpc_rtb_id \
                                                --profile $profile --region eu-west-1 --output text
fi
