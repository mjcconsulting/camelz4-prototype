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

# Define Netmask conversion Array
netmask[8]='255.0.0.0'
netmask[9]='255.128.0.0'
netmask[10]='255.192.0.0'
netmask[11]='255.224.0.0'
netmask[12]='255.240.0.0'
netmask[13]='255.248.0.0'
netmask[14]='255.252.0.0'
netmask[15]='255.254.0.0'
netmask[16]='255.255.0.0'
netmask[17]='255.255.128.0'
netmask[18]='255.255.192.0'
netmask[19]='255.255.224.0'
netmask[20]='255.255.240.0'
netmask[21]='255.255.248.0'
netmask[22]='255.255.252.0'
netmask[23]='255.255.254.0'
netmask[24]='255.255.255.0'
netmask[25]='255.255.255.128'
netmask[26]='255.255.255.192'
netmask[27]='255.255.255.224'
netmask[28]='255.255.255.240'
netmask[29]='255.255.255.248'
netmask[30]='255.255.255.252'
netmask[31]='255.255.255.254'
netmask[32]='255.255.255.255'

# Define environment
tmpdir=~/Workspaces/mjcconsulting/camelz3-prototype/tmp
templatesdir=~/Workspaces/mjcconsulting/camelz3-prototype/templates
documentsdir=~/Workspaces/mjcconsulting/camelz3-prototype/documents
certificatesdir=~/Workspaces/mjcconsulting/camelz3-prototype/certificates
cfgdir=~/Workspaces/mjcconsulting/camelz3-prototype/cfg

chrome_installer_url=http://installers-dxcapm.s3-website-us-east-1.amazonaws.com/GoogleChromeStandaloneEnterprise64.msi
chrome_installer_sha256=82bc081286f48148dce2c81f97bdb849b38680b7bb3435221fa470adcf75aa5b

royalts_installer_url=http://installers-dxcapm.s3-website-us-east-1.amazonaws.com/RoyalTSInstaller_5.02.60410.0.msi
royalts_installer_sha256=699ef4391df99f1864d53baf0ce7c637576e6fec50c5677c64e686f3a2050130

user=bootstrapadministrator

organization_account_id=482085898762
organization_account_name=mjcconsulting
organization_profile=$management_account_name-$user

management_account_id=310475726197
management_account_name=mjcm
management_profile=$management_account_name-$user

core_account_id=448496307850
core_account_name=mjcc
core_profile=$core_account_name-$user

log_account_id=238775257438
log_account_name=mjcl
log_profile=$log_account_name-$user

production_account_id=338021645315
production_account_name=mjcp
production_profile=$production_account_name-$user

recovery_account_id=923440168826
recovery_account_name=mjcr
recovery_profile=$recovery_account_name-$user

testing_account_id=796408812313
testing_account_name=mjct
testing_profile=$testing_account_name-$user

development_account_id=756469198966
development_account_name=mjcd
development_profile=$development_account_name-$user


global_nat_ami_id=ami-00a9d4a05375b2763 # Latest for us-east-1
global_amzn2_ami_id=ami-0fc61db8544a617ed # Latest for us-east-1
global_win2012r2_ami_id=ami-02fc0cb4aa47ce2e9 # Latest for us-east-1
global_win2016_ami_id=ami-08bf5f54919fada4a # Latest for us-east-1
global_win2019_ami_id=ami-0b940a1059f928462 # Latest for us-east-1
global_csr_ami_id=ami-0fc7a3d5400f4619d # "Cisco Cloud Services Router (CSR) 1000V - BYOL for Maximum Performance" Version 16.12.01a for us-east-1
#global_csr_ami_id=ami-0f28884e9c2990f73 # "Cisco Cloud Services Router (CSR) 1000V - BYOL for Maximum Performance" Version 17.1.1 for us-east-1

ohio_nat_ami_id=ami-00d1f8201864cc10c # Latest for us-east-2
ohio_amzn2_ami_id=ami-0e38b48473ea57778 # Latest for us-east-2
ohio_win2012r2_ami_id=ami-0a1a54d8690206089 # Latest for us-east-2
ohio_win2016_ami_id=ami-0148f346905f051c8 # Latest for us-east-2
ohio_win2019_ami_id=ami-067317d2d40fd5919 # Latest for us-east-2
ohio_csr_ami_id=ami-0fda690c9c2f5cbf9 # "Cisco Cloud Services Router (CSR) 1000V - BYOL for Maximum Performance" Version 16.12.01a for us-east-2
#ohio_csr_ami_id=ami-04633fcd5cef9c719 # "Cisco Cloud Services Router (CSR) 1000V - BYOL for Maximum Performance" Version 17.1.1 for us-east-2

ireland_nat_ami_id=ami-024107e3e3217a248 # Latest for eu-west-1
ireland_amzn2_ami_id=ami-099a8245f5daa82bf # Latest for eu-west-1
ireland_win2012r2_ami_id=ami-0d2f69fcc5f00c97a # Latest for eu-west-1
ireland_win2016_ami_id=ami-0894469f8333424c6 # Latest for eu-west-1
ireland_win2019_ami_id=ami-0a174bb076b94a327 # Latest for eu-west-1
ireland_csr_ami_id=ami-061919bc753fac9f1 # "Cisco Cloud Services Router (CSR) 1000V - BYOL for Maximum Performance" Version 16.12.01a for eu-west-1
#ireland_csr_ami_id=ami-0c9e8f15bd4588595 # "Cisco Cloud Services Router (CSR) 1000V - BYOL for Maximum Performance" Version 17.1.1 for eu-west-1


mcrawford_home_public_cidr=68.108.247.173/32
mcrawford_home_private_cidr=10.0.1.0/24

dxc_msy_public_cidr=192.46.53.0/24 # New Orleans Office Main
dxc_msy_public_guest_cidr=192.46.52.0/24 # New Orleans Office Guest
dxc_waw_public_cidr=192.46.111.0/24 # Warsaw Office
dxc_maa_public_cidr=192.46.83.0/24 # India Chennai Office (guess)

company_name=MJCConsulting
company_name_lc=mjc

system_name=Prototype
system_name_lc=proto

user=bootstrapadministrator

domain=mjcconsulting.com

use_ngw=1
ha_ngw=0

perclient_ds=1 # Changing this value will require re-creating any client Windows Instances

unset organization_id


# Overall CIDRs from which VPC or Client CIDRs are allocated
aws_cidr=10.0.0.0/8        # We will send this whole CIDR into Transit Gateway, most is used by other AWS VPCs
global_cidr=10.0.0.0/12
ohio_cidr=10.16.0.0/12
oregon_cidr=10.32.0.0/12
ireland_cidr=10.64.0.0/12
client_cidr=172.16.0.0/12  # Currently allocating Clients from only 172.16.0.0/12, but want to route this CIDR from VPC Route Tables
partner_cidr=100.64.0.0/10 # We may want to use this for future partners or some other use, so adding to VPC Route Tables


# Global
global_management_public_hostedzone_id=Z2EBB33O71Z1GD # This already exists, so we just reference it

