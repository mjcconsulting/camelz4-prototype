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
## Route53 Outbound Resolver Rule - PerClient Model ###################################################################
#######################################################################################################################

## Alfa Global Management Outbound Resolver Directory Service Rule ####################################################
#  - This is needed for the Alfa Global ActiveDirectoryManagement Instance
profile=$management_profile

# Create Global Management Outbound Resolver Directory Service Rule
alfa_global_management_outboundresolver_ds_rule_id=$(aws route53resolver create-resolver-rule --resolver-endpoint-id $global_management_outboundresolver_endpoint_id \
                                                                                              --name Alfa-Management-OutboundResolverDirectoryServiceRule \
                                                                                              --rule-type FORWARD \
                                                                                              --domain-name $alfa_global_management_directory_domain \
                                                                                              --target-ips $(echo $alfa_global_management_directory_dc_ips | sed -e "s/^/Ip=/;s/,/ Ip=/g") \
                                                                                              --creator-request-id $(date +%s) \
                                                                                              --tags Key=Name,Value=Alfa-Management-OutboundResolverDirectoryServiceRule Key=Company,Value=Alfa Key=Environment,Value=Management \
                                                                                              --query 'ResolverRule.Id' \
                                                                                              --profile $profile --region us-east-1 --output text)
echo "alfa_global_management_outboundresolver_ds_rule_id=$alfa_global_management_outboundresolver_ds_rule_id"

alfa_global_management_outboundresolver_ds_rule_arn=$(aws route53resolver get-resolver-rule --resolver-rule-id $alfa_global_management_outboundresolver_ds_rule_id \
                                                                                            --query 'ResolverRule.Arn' \
                                                                                            --profile $profile --region us-east-1 --output text)
echo "alfa_global_management_outboundresolver_ds_rule_arn=$alfa_global_management_outboundresolver_ds_rule_arn"

# - No need to share or associate a client Global Directory Service Rule


## Alfa Ohio Management Outbound Resolver Directory Service Rule ######################################################
profile=$management_profile

