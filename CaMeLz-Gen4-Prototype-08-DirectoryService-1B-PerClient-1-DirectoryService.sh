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
## Directory Service - PerClient Model ################################################################################
#######################################################################################################################
## Note: With the PerClient Model, each client has their own separate Directory Service Hierarchy of connected       ##
##       Forests, isolated from the Shared Directory Service Hierarchy of connected Forests in the OneGlobal model   ##
##       These are used exclusively for the client's Windows Instances.                                              ##
## Note: Because this is considered part of Management Infrastructure (at least currently), these Directory Service  ##
##       resources are created within the Global or Regional Management Accounts/VPCs.                               ##
## Note: But, we need to have a separate Domain-Joined ActiveDirectoryManagement Instance to manage each resource,   ##
##       and, since client's do not have a Management VPC, these are placed within the shared Management VPC, and    ##
##       are therefore part of the shared Global or Region parent domain (i.e. dxc-ap.com, us-east-2.dxc-ap.com)     ##
## Note: If a client only has resources deployed in a single Region, to save on costs, we can avoid creating a       ##
##       Global DS instance for them, but instead create their Users/Groups in that Region, and then have no Trust   ##
##       relationships to create. The Alfa example client has the full hierarchy, but Zulu has this single copy.     ##
#######################################################################################################################

## Alfa Global Management Directory Service ###########################################################################
profile=$management_profile

# Create Directory Service
echo "alfa_global_management_directory_domain=$alfa_global_management_directory_domain"
echo "alfa_global_management_directory_netbios_domain=$alfa_global_management_directory_netbios_domain"
echo "alfa_global_management_directory_admin_password=$alfa_global_management_directory_admin_password"
alfa_global_management_directory_id=$(aws ds create-microsoft-ad --name $alfa_global_management_directory_domain \
                                                                 --short-name $alfa_global_management_directory_netbios_domain \
                                                                 --description Alfa-Management-DirectoryService \
                                                                 --password $alfa_global_management_directory_admin_password \
                                                                 --edition Standard \
                                                                 --vpc-settings "VpcId=$global_management_vpc_id,SubnetIds=$global_management_directory_subneta_id,$global_management_directory_subnetb_id" \
                                                                 --tags Key=Name,Value=Alfa-Management-DirectoryService Key=Company,Value=Alfa Key=Environment,Value=Management Key=Utility,Value=DirectoryService Key=Project,Value="CAMELZ3 POC" Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                                                                 --query 'DirectoryId' \
                                                                 --profile $profile --region us-east-1 --output text)
echo "alfa_global_management_directory_id=$alfa_global_management_directory_id"

alfa_global_management_directory_sg_id=$(aws ds describe-directories --directory-ids  $alfa_global_management_directory_id \
                                                                     --query 'DirectoryDescriptions[0].VpcSettings.SecurityGroupId' \
                                                                     --profile $profile --region us-east-1 --output text)
echo "alfa_global_management_directory_sg_id=$alfa_global_management_directory_sg_id"

aws ec2 create-tags --resources $alfa_global_management_directory_sg_id \
                    --tags Key=Name,Value=Alfa-Management-DirectoryService-DomainControllersSecurityGroup \
                    --profile $profile --region us-east-1 --output text

alfa_global_management_directory_dc_ips=$(aws ds describe-domain-controllers --directory-id $alfa_global_management_directory_id \
                                                                             --query 'DomainControllers[*].DnsIpAddr' \
                                                                             --profile $profile --region us-east-1 --output text | tr "\t" ",")
echo "alfa_global_management_directory_dc_ips=$alfa_global_management_directory_dc_ips"


## Alfa Ohio Management Directory Service #############################################################################
profile=$management_profile