global_management_public_domain=$domain
global_management_private_domain=$domain
global_management_directory_domain=ad.$domain
global_management_directory_netbios_domain=dxcap
global_management_directory_admin_user=Admin@$global_management_directory_domain
global_management_directory_admin_password=SomethingHard2Guess
global_management_directory_ohio_trust_password=TellM3Wh0AreYou
global_management_directory_ireland_trust_password=1ReallyWant2Know

global_management_vpc_cidr=10.15.0.0/19
global_management_subnet_publica_cidr=10.15.0.0/25
global_management_subnet_publicb_cidr=10.15.8.0/25
global_management_subnet_publicc_cidr=10.15.16.0/25
global_management_subnet_weba_cidr=10.15.1.0/25
global_management_subnet_webb_cidr=10.15.9.0/25
global_management_subnet_webc_cidr=10.15.17.0/25
global_management_subnet_applicationa_cidr=10.15.2.0/25
global_management_subnet_applicationb_cidr=10.15.10.0/25
global_management_subnet_applicationc_cidr=10.15.18.0/25
global_management_subnet_databasea_cidr=10.15.4.0/25
global_management_subnet_databaseb_cidr=10.15.12.0/25
global_management_subnet_databasec_cidr=10.15.20.0/25
global_management_subnet_directorya_cidr=10.15.6.0/24
global_management_subnet_directoryb_cidr=10.15.14.0/24
global_management_subnet_directoryc_cidr=10.15.22.0/24
global_management_subnet_managementa_cidr=10.15.7.192/28
global_management_subnet_managementb_cidr=10.15.15.192/28
global_management_subnet_managementc_cidr=10.15.23.192/28
global_management_subnet_gatewaya_cidr=10.15.7.208/28
global_management_subnet_gatewayb_cidr=10.15.15.208/28
global_management_subnet_gatewayc_cidr=10.15.23.208/28
global_management_subnet_endpointa_cidr=10.15.7.224/27
global_management_subnet_endpointb_cidr=10.15.15.224/27
global_management_subnet_endpointc_cidr=10.15.23.224/27

if [ $perclient_ds = 1 ]; then
  # In the "PerClient" Directory Model, All Clients have their own Global Directory for Users & Groups
  alfa_global_management_directory_domain=ad.alfa.$domain
  alfa_global_management_directory_netbios_domain=alfa
  alfa_global_management_directory_admin_user=Admin@$alfa_global_management_directory_domain
  alfa_global_management_directory_admin_password=AlfaUniquePasswordGoesHere
  alfa_global_management_directory_ohio_trust_password=T0pDog4Now
  alfa_global_management_directory_ireland_trust_password=1ComeFirstB4U

  zulu_global_management_directory_domain=ad.zulu.$domain
  zulu_global_management_directory_netbios_domain=zulu
  zulu_global_management_directory_admin_user=Admin@$zulu_global_management_directory_domain
  zulu_global_management_directory_admin_password=ZuluUniquePasswordGoesHere
  zulu_global_management_directory_ohio_trust_password=SavingTheB3est4Last
  zulu_global_management_directory_ireland_trust_password=AgeB4beauty
else
  # In the "OneGlobal" Directory Model, All Clients Share the same Global Directory for Users & Groups
  alfa_global_management_directory_domain=$global_management_directory_domain                  # Shares Global Management Directory
  alfa_global_management_directory_netbios_domain=$global_management_directory_netbios_domain  # Shares Global Management Directory
  alfa_global_management_directory_admin_user=$global_management_directory_admin_user          # Shares Global Management Directory
  alfa_global_management_directory_admin_password=$global_management_directory_admin_password  # Shares Global Management Directory

  zulu_global_management_directory_domain=$global_management_directory_domain                  # Shares Global Management Directory
  zulu_global_management_directory_netbios_domain=$global_management_directory_netbios_domain  # Shares Global Management Directory
  zulu_global_management_directory_admin_user=$global_management_directory_admin_user          # Shares Global Management Directory
  zulu_global_management_directory_admin_password=$global_management_directory_admin_password  # Shares Global Management Directory
fi

global_core_public_domain=c.$domain
global_core_private_domain=c.$domain
global_core_directory_domain=$global_management_directory_domain                  # Shares Global Management Directory
global_core_directory_netbios_domain=$global_management_directory_netbios_domain  # Shares Global Management Directory
global_core_directory_admin_user=$global_management_directory_admin_user          # Shares Global Management Directory
global_core_directory_admin_password=$global_management_directory_admin_password  # Shares Global Management Directory

global_core_vpc_cidr=10.15.64.0/19
global_core_subnet_publica_cidr=10.15.64.0/25
global_core_subnet_publicb_cidr=10.15.72.0/25
global_core_subnet_publicc_cidr=10.15.80.0/25
global_core_subnet_weba_cidr=10.15.65.0/25
global_core_subnet_webb_cidr=10.15.73.0/25
global_core_subnet_webc_cidr=10.15.81.0/25
global_core_subnet_applicationa_cidr=10.15.66.0/25
global_core_subnet_applicationb_cidr=10.15.74.0/25
global_core_subnet_applicationc_cidr=10.15.82.0/25
global_core_subnet_databasea_cidr=10.15.68.0/25
global_core_subnet_databaseb_cidr=10.15.76.0/25
global_core_subnet_databasec_cidr=10.15.84.0/25
global_core_subnet_managementa_cidr=10.15.71.192/28
global_core_subnet_managementb_cidr=10.15.79.192/28
global_core_subnet_managementc_cidr=10.15.87.192/28
global_core_subnet_gatewaya_cidr=10.15.71.208/28
global_core_subnet_gatewayb_cidr=10.15.79.208/28
global_core_subnet_gatewayc_cidr=10.15.87.208/28
global_core_subnet_endpointa_cidr=10.15.71.224/27
global_core_subnet_endpointb_cidr=10.15.79.224/27
global_core_subnet_endpointc_cidr=10.15.87.224/27

global_log_public_domain=l.$domain
global_log_private_domain=l.$domain
global_log_directory_domain=$global_management_directory_domain                  # Shares Global Management Directory
global_log_directory_netbios_domain=$global_management_directory_netbios_domain  # Shares Global Management Directory
global_log_directory_admin_user=$global_management_directory_admin_user          # Shares Global Management Directory
global_log_directory_admin_password=$global_management_directory_admin_password  # Shares Global Management Directory

global_log_vpc_cidr=10.15.128.0/19
global_log_subnet_publica_cidr=10.15.128.0/25
global_log_subnet_publicb_cidr=10.15.136.0/25
global_log_subnet_publicc_cidr=10.15.144.0/25
global_log_subnet_weba_cidr=10.15.129.0/25
global_log_subnet_webb_cidr=10.15.137.0/25
global_log_subnet_webc_cidr=10.15.145.0/25
global_log_subnet_applicationa_cidr=10.15.130.0/25
global_log_subnet_applicationb_cidr=10.15.138.0/25
global_log_subnet_applicationc_cidr=10.15.146.0/25
global_log_subnet_databasea_cidr=10.15.132.0/25
global_log_subnet_databaseb_cidr=10.15.140.0/25
global_log_subnet_databasec_cidr=10.15.148.0/25
global_log_subnet_managementa_cidr=10.15.135.192/28
global_log_subnet_managementb_cidr=10.15.143.192/28
global_log_subnet_managementc_cidr=10.15.151.192/28
global_log_subnet_gatewaya_cidr=10.15.135.208/28
global_log_subnet_gatewayb_cidr=10.15.143.208/28
global_log_subnet_gatewayc_cidr=10.15.151.208/28
global_log_subnet_endpointa_cidr=10.15.135.224/27
global_log_subnet_endpointb_cidr=10.15.143.224/27
global_log_subnet_endpointc_cidr=10.15.151.224/27

