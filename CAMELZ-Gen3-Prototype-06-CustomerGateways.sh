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
## Customer Gateways ##################################################################################################
#######################################################################################################################

# Create Ohio Alfa LosAngeles Customer Gateway
profile=$core_profile

ohio_core_alfa_lax_cgw_id=$(aws ec2 create-customer-gateway --type ipsec.1 \
                                                            --bgp-asn $alfa_lax_cgw_asn \
                                                            --public-ip $alfa_lax_csr_instancea_public_ip \
                                                            --query 'CustomerGateway.CustomerGatewayId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_core_alfa_lax_cgw_id=$ohio_core_alfa_lax_cgw_id"

aws ec2 create-tags --resources $ohio_core_alfa_lax_cgw_id \
                    --tags Key=Name,Value=Core-AlfaLosAngelesCustomerGateway \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=LosAngeles \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text


# Create Ohio Core Alfa Miami Customer Gateway
ohio_core_alfa_mia_cgw_id=$(aws ec2 create-customer-gateway --type ipsec.1 \
                                                            --bgp-asn $alfa_mia_cgw_asn \
                                                            --public-ip $alfa_mia_csr_instancea_public_ip \
                                                            --query 'CustomerGateway.CustomerGatewayId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_core_alfa_mia_cgw_id=$ohio_core_alfa_mia_cgw_id"

aws ec2 create-tags --resources $ohio_core_alfa_mia_cgw_id \
                    --tags Key=Name,Value=Core-AlfaMiamiCustomerGateway \
                           Key=Company,Value=Alfa \
                           Key=Location,Value=Miami \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text


# Create Ohio Core Zulu Dallas Customer Gateway
ohio_core_zulu_dfw_cgw_id=$(aws ec2 create-customer-gateway --type ipsec.1 \
                                                            --bgp-asn $zulu_dfw_cgw_asn \
                                                            --public-ip $zulu_dfw_csr_instancea_public_ip \
                                                            --query 'CustomerGateway.CustomerGatewayId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_core_zulu_dfw_cgw_id=$ohio_core_zulu_dfw_cgw_id"

aws ec2 create-tags --resources $ohio_core_zulu_dfw_cgw_id \
                    --tags Key=Name,Value=Core-ZuluDallasCustomerGateway \
                           Key=Company,Value=Zulu \
                           Key=Location,Value=Dallas \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text


# Create Ohio Core DXC SantaBarbara Customer Gateway
ohio_core_dxc_sba_cgw_id=$(aws ec2 create-customer-gateway --type ipsec.1 \
                                                           --bgp-asn $dxc_sba_cgw_asn \
                                                           --public-ip $dxc_sba_csr_instancea_public_ip \
                                                           --query 'CustomerGateway.CustomerGatewayId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "ohio_core_dxc_sba_cgw_id=$ohio_core_dxc_sba_cgw_id"

aws ec2 create-tags --resources $ohio_core_dxc_sba_cgw_id \
                    --tags Key=Name,Value=Core-DXCSantaBarbaraCustomerGateway \
                           Key=Company,Value=DXC \
                           Key=Location,Value=SantaBarbara \
                           Key=Environment,Value=Core \
                           Key=Project,Value="CAMELZ3 POC" \
                           Key=Note,Value="Associated with the CAMELZ3 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text
