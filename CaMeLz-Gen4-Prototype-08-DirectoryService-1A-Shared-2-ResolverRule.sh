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
## Route53 Outbound Resolver Rule - OneGlobal (Shared) Model ##########################################################
#######################################################################################################################

## Global Management Outbound Resolver Directory Service Rule #########################################################
profile=$management_profile

# Create Global Management Outbound Resolver Directory Service Rule
global_management_outboundresolver_ds_rule_id=$(aws route53resolver create-resolver-rule --resolver-endpoint-id $global_management_outboundresolver_endpoint_id \
                                                                                         --name Management-OutboundResolverDirectoryServiceRule \
                                                                                         --rule-type FORWARD \
                                                                                         --domain-name $global_management_directory_domain \
                                                                                         --target-ips $(echo $global_management_directory_dc_ips | sed -e "s/^/Ip=/;s/,/ Ip=/g") \
                                                                                         --creator-request-id $(date +%s) \
                                                                                         --tags Key=Name,Value=Management-OutboundResolverDirectoryServiceRule Key=Company,Value=CaMeLz Key=Environment,Value=Management \
                                                                                         --query 'ResolverRule.Id' \
                                                                                         --profile $profile --region us-east-1 --output text)
echo "global_management_outboundresolver_ds_rule_id=$global_management_outboundresolver_ds_rule_id"

global_management_outboundresolver_ds_rule_arn=$(aws route53resolver get-resolver-rule --resolver-rule-id $global_management_outboundresolver_ds_rule_id \
                                                                                       --query 'ResolverRule.Arn' \
                                                                                       --profile $profile --region us-east-1 --output text)
echo "global_management_outboundresolver_ds_rule_arn=$global_management_outboundresolver_ds_rule_arn"

# Share Global Management Outbound Resolver Directory Service Rule
if [ ! -z $organization_id ]; then
  # Share Global Management Outbound Resolver Directory Service Rule with Organization (works with MJC Consulting)
  # TODO: Logic needed to share with organization likely different than per-account logic below.
  echo "Logic not correct!"
  exit 2
else
  # Share Global Management Outbound Resolver Directory Service Rule with Specific Accounts (works with CaMeLz)
  profile=$management_profile

  global_management_outboundresolver_ds_rule_rs_arn=$(aws ram create-resource-share --name Management-OutboundResolverDirectoryServiceRuleResourceShare \
                                                                                    --allow-external-principals \
                                                                                    --principals $core_account_id $log_account_id \
                                                                                    --resource-arns $global_management_outboundresolver_ds_rule_arn \
                                                                                    --tags "key=Name,value=Management-OutboundResolverDirectoryServiceRuleResourceShare" \
                                                                                    --query 'resourceShare.resourceShareArn' \
                                                                                    --profile $profile --region us-east-1 --output text)
  echo "global_management_outboundresolver_ds_rule_rs_arn=$global_management_outboundresolver_ds_rule_rs_arn"

  # Accept ResourceShare Invitation in Core Account
  profile=$core_profile

  global_core_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$global_management_outboundresolver_ds_rule_rs_arn" \
                                                                                        --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                        --profile $profile --region us-east-1 --output text)
  echo "global_core_outboundresolver_ds_rule_rsi_arn=$global_core_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $global_core_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region us-east-1 --output text

  # Accept ResourceShare Invitation in Log Account
  profile=$log_profile

  global_log_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$global_management_outboundresolver_ds_rule_rs_arn" \
                                                                                       --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                       --profile $profile --region us-east-1 --output text)
  echo "global_log_outboundresolver_ds_rule_rsi_arn=$global_log_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $global_log_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region us-east-1 --output text
fi

# Associate Global Management Outbound Resolver Directory Service Rule with VPCs in the Management Account
profile=$management_profile

aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $global_management_outboundresolver_ds_rule_id \
                                            --vpc-id $global_management_vpc_id \
                                            --profile $profile --region us-east-1 --output text

# Associate Global Management Outbound Resolver Directory Service Rule with VPCs in the Core Account
profile=$core_profile

aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $global_management_outboundresolver_ds_rule_id \
                                            --vpc-id $global_core_vpc_id \
                                            --profile $profile --region us-east-1 --output text

# Associate Global Management Outbound Resolver Directory Service Rule with VPCs in the Log Account
profile=$log_profile

aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $global_management_outboundresolver_ds_rule_id \
                                            --vpc-id $global_log_vpc_id \
                                            --profile $profile --region us-east-1 --output text


