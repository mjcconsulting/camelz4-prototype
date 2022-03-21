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
## Directory Service - OneGlobal (Shared) Model #######################################################################
#######################################################################################################################

## Global Management Directory Service ################################################################################
profile=$management_profile

# Create Directory Service
echo "global_management_directory_domain=$global_management_directory_domain"
echo "global_management_directory_netbios_domain=$global_management_directory_netbios_domain"
echo "global_management_directory_admin_password=$global_management_directory_admin_password"
global_management_directory_id=$(aws ds create-microsoft-ad --name $global_management_directory_domain \
                                                            --short-name $global_management_directory_netbios_domain \
                                                            --description Management-DirectoryService \
                                                            --password $global_management_directory_admin_password \
                                                            --edition Standard \
                                                            --vpc-settings "VpcId=$global_management_vpc_id,SubnetIds=$global_management_directory_subneta_id,$global_management_directory_subnetb_id" \
                                                            --tags Key=Name,Value=Management-DirectoryService Key=Company,Value=CaMeLz Key=Environment,Value=Management Key=Utility,Value=DirectoryService Key=Project,Value="CaMeLz4 POC" Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                                                            --query 'DirectoryId' \
                                                            --profile $profile --region us-east-1 --output text)
echo "global_management_directory_id=$global_management_directory_id"

global_management_directory_sg_id=$(aws ds describe-directories --directory-ids  $global_management_directory_id \
                                                                --query 'DirectoryDescriptions[0].VpcSettings.SecurityGroupId' \
                                                                --profile $profile --region us-east-1 --output text)
echo "global_management_directory_sg_id=$global_management_directory_sg_id"

aws ec2 create-tags --resources $global_management_directory_sg_id \
                    --tags Key=Name,Value=Management-DirectoryService-DomainControllersSecurityGroup \
                    --profile $profile --region us-east-1 --output text

global_management_directory_dc_ips=$(aws ds describe-domain-controllers --directory-id $global_management_directory_id \
                                                                        --query 'DomainControllers[*].DnsIpAddr' \
                                                                        --profile $profile --region us-east-1 --output text | tr "\t" ",")
echo "global_management_directory_dc_ips=$global_management_directory_dc_ips"


# Share Directory Service
if [ ! -z $organization_id ]; then
  # Share Directory with Organization (works with MJC Consulting)
  # TODO: This is NOT how this would work - The Directory needs to be created in the Organization Account,
  #       so once we have CaMeLz variant working, I need to go through this again working with the Organization account
  #       to nail down the final logic
  echo "Logic not correct!"
  exit 2
  #global_management_directory_id=$(aws ds share-directory --directory-id $global_management_directory_id \
  #                                                        --share-method ORGANIZATIONS \
  #                                                        --query 'SharedDirectoryId' \
  #                                                        --profile $profile --region us-east-1 --output text)
else
  profile=$management_profile

  # Share Directory with the Core Account (works with CaMeLz)
  global_core_directory_id=$(aws ds share-directory --directory-id $global_management_directory_id \
                                                    --share-method HANDSHAKE \
                                                    --share-target Id=$core_account_id,Type=ACCOUNT \
                                                    --share-notes "Sharing Global Management-DirectoryService (us-east-1)" \
                                                    --query 'SharedDirectoryId' \
                                                    --profile $profile --region us-east-1 --output text)
  echo "global_core_directory_id=$global_core_directory_id"

  global_core_directory_dc_ips=$global_management_directory_dc_ips
  echo "global_core_directory_dc_ips=$global_core_directory_dc_ips"

  # Share Directory with the Log Account (works with CaMeLz)
  global_log_directory_id=$(aws ds share-directory --directory-id $global_management_directory_id \
                                                   --share-method HANDSHAKE \
                                                   --share-target Id=$log_account_id,Type=ACCOUNT \
                                                   --share-notes "Sharing Global Management-DirectoryService (us-east-1)" \
                                                   --query 'SharedDirectoryId' \
                                                   --profile $profile --region us-east-1 --output text)
  echo "global_log_directory_id=$global_log_directory_id"

  global_log_directory_dc_ips=$global_management_directory_dc_ips
  echo "global_log_directory_dc_ips=$global_log_directory_dc_ips"
fi