# Ohio Region: Shared
ohio_management_public_domain=us-east-2.$domain
ohio_management_private_domain=us-east-2.$domain
ohio_management_directory_domain=ad.us-east-2.$domain
ohio_management_directory_netbios_domain=dxcapue2
ohio_management_directory_admin_user=Admin@$ohio_management_directory_domain
ohio_management_directory_admin_password=MaybeNotHard2Guess

ohio_management_vpc_cidr=10.31.0.0/20
ohio_management_subnet_publica_cidr=10.31.0.0/26
ohio_management_subnet_publicb_cidr=10.31.4.0/26
ohio_management_subnet_publicc_cidr=10.31.8.0/26
ohio_management_subnet_weba_cidr=10.31.0.128/26
ohio_management_subnet_webb_cidr=10.31.4.128/26
ohio_management_subnet_webc_cidr=10.31.8.128/26
ohio_management_subnet_applicationa_cidr=10.31.1.0/26
ohio_management_subnet_applicationb_cidr=10.31.5.0/26
ohio_management_subnet_applicationc_cidr=10.31.9.0/26
ohio_management_subnet_databasea_cidr=10.31.2.0/26
ohio_management_subnet_databaseb_cidr=10.31.6.0/26
ohio_management_subnet_databasec_cidr=10.31.10.0/26
ohio_management_subnet_directorya_cidr=10.31.3.0/25
ohio_management_subnet_directoryb_cidr=10.31.7.0/25
ohio_management_subnet_directoryc_cidr=10.31.11.0/25
ohio_management_subnet_managementa_cidr=10.31.3.192/28
ohio_management_subnet_managementb_cidr=10.31.7.192/28
ohio_management_subnet_managementc_cidr=10.31.11.192/28
ohio_management_subnet_gatewaya_cidr=10.31.3.208/28
ohio_management_subnet_gatewayb_cidr=10.31.7.208/28
ohio_management_subnet_gatewayc_cidr=10.31.11.208/28
ohio_management_subnet_endpointa_cidr=10.31.3.224/27
ohio_management_subnet_endpointb_cidr=10.31.7.224/27
ohio_management_subnet_endpointc_cidr=10.31.11.224/27

if [ $perclient_ds = 1 ]; then
  # In the "PerClient" Directory Model, All Clients have their own Ohio Directory for Computers in Ohio
  alfa_ohio_management_directory_domain=ad.us-east-2.alfa.$domain
  alfa_ohio_management_directory_netbios_domain=alfaue2
  alfa_ohio_management_directory_admin_user=Admin@$alfa_ohio_management_directory_domain
  alfa_ohio_management_directory_admin_password=AlfaOhioUniquePasswordGoesHere

  zulu_ohio_management_directory_domain=ad.us-east-2.zulu.$domain
  zulu_ohio_management_directory_netbios_domain=zuluue2
  zulu_ohio_management_directory_admin_user=Admin@$zulu_ohio_management_directory_domain
  zulu_ohio_management_directory_admin_password=ZuluOhioUniquePasswordGoesHere
else
  # In the "OneGlobal" Directory Model, All Clients Share the same Ohio Directory for Computers in Ohio
  alfa_ohio_management_directory_domain=$ohio_management_directory_domain                  # Shares Ohio Management Directory
  alfa_ohio_management_directory_netbios_domain=$ohio_management_directory_netbios_domain  # Shares Ohio Management Directory
  alfa_ohio_management_directory_admin_user=$ohio_management_directory_admin_user          # Shares Ohio Management Directory
  alfa_ohio_management_directory_admin_password=$ohio_management_directory_admin_password  # Shares Ohio Management Directory

  zulu_ohio_management_directory_domain=$ohio_management_directory_domain                  # Shares Ohio Management Directory
  zulu_ohio_management_directory_netbios_domain=$ohio_management_directory_netbios_domain  # Shares Ohio Management Directory
  zulu_ohio_management_directory_admin_user=$ohio_management_directory_admin_user          # Shares Ohio Management Directory
  zulu_ohio_management_directory_admin_password=$ohio_management_directory_admin_password  # Shares Ohio Management Directory
fi

ohio_core_public_domain=c.us-east-2.$domain
ohio_core_private_domain=c.us-east-2.$domain
ohio_core_directory_domain=$ohio_management_directory_domain                  # Shares Ohio Management Directory
ohio_core_directory_netbios_domain=$ohio_management_directory_netbios_domain  # Shares Ohio Management Directory
ohio_core_directory_admin_user=$ohio_management_directory_admin_user          # Shares Ohio Management Directory
ohio_core_directory_admin_password=$ohio_management_directory_admin_password  # Shares Ohio Management Directory

ohio_core_vpc_cidr=10.31.64.0/20
ohio_core_subnet_publica_cidr=10.31.64.0/26
ohio_core_subnet_publicb_cidr=10.31.68.0/26
ohio_core_subnet_publicc_cidr=10.31.72.0/26
ohio_core_subnet_weba_cidr=10.31.64.128/26
ohio_core_subnet_webb_cidr=10.31.68.128/26
ohio_core_subnet_webc_cidr=10.31.72.128/26
ohio_core_subnet_applicationa_cidr=10.31.65.0/26
ohio_core_subnet_applicationb_cidr=10.31.69.0/26
ohio_core_subnet_applicationc_cidr=10.31.73.0/26
ohio_core_subnet_databasea_cidr=10.31.66.0/26
ohio_core_subnet_databaseb_cidr=10.31.70.0/26
ohio_core_subnet_databasec_cidr=10.31.74.0/26
ohio_core_subnet_managementa_cidr=10.31.67.192/28
ohio_core_subnet_managementb_cidr=10.31.71.192/28
ohio_core_subnet_managementc_cidr=10.31.75.192/28
ohio_core_subnet_gatewaya_cidr=10.31.67.208/28
ohio_core_subnet_gatewayb_cidr=10.31.71.208/28
ohio_core_subnet_gatewayc_cidr=10.31.75.208/28
ohio_core_subnet_endpointa_cidr=10.31.67.224/27
ohio_core_subnet_endpointb_cidr=10.31.71.224/27
ohio_core_subnet_endpointc_cidr=10.31.75.224/27

ohio_core_tgw_asn=64513

ohio_core_tgw_rs_allow_external=true

