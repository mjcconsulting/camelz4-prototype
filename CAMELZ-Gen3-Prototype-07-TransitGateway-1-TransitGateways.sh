#!/usr/bin/env bash
#
# This is part of a set of scripts to setup a realistic DAP Prototype which uses multiple Accounts, VPCs and
# Transit Gateway to connect them all
#
# There are MANY resources needed to create this prototype, so we are splitting them into these files
# - CAMELZ-Gen3-Prototype-00-DefineParameters.sh
# - CAMELZ-Gen3-Prototype-01-Roles.sh
# - CAMELZ-Gen3-Prototype-02-SSM-1-Parameters.sh
# - CAMELZ-Gen3-Prototype-02-SSM-2-Documents.sh
# - CAMELZ-Gen3-Prototype-02-SSM-3-Associations.sh
# - CAMELZ-Gen3-Prototype-03-PublicHostedZones.sh
# - CAMELZ-Gen3-Prototype-04-VPCs.sh
# - CAMELZ-Gen3-Prototype-05-Resolvers-1-Outbound.sh
# - CAMELZ-Gen3-Prototype-05-Resolvers-2-Inbound.sh
# - CAMELZ-Gen3-Prototype-06-CustomerGateways.sh
# - CAMELZ-Gen3-Prototype-07-TransitGateway-1-TransitGateways.sh
# - CAMELZ-Gen3-Prototype-07-TransitGateway-2-VPCAttachments.sh
# - CAMELZ-Gen3-Prototype-07-TransitGateway-3-StaticVPCRoutes.sh
# - CAMELZ-Gen3-Prototype-07-TransitGateway-4-PeeringAttachments.sh
# - CAMELZ-Gen3-Prototype-07-TransitGateway-5-VPNAttachments.sh
# - CAMELZ-Gen3-Prototype-07-TransitGateway-6A-SimpleRouting.sh
# - CAMELZ-Gen3-Prototype-07-TransitGateway-6B-ComplexRouting.sh
# - CAMELZ-Gen3-Prototype-08-DirectoryService-1A-Shared-1-DirectoryService.sh
# - CAMELZ-Gen3-Prototype-08-DirectoryService-1A-Shared-2-ResolverRule.sh
# - CAMELZ-Gen3-Prototype-08-DirectoryService-1A-Shared-3-Trust.sh
# - CAMELZ-Gen3-Prototype-08-DirectoryService-1A-Shared-4-SSM-1-Parameters.sh
# - CAMELZ-Gen3-Prototype-08-DirectoryService-1A-Shared-4-SSM-2-Documents.sh
# - CAMELZ-Gen3-Prototype-08-DirectoryService-1A-Shared-4-SSM-3-Associations.sh
# - CAMELZ-Gen3-Prototype-08-DirectoryService-1B-PerClient-1-DirectoryService.sh
# - CAMELZ-Gen3-Prototype-08-DirectoryService-1B-PerClient-2-ResolverRule.sh
# - CAMELZ-Gen3-Prototype-08-DirectoryService-1B-PerClient-3-Trust.sh
# - CAMELZ-Gen3-Prototype-08-DirectoryService-1B-PerClient-4-SSM-1-Parameters.sh
# - CAMELZ-Gen3-Prototype-08-DirectoryService-1B-PerClient-4-SSM-2-Documents.sh
# - CAMELZ-Gen3-Prototype-08-DirectoryService-1B-PerClient-4-SSM-3-Associations.sh
# - CAMELZ-Gen3-Prototype-09-LinuxTestInstances.sh
# - CAMELZ-Gen3-Prototype-10-WindowsBastions.sh
# - CAMELZ-Gen3-Prototype-11-ActiveDirectoryManagement-1A-Shared.sh
# - CAMELZ-Gen3-Prototype-11-ActiveDirectoryManagement-1B-PerClient.sh
# - CAMELZ-Gen3-Prototype-12-ClientVPN.sh
# - CAMELZ-Gen3-Prototype-20-Remaining.sh
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
## Transit Gateways ###################################################################################################
#######################################################################################################################

## Global Transit Gateway #############################################################################################

# Create Transit Gateway
profile=$core_profile

