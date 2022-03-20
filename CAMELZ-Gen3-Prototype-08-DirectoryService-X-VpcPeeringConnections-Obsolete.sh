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
## Temporary VPC Peering Connections ##################################################################################
#######################################################################################################################
## - Until I have Transit Gateway Routing fully setup, which still depends on a few more pre-requisites I want
##   working first as I need to test that routing works with them (i.e. Client VPN)
## - I will setup VPC Peering Connections from Production, Testing, Development, Core and Log VPCs to the Management
##   VPC specifically to allow consumer VPCs to reach the Single Outbound Resolver Endpoint and Shared Directory Service
##   which both have ENIs inside the Ohio Management VPC.
## - I also need to create Routing Table Entries on both ends. So, this section will serve as documentation on how to
##   setup these VPC Peering Connections for these temporary routing paths, so we know how to remove them once no longer
##   needed.
#######################################################################################################################

## Production To Management VPC Peering Connection ####################################################################
profile=$production_profile

# Production to Management VPC Peering Connection
production_management_pcx_id=$(aws ec2 create-vpc-peering-connection --vpc-id $production_vpc_id \
                                                                     --peer-owner-id $management_account_id \
                                                                     --peer-vpc-id $management_vpc_id \
                                                                     --query 'VpcPeeringConnection.VpcPeeringConnectionId' \
                                                                     --profile $profile --region us-east-2 --output text)
echo "production_management_pcx_id=$production_management_pcx_id"

aws ec2 create-tags --resources $production_management_pcx_id \
                    --tags Key=Name,Value=Production-ManagementVPCPeeringConnection \
                           Key=Company,Value=DXC \
                           Key=Environment,Value=Production \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Production Routing Table Routes
aws ec2 create-route --route-table-id $production_public_rtb_id \
                     --vpc-peering-connection-id $production_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $production_private_rtba_id \
                     --vpc-peering-connection-id $production_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $production_private_rtbb_id \
                     --vpc-peering-connection-id $production_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $production_private_rtbc_id \
                     --vpc-peering-connection-id $production_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text

# Accept Production to Management VPC Peering Connection
profile=$management_profile

aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $production_management_pcx_id \
                                      --profile $profile --region us-east-2 --output text

aws ec2 create-tags --resources $production_management_pcx_id \
                    --tags Key=Name,Value=Management-ProductionVPCPeeringConnection \
                           Key=Company,Value=DXC \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Management Routing Table Routes
aws ec2 create-route --route-table-id $management_public_rtb_id \
                     --vpc-peering-connection-id $production_management_pcx_id \
                     --destination-cidr-block $alfa_ohio_production_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtba_id \
                     --vpc-peering-connection-id $production_management_pcx_id \
                     --destination-cidr-block $alfa_ohio_production_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtbb_id \
                     --vpc-peering-connection-id $production_management_pcx_id \
                     --destination-cidr-block $alfa_ohio_production_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtbc_id \
                     --vpc-peering-connection-id $production_management_pcx_id \
                     --destination-cidr-block $alfa_ohio_production_vpc_cidr \
                     --profile $profile --region us-east-2 --output text

## Testing To Management VPC Peering Connection #######################################################################
profile=$alfa_ohio_testing_profile