ohio_core_alfa_lax_vpn_tunnel1_cidr='169.254.10.0/30'
ohio_core_alfa_lax_vpn_tunnel1_psk='6kjdQGLeEYq7GwpRArxXtYVPZAkZvvf3'
ohio_core_alfa_lax_vpn_tunnel2_cidr='169.254.11.0/30'
ohio_core_alfa_lax_vpn_tunnel2_psk='Y2nJKcgmqnA4pq7LhDqu7Q6VFtx9QGTM'
ohio_core_alfa_lax_vpn_tunnel3_cidr='169.254.12.0/30'
ohio_core_alfa_lax_vpn_tunnel3_psk='q7Dqu7QY2nJKcx9QLhgmqnA4pTM6VFtG'
ohio_core_alfa_lax_vpn_tunnel4_cidr='169.254.13.0/30'
ohio_core_alfa_lax_vpn_tunnel4_psk='QGTMYmqnA4pq7L2nJKcg6VFtx9hDqu7Q'

ohio_core_alfa_mia_vpn_tunnel1_cidr='169.254.20.0/30'
ohio_core_alfa_mia_vpn_tunnel1_psk='wpRArxXtYEYq7GZAkZvvf3VP6kjdQGLe'
ohio_core_alfa_mia_vpn_tunnel2_cidr='169.254.21.0/30'
ohio_core_alfa_mia_vpn_tunnel2_psk='A4pq7LhDY2nJKcgmqnqu7QQGTM6VFtx9'
ohio_core_alfa_mia_vpn_tunnel3_cidr='169.254.22.0/30'
ohio_core_alfa_mia_vpn_tunnel3_psk='ZApRArkZwxXtYEGvvf3VkjdQP6GLeYq7'
ohio_core_alfa_mia_vpn_tunnel4_cidr='169.254.23.0/30'
ohio_core_alfa_mia_vpn_tunnel4_psk='nJKcgA4pq7LhDY2mQQM6qnqu7VFtx9GT'

ohio_core_zulu_dfw_vpn_tunnel1_cidr='169.254.30.0/30'
ohio_core_zulu_dfw_vpn_tunnel1_psk='VPZLeEYq7GA6kjdQGwptYkZvvf3RArxX'
ohio_core_zulu_dfw_vpn_tunnel2_cidr='169.254.31.0/30'
ohio_core_zulu_dfw_vpn_tunnel2_psk='qnA4VFtx9QpqY2hGTMnJDqu7Q6Kcgm7L'
ohio_core_zulu_dfw_vpn_tunnel3_cidr='169.254.32.0/30'
ohio_core_zulu_dfw_vpn_tunnel3_psk='6kjVeEYq7GAdQGwPZLptvfArYkZvxX3R'
ohio_core_zulu_dfw_vpn_tunnel4_cidr='169.254.33.0/30'
ohio_core_zulu_dfw_vpn_tunnel4_psk='x9A4VFtqYQpqn2hGqu7QgTMnJDm7L6Kc'

ohio_core_dxc_sba_vpn_tunnel1_cidr='169.254.250.0/30'
ohio_core_dxc_sba_vpn_tunnel1_psk='EYq7GVPZLeAptYkZvRArx6kjdQGwXvf3'
ohio_core_dxc_sba_vpn_tunnel2_cidr='169.254.251.0/30'
ohio_core_dxc_sba_vpn_tunnel2_psk='txqnAhGTMnJKcgm7L4VF9QpDqu7Q6qY2'
ohio_core_dxc_sba_vpn_tunnel3_cidr='169.254.252.0/30'
ohio_core_dxc_sba_vpn_tunnel3_psk='Yq7EptvfdQGwPZX3RArYkZL6kjVexvGA'
ohio_core_dxc_sba_vpn_tunnel4_cidr='169.254.253.0/30'
ohio_core_dxc_sba_vpn_tunnel4_psk='qnMx9A4V2hGqDm7L6KYQcu7QgTFtqpnJ'

ohio_core_client_vpn_cidr=172.32.16.0/22


ohio_log_public_domain=l.us-east-2.$domain
ohio_log_private_domain=l.us-east-2.$domain
ohio_log_directory_domain=$ohio_management_directory_domain                  # Shares Ohio Management Directory
ohio_log_directory_netbios_domain=$ohio_management_directory_netbios_domain  # Shares Ohio Management Directory
ohio_log_directory_admin_user=$ohio_management_directory_admin_user          # Shares Ohio Management Directory
ohio_log_directory_admin_password=$ohio_management_directory_admin_password  # Shares Ohio Management Directory

ohio_log_vpc_cidr=10.31.128.0/20
ohio_log_subnet_publica_cidr=10.31.128.0/26
ohio_log_subnet_publicb_cidr=10.31.132.0/26
ohio_log_subnet_publicc_cidr=10.31.136.0/26
ohio_log_subnet_weba_cidr=10.31.128.128/26
ohio_log_subnet_webb_cidr=10.31.132.128/26
ohio_log_subnet_webc_cidr=10.31.136.128/26
ohio_log_subnet_applicationa_cidr=10.31.129.0/26
ohio_log_subnet_applicationb_cidr=10.31.133.0/26
ohio_log_subnet_applicationc_cidr=10.31.137.0/26
ohio_log_subnet_databasea_cidr=10.31.130.0/26
ohio_log_subnet_databaseb_cidr=10.31.134.0/26
ohio_log_subnet_databasec_cidr=10.31.138.0/26
ohio_log_subnet_managementa_cidr=10.31.131.192/28
ohio_log_subnet_managementb_cidr=10.31.135.192/28
ohio_log_subnet_managementc_cidr=10.31.139.192/28
ohio_log_subnet_gatewaya_cidr=10.31.131.208/28
ohio_log_subnet_gatewayb_cidr=10.31.135.208/28
ohio_log_subnet_gatewayc_cidr=10.31.139.208/28
ohio_log_subnet_endpointa_cidr=10.31.131.224/27
ohio_log_subnet_endpointb_cidr=10.31.135.224/27
ohio_log_subnet_endpointc_cidr=10.31.139.224/27

# Ohio Region: Per-Client
alfa_ohio_production_public_domain=us-east-2.alfa.$domain
alfa_ohio_production_private_domain=us-east-2.alfa.$domain
alfa_ohio_production_directory_domain=$alfa_ohio_management_directory_domain                  # Shares Alfa Ohio Management Directory
alfa_ohio_production_directory_netbios_domain=$alfa_ohio_management_directory_netbios_domain  # Shares Alfa Ohio Management Directory
alfa_ohio_production_directory_admin_user=$alfa_ohio_management_directory_admin_user          # Shares Alfa Ohio Management Directory
alfa_ohio_production_directory_admin_password=$alfa_ohio_management_directory_admin_password  # Shares Alfa Ohio Management Directory