global_core_tgw_id=$(aws ec2 create-transit-gateway --description Core-TransitGateway \
                                                    --options "AmazonSideAsn=$ohio_core_tgw_asn,AutoAcceptSharedAttachments=enable,DefaultRouteTableAssociation=disable,DefaultRouteTablePropagation=disable,VpnEcmpSupport=enable,DnsSupport=enable" \
                                                    --tag-specifications "ResourceType=transit-gateway,Tags=[{Key=Name,Value=Core-TransitGateway},{Key=Company,Value=DXC},{Key=Environment,Value=Core},{Key=Project,Value=\"CAMELZ3 POC\"},{Key=Note,Value=\"Associated with the CAMELZ3 POC - do not alter or delete\"}]" \
                                                    --query 'TransitGateway.TransitGatewayId' \
                                                    --profile $profile --region us-east-1 --output text)
echo "global_core_tgw_id=$global_core_tgw_id"


## Ohio Transit Gateway ###############################################################################################

# Create Transit Gateway
profile=$core_profile

ohio_core_tgw_id=$(aws ec2 create-transit-gateway --description Core-TransitGateway \
                                                  --options "AmazonSideAsn=$ohio_core_tgw_asn,AutoAcceptSharedAttachments=enable,DefaultRouteTableAssociation=disable,DefaultRouteTablePropagation=disable,VpnEcmpSupport=enable,DnsSupport=enable" \
                                                  --tag-specifications "ResourceType=transit-gateway,Tags=[{Key=Name,Value=Core-TransitGateway},{Key=Company,Value=DXC},{Key=Environment,Value=Core},{Key=Project,Value=\"CAMELZ3 POC\"},{Key=Note,Value=\"Associated with the CAMELZ3 POC - do not alter or delete\"}]" \
                                                  --query 'TransitGateway.TransitGatewayId' \
                                                  --profile $profile --region us-east-2 --output text)
echo "ohio_core_tgw_id=$ohio_core_tgw_id"


## Ireland Transit Gateway ############################################################################################

# Create Transit Gateway
profile=$core_profile

ireland_core_tgw_id=$(aws ec2 create-transit-gateway --description Core-TransitGateway \
                                                     --options "AmazonSideAsn=$ireland_core_tgw_asn,AutoAcceptSharedAttachments=enable,DefaultRouteTableAssociation=disable,DefaultRouteTablePropagation=disable,VpnEcmpSupport=enable,DnsSupport=enable" \
                                                     --tag-specifications "ResourceType=transit-gateway,Tags=[{Key=Name,Value=Core-TransitGateway},{Key=Company,Value=DXC},{Key=Environment,Value=Core},{Key=Project,Value=\"CAMELZ3 POC\"},{Key=Note,Value=\"Associated with the CAMELZ3 POC - do not alter or delete\"}]" \
                                                     --query 'TransitGateway.TransitGatewayId' \
                                                     --profile $profile --region eu-west-1 --output text)
echo "ireland_core_tgw_id=$ireland_core_tgw_id"


#######################################################################################################################
## Transit Gateway Resource Shares ####################################################################################
#######################################################################################################################

## Global Transit Gateway Resource Share ##############################################################################
profile=$core_profile

# Create TransitGateway ResourceShare
if [ ! -z $organization_id ]; then
  # Share TransitGateway with Organization (works with MJC Consulting)
  global_core_tgw_rs_arn=$(aws ram create-resource-share --name Core-TransitGatewayResourceShare \
                                                         --no-allow-external-principals \
                                                         --principals "arn:aws:organizations::$organization_account_id:organization/$organization_id" \
                                                         --resource-arns "arn:aws:ec2:us-east-1:$core_account_id:transit-gateway/$global_core_tgw_id" \
                                                         --tags "key=Name,value=Core-TransitGatewayResourceShare" \
                                                         --query 'resourceShare.resourceShareArn' \
                                                         --profile $profile --region us-east-1 --output text)
  echo "global_core_tgw_rs_arn=$global_core_tgw_rs_arn"
else
  # Share TransitGateway with specific Accounts (Management & Log) (works with DXC)
  global_core_tgw_rs_arn=$(aws ram create-resource-share --name Core-TransitGatewayResourceShare \
                                                         --allow-external-principals \
                                                         --principals $management_account_id $log_account_id \
                                                         --resource-arns "arn:aws:ec2:us-east-1:$core_account_id:transit-gateway/$global_core_tgw_id" \
                                                         --tags key=Name,value=Core-TransitGatewayResourceShare key=Company,value=DXC key=Environment,value=Core \
                                                         --query 'resourceShare.resourceShareArn' \
                                                         --profile $profile --region us-east-1 --output text)
  echo "global_core_tgw_rs_arn=$global_core_tgw_rs_arn"


  # Accept ResourceShare Invitation in Management Account
  profile=$management_profile

  global_management_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$global_core_tgw_rs_arn" \
                                                                         --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                         --profile $profile --region us-east-1 --output text)
  echo "global_management_tgw_rsi_arn=$global_management_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $global_management_tgw_rsi_arn \
                                           --profile $profile --region us-east-1 --output text


  # Accept ResourceShare Invitation in Log Account
  profile=$log_profile

  global_log_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$global_core_tgw_rs_arn" \
                                                                  --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                  --profile $profile --region us-east-1 --output text)
  echo "global_log_tgw_rsi_arn=$global_log_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $global_log_tgw_rsi_arn \
                                           --profile $profile --region us-east-1 --output text