## Ohio Management Outbound Resolver Directory Service Rule ###########################################################
profile=$management_profile

# Create Ohio Management Outbound Resolver Directory Service Rule
ohio_management_outboundresolver_ds_rule_id=$(aws route53resolver create-resolver-rule --resolver-endpoint-id $ohio_management_outboundresolver_endpoint_id \
                                                                                       --name Management-OutboundResolverDirectoryServiceRule \
                                                                                       --rule-type FORWARD \
                                                                                       --domain-name $ohio_management_directory_domain \
                                                                                       --target-ips $(echo $ohio_management_directory_dc_ips | sed -e "s/^/Ip=/;s/,/ Ip=/g") \
                                                                                       --creator-request-id $(date +%s) \
                                                                                       --tags Key=Name,Value=Management-OutboundResolverDirectoryServiceRule Key=Company,Value=CaMeLz Key=Environment,Value=Management \
                                                                                       --query 'ResolverRule.Id' \
                                                                                       --profile $profile --region us-east-2 --output text)
echo "ohio_management_outboundresolver_ds_rule_id=$ohio_management_outboundresolver_ds_rule_id"

ohio_management_outboundresolver_ds_rule_arn=$(aws route53resolver get-resolver-rule --resolver-rule-id $ohio_management_outboundresolver_ds_rule_id \
                                                                                     --query 'ResolverRule.Arn' \
                                                                                     --profile $profile --region us-east-2 --output text)
echo "ohio_management_outboundresolver_ds_rule_arn=$ohio_management_outboundresolver_ds_rule_arn"

# Share Ohio Management Outbound Resolver Directory Service Rule
if [ ! -z $organization_id ]; then
  # Share Ohio Management Outbound Resolver Directory Service Rule with Organization (works with MJC Consulting)
  # TODO: Logic needed to share with organization likely different than per-account logic below.
  echo "Logic not correct!"
  exit 2
else
  # Share Ohio Management Outbound Resolver Directory Service Rule with Specific Accounts (works with CaMeLz)
  profile=$management_profile

  ohio_management_outboundresolver_ds_rule_rs_arn=$(aws ram create-resource-share --name Management-OutboundResolverDirectoryServiceRuleResourceShare \
                                                                                  --allow-external-principals \
                                                                                  --principals $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                                                                  --resource-arns $ohio_management_outboundresolver_ds_rule_arn \
                                                                                  --tags "key=Name,value=Management-OutboundResolverDirectoryServiceRuleResourceShare" \
                                                                                  --query 'resourceShare.resourceShareArn' \
                                                                                  --profile $profile --region us-east-2 --output text)
  echo "ohio_management_outboundresolver_ds_rule_rs_arn=$ohio_management_outboundresolver_ds_rule_rs_arn"

  # Accept ResourceShare Invitation in Core Account
  profile=$core_profile

  ohio_core_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ohio_management_outboundresolver_ds_rule_rs_arn" \
                                                                                      --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                      --profile $profile --region us-east-2 --output text)
  echo "ohio_core_outboundresolver_ds_rule_rsi_arn=$ohio_core_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ohio_core_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region us-east-2 --output text

  # Accept ResourceShare Invitation in Log Account
  profile=$log_profile

  ohio_log_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ohio_management_outboundresolver_ds_rule_rs_arn" \
                                                                                     --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                     --profile $profile --region us-east-2 --output text)
  echo "ohio_log_outboundresolver_ds_rule_rsi_arn=$ohio_log_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ohio_log_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region us-east-2 --output text

  # Accept ResourceShare Invitation in Production Account
  profile=$production_profile

  ohio_production_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ohio_management_outboundresolver_ds_rule_rs_arn" \
                                                                                            --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                            --profile $profile --region us-east-2 --output text)
  echo "ohio_production_outboundresolver_ds_rule_rsi_arn=$ohio_production_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ohio_production_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region us-east-2 --output text

  # Accept ResourceShare Invitation in Recovery Account
  profile=$recovery_profile

  ohio_recovery_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ohio_management_outboundresolver_ds_rule_rs_arn" \
                                                                                          --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                          --profile $profile --region us-east-2 --output text)
  echo "ohio_recovery_outboundresolver_ds_rule_rsi_arn=$ohio_recovery_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ohio_recovery_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region us-east-2 --output text

  # Accept ResourceShare Invitation in Testing Account
  profile=$testing_profile

  ohio_testing_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ohio_management_outboundresolver_ds_rule_rs_arn" \
                                                                                         --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                         --profile $profile --region us-east-2 --output text)
  echo "ohio_testing_outboundresolver_ds_rule_rsi_arn=$ohio_testing_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ohio_testing_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region us-east-2 --output text

  # Accept ResourceShare Invitation in Development Account
  profile=$development_profile

  ohio_development_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ohio_management_outboundresolver_ds_rule_rs_arn" \
                                                                                             --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                             --profile $profile --region us-east-2 --output text)
  echo "ohio_development_outboundresolver_ds_rule_rsi_arn=$ohio_development_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ohio_development_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region us-east-2 --output text
