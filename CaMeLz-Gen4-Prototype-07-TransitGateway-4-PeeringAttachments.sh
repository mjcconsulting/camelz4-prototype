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
## Transit Gateway Peering Attachments ################################################################################
#######################################################################################################################
## Note: Traffic should mainly be Region <->> Global, for stuff like AD Forest Trust Traffic, or access to           ##
##       centralized services in core, or if we stream log info direct (outside of CloudTrail replication, etc)      ##
##       so the main peering links will be hub-and-spoke from global-to-region.                                      ##
## Note: I don't think we are going to have clients which exist in multiple regions which need to communicate        ##
##       between Regions, but I'm not sure on that.                                                                  ##
## Note: I do think we could need to replicate data from Production -> Recovery, which would be Region -> Region,    ##
##       and I think we might pay double if we sent such traffic through global as two hops in a hub-and-spoke, so   ##
##       I think we do need to have Region-to-Region peering on an as needed basis.                                  ##
## Note: Since this prototype currently only has 2 regions + global, I'll setup all 3 peering links here, but this   ##
##       could be more messy if lots of other regions start getting used.                                            ##
#######################################################################################################################

## Global Core to Ohio Core Transit Gateway Peering Attachment ########################################################
profile=$core_profile

global_core_tgw_ohio_core_tgw_attachment_id=$(aws ec2 create-transit-gateway-peering-attachment  --transit-gateway-id $global_core_tgw_id \
                                                                                                 --peer-transit-gateway-id $ohio_core_tgw_id \
                                                                                                 --peer-account-id $core_account_id \
                                                                                                 --peer-region us-east-2 \
                                                                                                 --tag-specifications "ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Core-OhioCoreTgwTransitGatewayAttachment},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                                                 --query 'TransitGatewayPeeringAttachment.TransitGatewayAttachmentId' \
                                                                                                 --profile $profile --region us-east-1 --output text)
echo "global_core_tgw_ohio_core_tgw_attachment_id=$global_core_tgw_ohio_core_tgw_attachment_id"

aws ec2 accept-transit-gateway-peering-attachment --transit-gateway-attachment-id $global_core_tgw_ohio_core_tgw_attachment_id \
                                                  --profile $profile --region us-east-2 --output text

# We also need to tag the Attachment in the peered Region
aws ec2 create-tags --resources $global_core_tgw_ohio_core_tgw_attachment_id \
                    --tags Key=Name,Value=Core-GlobalCoreTgwTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

## Global Core to Ireland Core Transit Gateway Peering Attachment #####################################################
profile=$core_profile

global_core_tgw_ireland_core_tgw_attachment_id=$(aws ec2 create-transit-gateway-peering-attachment  --transit-gateway-id $global_core_tgw_id \
                                                                                                    --peer-transit-gateway-id $ireland_core_tgw_id \
                                                                                                    --peer-account-id $core_account_id \
                                                                                                    --peer-region eu-west-1 \
                                                                                                    --tag-specifications "ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Core-IrelandCoreTgwTransitGatewayAttachment},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                                                    --query 'TransitGatewayPeeringAttachment.TransitGatewayAttachmentId' \
                                                                                                    --profile $profile --region us-east-1 --output text)
echo "global_core_tgw_ireland_core_tgw_attachment_id=$global_core_tgw_ireland_core_tgw_attachment_id"

aws ec2 accept-transit-gateway-peering-attachment --transit-gateway-attachment-id $global_core_tgw_ireland_core_tgw_attachment_id \
                                                  --profile $profile --region eu-west-1 --output text


# We also need to tag the Attachment in the peered Region
aws ec2 create-tags --resources $global_core_tgw_ireland_core_tgw_attachment_id \
                    --tags Key=Name,Value=Core-GlobalCoreTgwTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text


## Ohio Core to Ireland Core Transit Gateway Peering Attachment #######################################################
profile=$core_profile

ohio_core_tgw_ireland_core_tgw_attachment_id=$(aws ec2 create-transit-gateway-peering-attachment  --transit-gateway-id $ohio_core_tgw_id \
                                                                                                  --peer-transit-gateway-id $ireland_core_tgw_id \
                                                                                                  --peer-account-id $core_account_id \
                                                                                                  --peer-region eu-west-1 \
                                                                                                  --tag-specifications "ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=Core-IrelandCoreTgwTransitGatewayAttachment},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                                                  --query 'TransitGatewayPeeringAttachment.TransitGatewayAttachmentId' \
                                                                                                  --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_ireland_core_tgw_attachment_id=$ohio_core_tgw_ireland_core_tgw_attachment_id"

aws ec2 accept-transit-gateway-peering-attachment --transit-gateway-attachment-id $ohio_core_tgw_ireland_core_tgw_attachment_id \
                                                  --profile $profile --region eu-west-1 --output text

# We also need to tag the Attachment in the peered Region
aws ec2 create-tags --resources $ohio_core_tgw_ireland_core_tgw_attachment_id \
                    --tags Key=Name,Value=Core-OhioCoreTgwTransitGatewayAttachment \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region eu-west-1 --output text