alfa_ohio_production_vpc_cidr=10.16.0.0/20
alfa_ohio_production_subnet_publica_cidr=10.16.0.0/26
alfa_ohio_production_subnet_publicb_cidr=10.16.4.0/26
alfa_ohio_production_subnet_publicc_cidr=10.16.8.0/26
alfa_ohio_production_subnet_weba_cidr=10.16.0.128/26
alfa_ohio_production_subnet_webb_cidr=10.16.4.128/26
alfa_ohio_production_subnet_webc_cidr=10.16.8.128/26
alfa_ohio_production_subnet_applicationa_cidr=10.16.1.0/26
alfa_ohio_production_subnet_applicationb_cidr=10.16.5.0/26
alfa_ohio_production_subnet_applicationc_cidr=10.16.9.0/26
alfa_ohio_production_subnet_databasea_cidr=10.16.2.0/26
alfa_ohio_production_subnet_databaseb_cidr=10.16.6.0/26
alfa_ohio_production_subnet_databasec_cidr=10.16.10.0/26
alfa_ohio_production_subnet_managementa_cidr=10.16.3.192/28
alfa_ohio_production_subnet_managementb_cidr=10.16.7.192/28
alfa_ohio_production_subnet_managementc_cidr=10.16.11.192/28
alfa_ohio_production_subnet_gatewaya_cidr=10.16.3.208/28
alfa_ohio_production_subnet_gatewayb_cidr=10.16.7.208/28
alfa_ohio_production_subnet_gatewayc_cidr=10.16.11.208/28
alfa_ohio_production_subnet_endpointa_cidr=10.16.3.224/27
alfa_ohio_production_subnet_endpointb_cidr=10.16.7.224/27
alfa_ohio_production_subnet_endpointc_cidr=10.16.11.224/27


alfa_ohio_testing_public_domain=t.us-east-2.alfa.$domain
alfa_ohio_testing_private_domain=t.us-east-2.alfa.$domain
alfa_ohio_testing_directory_domain=$alfa_ohio_management_directory_domain                  # Shares Alfa Ohio Management Directory
alfa_ohio_testing_directory_netbios_domain=$alfa_ohio_management_directory_netbios_domain  # Shares Alfa Ohio Management Directory
alfa_ohio_testing_directory_admin_user=$alfa_ohio_management_directory_admin_user          # Shares Alfa Ohio Management Directory
alfa_ohio_testing_directory_admin_password=$alfa_ohio_management_directory_admin_password  # Shares Alfa Ohio Management Directory

alfa_ohio_testing_vpc_cidr=10.16.32.0/20
alfa_ohio_testing_subnet_publica_cidr=10.16.32.0/26
alfa_ohio_testing_subnet_publicb_cidr=10.16.36.0/26
alfa_ohio_testing_subnet_publicc_cidr=10.16.40.0/26
alfa_ohio_testing_subnet_weba_cidr=10.16.32.128/26
alfa_ohio_testing_subnet_webb_cidr=10.16.36.128/26
alfa_ohio_testing_subnet_webc_cidr=10.16.40.128/26
alfa_ohio_testing_subnet_applicationa_cidr=10.16.33.0/26
alfa_ohio_testing_subnet_applicationb_cidr=10.16.37.0/26
alfa_ohio_testing_subnet_applicationc_cidr=10.16.41.0/26
alfa_ohio_testing_subnet_databasea_cidr=10.16.34.0/26
alfa_ohio_testing_subnet_databaseb_cidr=10.16.38.0/26
alfa_ohio_testing_subnet_databasec_cidr=10.16.42.0/26
alfa_ohio_testing_subnet_managementa_cidr=10.16.35.192/28
alfa_ohio_testing_subnet_managementb_cidr=10.16.39.192/28
alfa_ohio_testing_subnet_managementc_cidr=10.16.43.192/28
alfa_ohio_testing_subnet_gatewaya_cidr=10.16.35.208/28
alfa_ohio_testing_subnet_gatewayb_cidr=10.16.39.208/28
alfa_ohio_testing_subnet_gatewayc_cidr=10.16.43.208/28
alfa_ohio_testing_subnet_endpointa_cidr=10.16.35.224/27
alfa_ohio_testing_subnet_endpointb_cidr=10.16.39.224/27
alfa_ohio_testing_subnet_endpointc_cidr=10.16.43.224/27


alfa_ohio_development_public_domain=d.us-east-2.alfa.$domain
alfa_ohio_development_private_domain=d.us-east-2.alfa.$domain
alfa_ohio_development_directory_domain=$alfa_ohio_management_directory_domain                  # Shares Alfa Ohio Management Directory
alfa_ohio_development_directory_netbios_domain=$alfa_ohio_management_directory_netbios_domain  # Shares Alfa Ohio Management Directory
alfa_ohio_development_directory_admin_user=$alfa_ohio_management_directory_admin_user          # Shares Alfa Ohio Management Directory
alfa_ohio_development_directory_admin_password=$alfa_ohio_management_directory_admin_password  # Shares Alfa Ohio Management Directory

alfa_ohio_development_vpc_cidr=10.16.48.0/20
alfa_ohio_development_subnet_publica_cidr=10.16.48.0/26
alfa_ohio_development_subnet_publicb_cidr=10.16.52.0/26
alfa_ohio_development_subnet_publicc_cidr=10.16.56.0/26
alfa_ohio_development_subnet_weba_cidr=10.16.48.128/26
alfa_ohio_development_subnet_webb_cidr=10.16.52.128/26
alfa_ohio_development_subnet_webc_cidr=10.16.56.128/26
alfa_ohio_development_subnet_applicationa_cidr=10.16.49.0/26
alfa_ohio_development_subnet_applicationb_cidr=10.16.53.0/26
alfa_ohio_development_subnet_applicationc_cidr=10.16.57.0/26
alfa_ohio_development_subnet_databasea_cidr=10.16.50.0/26
alfa_ohio_development_subnet_databaseb_cidr=10.16.54.0/26
alfa_ohio_development_subnet_databasec_cidr=10.16.58.0/26
alfa_ohio_development_subnet_managementa_cidr=10.16.51.192/28
alfa_ohio_development_subnet_managementb_cidr=10.16.55.192/28
alfa_ohio_development_subnet_managementc_cidr=10.16.59.192/28
alfa_ohio_development_subnet_gatewaya_cidr=10.16.51.208/28
alfa_ohio_development_subnet_gatewayb_cidr=10.16.55.208/28
alfa_ohio_development_subnet_gatewayc_cidr=10.16.59.208/28
alfa_ohio_development_subnet_endpointa_cidr=10.16.51.224/27
alfa_ohio_development_subnet_endpointb_cidr=10.16.55.224/27
alfa_ohio_development_subnet_endpointc_cidr=10.16.59.224/27


zulu_ohio_production_public_domain=us-east-2.zulu.$domain
zulu_ohio_production_private_domain=us-east-2.zulu.$domain
zulu_ohio_production_directory_domain=$zulu_ohio_management_directory_domain                  # Shares Zulu Ohio Management Directory
zulu_ohio_production_directory_netbios_domain=$zulu_ohio_management_directory_netbios_domain  # Shares Zulu Ohio Management Directory
zulu_ohio_production_directory_admin_user=$zulu_ohio_management_directory_admin_user          # Shares Zulu Ohio Management Directory
zulu_ohio_production_directory_admin_password=$zulu_ohio_management_directory_admin_password  # Shares Zulu Ohio Management Directory