fi

# Associate Ohio Management Outbound Resolver Directory Service Rule with VPCs in the Management Account
profile=$management_profile

aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $ohio_management_outboundresolver_ds_rule_id \
                                            --vpc-id $ohio_management_vpc_id \
                                            --profile $profile --region us-east-2 --output text

# Associate Ohio Management Outbound Resolver Directory Service Rule with VPCs in the Core Account
profile=$core_profile

aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $ohio_management_outboundresolver_ds_rule_id \
                                            --vpc-id $ohio_core_vpc_id \
                                            --profile $profile --region us-east-2 --output text

# Associate Ohio Management Outbound Resolver Directory Service Rule with VPCs in the Log Account
profile=$log_profile

aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $ohio_management_outboundresolver_ds_rule_id \
                                            --vpc-id $ohio_log_vpc_id \
                                            --profile $profile --region us-east-2 --output text

# Associate Ohio Management Outbound Resolver Directory Service Rule with VPCs in the Production Account
profile=$production_profile
aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $ohio_management_outboundresolver_ds_rule_id \
                                            --vpc-id $alfa_ohio_production_vpc_id \
                                            --profile $profile --region us-east-2 --output text

aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $ohio_management_outboundresolver_ds_rule_id \
                                            --vpc-id $zulu_ohio_production_vpc_id \
                                            --profile $profile --region us-east-2 --output text

# Associate Ohio Management Outbound Resolver Directory Service Rule with VPCs in the Testing Account
profile=$testing_profile
aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $ohio_management_outboundresolver_ds_rule_id \
                                            --vpc-id $alfa_ohio_testing_vpc_id \
                                            --profile $profile --region us-east-2 --output text

# Associate Ohio Management Outbound Resolver Directory Service Rule with VPCs in the Development Account
profile=$development_profile
aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $ohio_management_outboundresolver_ds_rule_id \
                                            --vpc-id $alfa_ohio_development_vpc_id \
                                            --profile $profile --region us-east-2 --output text

aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $ohio_management_outboundresolver_ds_rule_id \
                                            --vpc-id $zulu_ohio_development_vpc_id \
                                            --profile $profile --region us-east-2 --output text


## Ireland Management Outbound Resolver Directory Service Rule ########################################################
profile=$management_profile

# Create Ireland Management Outbound Resolver Directory Service Rule
ireland_management_outboundresolver_ds_rule_id=$(aws route53resolver create-resolver-rule --resolver-endpoint-id $ireland_management_outboundresolver_endpoint_id \
                                                                                          --name Management-OutboundResolverDirectoryServiceRule \
                                                                                          --rule-type FORWARD \
                                                                                          --domain-name $ireland_management_directory_domain \
                                                                                          --target-ips $(echo $ireland_management_directory_dc_ips | sed -e "s/^/Ip=/;s/,/ Ip=/g") \
                                                                                          --creator-request-id $(date +%s) \
                                                                                          --tags Key=Name,Value=Management-OutboundResolverDirectoryServiceRule Key=Company,Value=CaMeLz Key=Environment,Value=Management \
                                                                                          --query 'ResolverRule.Id' \
                                                                                          --profile $profile --region eu-west-1 --output text)
echo "ireland_management_outboundresolver_ds_rule_id=$ireland_management_outboundresolver_ds_rule_id"

ireland_management_outboundresolver_ds_rule_arn=$(aws route53resolver get-resolver-rule --resolver-rule-id $ireland_management_outboundresolver_ds_rule_id \
                                                                                        --query 'ResolverRule.Arn' \
                                                                                        --profile $profile --region eu-west-1 --output text)
echo "ireland_management_outboundresolver_ds_rule_arn=$ireland_management_outboundresolver_ds_rule_arn"

# Share Ireland Management Outbound Resolver Directory Service Rule
if [ ! -z $organization_id ]; then
  # Share Ireland Management Outbound Resolver Directory Service Rule with Organization (works with MJC Consulting)
  # TODO: Logic needed to share with organization likely different than per-account logic below.
  echo "Logic not correct!"
  exit 2
