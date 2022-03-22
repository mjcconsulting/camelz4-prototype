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
## Customer Gateways ##################################################################################################
#######################################################################################################################

# Create Ohio Alfa LosAngeles Customer Gateway
profile=$core_profile

ohio_core_alfa_lax_cgw_id=$(aws ec2 create-customer-gateway --type ipsec.1 \
                                                            --bgp-asn $alfa_lax_cgw_asn \
                                                            --public-ip $alfa_lax_csr_instancea_public_ip \
                                                            --tag-specifications ResourceType=customer-gateway,Tags=[{Key=Name,Value=Core-AlfaLosAngelesCustomerGateway},{Key=Company,Value=Alfa},{Key=Environment,Value=Network},{Key=Location,Value=LosAngeles},{Key=Project,Value=CaMeLz-POC-4}] \
                                                            --query 'CustomerGateway.CustomerGatewayId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_core_alfa_lax_cgw_id=$ohio_core_alfa_lax_cgw_id"


# Create Ohio Core Alfa Miami Customer Gateway
ohio_core_alfa_mia_cgw_id=$(aws ec2 create-customer-gateway --type ipsec.1 \
                                                            --bgp-asn $alfa_mia_cgw_asn \
                                                            --public-ip $alfa_mia_csr_instancea_public_ip \
                                                            --tag-specifications ResourceType=customer-gateway,Tags=[{Key=Name,Value=Core-AlfaMiamiCustomerGateway},{Key=Company,Value=Alfa},{Key=Environment,Value=Network},{Key=Location,Value=Miami},{Key=Project,Value=CaMeLz-POC-4}] \
                                                            --query 'CustomerGateway.CustomerGatewayId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_core_alfa_mia_cgw_id=$ohio_core_alfa_mia_cgw_id"


# Create Ohio Core Zulu Dallas Customer Gateway
ohio_core_zulu_dfw_cgw_id=$(aws ec2 create-customer-gateway --type ipsec.1 \
                                                            --bgp-asn $zulu_dfw_cgw_asn \
                                                            --public-ip $zulu_dfw_csr_instancea_public_ip \
                                                            --tag-specifications ResourceType=customer-gateway,Tags=[{Key=Name,Value=Core-ZuluDallasCustomerGateway},{Key=Company,Value=Zulu},{Key=Environment,Value=Network},{Key=Location,Value=Dallas},{Key=Project,Value=CaMeLz-POC-4}] \
                                                            --query 'CustomerGateway.CustomerGatewayId' \
                                                            --profile $profile --region us-east-2 --output text)
echo "ohio_core_zulu_dfw_cgw_id=$ohio_core_zulu_dfw_cgw_id"


# Create Ohio Core CaMeLz SantaBarbara Customer Gateway
ohio_core_cml_sba_cgw_id=$(aws ec2 create-customer-gateway --type ipsec.1 \
                                                           --bgp-asn $cml_sba_cgw_asn \
                                                           --public-ip $cml_sba_csr_instancea_public_ip \
                                                           --tag-specifications ResourceType=customer-gateway,Tags=[{Key=Name,Value=Core-CaMeLzSantaBarbaraCustomerGateway},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Network},{Key=Location,Value=SantaBarbara},{Key=Project,Value=CaMeLz-POC-4}] \
                                                           --query 'CustomerGateway.CustomerGatewayId' \
                                                           --profile $profile --region us-east-2 --output text)
echo "ohio_core_cml_sba_cgw_id=$ohio_core_cml_sba_cgw_id"