zulu_ohio_production_vpc_cidr=10.22.64.0/19
zulu_ohio_production_subnet_publica_cidr=10.22.64.0/25
zulu_ohio_production_subnet_publicb_cidr=10.22.72.0/25
zulu_ohio_production_subnet_publicc_cidr=10.22.80.0/25
zulu_ohio_production_subnet_weba_cidr=10.22.65.0/25
zulu_ohio_production_subnet_webb_cidr=10.22.73.0/25
zulu_ohio_production_subnet_webc_cidr=10.22.81.0/25
zulu_ohio_production_subnet_applicationa_cidr=10.22.66.0/25
zulu_ohio_production_subnet_applicationb_cidr=10.22.74.0/25
zulu_ohio_production_subnet_applicationc_cidr=10.22.82.0/25
zulu_ohio_production_subnet_databasea_cidr=10.22.68.0/25
zulu_ohio_production_subnet_databaseb_cidr=10.22.76.0/25
zulu_ohio_production_subnet_databasec_cidr=10.22.84.0/25
zulu_ohio_production_subnet_managementa_cidr=10.22.71.192/28
zulu_ohio_production_subnet_managementb_cidr=10.22.79.192/28
zulu_ohio_production_subnet_managementc_cidr=10.22.87.192/28
zulu_ohio_production_subnet_gatewaya_cidr=10.22.71.208/28
zulu_ohio_production_subnet_gatewayb_cidr=10.22.79.208/28
zulu_ohio_production_subnet_gatewayc_cidr=10.22.87.208/28
zulu_ohio_production_subnet_endpointa_cidr=10.22.71.224/27
zulu_ohio_production_subnet_endpointb_cidr=10.22.79.224/27
zulu_ohio_production_subnet_endpointc_cidr=10.22.87.224/27


zulu_ohio_development_public_domain=d.us-east-2.zulu.$domain
zulu_ohio_development_private_domain=d.us-east-2.zulu.$domain
zulu_ohio_development_directory_domain=$zulu_ohio_management_directory_domain                  # Shares Zulu Ohio Management Directory
zulu_ohio_development_directory_netbios_domain=$zulu_ohio_management_directory_netbios_domain  # Shares Zulu Ohio Management Directory
zulu_ohio_development_directory_admin_user=$zulu_ohio_management_directory_admin_user          # Shares Zulu Ohio Management Directory
zulu_ohio_development_directory_admin_password=$zulu_ohio_management_directory_admin_password  # Shares Zulu Ohio Management Directory

zulu_ohio_development_vpc_cidr=10.22.112.0/20
zulu_ohio_development_subnet_publica_cidr=10.22.112.0/26
zulu_ohio_development_subnet_publicb_cidr=10.22.116.0/26
zulu_ohio_development_subnet_publicc_cidr=10.22.120.0/26
zulu_ohio_development_subnet_weba_cidr=10.22.112.128/26
zulu_ohio_development_subnet_webb_cidr=10.22.116.128/26
zulu_ohio_development_subnet_webc_cidr=10.22.120.128/26
zulu_ohio_development_subnet_applicationa_cidr=10.22.113.0/26
zulu_ohio_development_subnet_applicationb_cidr=10.22.117.0/26
zulu_ohio_development_subnet_applicationc_cidr=10.22.121.0/26
zulu_ohio_development_subnet_databasea_cidr=10.22.114.0/26
zulu_ohio_development_subnet_databaseb_cidr=10.22.118.0/26
zulu_ohio_development_subnet_databasec_cidr=10.22.122.0/26
zulu_ohio_development_subnet_managementa_cidr=10.22.115.192/28
zulu_ohio_development_subnet_managementb_cidr=10.22.119.192/28
zulu_ohio_development_subnet_managementc_cidr=10.22.123.192/28
zulu_ohio_development_subnet_gatewaya_cidr=10.22.115.208/28
zulu_ohio_development_subnet_gatewayb_cidr=10.22.119.208/28
zulu_ohio_development_subnet_gatewayc_cidr=10.22.123.208/28
zulu_ohio_development_subnet_endpointa_cidr=10.22.115.224/27
zulu_ohio_development_subnet_endpointb_cidr=10.22.119.224/27
zulu_ohio_development_subnet_endpointc_cidr=10.22.123.224/27


# Ireland Region: Shared
ireland_management_public_domain=eu-west-1.$domain
ireland_management_private_domain=eu-west-1.$domain
ireland_management_directory_domain=ad.eu-west-1.$domain
ireland_management_directory_netbios_domain=dxcapew1
ireland_management_directory_admin_user=Admin@$ireland_management_directory_domain
ireland_management_directory_admin_password=CouldBEasy2Guess

ireland_management_vpc_cidr=10.79.0.0/20
ireland_management_subnet_publica_cidr=10.79.0.0/26
ireland_management_subnet_publicb_cidr=10.79.4.0/26
ireland_management_subnet_publicc_cidr=10.79.8.0/26
ireland_management_subnet_weba_cidr=10.79.0.128/26
ireland_management_subnet_webb_cidr=10.79.4.128/26
ireland_management_subnet_webc_cidr=10.79.8.128/26
ireland_management_subnet_applicationa_cidr=10.79.1.0/26
ireland_management_subnet_applicationb_cidr=10.79.5.0/26
ireland_management_subnet_applicationc_cidr=10.79.9.0/26
ireland_management_subnet_databasea_cidr=10.79.2.0/26
ireland_management_subnet_databaseb_cidr=10.79.6.0/26
ireland_management_subnet_databasec_cidr=10.79.10.0/26
ireland_management_subnet_directorya_cidr=10.79.3.0/25
ireland_management_subnet_directoryb_cidr=10.79.7.0/25
ireland_management_subnet_directoryc_cidr=10.79.11.0/25
ireland_management_subnet_managementa_cidr=10.79.3.192/28
ireland_management_subnet_managementb_cidr=10.79.7.192/28
ireland_management_subnet_managementc_cidr=10.79.11.192/28
ireland_management_subnet_gatewaya_cidr=10.79.3.208/28
ireland_management_subnet_gatewayb_cidr=10.79.7.208/28
ireland_management_subnet_gatewayc_cidr=10.79.11.208/28
ireland_management_subnet_endpointa_cidr=10.79.3.224/27
ireland_management_subnet_endpointb_cidr=10.79.7.224/27
ireland_management_subnet_endpointc_cidr=10.79.11.224/27

if [ $perclient_ds = 1 ]; then
  # In the "PerClient" Directory Model, All Clients have their own Ireland Directory for Computers in Ireland
  alfa_ireland_management_directory_domain=ad.eu-west-1.alfa.$domain
  alfa_ireland_management_directory_netbios_domain=alfaew1
  alfa_ireland_management_directory_admin_user=Admin@$alfa_ireland_management_directory_domain
  alfa_ireland_management_directory_admin_password=AlfaIrelandUniquePasswordGoesHere

  zulu_ireland_management_directory_domain=ad.eu-west-1.zulu.$domain
  zulu_ireland_management_directory_netbios_domain=zuluew1
  zulu_ireland_management_directory_admin_user=Admin@$zulu_ireland_management_directory_domain
  zulu_ireland_management_directory_admin_password=ZuluIrelandUniquePasswordGoesHere
