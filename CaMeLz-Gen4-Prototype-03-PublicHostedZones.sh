#!/usr/bin/env bash
#
# This is part of a set of scripts to setup a realistic CaMeLz Prototype which uses multiple Accounts, VPCs and
# Transit Gateway to connect them all
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
## Public Hosted Zones ################################################################################################
#######################################################################################################################

## Global Management Public Hosted Zone ###############################################################################
profile=$management_profile

# Reference Global Management Public Hosted Zone
echo "global_management_public_hostedzone_id=$global_management_public_hostedzone_id"


## Global Core Public Hosted Zone #####################################################################################
profile=$core_profile

# Create Public Hosted Zone
global_core_public_hostedzone_id=$(aws route53 create-hosted-zone --name $global_core_public_domain \
                                                                  --hosted-zone-config Comment="Public Zone for $global_core_public_domain",PrivateZone=false \
                                                                  --caller-reference $(date +%s) \
                                                                  --query 'HostedZone.Id' \
                                                                  --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "global_core_public_hostedzone_id=$global_core_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Global Log Public Hosted Zone ######################################################################################
profile=$log_profile

# Create Public Hosted Zone
global_log_public_hostedzone_id=$(aws route53 create-hosted-zone --name $global_log_public_domain \
                                                                 --hosted-zone-config Comment="Public Zone for $global_log_public_domain",PrivateZone=false \
                                                                 --caller-reference $(date +%s) \
                                                                 --query 'HostedZone.Id' \
                                                                 --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "global_log_public_hostedzone_id=$global_log_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Ohio Management Public Hosted Zone #################################################################################
profile=$management_profile

# Create Public Hosted Zone
ohio_management_public_hostedzone_id=$(aws route53 create-hosted-zone --name $ohio_management_public_domain \
                                                                      --hosted-zone-config Comment="Public Zone for $ohio_management_public_domain",PrivateZone=false \
                                                                      --caller-reference $(date +%s) \
                                                                      --query 'HostedZone.Id' \
                                                                      --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "ohio_management_public_hostedzone_id=$ohio_management_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Ohio Core Public Hosted Zone #######################################################################################
profile=$core_profile

# Create Public Hosted Zone
ohio_core_public_hostedzone_id=$(aws route53 create-hosted-zone --name $ohio_core_public_domain \
                                                                --hosted-zone-config Comment="Public Zone for $ohio_core_public_domain",PrivateZone=false \
                                                                --caller-reference $(date +%s) \
                                                                --query 'HostedZone.Id' \
                                                                --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "ohio_core_public_hostedzone_id=$ohio_core_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Ohio Log Public Hosted Zone ########################################################################################
profile=$log_profile

# Create Public Hosted Zone
ohio_log_public_hostedzone_id=$(aws route53 create-hosted-zone --name $ohio_log_public_domain \
                                                               --hosted-zone-config Comment="Public Zone for $ohio_log_public_domain",PrivateZone=false \
                                                               --caller-reference $(date +%s) \
                                                               --query 'HostedZone.Id' \
                                                               --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "ohio_log_public_hostedzone_id=$ohio_log_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Alfa Ohio Production Public Hosted Zone ############################################################################
profile=$production_profile

# Create Public Hosted Zone
alfa_ohio_production_public_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_ohio_production_public_domain \
                                                                           --hosted-zone-config Comment="Public Zone for $alfa_ohio_production_public_domain",PrivateZone=false \
                                                                           --caller-reference $(date +%s) \
                                                                           --query 'HostedZone.Id' \
                                                                           --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "alfa_ohio_production_public_hostedzone_id=$alfa_ohio_production_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Alfa Ohio Testing Public Hosted Zone ###############################################################################
profile=$testing_profile

# Create Public Hosted Zone
alfa_ohio_testing_public_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_ohio_testing_public_domain \
                                                                        --hosted-zone-config Comment="Public Zone for $alfa_ohio_testing_public_domain",PrivateZone=false \
                                                                        --caller-reference $(date +%s) \
                                                                        --query 'HostedZone.Id' \
                                                                        --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "alfa_ohio_testing_public_hostedzone_id=$alfa_ohio_testing_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Alfa Ohio Development Public Hosted Zone ###########################################################################
profile=$development_profile

# Create Public Hosted Zone
alfa_ohio_development_public_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_ohio_development_public_domain \
                                                                            --hosted-zone-config Comment="Public Zone for $alfa_ohio_development_public_domain",PrivateZone=false \
                                                                            --caller-reference $(date +%s) \
                                                                            --query 'HostedZone.Id' \
                                                                            --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "alfa_ohio_development_public_hostedzone_id=$alfa_ohio_development_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Zulu Ohio Production Public Hosted Zone ############################################################################
profile=$production_profile

# Create Public Hosted Zone
zulu_ohio_production_public_hostedzone_id=$(aws route53 create-hosted-zone --name $zulu_ohio_production_public_domain \
                                                                           --hosted-zone-config Comment="Public Zone for $zulu_ohio_production_public_domain",PrivateZone=false \
                                                                           --caller-reference $(date +%s) \
                                                                           --query 'HostedZone.Id' \
                                                                           --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "zulu_ohio_production_public_hostedzone_id=$zulu_ohio_production_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Zulu Ohio Development Public Hosted Zone ###########################################################################
profile=$development_profile

# Create Public Hosted Zone
zulu_ohio_development_public_hostedzone_id=$(aws route53 create-hosted-zone --name $zulu_ohio_development_public_domain \
                                                                            --hosted-zone-config Comment="Public Zone for $zulu_ohio_development_public_domain",PrivateZone=false \
                                                                            --caller-reference $(date +%s) \
                                                                            --query 'HostedZone.Id' \
                                                                            --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "zulu_ohio_development_public_hostedzone_id=$zulu_ohio_development_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Ireland Management Public Hosted Zone ##############################################################################
profile=$management_profile

# Create Public Hosted Zone
ireland_management_public_hostedzone_id=$(aws route53 create-hosted-zone --name $ireland_management_public_domain \
                                                                         --hosted-zone-config Comment="Public Zone for $ireland_management_public_domain",PrivateZone=false \
                                                                         --caller-reference $(date +%s) \
                                                                         --query 'HostedZone.Id' \
                                                                         --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "ireland_management_public_hostedzone_id=$ireland_management_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Ireland Core Public Hosted Zone ####################################################################################
profile=$core_profile

# Create Public Hosted Zone
ireland_core_public_hostedzone_id=$(aws route53 create-hosted-zone --name $ireland_core_public_domain \
                                                                   --hosted-zone-config Comment="Public Zone for $ireland_core_public_domain",PrivateZone=false \
                                                                   --caller-reference $(date +%s) \
                                                                   --query 'HostedZone.Id' \
                                                                   --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "ireland_core_public_hostedzone_id=$ireland_core_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Ireland Log Public Hosted Zone #####################################################################################
profile=$log_profile

# Create Public Hosted Zone
ireland_log_public_hostedzone_id=$(aws route53 create-hosted-zone --name $ireland_log_public_domain \
                                                                  --hosted-zone-config Comment="Public Zone for $ireland_log_public_domain",PrivateZone=false \
                                                                  --caller-reference $(date +%s) \
                                                                  --query 'HostedZone.Id' \
                                                                  --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "ireland_log_public_hostedzone_id=$ireland_log_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Alfa Ireland Production Public Hosted Zone #########################################################################
profile=$production_profile

# Create Public Hosted Zone
alfa_ireland_production_public_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_ireland_production_public_domain \
                                                                              --hosted-zone-config Comment="Public Zone for $alfa_ireland_production_public_domain",PrivateZone=false \
                                                                              --caller-reference $(date +%s) \
                                                                              --query 'HostedZone.Id' \
                                                                              --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "alfa_ireland_production_public_hostedzone_id=$alfa_ireland_production_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Alfa Ireland Recovery Public Hosted Zone ###########################################################################
profile=$recovery_profile

# Create Public Hosted Zone
alfa_ireland_recovery_public_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_ireland_recovery_public_domain \
                                                                            --hosted-zone-config Comment="Public Zone for $alfa_ireland_recovery_public_domain",PrivateZone=false \
                                                                            --caller-reference $(date +%s) \
                                                                            --query 'HostedZone.Id' \
                                                                            --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "alfa_ireland_recovery_public_hostedzone_id=$alfa_ireland_recovery_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Alfa Public Hosted Zones ###########################################################################################
profile=$management_profile

# Create LosAngeles Public Hosted Zone
alfa_lax_public_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_lax_public_domain \
                                                               --hosted-zone-config Comment="Public Zone for $alfa_lax_public_domain",PrivateZone=false \
                                                               --caller-reference $(date +%s) \
                                                               --query 'HostedZone.Id' \
                                                               --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "alfa_lax_public_hostedzone_id=$alfa_lax_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare

profile=$management_profile

# Create Miami Public Hosted Zone
alfa_mia_public_hostedzone_id=$(aws route53 create-hosted-zone --name $alfa_mia_public_domain \
                                                               --hosted-zone-config Comment="Public Zone for $alfa_mia_public_domain",PrivateZone=false \
                                                               --caller-reference $(date +%s) \
                                                               --query 'HostedZone.Id' \
                                                               --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "alfa_mia_public_hostedzone_id=$alfa_mia_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## Zulu Public Hosted Zone ############################################################################################
profile=$management_profile

# Create Public Hosted Zone
zulu_dfw_public_hostedzone_id=$(aws route53 create-hosted-zone --name $zulu_dfw_public_domain \
                                                               --hosted-zone-config Comment="Public Zone for $zulu_dfw_public_domain",PrivateZone=false \
                                                               --caller-reference $(date +%s) \
                                                               --query 'HostedZone.Id' \
                                                               --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "zulu_dfw_public_hostedzone_id=$zulu_dfw_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare


## CaMeLz Public Hosted Zones ############################################################################################
profile=$management_profile

# Create Public Hosted Zone
cml_sba_public_hostedzone_id=$(aws route53 create-hosted-zone --name $cml_sba_public_domain \
                                                              --hosted-zone-config Comment="Public Zone for $cml_sba_public_domain",PrivateZone=false \
                                                              --caller-reference $(date +%s) \
                                                              --query 'HostedZone.Id' \
                                                              --profile $profile --region us-east-1 --output text | cut -f3 -d /)
echo "cml_sba_public_hostedzone_id=$cml_sba_public_hostedzone_id"

# Note: You must manually create the NS records to hook this into the parent in both AWS and CloudFlare