else
  # Share Ireland Management Outbound Resolver Directory Service Rule with Specific Accounts (works with CaMeLz)
  profile=$management_profile

  ireland_management_outboundresolver_ds_rule_rs_arn=$(aws ram create-resource-share --name Management-OutboundResolverDirectoryServiceRuleResourceShare \
                                                                                     --allow-external-principals \
                                                                                     --principals $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                                                                     --resource-arns $ireland_management_outboundresolver_ds_rule_arn \
                                                                                     --tags "key=Name,value=Management-OutboundResolverDirectoryServiceRuleResourceShare" \
                                                                                     --query 'resourceShare.resourceShareArn' \
                                                                                     --profile $profile --region eu-west-1 --output text)
  echo "ireland_management_outboundresolver_ds_rule_rs_arn=$ireland_management_outboundresolver_ds_rule_rs_arn"

  # Accept ResourceShare Invitation in Core Account
  profile=$core_profile

  ireland_core_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ireland_management_outboundresolver_ds_rule_rs_arn" \
                                                                                         --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                         --profile $profile --region eu-west-1 --output text)
  echo "ireland_core_outboundresolver_ds_rule_rsi_arn=$ireland_core_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ireland_core_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region eu-west-1 --output text

  # Accept ResourceShare Invitation in Log Account
  profile=$log_profile

  ireland_log_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ireland_management_outboundresolver_ds_rule_rs_arn" \
                                                                                        --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                        --profile $profile --region eu-west-1 --output text)
  echo "ireland_log_outboundresolver_ds_rule_rsi_arn=$ireland_log_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ireland_log_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region eu-west-1 --output text

  # Accept ResourceShare Invitation in Production Account
  profile=$production_profile

  ireland_production_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ireland_management_outboundresolver_ds_rule_rs_arn" \
                                                                                               --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                               --profile $profile --region eu-west-1 --output text)
  echo "ireland_production_outboundresolver_ds_rule_rsi_arn=$ireland_production_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ireland_production_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region eu-west-1 --output text

  # Accept ResourceShare Invitation in Recovery Account
  profile=$recovery_profile

  ireland_recovery_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ireland_management_outboundresolver_ds_rule_rs_arn" \
                                                                                             --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                             --profile $profile --region eu-west-1 --output text)
  echo "ireland_recovery_outboundresolver_ds_rule_rsi_arn=$ireland_recovery_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ireland_recovery_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region eu-west-1 --output text

  # Accept ResourceShare Invitation in Testing Account
  profile=$testing_profile

  ireland_testing_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ireland_management_outboundresolver_ds_rule_rs_arn" \
                                                                                            --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                            --profile $profile --region eu-west-1 --output text)
  echo "ireland_testing_outboundresolver_ds_rule_rsi_arn=$ireland_testing_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ireland_testing_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region eu-west-1 --output text

  # Accept ResourceShare Invitation in Development Account
  profile=$development_profile

  ireland_development_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$ireland_management_outboundresolver_ds_rule_rs_arn" \
                                                                                                --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                                --profile $profile --region eu-west-1 --output text)
  echo "ireland_development_outboundresolver_ds_rule_rsi_arn=$ireland_development_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $ireland_development_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region eu-west-1 --output text
fi

# Associate Ireland Management Outbound Resolver Directory Service Rule with VPCs in the Management Account
profile=$management_profile

aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $ireland_management_outboundresolver_ds_rule_id \
                                            --vpc-id $ireland_management_vpc_id \
                                            --profile $profile --region eu-west-1 --output text

# Associate Ireland Management Outbound Resolver Directory Service Rule with VPCs in the Core Account
profile=$core_profile

aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $ireland_management_outboundresolver_ds_rule_id \
                                            --vpc-id $ireland_core_vpc_id \
                                            --profile $profile --region eu-west-1 --output text

# Associate Ireland Management Outbound Resolver Directory Service Rule with VPCs in the Log Account
profile=$log_profile

aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $ireland_management_outboundresolver_ds_rule_id \
                                            --vpc-id $ireland_log_vpc_id \
                                            --profile $profile --region eu-west-1 --output text

# Associate Ireland Management Outbound Resolver Directory Service Rule with VPCs in the Recovery Account
profile=$recovery_profile

aws route53resolver associate-resolver-rule --name Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $ireland_management_outboundresolver_ds_rule_id \
                                            --vpc-id $alfa_ireland_recovery_vpc_id \
                                            --profile $profile --region eu-west-1 --output text
