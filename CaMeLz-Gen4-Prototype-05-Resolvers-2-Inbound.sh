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
## Route53 Inbound Resolvers ##########################################################################################
#######################################################################################################################

## Global Management Route53 Resolver Inbound Endpoint ################################################################
#profile=$production_profile
#
#alfa_ohio_production_inboundresolver_sg_id=$(aws ec2 create-security-group --group-name Alfa-Production-InboundResolverSecurityGroup \
#                                                                           --description Alfa-Production-InboundResolverSecurityGroup \
#                                                                           --vpc-id $alfa_ohio_production_vpc_id \
#                                                                           --query 'GroupId' \
#                                                                           --profile $profile --region us-east-2 --output text)
#echo "alfa_ohio_production_inboundresolver_sg_id=$alfa_ohio_production_resolver_endpoint_sg_id"
#
#aws ec2 create-tags --resources $alfa_ohio_production_inboundresolver_sg_id \
#                    --tags Key=Name,Value=Alfa-Production-Resolver-InboundSecurityGroup \
#                           Key=Company,Value=Alfa \
#                           Key=Environment,Value=Production \
#                           Key=Utility,Value=Resolver \
#                           Key=Project,Value="CaMeLz4 POC" \
#                           Key=Note,Value="Associated with the CaMeLz4 POC - do not alter or delete" \
#                    --profile $profile --region us-east-2 --output text
#
#aws ec2 authorize-security-group-ingress --group-id $alfa_ohio_production_inboundresolver_sg_id \
#                                         --ip-permissions "IpProtocol=udp,FromPort=53,ToPort=53,IpRanges=[{CidrIp=0.0.0.0/0,Description=\"Global (DNS)\"}]" \
#                                         --profile $profile --region us-east-2 --output text
#
#alfa_ohio_production_inboundresolver_endpoint_id=$(aws route53resolver create-resolver-endpoint --name Alfa-Production-Resolver-InboundEndpoint \
#                                                                                       --direction INBOUND \
#                                                                                       --security-group-ids $alfa_ohio_production_inboundresolver_sg_id \
#                                                                                       --ip-addresses SubnetId=$alfa_ohio_production_endpoint_subneta_id SubnetId=$alfa_ohio_production_endpoint_subnetb_id \
#                                                                                       --creator-request-id $(date +%s) \
#                                                                                       --tags "Key=Name,Value=Alfa-Production-Resolver-InboundEndpoint Key=Environment,Value=Production Key=Utility,Value=Resolver" \
#                                                                                       --query 'ResolverEndpoint.Id' \
#                                                                                       --profile $profile --region us-east-2 --output text)
#echo "alfa_ohio_production_inboundresolver_endpoint_id=$alfa_ohio_production_inboundresolver_endpoint_id"
#
#alfa_ohio_production_inboundresolver_endpoint_ips=$(aws route53resolver list-resolver-endpoint-ip-addresses --resolver-endpoint-id $alfa_ohio_production_inboundresolver_endpoint_id \
#                                                                                                            --query 'IpAddresses[*].Ip' \
#                                                                                                            --profile $profile --region us-east-2 --output text | tr "\t" ",")
#echo "alfa_ohio_production_inboundresolver_endpoint_ips=$alfa_ohio_production_inboundresolver_endpoint_ips"