# Testing to Management VPC Peering Connection
alfa_ohio_testing_management_pcx_id=$(aws ec2 create-vpc-peering-connection --vpc-id $alfa_ohio_testing_vpc_id \
                                                                  --peer-owner-id $management_account_id \
                                                                  --peer-vpc-id $management_vpc_id \
                                                                  --query 'VpcPeeringConnection.VpcPeeringConnectionId' \
                                                                  --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_testing_management_pcx_id=$alfa_ohio_testing_management_pcx_id"

aws ec2 create-tags --resources $alfa_ohio_testing_management_pcx_id \
                    --tags Key=Name,Value=Testing-ManagementVPCPeeringConnection \
                           Key=Company,Value=DXC \
                           Key=Environment,Value=Testing \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Testing Routing Table Routes
aws ec2 create-route --route-table-id $alfa_ohio_testing_public_rtb_id \
                     --vpc-peering-connection-id $alfa_ohio_testing_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtba_id \
                     --vpc-peering-connection-id $alfa_ohio_testing_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbb_id \
                     --vpc-peering-connection-id $alfa_ohio_testing_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_testing_private_rtbc_id \
                     --vpc-peering-connection-id $alfa_ohio_testing_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text

# Accept Testing to Management VPC Peering Connection
profile=$management_profile

aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $alfa_ohio_testing_management_pcx_id \
                                      --profile $profile --region us-east-2 --output text

aws ec2 create-tags --resources $alfa_ohio_testing_management_pcx_id \
                    --tags Key=Name,Value=Management-TestingVPCPeeringConnection \
                           Key=Company,Value=DXC \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Management Routing Table Routes
aws ec2 create-route --route-table-id $management_public_rtb_id \
                     --vpc-peering-connection-id $alfa_ohio_testing_management_pcx_id \
                     --destination-cidr-block $alfa_ohio_testing_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtba_id \
                     --vpc-peering-connection-id $alfa_ohio_testing_management_pcx_id \
                     --destination-cidr-block $alfa_ohio_testing_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtbb_id \
                     --vpc-peering-connection-id $alfa_ohio_testing_management_pcx_id \
                     --destination-cidr-block $alfa_ohio_testing_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtbc_id \
                     --vpc-peering-connection-id $alfa_ohio_testing_management_pcx_id \
                     --destination-cidr-block $alfa_ohio_testing_vpc_cidr \
                     --profile $profile --region us-east-2 --output text

## Development To Management VPC Peering Connection ###################################################################
profile=$alfa_ohio_development_profile

# Development to Management VPC Peering Connection
alfa_ohio_development_management_pcx_id=$(aws ec2 create-vpc-peering-connection --vpc-id $alfa_ohio_development_vpc_id \
                                                                      --peer-owner-id $management_account_id \
                                                                      --peer-vpc-id $management_vpc_id \
                                                                      --query 'VpcPeeringConnection.VpcPeeringConnectionId' \
                                                                      --profile $profile --region us-east-2 --output text)
echo "alfa_ohio_development_management_pcx_id=$alfa_ohio_development_management_pcx_id"

aws ec2 create-tags --resources $alfa_ohio_development_management_pcx_id \
                    --tags Key=Name,Value=Development-ManagementVPCPeeringConnection \
                           Key=Company,Value=DXC \
                           Key=Environment,Value=Development \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Development Routing Table Routes
aws ec2 create-route --route-table-id $alfa_ohio_development_public_rtb_id \
                     --vpc-peering-connection-id $alfa_ohio_development_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtba_id \
                     --vpc-peering-connection-id $alfa_ohio_development_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtbb_id \
                     --vpc-peering-connection-id $alfa_ohio_development_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $alfa_ohio_development_private_rtbc_id \
                     --vpc-peering-connection-id $alfa_ohio_development_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text

# Accept Development to Management VPC Peering Connection
profile=$management_profile

aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $alfa_ohio_development_management_pcx_id \
                                      --profile $profile --region us-east-2 --output text

aws ec2 create-tags --resources $alfa_ohio_development_management_pcx_id \
                    --tags Key=Name,Value=Management-DevelopmentVPCPeeringConnection \
                           Key=Company,Value=DXC \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Management Routing Table Routes
aws ec2 create-route --route-table-id $management_public_rtb_id \
                     --vpc-peering-connection-id $alfa_ohio_development_management_pcx_id \
                     --destination-cidr-block $alfa_ohio_development_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtba_id \
                     --vpc-peering-connection-id $alfa_ohio_development_management_pcx_id \
                     --destination-cidr-block $alfa_ohio_development_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtbb_id \
                     --vpc-peering-connection-id $alfa_ohio_development_management_pcx_id \
                     --destination-cidr-block $alfa_ohio_development_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtbc_id \
                     --vpc-peering-connection-id $alfa_ohio_development_management_pcx_id \
                     --destination-cidr-block $alfa_ohio_development_vpc_cidr \
                     --profile $profile --region us-east-2 --output text

## Core To Management VPC Peering Connection ##########################################################################
profile=$core_profile

# Core to Management VPC Peering Connection
core_management_pcx_id=$(aws ec2 create-vpc-peering-connection --vpc-id $core_vpc_id \
                                                               --peer-owner-id $management_account_id \
                                                               --peer-vpc-id $management_vpc_id \
                                                               --query 'VpcPeeringConnection.VpcPeeringConnectionId' \
                                                               --profile $profile --region us-east-2 --output text)
echo "core_management_pcx_id=$core_management_pcx_id"

aws ec2 create-tags --resources $core_management_pcx_id \
                    --tags Key=Name,Value=Core-ManagementVPCPeeringConnection \
                           Key=Company,Value=DXC \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Core Routing Table Routes
aws ec2 create-route --route-table-id $core_public_rtb_id \
                     --vpc-peering-connection-id $core_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $core_private_rtba_id \
                     --vpc-peering-connection-id $core_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $core_private_rtbb_id \
                     --vpc-peering-connection-id $core_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $core_private_rtbc_id \
                     --vpc-peering-connection-id $core_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text

# Accept Core to Management VPC Peering Connection
profile=$management_profile

aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $core_management_pcx_id \
                                      --profile $profile --region us-east-2 --output text

aws ec2 create-tags --resources $core_management_pcx_id \
                    --tags Key=Name,Value=Management-CoreVPCPeeringConnection \
                           Key=Company,Value=DXC \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Management Routing Table Routes
aws ec2 create-route --route-table-id $management_public_rtb_id \
                     --vpc-peering-connection-id $core_management_pcx_id \
                     --destination-cidr-block $core_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtba_id \
                     --vpc-peering-connection-id $core_management_pcx_id \
                     --destination-cidr-block $core_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtbb_id \
                     --vpc-peering-connection-id $core_management_pcx_id \
                     --destination-cidr-block $core_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtbc_id \
                     --vpc-peering-connection-id $core_management_pcx_id \
                     --destination-cidr-block $core_vpc_cidr \
                     --profile $profile --region us-east-2 --output text

## Log To Management VPC Peering Connection ###########################################################################
profile=$log_profile

# Log to Management VPC Peering Connection
log_management_pcx_id=$(aws ec2 create-vpc-peering-connection --vpc-id $log_vpc_id \
                                                              --peer-owner-id $management_account_id \
                                                              --peer-vpc-id $management_vpc_id \
                                                              --query 'VpcPeeringConnection.VpcPeeringConnectionId' \
                                                              --profile $profile --region us-east-2 --output text)
echo "log_management_pcx_id=$log_management_pcx_id"

aws ec2 create-tags --resources $log_management_pcx_id \
                    --tags Key=Name,Value=Log-ManagementVPCPeeringConnection \
                           Key=Company,Value=DXC \
                           Key=Environment,Value=Log \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Log Routing Table Routes
aws ec2 create-route --route-table-id $log_public_rtb_id \
                     --vpc-peering-connection-id $log_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $log_private_rtba_id \
                     --vpc-peering-connection-id $log_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $log_private_rtbb_id \
                     --vpc-peering-connection-id $log_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $log_private_rtbc_id \
                     --vpc-peering-connection-id $log_management_pcx_id \
                     --destination-cidr-block $management_vpc_cidr \
                     --profile $profile --region us-east-2 --output text

# Accept Log to Management VPC Peering Connection
profile=$management_profile

aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $log_management_pcx_id \
                                      --profile $profile --region us-east-2 --output text

aws ec2 create-tags --resources $log_management_pcx_id \
                    --tags Key=Name,Value=Management-LogVPCPeeringConnection \
                           Key=Company,Value=DXC \
                           Key=Environment,Value=Management \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

# Management Routing Table Routes
aws ec2 create-route --route-table-id $management_public_rtb_id \
                     --vpc-peering-connection-id $log_management_pcx_id \
                     --destination-cidr-block $log_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtba_id \
                     --vpc-peering-connection-id $log_management_pcx_id \
                     --destination-cidr-block $log_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtbb_id \
                     --vpc-peering-connection-id $log_management_pcx_id \
                     --destination-cidr-block $log_vpc_cidr \
                     --profile $profile --region us-east-2 --output text
aws ec2 create-route --route-table-id $management_private_rtbc_id \
                     --vpc-peering-connection-id $log_management_pcx_id \
                     --destination-cidr-block $log_vpc_cidr \
                     --profile $profile --region us-east-2 --output text

# >>>>> STOP HERE - We now need to test that the Shared Directory Service, accessed via the Shared Outbound Resolver
# >>>>>             Directory Service Rule, Which Directs to the Single Outbound Resolver located in the Management VPC,
# >>>>>             which then conditionally forwards DNS requests for ad.us-east-2.dxc-ap.com to the Shared Directory
# >>>>>             Service ENIs which are also located in the Management VPC, can be used to Join Windows Instances
# >>>>>             located in the Production, Testing, Development, Core & Log Accounts/VPCs to the shared Domain.
# >>>>>             (Yes, I know this is complicated, and convoluted, but I didn't design it, and I've confirmed via
# >>>>>              AWS Support cases this IS the way it's supposed to work!)
# >>>>>           - Update the Production WindowsBastion HostName to dxcue2pwb01a; Join ad.us-east-2.dxc-ap.com Domain; Reboot
# >>>>>           - Confirm you can RDP to the Production Bastion with dxcapue2/Admin
# >>>>>           - Disable IE Enhanced Security, then download and install Chrome
# >>>>>           - Create the Production-WindowsManualServer-InstanceSecurityGroup (used in next step)
# >>>>>           - Create with seamless domain join the Production-WindowsManualServer-InstanceA, use the SG you just created
# >>>>>             - Note this will join the computer with a generated hostname, like WIN-XXXXXXXXXX, and we would have
# >>>>>               to manually change the hostname after the join to fix this, should we want to have a more conventional
# >>>>>               and purpose-specific hostname matching naming conventions
# >>>>>           - Confirm you can RDP from the Production Bastion to the WindowsManualServer with dxcapue2/Admin
# >>>>>           - Disable IE Enhanced Security, then download and install Chrome
# >>>>>           - Repeat the steps to setup the Production Bastion for the Testing, Development, Core and Log Bastions.
# >>>>>           - Optionally repeat the steps to create the WindowsManualServer in other accounts (This is not really
# >>>>>             unnecessary, as we will have confirmed what we need with the Bastion Domain Join)
# >>>>>           - RDP to the Management Bastion as dxcapue2/Admin, then RDP to the Management ActiveDirectoryManagement
# >>>>>           - Instance, then use the Users & Computers Application to confirm all Bastions are visible.
# >>>>>           - Assuming the last check passes, we now have Directory Service working across all Accounts and VPCs!