else
  # In the "OneGlobal" Directory Model, All Clients Share the same Ohio Directory for Computers in Ireland
  alfa_ireland_management_directory_domain=$ireland_management_directory_domain                  # Shares Ireland Management Directory
  alfa_ireland_management_directory_netbios_domain=$ireland_management_directory_netbios_domain  # Shares Ireland Management Directory
  alfa_ireland_management_directory_admin_user=$ireland_management_directory_admin_user          # Shares Ireland Management Directory
  alfa_ireland_management_directory_admin_password=$ireland_management_directory_admin_password  # Shares Ireland Management Directory

  zulu_ireland_management_directory_domain=$ireland_management_directory_domain                  # Shares Ireland Management Directory
  zulu_ireland_management_directory_netbios_domain=$ireland_management_directory_netbios_domain  # Shares Ireland Management Directory
  zulu_ireland_management_directory_admin_user=$ireland_management_directory_admin_user          # Shares Ireland Management Directory
  zulu_ireland_management_directory_admin_password=$ireland_management_directory_admin_password  # Shares Ireland Management Directory
fi

ireland_core_public_domain=c.eu-west-1.$domain
ireland_core_private_domain=c.eu-west-1.$domain
ireland_core_directory_domain=$ireland_management_directory_domain                  # Shares Ireland Management Directory
ireland_core_directory_netbios_domain=$ireland_management_directory_netbios_domain  # Shares Ireland Management Directory
ireland_core_directory_admin_user=$ireland_management_directory_admin_user          # Shares Ireland Management Directory
ireland_core_directory_admin_password=$ireland_management_directory_admin_password  # Shares Ireland Management Directory

ireland_core_vpc_cidr=10.79.64.0/20
ireland_core_subnet_publica_cidr=10.79.64.0/26
ireland_core_subnet_publicb_cidr=10.79.68.0/26
ireland_core_subnet_publicc_cidr=10.79.72.0/26
ireland_core_subnet_weba_cidr=10.79.64.128/26
ireland_core_subnet_webb_cidr=10.79.68.128/26
ireland_core_subnet_webc_cidr=10.79.72.128/26
ireland_core_subnet_applicationa_cidr=10.79.65.0/26
ireland_core_subnet_applicationb_cidr=10.79.69.0/26
ireland_core_subnet_applicationc_cidr=10.79.73.0/26
ireland_core_subnet_databasea_cidr=10.79.66.0/26
ireland_core_subnet_databaseb_cidr=10.79.70.0/26
ireland_core_subnet_databasec_cidr=10.79.74.0/26
ireland_core_subnet_managementa_cidr=10.79.67.192/28
ireland_core_subnet_managementb_cidr=10.79.71.192/28
ireland_core_subnet_managementc_cidr=10.79.75.192/28
ireland_core_subnet_gatewaya_cidr=10.79.67.208/28
ireland_core_subnet_gatewayb_cidr=10.79.71.208/28
ireland_core_subnet_gatewayc_cidr=10.79.75.208/28
ireland_core_subnet_endpointa_cidr=10.79.67.224/27
ireland_core_subnet_endpointb_cidr=10.79.71.224/27
ireland_core_subnet_endpointc_cidr=10.79.75.224/27

ireland_core_tgw_asn=64514

ireland_core_tgw_rs_allow_external=true

ireland_core_alfa_lax_vpn_tunnel1_cidr='169.254.10.0/30'
ireland_core_alfa_lax_vpn_tunnel1_psk='6kjdQGLeEYq7GwpRArxXtYVPZAkZvvf3'
ireland_core_alfa_lax_vpn_tunnel2_cidr='169.254.11.0/30'
ireland_core_alfa_lax_vpn_tunnel2_psk='Y2nJKcgmqnA4pq7LhDqu7Q6VFtx9QGTM'
ireland_core_alfa_lax_vpn_tunnel3_cidr='169.254.12.0/30'
ireland_core_alfa_lax_vpn_tunnel3_psk='q7Dqu7QY2nJKcx9QLhgmqnA4pTM6VFtG'
ireland_core_alfa_lax_vpn_tunnel4_cidr='169.254.13.0/30'
ireland_core_alfa_lax_vpn_tunnel4_psk='QGTMYmqnA4pq7L2nJKcg6VFtx9hDqu7Q'

ireland_core_alfa_mia_vpn_tunnel1_cidr='169.254.20.0/30'
ireland_core_alfa_mia_vpn_tunnel1_psk='wpRArxXtYEYq7GZAkZvvf3VP6kjdQGLe'
ireland_core_alfa_mia_vpn_tunnel2_cidr='169.254.21.0/30'
ireland_core_alfa_mia_vpn_tunnel2_psk='A4pq7LhDY2nJKcgmqnqu7QQGTM6VFtx9'
ireland_core_alfa_mia_vpn_tunnel3_cidr='169.254.22.0/30'
ireland_core_alfa_mia_vpn_tunnel3_psk='ZApRArkZwxXtYEGvvf3VkjdQP6GLeYq7'
ireland_core_alfa_mia_vpn_tunnel4_cidr='169.254.23.0/30'
ireland_core_alfa_mia_vpn_tunnel4_psk='nJKcgA4pq7LhDY2mQQM6qnqu7VFtx9GT'

ireland_core_client_vpn_cidr=172.32.16.0/22


ireland_log_public_domain=l.eu-west-1.$domain
ireland_log_private_domain=l.eu-west-1.$domain
ireland_log_directory_domain=$ireland_management_directory_domain                  # Shares Ireland Management Directory
ireland_log_directory_netbios_domain=$ireland_management_directory_netbios_domain  # Shares Ireland Management Directory
ireland_log_directory_admin_user=$ireland_management_directory_admin_user          # Shares Ireland Management Directory
ireland_log_directory_admin_password=$ireland_management_directory_admin_password  # Shares Ireland Management Directory

ireland_log_vpc_cidr=10.79.128.0/20
ireland_log_subnet_publica_cidr=10.79.128.0/26
ireland_log_subnet_publicb_cidr=10.79.132.0/26
ireland_log_subnet_publicc_cidr=10.79.136.0/26
ireland_log_subnet_weba_cidr=10.79.128.128/26
ireland_log_subnet_webb_cidr=10.79.132.128/26
ireland_log_subnet_webc_cidr=10.79.136.128/26
ireland_log_subnet_applicationa_cidr=10.79.129.0/26
ireland_log_subnet_applicationb_cidr=10.79.133.0/26
ireland_log_subnet_applicationc_cidr=10.79.137.0/26
ireland_log_subnet_databasea_cidr=10.79.130.0/26
ireland_log_subnet_databaseb_cidr=10.79.134.0/26
ireland_log_subnet_databasec_cidr=10.79.138.0/26
ireland_log_subnet_managementa_cidr=10.79.131.192/28
ireland_log_subnet_managementb_cidr=10.79.135.192/28
ireland_log_subnet_managementc_cidr=10.79.139.192/28
ireland_log_subnet_gatewaya_cidr=10.79.131.208/28
ireland_log_subnet_gatewayb_cidr=10.79.135.208/28
ireland_log_subnet_gatewayc_cidr=10.79.139.208/28
ireland_log_subnet_endpointa_cidr=10.79.131.224/27
ireland_log_subnet_endpointb_cidr=10.79.135.224/27
ireland_log_subnet_endpointc_cidr=10.79.139.224/27