# Accept the Shared Directory
if [ -z $organization_id ]; then
  # Accept Shared Directory in Core Account
  profile=$core_profile

  aws ds accept-shared-directory --shared-directory-id $global_core_directory_id \
                                 --profile $profile --region us-east-1 --output text

  # Accept Shared Directory in Log Account
  profile=$log_profile

  aws ds accept-shared-directory --shared-directory-id $global_log_directory_id \
                                 --profile $profile --region us-east-1 --output text
fi


## Ohio Management Directory Service ##################################################################################
profile=$management_profile

# Create Directory Service
echo "ohio_management_directory_domain=$ohio_management_directory_domain"
echo "ohio_management_directory_netbios_domain=$ohio_management_directory_netbios_domain"
echo "ohio_management_directory_admin_password=$ohio_management_directory_admin_password"
ohio_management_directory_id=$(aws ds create-microsoft-ad --name $ohio_management_directory_domain \
                                                          --short-name $ohio_management_directory_netbios_domain \
                                                          --description Management-DirectoryService \
                                                          --password $ohio_management_directory_admin_password \
                                                          --edition Standard \
                                                          --vpc-settings "VpcId=$ohio_management_vpc_id,SubnetIds=$ohio_management_directory_subneta_id,$ohio_management_directory_subnetb_id" \
                                                          --tags Key=Name,Value=Management-DirectoryService Key=Company,Value=CaMeLz Key=Environment,Value=Management Key=Utility,Value=DirectoryService Key=Project,Value="CaMeLz4 POC" Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                                                          --query 'DirectoryId' \
                                                          --profile $profile --region us-east-2 --output text)
echo "ohio_management_directory_id=$ohio_management_directory_id"

