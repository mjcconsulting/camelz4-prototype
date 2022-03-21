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
## VPC Route Table Static Routes TO Transit Gateway - Default (Single) Route Table ####################################
#######################################################################################################################
## Note: When we move this into CloudFormation, we will want to create the TGW FIRST, and have the Stack which       ##
##       creates the TGW as an optional stack dependency when creating a VPC. If Specified, the VPC Stack should     ##
##       attach to the TGW, then it can create the Route below, so this does not have to be a separate Stack/Step.   ##
## Note: Additionally, we should have a UseInternetGateway parameter, which if true, would create the IGW, and a     ##
##       default route from public subnets, and NGW or NAT instances, and default routs to that from private subnets ##
##       and the specific routes below. If that is false, we should not create the IGW, or NAT Gateways, and instead ##
##       of the routes below, just create a default route to the TGW, as it's assumed some other VPC would have the  ##
##       default route out to the Internet.                                                                          ##
#######################################################################################################################

## Global Management VPC Static Routes ################################################################################
profile=$management_profile

aws ec2 create-route --route-table-id $global_management_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_management_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_management_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text

aws ec2 create-route --route-table-id $global_management_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_management_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_management_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text

aws ec2 create-route --route-table-id $global_management_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_management_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_management_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text

aws ec2 create-route --route-table-id $global_management_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_management_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_management_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text


## Global Core VPC Static Routes ######################################################################################
profile=$core_profile

aws ec2 create-route --route-table-id $global_core_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_core_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_core_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text

aws ec2 create-route --route-table-id $global_core_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_core_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_core_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text

aws ec2 create-route --route-table-id $global_core_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_core_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_core_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text

aws ec2 create-route --route-table-id $global_core_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_core_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_core_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text


## Global Log VPC Static Routes #######################################################################################
profile=$log_profile

aws ec2 create-route --route-table-id $global_log_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_log_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_log_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text

aws ec2 create-route --route-table-id $global_log_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_log_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_log_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text

aws ec2 create-route --route-table-id $global_log_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_log_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_log_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text

aws ec2 create-route --route-table-id $global_log_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_log_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text
aws ec2 create-route --route-table-id $global_log_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $global_core_tgw_id \
                     --profile $profile --region us-east-1 --output text


## Ohio Management VPC Static Routes ##################################################################################
profile=$management_profile

aws ec2 create-route --route-table-id $ohio_management_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_management_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_management_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $ohio_management_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_management_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_management_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $ohio_management_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_management_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_management_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $ohio_management_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_management_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_management_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text


## Ohio Core VPC Static Routes ########################################################################################
profile=$core_profile

aws ec2 create-route --route-table-id $ohio_core_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_core_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_core_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $ohio_core_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_core_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_core_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $ohio_core_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_core_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_core_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $ohio_core_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_core_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_core_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text


## Ohio Log VPC Static Routes #########################################################################################
profile=$log_profile

aws ec2 create-route --route-table-id $ohio_log_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_log_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_log_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $ohio_log_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_log_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_log_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $ohio_log_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_log_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_log_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $ohio_log_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_log_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $ohio_log_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text


## Alfa Ohio Production VPC Static Routes #############################################################################
profile=$production_profile

aws ec2 create-route --route-table-id $alfa_ohio_production_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_production_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_production_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_production_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text


## Alfa Ohio Testing VPC Static Routes ################################################################################
profile=$testing_profile

aws ec2 create-route --route-table-id $alfa_ohio_testing_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_testing_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_testing_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text


## Alfa Ohio Development VPC Static Routes ############################################################################
profile=$development_profile

aws ec2 create-route --route-table-id $alfa_ohio_development_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_development_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_development_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text


## Zulu Ohio Production VPC Static Routes #############################################################################
profile=$production_profile

aws ec2 create-route --route-table-id $zulu_ohio_production_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_production_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_production_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_production_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text


## Zulu Ohio Development VPC Static Routes ############################################################################
profile=$development_profile

aws ec2 create-route --route-table-id $zulu_ohio_development_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_development_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_development_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_ohio_development_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_development_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_development_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_ohio_development_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_development_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_development_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text

aws ec2 create-route --route-table-id $zulu_ohio_development_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_development_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $zulu_ohio_development_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ohio_core_tgw_id \
                     --profile $profile --region us-east-2 --output text


## Ireland Management VPC Static Routes ###############################################################################
profile=$management_profile

aws ec2 create-route --route-table-id $ireland_management_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_management_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_management_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $ireland_management_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_management_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_management_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $ireland_management_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_management_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_management_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $ireland_management_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_management_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_management_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text


## Ireland Core VPC Static Routes #####################################################################################
profile=$core_profile

aws ec2 create-route --route-table-id $ireland_core_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_core_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_core_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $ireland_core_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_core_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_core_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $ireland_core_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_core_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_core_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $ireland_core_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_core_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_core_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text


## Ireland Log VPC Static Routes ######################################################################################
profile=$log_profile

aws ec2 create-route --route-table-id $ireland_log_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_log_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_log_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $ireland_log_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_log_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_log_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $ireland_log_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_log_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_log_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $ireland_log_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_log_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $ireland_log_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text


## Alfa Ireland Recovery VPC Static Routes ############################################################################
profile=$recovery_profile

aws ec2 create-route --route-table-id $alfa_ireland_recovery_public_rtb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $alfa_ireland_recovery_public_rtb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $alfa_ireland_recovery_public_rtb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtba_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtba_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtba_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtbb_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtbb_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtbb_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text

aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtbc_id \
                     --destination-cidr-block $aws_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtbc_id \
                     --destination-cidr-block $client_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
aws ec2 create-route --route-table-id $alfa_ireland_recovery_private_rtbc_id \
                     --destination-cidr-block $partner_cidr \
                     --transit-gateway-id $ireland_core_tgw_id \
                     --profile $profile --region eu-west-1 --output text
