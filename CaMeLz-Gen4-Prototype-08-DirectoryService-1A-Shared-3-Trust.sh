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
## Directory Service Trust Relationships - OneGlobal (Shared) Model ###################################################
#######################################################################################################################

## Create Trust between Global Management and Ohio Management #########################################################
profile=$management_profile

# Modify Global Management Directory Service Domain Controllers Security Group to allow Forest Trust Traffic
aws ec2 authorize-security-group-ingress --group-id $global_management_directory_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=137,ToPort=137,IpRanges=[{CidrIp=$ohio_management_vpc_cidr,Description=\"(Ohio) Management-VPC (NetLogon)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_directory_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=139,ToPort=139,IpRanges=[{CidrIp=$ohio_management_vpc_cidr,Description=\"(Ohio) Management-VPC (NetLogon)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_directory_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=873,ToPort=873,IpRanges=[{CidrIp=$ohio_management_vpc_cidr,Description=\"(Ohio) Management-VPC (Rsync)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-egress --group-id $global_management_directory_sg_id \
                                        --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$ohio_management_vpc_cidr,Description=\"(Ohio) Management-VPC (All)\"}]" \
                                        --profile $profile --region us-east-1 --output text

# Modify Ohio Management Directory Service Domain Controllers Security Group to allow Forest Trust Traffic
aws ec2 authorize-security-group-ingress --group-id $ohio_management_directory_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=137,ToPort=137,IpRanges=[{CidrIp=$global_management_vpc_cidr,Description=\"(Global) Management-VPC (NetLogon)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_management_directory_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=139,ToPort=139,IpRanges=[{CidrIp=$global_management_vpc_cidr,Description=\"(Global) Management-VPC (NetLogon)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-ingress --group-id $ohio_management_directory_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=873,ToPort=873,IpRanges=[{CidrIp=$global_management_vpc_cidr,Description=\"(Global) Management-VPC (Rsync)\"}]" \
                                         --profile $profile --region us-east-2 --output text
aws ec2 authorize-security-group-egress --group-id $ohio_management_directory_sg_id \
                                        --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$global_management_vpc_cidr,Description=\"(Global) Management-VPC (All)\"}]" \
                                        --profile $profile --region us-east-2 --output text

# Obtain Trust Password
# - Note: This variable already exists as global_management_directory_ohio_trust_password, and we could use that here
#         But I wanted to show how we should save that value as an SSM SecureString Parameter, as we do with the
#         Directory Admin User Password, and show how to look that up when we need it, using a new variable.
global_management_ohio_management_trust_password=$(aws ssm get-parameter --name Management-Directory-OhioTrust-Password \
                                                                         --with-decryption \
                                                                         --query 'Parameter.Value' \
                                                                         --profile $profile --region us-east-1 --output text)
echo "global_management_ohio_management_trust_password=$global_management_ohio_management_trust_password"

# - Note: I first created this trust with what I thought was the correct One-Way trust directions as noted below, but
#         this didn't seem to work. So, I then created this with the Two-Way Trust. We don't really want that, so open
#         a ticket to improve this at some point.
# - Note: this should have trust direction: "One-Way: Outgoing"
IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ohio_management_directory_dc_ips"
global_management_ohio_management_trust_id=$(aws ds create-trust --directory-id $global_management_directory_id \
                                                                 --trust-type Forest \
                                                                 --trust-direction "Two-Way" \
                                                                 --remote-domain-name $ohio_management_directory_domain \
                                                                 --trust-password $global_management_ohio_management_trust_password \
                                                                 --conditional-forwarder-ip-addrs $dc_ip1 $dc_ip2 $dc_ip3 $dc_ip4 \
                                                                 --query 'TrustId' \
                                                                 --profile $profile --region us-east-1 --output text)
echo "global_management_ohio_management_trust_id=$global_management_ohio_management_trust_id"

# - Note: this should have trust direction: "One-Way: Incoming"
IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$global_management_directory_dc_ips"
ohio_management_global_management_trust_id=$(aws ds create-trust --directory-id $ohio_management_directory_id \
                                                                 --trust-type Forest \
                                                                 --trust-direction "Two-Way" \
                                                                 --remote-domain-name $global_management_directory_domain \
                                                                 --trust-password $global_management_ohio_management_trust_password \
                                                                 --conditional-forwarder-ip-addrs $dc_ip1 $dc_ip2 $dc_ip3 $dc_ip4 \
                                                                 --query 'TrustId' \
                                                                 --profile $profile --region us-east-2 --output text)
echo "ohio_management_global_management_trust_id=$ohio_management_global_management_trust_id"


## Create Trust between Global Management and Ireland Management ######################################################
profile=$management_profile

# Modify Global Management Directory Service Domain Controllers Security Group to allow Forest Trust Traffic
aws ec2 authorize-security-group-ingress --group-id $global_management_directory_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=137,ToPort=137,IpRanges=[{CidrIp=$ireland_management_vpc_cidr,Description=\"(Ireland) Management-VPC (NetLogon)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_directory_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=139,ToPort=139,IpRanges=[{CidrIp=$ireland_management_vpc_cidr,Description=\"(Ireland) Management-VPC (NetLogon)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-ingress --group-id $global_management_directory_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=873,ToPort=873,IpRanges=[{CidrIp=$ireland_management_vpc_cidr,Description=\"(Ireland) Management-VPC (Rsync)\"}]" \
                                         --profile $profile --region us-east-1 --output text
aws ec2 authorize-security-group-egress --group-id $global_management_directory_sg_id \
                                        --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$ireland_management_vpc_cidr,Description=\"(Ireland) Management-VPC (All)\"}]" \
                                        --profile $profile --region us-east-1 --output text

# Modify Ireland Management Directory Service Domain Controllers Security Group to allow Forest Trust Traffic
aws ec2 authorize-security-group-ingress --group-id $ireland_management_directory_sg_id \
                                         --ip-permissions "IpProtocol=udp,FromPort=137,ToPort=137,IpRanges=[{CidrIp=$global_management_vpc_cidr,Description=\"(Global) Management-VPC (NetLogon)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_management_directory_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=139,ToPort=139,IpRanges=[{CidrIp=$global_management_vpc_cidr,Description=\"(Global) Management-VPC (NetLogon)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-ingress --group-id $ireland_management_directory_sg_id \
                                         --ip-permissions "IpProtocol=tcp,FromPort=873,ToPort=873,IpRanges=[{CidrIp=$global_management_vpc_cidr,Description=\"(Global) Management-VPC (Rsync)\"}]" \
                                         --profile $profile --region eu-west-1 --output text
aws ec2 authorize-security-group-egress --group-id $ireland_management_directory_sg_id \
                                        --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$global_management_vpc_cidr,Description=\"(Global) Management-VPC (All)\"}]" \
                                        --profile $profile --region eu-west-1 --output text

# Obtain Trust Password
# - Note: This variable already exists as global_management_directory_ohio_trust_password, and we could use that here
#         But I wanted to show how we should save that value as an SSM SecureString Parameter, as we do with the
#         Directory Admin User Password, and show how to look that up when we need it, using a new variable.
global_management_ireland_management_trust_password=$(aws ssm get-parameter --name Management-Directory-IrelandTrust-Password \
                                                                            --with-decryption \
                                                                            --query 'Parameter.Value' \
                                                                            --profile $profile --region us-east-1 --output text)
echo "global_management_ireland_management_trust_password=$global_management_ireland_management_trust_password"

# - Note: I first created this trust with what I thought was the correct One-Way trust directions as noted below, but
#         this didn't seem to work. So, I then created this with the Two-Way Trust. We don't really want that, so open
#         a ticket to improve this at some point.
# - Note: this should have trust direction: "One-Way: Outgoing"
IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ireland_management_directory_dc_ips"
global_management_ireland_management_trust_id=$(aws ds create-trust --directory-id $global_management_directory_id \
                                                                    --trust-type Forest \
                                                                    --trust-direction "Two-Way" \
                                                                    --remote-domain-name $ireland_management_directory_domain \
                                                                    --trust-password $global_management_ireland_management_trust_password \
                                                                    --conditional-forwarder-ip-addrs $dc_ip1 $dc_ip2 $dc_ip3 $dc_ip4 \
                                                                    --query 'TrustId' \
                                                                    --profile $profile --region us-east-1 --output text)
echo "global_management_ireland_management_trust_id=$global_management_ireland_management_trust_id"

# - Note: this should have trust direction: "One-Way: Incoming"
IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$global_management_directory_dc_ips"
ireland_management_global_management_trust_id=$(aws ds create-trust --directory-id $ireland_management_directory_id \
                                                                    --trust-type Forest \
                                                                    --trust-direction "Two-Way" \
                                                                    --remote-domain-name $global_management_directory_domain \
                                                                    --trust-password $global_management_ireland_management_trust_password \
                                                                    --conditional-forwarder-ip-addrs $dc_ip1 $dc_ip2 $dc_ip3 $dc_ip4 \
                                                                    --query 'TrustId' \
                                                                    --profile $profile --region eu-west-1 --output text)
echo "ireland_management_global_management_trust_id=$ireland_management_global_management_trust_id"