ohio_management_directory_sg_id=$(aws ds describe-directories --directory-ids  $ohio_management_directory_id \
                                                              --query 'DirectoryDescriptions[0].VpcSettings.SecurityGroupId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "ohio_management_directory_sg_id=$ohio_management_directory_sg_id"

aws ec2 create-tags --resources $ohio_management_directory_sg_id \
                    --tags Key=Name,Value=Management-DirectoryService-DomainControllersSecurityGroup \
                    --profile $profile --region us-east-2 --output text

ohio_management_directory_dc_ips=$(aws ds describe-domain-controllers --directory-id $ohio_management_directory_id \
                                                                      --query 'DomainControllers[*].DnsIpAddr' \
                                                                      --profile $profile --region us-east-2 --output text | tr "\t" ",")
echo "ohio_management_directory_dc_ips=$ohio_management_directory_dc_ips"

# Share Directory Service
if [ ! -z $organization_id ]; then
  # Share Directory with Organization (works with MJC Consulting)
  # TODO: This is NOT how this would work - The Directory needs to be created in the Organization Account,
  #       so once we have CaMeLz variant working, I need to go through this again working with the Organization account
  #       to nail down the final logic
  echo "Logic not correct!"
  exit 2
  #ohio_management_directory_id=$(aws ds share-directory --directory-id $ohio_management_directory_id \
  #                                                      --share-method ORGANIZATIONS \
  #                                                      --query 'SharedDirectoryId' \
  #                                                      --profile $profile --region us-east-2 --output text)
else
  profile=$management_profile

  # Share Directory with the Core Account (works with CaMeLz)
  ohio_core_directory_id=$(aws ds share-directory --directory-id $ohio_management_directory_id \
                                                  --share-method HANDSHAKE \
                                                  --share-target Id=$core_account_id,Type=ACCOUNT \
                                                  --share-notes "Sharing Regional Management-DirectoryService for us-east-2" \
                                                  --query 'SharedDirectoryId' \
                                                  --profile $profile --region us-east-2 --output text)
  echo "ohio_core_directory_id=$ohio_core_directory_id"

  ohio_core_directory_dc_ips=$ohio_management_directory_dc_ips
  echo "ohio_core_directory_dc_ips=$ohio_core_directory_dc_ips"

  # Share Directory with the Log Account (works with CaMeLz)
  ohio_log_directory_id=$(aws ds share-directory --directory-id $ohio_management_directory_id \
                                                 --share-method HANDSHAKE \
                                                 --share-target Id=$log_account_id,Type=ACCOUNT \
                                                 --share-notes "Sharing Regional Management-DirectoryService for us-east-2" \
                                                 --query 'SharedDirectoryId' \
                                                 --profile $profile --region us-east-2 --output text)
  echo "ohio_log_directory_id=$ohio_log_directory_id"

  ohio_log_directory_dc_ips=$ohio_management_directory_dc_ips
  echo "ohio_log_directory_dc_ips=$ohio_log_directory_dc_ips"

  # Share Directory with the Production Account (works with CaMeLz)
  ohio_production_directory_id=$(aws ds share-directory --directory-id $ohio_management_directory_id \
                                                        --share-method HANDSHAKE \
                                                        --share-target Id=$production_account_id,Type=ACCOUNT \
                                                        --share-notes "Sharing Regional Management-DirectoryService for us-east-2" \
                                                        --query 'SharedDirectoryId' \
                                                        --profile $profile --region us-east-2 --output text)
  echo "ohio_production_directory_id=$ohio_production_directory_id"

  ohio_production_directory_dc_ips=$ohio_management_directory_dc_ips
  echo "ohio_production_directory_dc_ips=$ohio_production_directory_dc_ips"

  # Share Directory with the Recovery Account (works with CaMeLz)
  # - Note: Hard limit of 5 accounts with Standard Edition
  #ohio_recovery_directory_id=$(aws ds share-directory --directory-id $ohio_management_directory_id \
  #                                                    --share-method HANDSHAKE \
  #                                                    --share-target Id=$recovery_account_id,Type=ACCOUNT \
  #                                                    --share-notes "Sharing Regional Management-DirectoryService for us-east-2" \
  #                                                    --query 'SharedDirectoryId' \
  #                                                    --profile $profile --region us-east-2 --output text)
  #echo "ohio_recovery_directory_id=$ohio_recovery_directory_id"
  #
  #ohio_recovery_directory_dc_ips=$ohio_management_directory_dc_ips
  #echo "ohio_recovery_directory_dc_ips=$ohio_recovery_directory_dc_ips"

  # Share Directory with the Testing Account (works with CaMeLz)
  ohio_testing_directory_id=$(aws ds share-directory --directory-id $ohio_management_directory_id \
                                                     --share-method HANDSHAKE \
                                                     --share-target Id=$testing_account_id,Type=ACCOUNT \
                                                     --share-notes "Sharing Regional Management-DirectoryService for us-east-2" \
                                                     --query 'SharedDirectoryId' \
                                                     --profile $profile --region us-east-2 --output text)
  echo "ohio_testing_directory_id=$ohio_testing_directory_id"

  ohio_testing_directory_dc_ips=$ohio_management_directory_dc_ips
  echo "ohio_testing_directory_dc_ips=$ohio_testing_directory_dc_ips"

  # Share Directory with the Development Account (works with CaMeLz)
  ohio_development_directory_id=$(aws ds share-directory --directory-id $ohio_management_directory_id \
                                                         --share-method HANDSHAKE \
                                                         --share-target Id=$development_account_id,Type=ACCOUNT \
                                                         --share-notes "Sharing Regional Management-DirectoryService for us-east-2" \
                                                         --query 'SharedDirectoryId' \
                                                         --profile $profile --region us-east-2 --output text)
  echo "ohio_development_directory_id=$ohio_development_directory_id"

  ohio_development_directory_dc_ips=$ohio_management_directory_dc_ips
  echo "ohio_development_directory_dc_ips=$ohio_development_directory_dc_ips"
fi

# Accept the Shared Directory
if [ -z $organization_id ]; then
  # Accept Shared Directory in Core Account
  profile=$core_profile

  aws ds accept-shared-directory --shared-directory-id $ohio_core_directory_id \
                                 --profile $profile --region us-east-2 --output text

  # Accept Shared Directory in Log Account
  profile=$log_profile

  aws ds accept-shared-directory --shared-directory-id $ohio_log_directory_id \
                                 --profile $profile --region us-east-2 --output text

  # Accept Shared Directory in Production Account
  profile=$production_profile

  aws ds accept-shared-directory --shared-directory-id $ohio_production_directory_id \
                                 --profile $profile --region us-east-2 --output text

  # Accept Shared Directory in Recovery Account
  # - Note: Hard limit of 5 accounts with Standard Edition
  #profile=$recovery_profile
  #
  #aws ds accept-shared-directory --shared-directory-id $ohio_recovery_directory_id \
  #                               --profile $profile --region us-east-2 --output text

  # Accept Shared Directory in Testing Account
  profile=$testing_profile

  aws ds accept-shared-directory --shared-directory-id $ohio_testing_directory_id \
                                 --profile $profile --region us-east-2 --output text

  # Accept Shared Directory in Development Account
  profile=$development_profile

  aws ds accept-shared-directory --shared-directory-id $ohio_development_directory_id \
                                 --profile $profile --region us-east-2 --output text
fi


## Ireland Management Directory Service ###############################################################################
profile=$management_profile

# Create Directory Service
echo "ireland_management_directory_domain=$ireland_management_directory_domain"
echo "ireland_management_directory_netbios_domain=$ireland_management_directory_netbios_domain"
echo "ireland_management_directory_admin_password=$ireland_management_directory_admin_password"
ireland_management_directory_id=$(aws ds create-microsoft-ad --name $ireland_management_directory_domain \
                                                             --short-name $ireland_management_directory_netbios_domain \
                                                             --description Management-DirectoryService \
                                                             --password $ireland_management_directory_admin_password \
                                                             --edition Standard \
                                                             --vpc-settings "VpcId=$ireland_management_vpc_id,SubnetIds=$ireland_management_directory_subneta_id,$ireland_management_directory_subnetb_id" \
                                                             --tags Key=Name,Value=Management-DirectoryService Key=Company,Value=CaMeLz Key=Environment,Value=Management Key=Utility,Value=DirectoryService Key=Project,Value="CaMeLz4 POC" Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                                                             --query 'DirectoryId' \
                                                             --profile $profile --region eu-west-1 --output text)
echo "ireland_management_directory_id=$ireland_management_directory_id"

ireland_management_directory_sg_id=$(aws ds describe-directories --directory-ids  $ireland_management_directory_id \
                                                                 --query 'DirectoryDescriptions[0].VpcSettings.SecurityGroupId' \
                                                                 --profile $profile --region eu-west-1 --output text)
echo "ireland_management_directory_sg_id=$ireland_management_directory_sg_id"

aws ec2 create-tags --resources $ireland_management_directory_sg_id \
                    --tags Key=Name,Value=Management-DirectoryService-DomainControllersSecurityGroup \
                    --profile $profile --region eu-west-1 --output text

ireland_management_directory_dc_ips=$(aws ds describe-domain-controllers --directory-id $ireland_management_directory_id \
                                                                         --query 'DomainControllers[*].DnsIpAddr' \
                                                                         --profile $profile --region eu-west-1 --output text | tr "\t" ",")
echo "ireland_management_directory_dc_ips=$ireland_management_directory_dc_ips"

# Share Directory Service
if [ ! -z $organization_id ]; then
  # Share Directory with Organization (works with MJC Consulting)
  # TODO: This is NOT how this would work - The Directory needs to be created in the Organization Account,
  #       so once we have CaMeLz variant working, I need to go through this again working with the Organization account
  #       to nail down the final logic
  echo "Logic not correct!"
  exit 2
  #ireland_management_directory_id=$(aws ds share-directory --directory-id $ireland_management_directory_id \
  #                                                         --share-method ORGANIZATIONS \
  #                                                         --query 'SharedDirectoryId' \
  #                                                         --profile $profile --region eu-west-1 --output text)
else
  profile=$management_profile

  # Share Directory with the Core Account (works with CaMeLz)
  ireland_core_directory_id=$(aws ds share-directory --directory-id $ireland_management_directory_id \
                                                     --share-method HANDSHAKE \
                                                     --share-target Id=$core_account_id,Type=ACCOUNT \
                                                     --share-notes "Sharing Regional Management-DirectoryService for eu-west-1" \
                                                     --query 'SharedDirectoryId' \
                                                     --profile $profile --region eu-west-1 --output text)
  echo "ireland_core_directory_id=$ireland_core_directory_id"

  ireland_core_directory_dc_ips=$ireland_management_directory_dc_ips
  echo "ireland_core_directory_dc_ips=$ireland_core_directory_dc_ips"

  # Share Directory with the Log Account (works with CaMeLz)
  ireland_log_directory_id=$(aws ds share-directory --directory-id $ireland_management_directory_id \
                                                    --share-method HANDSHAKE \
                                                    --share-target Id=$log_account_id,Type=ACCOUNT \
                                                    --share-notes "Sharing Regional Management-DirectoryService for eu-west-1" \
                                                    --query 'SharedDirectoryId' \
                                                    --profile $profile --region eu-west-1 --output text)
  echo "ireland_log_directory_id=$ireland_log_directory_id"

  ireland_log_directory_dc_ips=$ireland_management_directory_dc_ips
  echo "ireland_log_directory_dc_ips=$ireland_log_directory_dc_ips"

  # Share Directory with the Production Account (works with CaMeLz)
  ireland_production_directory_id=$(aws ds share-directory --directory-id $ireland_management_directory_id \
                                                           --share-method HANDSHAKE \
                                                           --share-target Id=$production_account_id,Type=ACCOUNT \
                                                           --share-notes "Sharing Regional Management-DirectoryService for eu-west-1" \
                                                           --query 'SharedDirectoryId' \
                                                           --profile $profile --region eu-west-1 --output text)
  echo "ireland_production_directory_id=$ireland_production_directory_id"

  ireland_production_directory_dc_ips=$ireland_management_directory_dc_ips
  echo "ireland_production_directory_dc_ips=$ireland_production_directory_dc_ips"

  # Share Directory with the Recovery Account (works with CaMeLz)
  ireland_recovery_directory_id=$(aws ds share-directory --directory-id $ireland_management_directory_id \
                                                         --share-method HANDSHAKE \
                                                         --share-target Id=$recovery_account_id,Type=ACCOUNT \
                                                         --share-notes "Sharing Regional Management-DirectoryService for eu-west-1" \
                                                         --query 'SharedDirectoryId' \
                                                         --profile $profile --region eu-west-1 --output text)
  echo "ireland_recovery_directory_id=$ireland_recovery_directory_id"

  ireland_recovery_directory_dc_ips=$ireland_management_directory_dc_ips
  echo "ireland_recovery_directory_dc_ips=$ireland_recovery_directory_dc_ips"

  # Share Directory with the Testing Account (works with CaMeLz)
  # - Note: Hard limit of 5 accounts with Standard Edition
  #ireland_testing_directory_id=$(aws ds share-directory --directory-id $ireland_management_directory_id \
  #                                                      --share-method HANDSHAKE \
  #                                                      --share-target Id=$testing_account_id,Type=ACCOUNT \
  #                                                      --share-notes "Sharing Regional Management-DirectoryService for eu-west-1" \
  #                                                      --query 'SharedDirectoryId' \
  #                                                      --profile $profile --region eu-west-1 --output text)
  #echo "ireland_testing_directory_id=$ireland_testing_directory_id"
  #
  #ireland_testing_directory_dc_ips=$ireland_management_directory_dc_ips
  #echo "ireland_testing_directory_dc_ips=$ireland_testing_directory_dc_ips"

  # Share Directory with the Development Account (works with CaMeLz)
  ireland_development_directory_id=$(aws ds share-directory --directory-id $ireland_management_directory_id \
                                                            --share-method HANDSHAKE \
                                                            --share-target Id=$development_account_id,Type=ACCOUNT \
                                                            --share-notes "Sharing Regional Management-DirectoryService for eu-west-1" \
                                                            --query 'SharedDirectoryId' \
                                                            --profile $profile --region eu-west-1 --output text)
  echo "ireland_development_directory_id=$ireland_development_directory_id"

  ireland_development_directory_dc_ips=$ireland_management_directory_dc_ips
  echo "ireland_development_directory_dc_ips=$ireland_development_directory_dc_ips"
fi

# Accept the Shared Directory
if [ -z $organization_id ]; then
  # Accept Shared Directory in Core Account
  profile=$core_profile

  aws ds accept-shared-directory --shared-directory-id $ireland_core_directory_id \
                                 --profile $profile --region eu-west-1 --output text

  # Accept Shared Directory in Log Account
  profile=$log_profile

  aws ds accept-shared-directory --shared-directory-id $ireland_log_directory_id \
                                 --profile $profile --region eu-west-1 --output text

  # Accept Shared Directory in Production Account
  profile=$production_profile

  aws ds accept-shared-directory --shared-directory-id $ireland_production_directory_id \
                                 --profile $profile --region eu-west-1 --output text

  # Accept Shared Directory in Recovery Account
  profile=$recovery_profile

  aws ds accept-shared-directory --shared-directory-id $ireland_recovery_directory_id \
                                 --profile $profile --region eu-west-1 --output text

  # Accept Shared Directory in Testing Account
  # - Note: Hard limit of 5 accounts with Standard Edition
  #profile=$testing_profile
  #
  #aws ds accept-shared-directory --shared-directory-id $ireland_testing_directory_id \
  #                               --profile $profile --region eu-west-1 --output text

  # Accept Shared Directory in Development Account
  profile=$development_profile

  aws ds accept-shared-directory --shared-directory-id $ireland_development_directory_id \
                                 --profile $profile --region eu-west-1 --output text
fi