fi


## Ohio Transit Gateway Resource Share ################################################################################
profile=$core_profile

# Create TransitGateway ResourceShare
if [ ! -z $organization_id ]; then
  # Share TransitGateway with Organization (works with MJC Consulting)
  ohio_core_tgw_rs_arn=$(aws ram create-resource-share --name Core-TransitGatewayResourceShare \
                                                       --no-allow-external-principals \
                                                       --principals "arn:aws:organizations::$organization_account_id:organization/$organization_id" \
                                                       --resource-arns "arn:aws:ec2:us-east-2:$core_account_id:transit-gateway/$ohio_core_tgw_id" \
                                                       --tags "key=Name,value=Core-TransitGatewayResourceShare" \
                                                       --query 'resourceShare.resourceShareArn' \
                                                       --profile $profile --region us-east-2 --output text)
  echo "ohio_core_tgw_rs_arn=$ohio_core_tgw_rs_arn"
else
  # Share TransitGateway with specific Accounts (Management, Log, Production, Recovery, Testing, Development) (works with DXC)
  ohio_core_tgw_rs_arn=$(aws ram create-resource-share --name Core-TransitGatewayResourceShare \
                                                       --allow-external-principals \
                                                       --principals $management_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                                       --resource-arns "arn:aws:ec2:us-east-2:$core_account_id:transit-gateway/$ohio_core_tgw_id" \
                                                       --tags key=Name,value=Core-TransitGatewayResourceShare key=Company,value=DXC key=Environment,value=Core \
                                                       --query 'resourceShare.resourceShareArn' \
                                                       --profile $profile --region us-east-2 --output text)
  echo "ohio_core_tgw_rs_arn=$ohio_core_tgw_rs_arn"


  # Accept ResourceShare Invitation in Management Account
  profile=$management_profile

  ohio_management_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ohio_core_tgw_rs_arn" \
                                                                       --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                       --profile $profile --region us-east-2 --output text)
  echo "ohio_management_tgw_rsi_arn=$ohio_management_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ohio_management_tgw_rsi_arn \
                                           --profile $profile --region us-east-2 --output text


  # Accept ResourceShare Invitation in Log Account
  profile=$log_profile

  ohio_log_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ohio_core_tgw_rs_arn" \
                                                                --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                --profile $profile --region us-east-2 --output text)
  echo "ohio_log_tgw_rsi_arn=$ohio_log_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ohio_log_tgw_rsi_arn \
                                           --profile $profile --region us-east-2 --output text


  # Accept ResourceShare Invitation in Production Account
  profile=$production_profile

  ohio_production_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ohio_core_tgw_rs_arn" \
                                                                       --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                       --profile $profile --region us-east-2 --output text)
  echo "ohio_production_tgw_rsi_arn=$ohio_production_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ohio_production_tgw_rsi_arn \
                                           --profile $profile --region us-east-2 --output text


  # Accept ResourceShare Invitation in Recovery Account
  profile=$recovery_profile

  ohio_recovery_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ohio_core_tgw_rs_arn" \
                                                                     --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                     --profile $profile --region us-east-2 --output text)
  echo "ohio_recovery_tgw_rsi_arn=$ohio_recovery_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ohio_recovery_tgw_rsi_arn \
                                           --profile $profile --region us-east-2 --output text


  # Accept ResourceShare Invitation in Testing Account
  profile=$testing_profile

  ohio_testing_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ohio_core_tgw_rs_arn" \
                                                                    --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                    --profile $profile --region us-east-2 --output text)
  echo "ohio_testing_tgw_rsi_arn=$ohio_testing_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ohio_testing_tgw_rsi_arn \
                                           --profile $profile --region us-east-2 --output text


  # Accept ResourceShare Invitation in Development Account
  profile=$development_profile

  ohio_development_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ohio_core_tgw_rs_arn" \
                                                                        --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                        --profile $profile --region us-east-2 --output text)
  echo "ohio_development_tgw_rsi_arn=$ohio_development_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ohio_development_tgw_rsi_arn \
                                           --profile $profile --region us-east-2 --output text