# Create Directory Service
echo "alfa_ohio_management_directory_domain=$alfa_ohio_management_directory_domain"
echo "alfa_ohio_management_directory_netbios_domain=$alfa_ohio_management_directory_netbios_domain"
echo "alfa_ohio_management_directory_admin_password=$alfa_ohio_management_directory_admin_password"
alfa_ohio_management_directory_id=$(aws ds create-microsoft-ad --name $alfa_ohio_management_directory_domain \
                                                               --short-name $alfa_ohio_management_directory_netbios_domain \
                                                               --description Management-DirectoryService \
                                                               --password $alfa_ohio_management_directory_admin_password \
                                                               --edition Standard \
                                                               --vpc-settings "VpcId=$ohio_management_vpc_id,SubnetIds=$ohio_management_directory_subneta_id,$ohio_management_directory_subnetb_id" \
                                                               --tags Key=Name,Value=Alfa-Management-DirectoryService Key=Company,Value=Alfa Key=Environment,Value=Management Key=Utility,Value=DirectoryService Key=Project,Value="CAMELZ3 POC" Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                                                               --query 'DirectoryId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_management_directory_id=$alfa_ohio_management_directory_id"

alfa_ohio_management_directory_sg_id=$(aws ds describe-directories --directory-ids  $alfa_ohio_management_directory_id \
                                                                   --query 'DirectoryDescriptions[0].VpcSettings.SecurityGroupId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_management_directory_sg_id=$alfa_ohio_management_directory_sg_id"

aws ec2 create-tags --resources $alfa_ohio_management_directory_sg_id \
                    --tags Key=Name,Value=Management-DirectoryService-DomainControllersSecurityGroup \
                    --profile $profile --region us-east-2 --output text

alfa_ohio_management_directory_dc_ips=$(aws ds describe-domain-controllers --directory-id $alfa_ohio_management_directory_id \
                                                                           --query 'DomainControllers[*].DnsIpAddr' \
                                                                           --profile $profile --region us-east-2 --output text | tr "\t" ",")
echo "alfa_ohio_management_directory_dc_ips=$alfa_ohio_management_directory_dc_ips"

# Share Directory Service
if [ ! -z $organization_id ]; then
  # Share Directory with Organization (works with MJC Consulting)
  # TODO: This is NOT how this would work - The Directory needs to be created in the Organization Account,
  #       so once we have DXC variant working, I need to go through this again working with the Organization account
  #       to nail down the final logic
  echo "Logic not correct!"
  exit 2
  #ohio_management_directory_id=$(aws ds share-directory --directory-id $ohio_management_directory_id \
  #                                                      --share-method ORGANIZATIONS \
  #                                                      --query 'SharedDirectoryId' \
  #                                                      --profile $profile --region us-east-2 --output text)
else
  profile=$management_profile

  # Share Directory with the Production Account (works with DXC)
  alfa_ohio_production_directory_id=$(aws ds share-directory --directory-id $alfa_ohio_management_directory_id \
                                                             --share-method HANDSHAKE \
                                                             --share-target Id=$production_account_id,Type=ACCOUNT \
                                                             --share-notes "Sharing Regional Management-DirectoryService for us-east-2" \
                                                             --query 'SharedDirectoryId' \
                                                             --profile $profile --region us-east-2 --output text)
  echo "alfa_ohio_production_directory_id=$alfa_ohio_production_directory_id"

  alfa_ohio_production_directory_dc_ips=$alfa_ohio_management_directory_dc_ips
  echo "alfa_ohio_production_directory_dc_ips=$alfa_ohio_production_directory_dc_ips"

  # Share Directory with the Testing Account (works with DXC)
  alfa_ohio_testing_directory_id=$(aws ds share-directory --directory-id $alfa_ohio_management_directory_id \
                                                          --share-method HANDSHAKE \
                                                          --share-target Id=$testing_account_id,Type=ACCOUNT \
                                                          --share-notes "Sharing Regional Management-DirectoryService for us-east-2" \
                                                          --query 'SharedDirectoryId' \
                                                          --profile $profile --region us-east-2 --output text)
  echo "alfa_ohio_testing_directory_id=$alfa_ohio_testing_directory_id"

  alfa_ohio_testing_directory_dc_ips=$alfa_ohio_management_directory_dc_ips
  echo "alfa_ohio_testing_directory_dc_ips=$alfa_ohio_testing_directory_dc_ips"

  # Share Directory with the Development Account (works with DXC)
  alfa_ohio_development_directory_id=$(aws ds share-directory --directory-id $alfa_ohio_management_directory_id \
                                                              --share-method HANDSHAKE \
                                                              --share-target Id=$development_account_id,Type=ACCOUNT \
                                                              --share-notes "Sharing Regional Management-DirectoryService for us-east-2" \
                                                              --query 'SharedDirectoryId' \
                                                              --profile $profile --region us-east-2 --output text)
  echo "alfa_ohio_development_directory_id=$alfa_ohio_development_directory_id"

  alfa_ohio_development_directory_dc_ips=$alfa_ohio_management_directory_dc_ips
  echo "alfa_ohio_development_directory_dc_ips=$alfa_ohio_development_directory_dc_ips"
fi

# Accept the Shared Directory
if [ -z $organization_id ]; then
  # Accept Shared Directory in Production Account
  profile=$production_profile

  aws ds accept-shared-directory --shared-directory-id $alfa_ohio_production_directory_id \
                                 --profile $profile --region us-east-2 --output text

  # Accept Shared Directory in Testing Account
  profile=$testing_profile

  aws ds accept-shared-directory --shared-directory-id $alfa_ohio_testing_directory_id \
                                 --profile $profile --region us-east-2 --output text

  # Accept Shared Directory in Development Account
  profile=$development_profile

  aws ds accept-shared-directory --shared-directory-id $alfa_ohio_development_directory_id \
                                 --profile $profile --region us-east-2 --output text
fi


## Zulu Ohio Management Directory Service #############################################################################
profile=$management_profile

# Create Directory Service
echo "zulu_ohio_management_directory_domain=$zulu_ohio_management_directory_domain"
echo "zulu_ohio_management_directory_netbios_domain=$zulu_ohio_management_directory_netbios_domain"
echo "zulu_ohio_management_directory_admin_password=$zulu_ohio_management_directory_admin_password"
zulu_ohio_management_directory_id=$(aws ds create-microsoft-ad --name $zulu_ohio_management_directory_domain \
                                                               --short-name $zulu_ohio_management_directory_netbios_domain \
                                                               --description Management-DirectoryService \
                                                               --password $zulu_ohio_management_directory_admin_password \
                                                               --edition Standard \
                                                               --vpc-settings "VpcId=$ohio_management_vpc_id,SubnetIds=$ohio_management_directory_subneta_id,$ohio_management_directory_subnetb_id" \
                                                               --tags Key=Name,Value=Zulu-Management-DirectoryService Key=Company,Value=Zulu Key=Environment,Value=Management Key=Utility,Value=DirectoryService Key=Project,Value="CAMELZ3 POC" Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                                                               --query 'DirectoryId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_management_directory_id=$zulu_ohio_management_directory_id"

zulu_ohio_management_directory_sg_id=$(aws ds describe-directories --directory-ids  $zulu_ohio_management_directory_id \
                                                                   --query 'DirectoryDescriptions[0].VpcSettings.SecurityGroupId' \
                                                                   --profile $profile --region us-east-2 --output text)
echo "zulu_ohio_management_directory_sg_id=$zulu_ohio_management_directory_sg_id"

aws ec2 create-tags --resources $zulu_ohio_management_directory_sg_id \
                    --tags Key=Name,Value=Management-DirectoryService-DomainControllersSecurityGroup \
                    --profile $profile --region us-east-2 --output text

zulu_ohio_management_directory_dc_ips=$(aws ds describe-domain-controllers --directory-id $zulu_ohio_management_directory_id \
                                                                           --query 'DomainControllers[*].DnsIpAddr' \
                                                                           --profile $profile --region us-east-2 --output text | tr "\t" ",")
echo "zulu_ohio_management_directory_dc_ips=$zulu_ohio_management_directory_dc_ips"

# Share Directory Service
if [ ! -z $organization_id ]; then
  # Share Directory with Organization (works with MJC Consulting)
  # TODO: This is NOT how this would work - The Directory needs to be created in the Organization Account,
  #       so once we have DXC variant working, I need to go through this again working with the Organization account
  #       to nail down the final logic
  echo "Logic not correct!"
  exit 2
  #ohio_management_directory_id=$(aws ds share-directory --directory-id $ohio_management_directory_id \
  #                                                      --share-method ORGANIZATIONS \
  #                                                      --query 'SharedDirectoryId' \
  #                                                      --profile $profile --region us-east-2 --output text)
else
  profile=$management_profile

  # Share Directory with the Production Account (works with DXC)
  zulu_ohio_production_directory_id=$(aws ds share-directory --directory-id $zulu_ohio_management_directory_id \
                                                             --share-method HANDSHAKE \
                                                             --share-target Id=$production_account_id,Type=ACCOUNT \
                                                             --share-notes "Sharing Regional Management-DirectoryService for us-east-2" \
                                                             --query 'SharedDirectoryId' \
                                                             --profile $profile --region us-east-2 --output text)
  echo "zulu_ohio_production_directory_id=$zulu_ohio_production_directory_id"

  zulu_ohio_production_directory_dc_ips=$zulu_ohio_management_directory_dc_ips
  echo "zulu_ohio_production_directory_dc_ips=$zulu_ohio_production_directory_dc_ips"

  # Share Directory with the Development Account (works with DXC)
  zulu_ohio_development_directory_id=$(aws ds share-directory --directory-id $zulu_ohio_management_directory_id \
                                                              --share-method HANDSHAKE \
                                                              --share-target Id=$development_account_id,Type=ACCOUNT \
                                                              --share-notes "Sharing Regional Management-DirectoryService for us-east-2" \
                                                              --query 'SharedDirectoryId' \
                                                              --profile $profile --region us-east-2 --output text)
  echo "zulu_ohio_development_directory_id=$zulu_ohio_development_directory_id"

  zulu_ohio_development_directory_dc_ips=$zulu_ohio_management_directory_dc_ips
  echo "zulu_ohio_development_directory_dc_ips=$zulu_ohio_development_directory_dc_ips"
fi

# Accept the Shared Directory
if [ -z $organization_id ]; then
  # Accept Shared Directory in Production Account
  profile=$production_profile

  aws ds accept-shared-directory --shared-directory-id $zulu_ohio_production_directory_id \
                                 --profile $profile --region us-east-2 --output text

  # Accept Shared Directory in Development Account
  profile=$development_profile

  aws ds accept-shared-directory --shared-directory-id $zulu_ohio_development_directory_id \
                                 --profile $profile --region us-east-2 --output text
fi


## Alfa Ireland Management Directory Service ##########################################################################
profile=$management_profile

# Create Directory Service
echo "alfa_ireland_management_directory_domain=$alfa_ireland_management_directory_domain"
echo "alfa_ireland_management_directory_netbios_domain=$alfa_ireland_management_directory_netbios_domain"
echo "alfa_ireland_management_directory_admin_password=$alfa_ireland_management_directory_admin_password"
alfa_ireland_management_directory_id=$(aws ds create-microsoft-ad --name $alfa_ireland_management_directory_domain \
                                                             --short-name $alfa_ireland_management_directory_netbios_domain \
                                                             --description Management-DirectoryService \
                                                             --password $alfa_ireland_management_directory_admin_password \
                                                             --edition Standard \
                                                             --vpc-settings "VpcId=$ireland_management_vpc_id,SubnetIds=$ireland_management_directory_subneta_id,$ireland_management_directory_subnetb_id" \
                                                             --tags Key=Name,Value=Alfa-Management-DirectoryService Key=Company,Value=Alfa Key=Environment,Value=Management Key=Utility,Value=DirectoryService Key=Project,Value="CAMELZ3 POC" Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                                                             --query 'DirectoryId' \
                                                             --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_management_directory_id=$alfa_ireland_management_directory_id"

alfa_ireland_management_directory_sg_id=$(aws ds describe-directories --directory-ids  $alfa_ireland_management_directory_id \
                                                                      --query 'DirectoryDescriptions[0].VpcSettings.SecurityGroupId' \
                                                                      --profile $profile --region eu-west-1 --output text)
echo "alfa_ireland_management_directory_sg_id=$alfa_ireland_management_directory_sg_id"

aws ec2 create-tags --resources $alfa_ireland_management_directory_sg_id \
                    --tags Key=Name,Value=Management-DirectoryService-DomainControllersSecurityGroup \
                    --profile $profile --region eu-west-1 --output text

alfa_ireland_management_directory_dc_ips=$(aws ds describe-domain-controllers --directory-id $alfa_ireland_management_directory_id \
                                                                              --query 'DomainControllers[*].DnsIpAddr' \
                                                                              --profile $profile --region eu-west-1 --output text | tr "\t" ",")
echo "alfa_ireland_management_directory_dc_ips=$alfa_ireland_management_directory_dc_ips"

# Share Directory Service
if [ ! -z $organization_id ]; then
  # Share Directory with Organization (works with MJC Consulting)
  # TODO: This is NOT how this would work - The Directory needs to be created in the Organization Account,
  #       so once we have DXC variant working, I need to go through this again working with the Organization account
  #       to nail down the final logic
  echo "Logic not correct!"
  exit 2
  #ireland_management_directory_id=$(aws ds share-directory --directory-id $ireland_management_directory_id \
  #                                                         --share-method ORGANIZATIONS \
  #                                                         --query 'SharedDirectoryId' \
  #                                                         --profile $profile --region eu-west-1 --output text)
else
  profile=$management_profile

  # Share Directory with the Recovery Account (works with DXC)
  alfa_ireland_recovery_directory_id=$(aws ds share-directory --directory-id $alfa_ireland_management_directory_id \
                                                              --share-method HANDSHAKE \
                                                              --share-target Id=$recovery_account_id,Type=ACCOUNT \
                                                              --share-notes "Sharing Regional Management-DirectoryService for eu-west-1" \
                                                              --query 'SharedDirectoryId' \
                                                              --profile $profile --region eu-west-1 --output text)
  echo "alfa_ireland_recovery_directory_id=$alfa_ireland_recovery_directory_id"

  ireland_recovery_directory_dc_ips=$ireland_management_directory_dc_ips
  echo "ireland_recovery_directory_dc_ips=$ireland_recovery_directory_dc_ips"
fi

# Accept the Shared Directory
if [ -z $organization_id ]; then
  # Accept Shared Directory in Recovery Account
  profile=$recovery_profile

  aws ds accept-shared-directory --shared-directory-id $alfa_ireland_recovery_directory_id \
                                 --profile $profile --region eu-west-1 --output text
fi