# Create Alfa Ohio Management Outbound Resolver Directory Service Rule
alfa_ohio_management_outboundresolver_ds_rule_id=$(aws route53resolver create-resolver-rule --resolver-endpoint-id $alfa_ohio_management_outboundresolver_endpoint_id \
                                                                                            --name Alfa-Management-OutboundResolverDirectoryServiceRule \
                                                                                            --rule-type FORWARD \
                                                                                            --domain-name $alfa_ohio_management_directory_domain \
                                                                                            --target-ips $(echo $alfa_ohio_management_directory_dc_ips | sed -e "s/^/Ip=/;s/,/ Ip=/g") \
                                                                                            --creator-request-id $(date +%s) \
                                                                                            --tags Key=Name,Value=Alfa-Management-OutboundResolverDirectoryServiceRule Key=Company,Value=Alfa Key=Environment,Value=Management \
                                                                                            --query 'ResolverRule.Id' \
                                                                                            --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_management_outboundresolver_ds_rule_id=$alfa_ohio_management_outboundresolver_ds_rule_id"

alfa_ohio_management_outboundresolver_ds_rule_arn=$(aws route53resolver get-resolver-rule --resolver-rule-id $alfa_ohio_management_outboundresolver_ds_rule_id \
                                                                                          --query 'ResolverRule.Arn' \
                                                                                          --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_management_outboundresolver_ds_rule_arn=$alfa_ohio_management_outboundresolver_ds_rule_arn"

# Share Alfa Ohio Management Outbound Resolver Directory Service Rule
if [ ! -z $organization_id ]; then
  # Share Alfa Ohio Management Outbound Resolver Directory Service Rule with Organization (works with MJC Consulting)
  # TODO: Logic needed to share with organization likely different than per-account logic below.
  echo "Logic not correct!"
  exit 2
else
  # Share Alfa Ohio Management Outbound Resolver Directory Service Rule with Specific Accounts (works with CaMeLz)
  profile=$management_profile

  alfa_ohio_management_outboundresolver_ds_rule_rs_arn=$(aws ram create-resource-share --name Alfa-Management-OutboundResolverDirectoryServiceRuleResourceShare \
                                                                                       --allow-external-principals \
                                                                                       --principals $production_account_id $testing_account_id $development_account_id \
                                                                                       --resource-arns $alfa_ohio_management_outboundresolver_ds_rule_arn \
                                                                                       --tags "key=Name,value=Alfa-Management-OutboundResolverDirectoryServiceRuleResourceShare" \
                                                                                       --query 'resourceShare.resourceShareArn' \
                                                                                       --profile $profile --region us-east-2 --output text)
  echo "alfa_ohio_management_outboundresolver_ds_rule_rs_arn=$alfa_ohio_management_outboundresolver_ds_rule_rs_arn"

  # Accept ResourceShare Invitation in Production Account
  profile=$production_profile

  alfa_ohio_production_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$alfa_ohio_management_outboundresolver_ds_rule_rs_arn" \
                                                                                                 --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                                 --profile $profile --region us-east-2 --output text)
  echo "alfa_ohio_production_outboundresolver_ds_rule_rsi_arn=$alfa_ohio_production_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $alfa_ohio_production_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region us-east-2 --output text

  # Accept ResourceShare Invitation in Testing Account
  profile=$testing_profile

  alfa_ohio_testing_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$alfa_ohio_management_outboundresolver_ds_rule_rs_arn" \
                                                                                              --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                              --profile $profile --region us-east-2 --output text)
  echo "alfa_ohio_testing_outboundresolver_ds_rule_rsi_arn=$alfa_ohio_testing_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $alfa_ohio_testing_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region us-east-2 --output text

  # Accept ResourceShare Invitation in Development Account
  profile=$development_profile

  alfa_ohio_development_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$alfa_ohio_management_outboundresolver_ds_rule_rs_arn" \
                                                                                                  --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                                  --profile $profile --region us-east-2 --output text)
  echo "alfa_ohio_development_outboundresolver_ds_rule_rsi_arn=$alfa_ohio_development_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $alfa_ohio_development_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region us-east-2 --output text
fi

# Associate Alfa Ohio Management Outbound Resolver Directory Service Rule with VPCs in the Production Account
profile=$production_profile
aws route53resolver associate-resolver-rule --name Alfa-Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $alfa_ohio_management_outboundresolver_ds_rule_id \
                                            --vpc-id $alfa_ohio_production_vpc_id \
                                            --profile $profile --region us-east-2 --output text

# Associate Alfa Ohio Management Outbound Resolver Directory Service Rule with VPCs in the Testing Account
profile=$testing_profile
aws route53resolver associate-resolver-rule --name Alfa-Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $alfa_ohio_management_outboundresolver_ds_rule_id \
                                            --vpc-id $alfa_ohio_testing_vpc_id \
                                            --profile $profile --region us-east-2 --output text

# Associate Alfa Ohio Management Outbound Resolver Directory Service Rule with VPCs in the Development Account
profile=$development_profile
aws route53resolver associate-resolver-rule --name Alfa-Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $alfa_ohio_management_outboundresolver_ds_rule_id \
                                            --vpc-id $alfa_ohio_development_vpc_id \
                                            --profile $profile --region us-east-2 --output text


## Zulu Ohio Management Outbound Resolver Directory Service Rule ######################################################
profile=$management_profile

# Create Zulu Ohio Management Outbound Resolver Directory Service Rule
zulu_ohio_management_outboundresolver_ds_rule_id=$(aws route53resolver create-resolver-rule --resolver-endpoint-id $zulu_ohio_management_outboundresolver_endpoint_id \
                                                                                            --name Zulu-Management-OutboundResolverDirectoryServiceRule \
                                                                                            --rule-type FORWARD \
                                                                                            --domain-name $zulu_ohio_management_directory_domain \
                                                                                            --target-ips $(echo $zulu_ohio_management_directory_dc_ips | sed -e "s/^/Ip=/;s/,/ Ip=/g") \
                                                                                            --creator-request-id $(date +%s) \
                                                                                            --tags Key=Name,Value=Zulu-Management-OutboundResolverDirectoryServiceRule Key=Company,Value=Zulu Key=Environment,Value=Management \
                                                                                            --query 'ResolverRule.Id' \
                                                                                            --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_management_outboundresolver_ds_rule_id=$zulu_ohio_management_outboundresolver_ds_rule_id"

zulu_ohio_management_outboundresolver_ds_rule_arn=$(aws route53resolver get-resolver-rule --resolver-rule-id $zulu_ohio_management_outboundresolver_ds_rule_id \
                                                                                          --query 'ResolverRule.Arn' \
                                                                                          --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_management_outboundresolver_ds_rule_arn=$zulu_ohio_management_outboundresolver_ds_rule_arn"

# Share Zulu Ohio Management Outbound Resolver Directory Service Rule
if [ ! -z $organization_id ]; then
  # Share Zulu Ohio Management Outbound Resolver Directory Service Rule with Organization (works with MJC Consulting)
  # TODO: Logic needed to share with organization likely different than per-account logic below.
  echo "Logic not correct!"
  exit 2
else
  # Share Zulu Ohio Management Outbound Resolver Directory Service Rule with Specific Accounts (works with CaMeLz)
  profile=$management_profile

  zulu_ohio_management_outboundresolver_ds_rule_rs_arn=$(aws ram create-resource-share --name Zulu-Management-OutboundResolverDirectoryServiceRuleResourceShare \
                                                                                       --allow-external-principals \
                                                                                       --principals $production_account_id $development_account_id \
                                                                                       --resource-arns $zulu_ohio_management_outboundresolver_ds_rule_arn \
                                                                                       --tags "key=Name,value=Zulu-Management-OutboundResolverDirectoryServiceRuleResourceShare" \
                                                                                       --query 'resourceShare.resourceShareArn' \
                                                                                       --profile $profile --region us-east-2 --output text)
  echo "zulu_ohio_management_outboundresolver_ds_rule_rs_arn=$zulu_ohio_management_outboundresolver_ds_rule_rs_arn"

  # Accept ResourceShare Invitation in Production Account
  profile=$production_profile

  zulu_ohio_production_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$zulu_ohio_management_outboundresolver_ds_rule_rs_arn" \
                                                                                                 --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                                 --profile $profile --region us-east-2 --output text)
  echo "zulu_ohio_production_outboundresolver_ds_rule_rsi_arn=$zulu_ohio_production_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $zulu_ohio_production_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region us-east-2 --output text

  # Accept ResourceShare Invitation in Development Account
  profile=$development_profile

  zulu_ohio_development_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$zulu_ohio_management_outboundresolver_ds_rule_rs_arn" \
                                                                                                  --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                                  --profile $profile --region us-east-2 --output text)
  echo "zulu_ohio_development_outboundresolver_ds_rule_rsi_arn=$zulu_ohio_development_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $zulu_ohio_development_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region us-east-2 --output text
fi

# Associate Zulu Ohio Management Outbound Resolver Directory Service Rule with VPCs in the Production Account
profile=$production_profile
aws route53resolver associate-resolver-rule --name Zulu-Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $zulu_ohio_management_outboundresolver_ds_rule_id \
                                            --vpc-id $zulu_ohio_production_vpc_id \
                                            --profile $profile --region us-east-2 --output text

# Associate Zulu Ohio Management Outbound Resolver Directory Service Rule with VPCs in the Development Account
profile=$development_profile
aws route53resolver associate-resolver-rule --name Zulu-Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $zulu_ohio_management_outboundresolver_ds_rule_id \
                                            --vpc-id $zulu_ohio_development_vpc_id \
                                            --profile $profile --region us-east-2 --output text


## Alfa Ireland Management Outbound Resolver Directory Service Rule ###################################################
profile=$management_profile

# Create Alfa Ireland Management Outbound Resolver Directory Service Rule
alfa_ireland_management_outboundresolver_ds_rule_id=$(aws route53resolver create-resolver-rule --resolver-endpoint-id $ireland_management_outboundresolver_endpoint_id \
                                                                                               --name Alfa-Management-OutboundResolverDirectoryServiceRule \
                                                                                               --rule-type FORWARD \
                                                                                               --domain-name $alfa_ireland_management_directory_domain \
                                                                                               --target-ips $(echo $alfa_ireland_management_directory_dc_ips | sed -e "s/^/Ip=/;s/,/ Ip=/g") \
                                                                                               --creator-request-id $(date +%s) \
                                                                                               --tags Key=Name,Value=Alfa-Management-OutboundResolverDirectoryServiceRule Key=Company,Value=Alfa Key=Environment,Value=Management \
                                                                                               --query 'ResolverRule.Id' \
                                                                                               --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_management_outboundresolver_ds_rule_id=$alfa_ireland_management_outboundresolver_ds_rule_id"

alfa_ireland_management_outboundresolver_ds_rule_arn=$(aws route53resolver get-resolver-rule --resolver-rule-id $alfa_ireland_management_outboundresolver_ds_rule_id \
                                                                                             --query 'ResolverRule.Arn' \
                                                                                             --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_management_outboundresolver_ds_rule_arn=$alfa_ireland_management_outboundresolver_ds_rule_arn"

# Share Alfa Ireland Management Outbound Resolver Directory Service Rule
if [ ! -z $organization_id ]; then
  # Share Alfa Ireland Management Outbound Resolver Directory Service Rule with Organization (works with MJC Consulting)
  # TODO: Logic needed to share with organization likely different than per-account logic below.
  echo "Logic not correct!"
  exit 2
else
  # Share Alfa Ireland Management Outbound Resolver Directory Service Rule with Specific Accounts (works with CaMeLz)
  # Accept ResourceShare Invitation in Recovery Account
  profile=$recovery_profile

  alfa_ireland_recovery_outboundresolver_ds_rule_rsi_arn=$(aws ram get-resource-share-invitations --resource-share-arns "$alfa_ireland_management_outboundresolver_ds_rule_rs_arn" \
                                                                                                  --query 'resourceShareInvitations[0].resourceShareInvitationArn' \
                                                                                                  --profile $profile --region eu-west-1 --output text)
  echo "alfa_ireland_recovery_outboundresolver_ds_rule_rsi_arn=$alfa_ireland_recovery_outboundresolver_ds_rule_rsi_arn"

  aws ram accept-resource-share-invitation --resource-share-invitation-arn $alfa_ireland_recovery_outboundresolver_ds_rule_rsi_arn \
                                           --profile $profile --region eu-west-1 --output text
fi

# Associate Alfa Ireland Management Outbound Resolver Directory Service Rule with VPCs in the Recovery Account
profile=$recovery_profile

aws route53resolver associate-resolver-rule --name Alfa-Management-OutboundResolverDirectoryServiceRule \
                                            --resolver-rule-id $alfa_ireland_management_outboundresolver_ds_rule_id \
                                            --vpc-id $alfa_ireland_recovery_vpc_id \
                                            --profile $profile --region eu-west-1 --output text