fi


## Ireland Transit Gateway Resource Share #############################################################################
profile=$core_profile

# Create TransitGateway ResourceShare
if [ ! -z $organization_id ]; then
  # Share TransitGateway with Organization (works with MJC Consulting)
  ireland_core_tgw_rs_arn=$(aws ram create-resource-share --name Core-TransitGatewayResourceShare \
                                                          --no-allow-external-principals \
                                                          --principals "arn:aws:organizations::$organization_account_id:organization/$organization_id" \
                                                          --resource-arns "arn:aws:ec2:eu-west-1:$core_account_id:transit-gateway/$ireland_core_tgw_id" \
                                                          --tags "key=Name,value=Core-TransitGatewayResourceShare" \
                                                          --query 'resourceShare.resourceShareArn' \
                                                          --profile $profile --region eu-west-1 --output text)
  echo "ireland_core_tgw_rs_arn=$ireland_core_tgw_rs_arn"
else
  # Share TransitGateway with specific Accounts (Management, Log, Production, Recovery, Testing, Development) (works with DXC)
  ireland_core_tgw_rs_arn=$(aws ram create-resource-share --name Core-TransitGatewayResourceShare \
                                                          --allow-external-principals \
                                                          --principals $management_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                                          --resource-arns "arn:aws:ec2:eu-west-1:$core_account_id:transit-gateway/$ireland_core_tgw_id" \
                                                          --tags key=Name,value=Core-TransitGatewayResourceShare key=Company,value=DXC key=Environment,value=Core \
                                                          --query 'resourceShare.resourceShareArn' \
                                                          --profile $profile --region eu-west-1 --output text)
  echo "ireland_core_tgw_rs_arn=$ireland_core_tgw_rs_arn"


  # Accept ResourceShare Invitation in Management Account
  profile=$management_profile

  ireland_management_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ireland_core_tgw_rs_arn" \
                                                                          --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                          --profile $profile --region eu-west-1 --output text)
  echo "ireland_management_tgw_rsi_arn=$ireland_management_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ireland_management_tgw_rsi_arn \
                                           --profile $profile --region eu-west-1 --output text


  # Accept ResourceShare Invitation in Log Account
  profile=$log_profile

  ireland_log_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ireland_core_tgw_rs_arn" \
                                                                   --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                   --profile $profile --region eu-west-1 --output text)
  echo "ireland_log_tgw_rsi_arn=$ireland_log_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ireland_log_tgw_rsi_arn \
                                           --profile $profile --region eu-west-1 --output text


  # Accept ResourceShare Invitation in Production Account
  profile=$production_profile

  ireland_production_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ireland_core_tgw_rs_arn" \
                                                                          --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                          --profile $profile --region eu-west-1 --output text)
  echo "ireland_production_tgw_rsi_arn=$ireland_production_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ireland_production_tgw_rsi_arn \
                                           --profile $profile --region eu-west-1 --output text


  # Accept ResourceShare Invitation in Recovery Account
  profile=$recovery_profile

  ireland_recovery_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ireland_core_tgw_rs_arn" \
                                                                        --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                        --profile $profile --region eu-west-1 --output text)
  echo "ireland_recovery_tgw_rsi_arn=$ireland_recovery_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ireland_recovery_tgw_rsi_arn \
                                           --profile $profile --region eu-west-1 --output text


  # Accept ResourceShare Invitation in Testing Account
  profile=$testing_profile

  ireland_testing_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ireland_core_tgw_rs_arn" \
                                                                       --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                       --profile $profile --region eu-west-1 --output text)
  echo "ireland_testing_tgw_rsi_arn=$ireland_testing_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ireland_testing_tgw_rsi_arn \
                                           --profile $profile --region eu-west-1 --output text


  # Accept ResourceShare Invitation in Development Account
  profile=$development_profile

  ireland_development_tgw_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ireland_core_tgw_rs_arn" \
                                                                           --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                           --profile $profile --region eu-west-1 --output text)
  echo "ireland_development_tgw_rsi_arn=$ireland_development_tgw_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ireland_development_tgw_rsi_arn \
                                           --profile $profile --region eu-west-1 --output text
fi