# Ireland Region: Per-Client
alfa_ireland_production_public_domain=eu-west-1.alfa.$domain # Even though we do not have production in Ireland, we need this as a parent

alfa_ireland_recovery_public_domain=r.eu-west-1.alfa.$domain
alfa_ireland_recovery_private_domain=r.eu-west-1.alfa.$domain
alfa_ireland_recovery_directory_domain=$alfa_ireland_management_directory_domain                  # Shares Alfa Ireland Management Directory
alfa_ireland_recovery_directory_netbios_domain=$alfa_ireland_management_directory_netbios_domain  # Shares Alfa Ireland Management Directory
alfa_ireland_recovery_directory_admin_user=$alfa_ireland_management_directory_admin_user          # Shares Alfa Ireland Management Directory
alfa_ireland_recovery_directory_admin_password=$alfa_ireland_management_directory_admin_password  # Shares Alfa Ireland Management Directory

alfa_ireland_recovery_vpc_cidr=10.64.0.0/20
alfa_ireland_recovery_subnet_publica_cidr=10.64.0.0/26
alfa_ireland_recovery_subnet_publicb_cidr=10.64.4.0/26
alfa_ireland_recovery_subnet_publicc_cidr=10.64.8.0/26
alfa_ireland_recovery_subnet_weba_cidr=10.64.0.128/26
alfa_ireland_recovery_subnet_webb_cidr=10.64.4.128/26
alfa_ireland_recovery_subnet_webc_cidr=10.64.8.128/26
alfa_ireland_recovery_subnet_applicationa_cidr=10.64.1.0/26
alfa_ireland_recovery_subnet_applicationb_cidr=10.64.5.0/26
alfa_ireland_recovery_subnet_applicationc_cidr=10.64.9.0/26
alfa_ireland_recovery_subnet_databasea_cidr=10.64.2.0/26
alfa_ireland_recovery_subnet_databaseb_cidr=10.64.6.0/26
alfa_ireland_recovery_subnet_databasec_cidr=10.64.10.0/26
alfa_ireland_recovery_subnet_managementa_cidr=10.64.3.192/28
alfa_ireland_recovery_subnet_managementb_cidr=10.64.7.192/28
alfa_ireland_recovery_subnet_managementc_cidr=10.64.11.192/28
alfa_ireland_recovery_subnet_gatewaya_cidr=10.64.3.208/28
alfa_ireland_recovery_subnet_gatewayb_cidr=10.64.7.208/28
alfa_ireland_recovery_subnet_gatewayc_cidr=10.64.11.208/28
alfa_ireland_recovery_subnet_endpointa_cidr=10.64.3.224/27
alfa_ireland_recovery_subnet_endpointb_cidr=10.64.7.224/27
alfa_ireland_recovery_subnet_endpointc_cidr=10.64.11.224/27

# Data Center Simulation VPCs
alfa_lax_public_domain=lax.alfa.$domain
alfa_lax_private_domain=lax.alfa.$domain

alfa_lax_vpc_cidr=172.24.0.0/24
alfa_lax_subnet_publica_cidr=172.24.0.0/27
alfa_lax_subnet_publicb_cidr=172.24.0.128/27
alfa_lax_subnet_privatea_cidr=172.24.0.32/27
alfa_lax_subnet_privateb_cidr=172.24.0.160/27
alfa_lax_subnet_managementa_cidr=172.24.0.64/28
alfa_lax_subnet_managementb_cidr=172.24.0.192/28
alfa_lax_subnet_gatewaya_cidr=172.24.0.80/28
alfa_lax_subnet_gatewayb_cidr=172.24.0.208/28
alfa_lax_subnet_endpointa_cidr=172.24.0.96/27
alfa_lax_subnet_endpointb_cidr=172.24.0.224/27
alfa_lax_cgw_asn=64768


alfa_mia_public_domain=mia.alfa.$domain
alfa_mia_private_domain=mia.alfa.$domain

alfa_mia_vpc_cidr=172.24.1.0/24
alfa_mia_subnet_publica_cidr=172.24.1.0/27
alfa_mia_subnet_publicb_cidr=172.24.1.128/27
alfa_mia_subnet_privatea_cidr=172.24.1.32/27
alfa_mia_subnet_privateb_cidr=172.24.1.160/27
alfa_mia_subnet_managementa_cidr=172.24.1.64/28
alfa_mia_subnet_managementb_cidr=172.24.1.192/28
alfa_mia_subnet_gatewaya_cidr=172.24.1.80/28
alfa_mia_subnet_gatewayb_cidr=172.24.1.208/28
alfa_mia_subnet_endpointa_cidr=172.24.1.96/27
alfa_mia_subnet_endpointb_cidr=172.24.1.224/27
alfa_mia_cgw_asn=64769


zulu_dfw_public_domain=dfw.zulu.$domain
zulu_dfw_private_domain=dfw.zulu.$domain

zulu_dfw_vpc_cidr=172.28.0.0/24
zulu_dfw_subnet_publica_cidr=172.28.0.0/27
zulu_dfw_subnet_publicb_cidr=172.28.0.128/27
zulu_dfw_subnet_privatea_cidr=172.28.0.32/27
zulu_dfw_subnet_privateb_cidr=172.28.0.160/27
zulu_dfw_subnet_managementa_cidr=172.28.0.64/28
zulu_dfw_subnet_managementb_cidr=172.28.0.192/28
zulu_dfw_subnet_gatewaya_cidr=172.28.0.80/28
zulu_dfw_subnet_gatewayb_cidr=172.28.0.208/28
zulu_dfw_subnet_endpointa_cidr=172.28.0.96/27
zulu_dfw_subnet_endpointb_cidr=172.28.0.224/27
zulu_dfw_cgw_asn=64780

dxc_sba_public_domain=sba.$domain
dxc_sba_private_domain=sba.$domain

dxc_sba_vpc_cidr=172.31.255.0/24
dxc_sba_subnet_publica_cidr=172.31.255.0/27
dxc_sba_subnet_publicb_cidr=172.31.255.128/27
dxc_sba_subnet_privatea_cidr=172.31.255.32/27
dxc_sba_subnet_privateb_cidr=172.31.255.160/27
dxc_sba_subnet_managementa_cidr=172.31.255.64/28
dxc_sba_subnet_managementb_cidr=172.31.255.192/28
dxc_sba_subnet_gatewaya_cidr=172.31.255.80/28
dxc_sba_subnet_gatewayb_cidr=172.31.255.208/28
dxc_sba_subnet_endpointa_cidr=172.31.255.96/27
dxc_sba_subnet_endpointb_cidr=172.31.255.224/27
dxc_sba_cgw_asn=65532
