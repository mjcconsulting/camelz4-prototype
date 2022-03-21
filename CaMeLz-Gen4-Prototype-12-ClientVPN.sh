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
## Client VPN #########################################################################################################
#######################################################################################################################
## - This step requires external work documented elsewhere, to setup the CaMeLz Analytics Platform PKI infrastructure,
##   and generate the server and client certificates.
## - It is assumed this work has been completed, and the resulting files have been placed into a single directory, where
##   we can use them to import the certificates needed into ACM.
#######################################################################################################################

## Core Client VPN ####################################################################################################
profile=$core_profile

pushd $core_client_vpn_dir
core_client_vpn_server_certificate_arn=$(aws acm import-certificate --certificate file://vpn.c.us-east-2.$domain.crt \
                                                                    --private-key file://vpn.c.us-east-2.$domain.key \
                                                                    --certificate-chain file://CaMeLz_Analytics_Platform_Chain.crt \
                                                                    --query 'CertificateArn' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "core_client_vpn_server_certificate_arn=$core_client_vpn_server_certificate_arn"

core_client_vpn_client_certificate_arn=$(aws acm import-certificate --certificate file://mcrawford.c.us-east-2.$domain.crt \
                                                                    --private-key file://mcrawford.c.us-east-2.$domain.key \
                                                                    --certificate-chain file://CaMeLz_Analytics_Platform_Chain.crt \
                                                                    --query 'CertificateArn' \
                                                                    --profile $profile --region us-east-2 --output text)
echo "core_client_vpn_client_certificate_arn=$core_client_vpn_client_certificate_arn"
popd

core_client_vpn_sg_id=$(aws ec2 create-security-group --group-name Core-ClientVpn-EndpointSecurityGroup \
                                                      --description Core-ClientVpn-EndpointSecurityGroup \
                                                      --vpc-id $core_vpc_id \
                                                      --query 'GroupId' \
                                                      --profile $profile --region us-east-2 --output text)
echo "core_client_vpn_sg_id=$core_client_vpn_sg_id"

aws ec2 create-tags --resources $core_client_vpn_sg_id \
                    --tags Key=Name,Value=Core-ClientVpn-EndpointSecurityGroup \
                           Key=Company,Value=CaMeLz \
                           Key=Environment,Value=Core \
                           Key=Utility,Value=ClientVpn \
                           Key=Project,Value="CaMeLz4 POC" \
                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
                    --profile $profile --region us-east-2 --output text

aws ec2 authorize-security-group-ingress --group-id $core_client_vpn_sg_id \
                                         --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$core_vpc_cidr,Description=\"VPC (All)\"}]" \
                                         --profile $profile --region us-east-2 --output text


#aws logs create-log-group --log-group-name "/$company_name_lc/$system_name_lc/ClientVPN" \
#                          --profile $profile --region us-east-2 --output text
#
#aws logs create-log-stream --log-group-name "/$company_name_lc/$system_name_lc/ClientVPN" \
#                           --log-stream-name "ClientVPN" \
#                           --profile $profile --region us-east-2 --output text

core_client_vpn_endpoint_id=$(aws ec2 create-client-vpn-endpoint --description Core-ClientVpnEndpoint \
                                                                 --client-cidr-block $core_client_vpn_cidr \
                                                                 --vpc-id $core_vpc_id \
                                                                 --security-group-ids $core_client_vpn_sg_id \
                                                                 --server-certificate-arn $core_client_vpn_server_certificate_arn \
                                                                 --authentication-options "Type=certificate-authentication,MutualAuthentication={ClientRootCertificateChainArn=$core_client_vpn_client_certificate_arn}" \
                                                                 --connection-log-options "Enabled=false" \
                                                                 --transport-protocol udp \
                                                                 --vpn-port 1194 \
                                                                 --split-tunnel \
                                                                 --client-token $(date +%s) \
                                                                 --tag-specifications "ResourceType=client-vpn-endpoint,Tags=[{Key=Name,Value=Core-ClientVpnEndpoint},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Core},{Key=Project,Value=\"CaMeLz4 POC\"},{Key=Note,Value=\"Associated with the CaMeLz4 POC - do not alter or delete\"}]" \
                                                                 --query 'ClientVpnEndpointId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "core_client_vpn_endpoint_id=$core_client_vpn_endpoint_id"

#                                                                 --authentication-options "Type=directory-service-authentication,ActiveDirectory={DirectoryId=$core_shared_directory_id}" \
#                                                                 --connection-log-options "Enabled=true" \
#                                                                 [--dns-servers <value>]
#                                                                 --connection-log-options "Enabled=true,CloudwatchLogGroup=/$company_name_lc/$system_name_lc/ClientVPN,CloudwatchLogStream=ClientVPN' \

# Note: Was going to map this to the public subnets, but got an error that at least at /27 network is required
aws ec2 associate-client-vpn-target-network --client-vpn-endpoint-id $core_client_vpn_endpoint_id \
                                            --subnet-id $core_endpoint_subneta_id \
                                            --client-token $(date +%s) \
                                            --profile $profile --region us-east-2 --output text

aws ec2 associate-client-vpn-target-network --client-vpn-endpoint-id $core_client_vpn_endpoint_id \
                                            --subnet-id $core_endpoint_subnetb_id \
                                            --client-token $(date +%s) \
                                            --profile $profile --region us-east-2 --output text

#aws ec2 associate-client-vpn-target-network --client-vpn-endpoint-id $core_client_vpn_endpoint_id \
#                                            --subnet-id $core_endpoint_subnetc_id \
#                                            --client-token $(date +%s) \
#                                            --profile $profile --region us-east-2 --output text

YOU ARE HERE

aws ec2 create-client-vpn-route --client-vpn-endpoint-id $core_client_vpn_endpoint_id \
                                --description Core-Production-VPC-Route \
                                --destination-cidr-block $alfa_ohio_production_vpc_cidr \
                                --target-vpc-subnet-id $core_gateway_subneta_id \
                                --client-token $(date +%s) \
                                --profile $profile --region us-east-2 --output text


# Example of rule to authorize all groups, without Directory Service integration
aws ec2 authorize-client-vpn-ingress --client-vpn-endpoint-id $core_client_vpn_endpoint_id \
                                     --description Core-ClientVpnIngress-Core-VPC \
                                     --target-network-cidr $core_vpc_cidr \
                                     --authorize-all-groups \
                                     --client-token $(date +%s) \
                                     --profile $profile --region us-east-2 --output text

# TODO: Create and test groups in Active Directory to do per-Environment VPC access control from central location
#aws ec2 authorize-client-vpn-ingress --client-vpn-endpoint-id $core_client_vpn_endpoint_id \
#                                     --description Core-ClientVpnIngress-Core-VPC \
#                                     --target-network-cidr $core_vpc_cidr \
#                                     [--access-group-id <value>]
#                                     [--authorize-all-groups | --no-authorize-all-groups]
#                                     --client-token $(date +%s) \
#                                     --profile $profile --region us-east-2 --output text
