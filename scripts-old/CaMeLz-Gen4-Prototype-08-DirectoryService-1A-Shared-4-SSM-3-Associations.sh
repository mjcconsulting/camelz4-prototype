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
## Directory Service SSM Associations - OneGlobal (Shared) Model ######################################################
#######################################################################################################################
## Note: These could not be created sooner, as they depend on the Directories created just before this script is run ##
## Note: Below is an example of what we could do, to automatically join all Instances to the Domain.                 ##
##       I'm not sure this would be a good idea, so this is currently commented out. We explicitly join instead.     ##
#######################################################################################################################

## Create Ohio Core Default JoinDirectoryServiceDomain SSM Association ################################################
#profile=$core_profile
#
#if [ -z $(aws ssm list-associations --association-filter-list key=AssociationName,value=SystemAssociationForJoinDirectoryServiceDomain \
#                                    --query 'Associations[?Name==`AWS-JoinDirectoryServiceDomain`].Name' \
#                                    --profile $profile --region us-east-2 --output text) ]; then
#  echo "Association: SystemAssociationForJoinDirectoryServiceDomain does not exist, creating"
#  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ohio_core_directory_dc_ips"
#  aws ssm create-association --association-name SystemAssociationForJoinDirectoryServiceDomain \
#                             --name AWS-JoinDirectoryServiceDomain \
#                             --parameters directoryId=$ohio_core_directory_id,directoryName=$ohio_core_directory_domain,dnsIpAddresses="[$dc_ip1,$dc_ip2]" \
#                             --targets Key=InstanceIds,Values=* \
#                             --schedule-expression "rate(14 days)" \
#                             --query 'AssociationDescription.Overview.DetailedStatus' \
#                             --profile $profile --region us-east-2 --output text
#else
#  echo "Association: SystemAssociationForJoinDirectoryServiceDomain exists, skipping"
#fi
