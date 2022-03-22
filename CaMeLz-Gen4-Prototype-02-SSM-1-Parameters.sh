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
## Baseline SSM Parameters ############################################################################################
#######################################################################################################################

## Global Management Parameters #######################################################################################
profile=$management_profile

aws ssm put-parameter --name Management-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Management-Administrator-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text

aws ssm put-parameter --name Management-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$global_management_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Management-Directory-Domain \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text

aws ssm put-parameter --name Management-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$global_management_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Management-Directory-DomainJoin-User \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text

aws ssm put-parameter --name Management-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$global_management_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Management-Directory-DomainJoin-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text

aws ssm put-parameter --name Management-Directory-OhioTrust-Password \
                      --description 'Password for Trust Relationship with Ohio Management Directory Service' \
                      --value "$global_management_directory_ohio_trust_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Management-Directory-OhioTrust-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text

aws ssm put-parameter --name Management-Directory-IrelandTrust-Password \
                      --description 'Password for Trust Relationship with Ireland Management Directory Service' \
                      --value "$global_management_directory_ireland_trust_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Management-Directory-IrelandTrust-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text

if [ $perclient_ds = 1 ]; then
  aws ssm put-parameter --name Alfa-Management-Directory-Domain \
                        --description 'Alfa Directory Domain' \
                        --value "$alfa_global_management_directory_domain" \
                        --type String \
                        --tags Key=Name,Value=Alfa-Management-Directory-Domain \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-1 --output text

  aws ssm put-parameter --name Alfa-Management-Directory-DomainJoin-User \
                        --description 'User with permissions to Join Instances to the Alfa Directory Domain' \
                        --value "$alfa_global_management_directory_admin_user" \
                        --type String \
                        --tags Key=Name,Value=Alfa-Management-Directory-DomainJoin-User \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-1 --output text

  aws ssm put-parameter --name Alfa-Management-Directory-DomainJoin-Password \
                        --description 'Password for User with permissions to Join Instances to the Alfa Directory Domain' \
                        --value "$alfa_global_management_directory_admin_password" \
                        --type SecureString \
                        --tags Key=Name,Value=Alfa-Management-Directory-DomainJoin-Password \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-1 --output text

  aws ssm put-parameter --name Alfa-Management-Directory-OhioTrust-Password \
                        --description 'Password for Trust Relationship with Alfa Ohio Management Directory Service' \
                        --value "$alfa_global_management_directory_ohio_trust_password" \
                        --type SecureString \
                        --tags Key=Name,Value=Alfa-Management-Directory-OhioTrust-Password \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-1 --output text

  aws ssm put-parameter --name Alfa-Management-Directory-IrelandTrust-Password \
                        --description 'Password for Trust Relationship with Alfa Ireland Management Directory Service' \
                        --value "$alfa_global_management_directory_ireland_trust_password" \
                        --type SecureString \
                        --tags Key=Name,Value=Alfa-Management-Directory-IrelandTrust-Password \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-1 --output text

  aws ssm put-parameter --name Zulu-Management-Directory-Domain \
                        --description 'Zulu Directory Domain' \
                        --value "$zulu_global_management_directory_domain" \
                        --type String \
                        --tags Key=Name,Value=Zulu-Management-Directory-Domain \
                               Key=Company,Value=Zulu \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-1 --output text

  aws ssm put-parameter --name Zulu-Management-Directory-DomainJoin-User \
                        --description 'User with permissions to Join Instances to the Zulu Directory Domain' \
                        --value "$zulu_global_management_directory_admin_user" \
                        --type String \
                        --tags Key=Name,Value=Zulu-Management-Directory-DomainJoin-User \
                               Key=Company,Value=Zulu \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-1 --output text

  aws ssm put-parameter --name Zulu-Management-Directory-DomainJoin-Password \
                        --description 'Password for User with permissions to Join Instances to the Zulu Directory Domain' \
                        --value "$zulu_global_management_directory_admin_password" \
                        --type SecureString \
                        --tags Key=Name,Value=Zulu-Management-Directory-DomainJoin-Password \
                               Key=Company,Value=Zulu \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-1 --output text
fi


## Global Core Parameters #############################################################################################
profile=$core_profile

aws ssm put-parameter --name Core-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Core-Administrator-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text

aws ssm put-parameter --name Core-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$global_core_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Core-Directory-Domain \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text

aws ssm put-parameter --name Core-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$global_core_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Core-Directory-DomainJoin-User \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text

aws ssm put-parameter --name Core-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$global_core_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Core-Directory-DomainJoin-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text


## Global Log Parameters ##############################################################################################
profile=$log_profile

aws ssm put-parameter --name Log-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Log-Administrator-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text

aws ssm put-parameter --name Log-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$global_log_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Log-Directory-Domain \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text

aws ssm put-parameter --name Log-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$global_log_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Log-Directory-DomainJoin-User \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text

aws ssm put-parameter --name Log-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$global_log_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Log-Directory-DomainJoin-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-1 --output text


## Ohio Management Parameters #########################################################################################
profile=$management_profile

aws ssm put-parameter --name Management-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Management-Administrator-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Management-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$ohio_management_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Management-Directory-Domain \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Management-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$ohio_management_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Management-Directory-DomainJoin-User \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Management-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$ohio_management_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Management-Directory-DomainJoin-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

if [ $perclient_ds = 1 ]; then
  aws ssm put-parameter --name Alfa-Management-Directory-Domain \
                        --description 'Alfa Directory Domain' \
                        --value "$alfa_ohio_management_directory_domain" \
                        --type String \
                        --tags Key=Name,Value=Alfa-Management-Directory-Domain \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

  aws ssm put-parameter --name Alfa-Management-Directory-DomainJoin-User \
                        --description 'User with permissions to Join Instances to the Alfa Directory Domain' \
                        --value "$alfa_ohio_management_directory_admin_user" \
                        --type String \
                        --tags Key=Name,Value=Alfa-Management-Directory-DomainJoin-User \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

  aws ssm put-parameter --name Alfa-Management-Directory-DomainJoin-Password \
                        --description 'Password for User with permissions to Join Instances to the Alfa Directory Domain' \
                        --value "$alfa_ohio_management_directory_admin_password" \
                        --type SecureString \
                        --tags Key=Name,Value=Alfa-Management-Directory-DomainJoin-Password \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

  aws ssm put-parameter --name Zulu-Management-Directory-Domain \
                        --description 'Zulu Directory Domain' \
                        --value "$zulu_ohio_management_directory_domain" \
                        --type String \
                        --tags Key=Name,Value=Zulu-Management-Directory-Domain \
                               Key=Company,Value=Zulu \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

  aws ssm put-parameter --name Zulu-Management-Directory-DomainJoin-User \
                        --description 'User with permissions to Join Instances to the Zulu Directory Domain' \
                        --value "$zulu_ohio_management_directory_admin_user" \
                        --type String \
                        --tags Key=Name,Value=Zulu-Management-Directory-DomainJoin-User \
                               Key=Company,Value=Zulu \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text

  aws ssm put-parameter --name Zulu-Management-Directory-DomainJoin-Password \
                        --description 'Password for User with permissions to Join Instances to the Zulu Directory Domain' \
                        --value "$zulu_ohio_management_directory_admin_password" \
                        --type SecureString \
                        --tags Key=Name,Value=Zulu-Management-Directory-DomainJoin-Password \
                               Key=Company,Value=Zulu \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region us-east-2 --output text
fi

## Ohio Core Parameters ###############################################################################################
profile=$core_profile

aws ssm put-parameter --name Core-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Core-Administrator-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Core-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$ohio_core_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Core-Directory-Domain \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Core-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$ohio_core_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Core-Directory-DomainJoin-User \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Core-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$ohio_core_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Core-Directory-DomainJoin-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text


## Ohio Log Parameters ################################################################################################
profile=$log_profile

aws ssm put-parameter --name Log-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Log-Administrator-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Log-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$ohio_log_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Log-Directory-Domain \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Log-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$ohio_log_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Log-Directory-DomainJoin-User \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Log-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$ohio_log_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Log-Directory-DomainJoin-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text


## Alfa Ohio Production Parameters ####################################################################################
profile=$production_profile

aws ssm put-parameter --name Alfa-Production-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Alfa-Production-Administrator-Password \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Production \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Alfa-Production-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$alfa_ohio_production_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Alfa-Production-Directory-Domain \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Production \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Alfa-Production-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$alfa_ohio_production_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Alfa-Production-Directory-DomainJoin-User \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Production \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Alfa-Production-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$alfa_ohio_production_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Alfa-Production-Directory-DomainJoin-Password \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Production \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text


## Alfa Ohio Testing Parameters #######################################################################################
profile=$testing_profile

aws ssm put-parameter --name Alfa-Testing-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Alfa-Testing-Administrator-Password \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Testing \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Alfa-Testing-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$alfa_ohio_testing_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Alfa-Testing-Directory-Domain \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Testing \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Alfa-Testing-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$alfa_ohio_testing_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Alfa-Testing-Directory-DomainJoin-User \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Testing \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Alfa-Testing-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$alfa_ohio_testing_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Alfa-Testing-Directory-DomainJoin-Password \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Testing \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text


## Alfa Ohio Development Parameters ####################################################################################
profile=$development_profile

aws ssm put-parameter --name Alfa-Development-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Alfa-Development-Administrator-Password \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Development \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Alfa-Development-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$alfa_ohio_development_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Alfa-Development-Directory-Domain \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Development \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Alfa-Development-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$alfa_ohio_development_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Alfa-Development-Directory-DomainJoin-User \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Development \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Alfa-Development-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$alfa_ohio_development_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Alfa-Development-Directory-DomainJoin-Password \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Development \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text


## Zulu Ohio Production Parameters ####################################################################################
profile=$production_profile

aws ssm put-parameter --name Zulu-Production-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Zulu-Production-Administrator-Password \
                             Key=Company,Value=Zulu \
                             Key=Environment,Value=Production \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Zulu-Production-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$zulu_ohio_production_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Zulu-Production-Directory-Domain \
                             Key=Company,Value=Zulu \
                             Key=Environment,Value=Production \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Zulu-Production-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$zulu_ohio_production_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Zulu-Production-Directory-DomainJoin-User \
                             Key=Company,Value=Zulu \
                             Key=Environment,Value=Production \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Zulu-Production-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$zulu_ohio_production_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Zulu-Production-Directory-DomainJoin-Password \
                             Key=Company,Value=Zulu \
                             Key=Environment,Value=Production \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text


## Zulu Ohio Development Parameters ####################################################################################
profile=$development_profile

aws ssm put-parameter --name Zulu-Development-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Zulu-Development-Administrator-Password \
                             Key=Company,Value=Zulu \
                             Key=Environment,Value=Development \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Zulu-Development-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$zulu_ohio_development_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Zulu-Development-Directory-Domain \
                             Key=Company,Value=Zulu \
                             Key=Environment,Value=Development \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Zulu-Development-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$zulu_ohio_development_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Zulu-Development-Directory-DomainJoin-User \
                             Key=Company,Value=Zulu \
                             Key=Environment,Value=Development \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text

aws ssm put-parameter --name Zulu-Development-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$zulu_ohio_development_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Zulu-Development-Directory-DomainJoin-Password \
                             Key=Company,Value=Zulu \
                             Key=Environment,Value=Development \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text


## Ireland Management Parameters ######################################################################################
profile=$management_profile

aws ssm put-parameter --name Management-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Management-Administrator-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text

aws ssm put-parameter --name Management-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$ireland_management_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Management-Directory-Domain \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text

aws ssm put-parameter --name Management-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$ireland_management_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Management-Directory-DomainJoin-User \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text

aws ssm put-parameter --name Management-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$ireland_management_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Management-Directory-DomainJoin-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Management \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text

if [ $perclient_ds = 1 ]; then
  aws ssm put-parameter --name Alfa-Management-Directory-Domain \
                        --description 'Alfa Directory Domain' \
                        --value "$alfa_ireland_management_directory_domain" \
                        --type String \
                        --tags Key=Name,Value=Alfa-Management-Directory-Domain \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region eu-west-1 --output text

  aws ssm put-parameter --name Alfa-Management-Directory-DomainJoin-User \
                        --description 'User with permissions to Join Instances to the Alfa Directory Domain' \
                        --value "$alfa_ireland_management_directory_admin_user" \
                        --type String \
                        --tags Key=Name,Value=Alfa-Management-Directory-DomainJoin-User \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region eu-west-1 --output text

  aws ssm put-parameter --name Alfa-Management-Directory-DomainJoin-Password \
                        --description 'Password for User with permissions to Join Instances to the Alfa Directory Domain' \
                        --value "$alfa_ireland_management_directory_admin_password" \
                        --type SecureString \
                        --tags Key=Name,Value=Alfa-Management-Directory-DomainJoin-Password \
                               Key=Company,Value=Alfa \
                               Key=Environment,Value=Management \
                               Key=Project,Value=CaMeLz-POC-4 \
                        --profile $profile --region eu-west-1 --output text
fi

## Ireland Core Parameters ############################################################################################
profile=$core_profile

aws ssm put-parameter --name Core-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Core-Administrator-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text

aws ssm put-parameter --name Core-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$ireland_core_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Core-Directory-Domain \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text

aws ssm put-parameter --name Core-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$ireland_core_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Core-Directory-DomainJoin-User \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text

aws ssm put-parameter --name Core-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$ireland_core_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Core-Directory-DomainJoin-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Core \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text


## Ireland Log Parameters #############################################################################################
profile=$log_profile

aws ssm put-parameter --name Log-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Log-Administrator-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text

aws ssm put-parameter --name Log-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$ireland_log_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Log-Directory-Domain \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text

aws ssm put-parameter --name Log-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$ireland_log_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Log-Directory-DomainJoin-User \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text

aws ssm put-parameter --name Log-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$ireland_log_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Log-Directory-DomainJoin-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Environment,Value=Log \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text


## Alfa Ireland Recovery Parameters ###################################################################################
profile=$recovery_profile

aws ssm put-parameter --name Alfa-Recovery-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Alfa-Recovery-Administrator-Password \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Recovery \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text

aws ssm put-parameter --name Alfa-Recovery-Directory-Domain \
                      --description 'Directory Domain' \
                      --value "$alfa_ireland_recovery_directory_domain" \
                      --type String \
                      --tags Key=Name,Value=Alfa-Recovery-Directory-Domain \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Recovery \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text

aws ssm put-parameter --name Alfa-Recovery-Directory-DomainJoin-User \
                      --description 'User with permissions to Join Instances to the Directory Domain' \
                      --value "$alfa_ireland_recovery_directory_admin_user" \
                      --type String \
                      --tags Key=Name,Value=Alfa-Recovery-Directory-DomainJoin-User \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Recovery \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text

aws ssm put-parameter --name Alfa-Recovery-Directory-DomainJoin-Password \
                      --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                      --value "$alfa_ireland_recovery_directory_admin_password" \
                      --type SecureString \
                      --tags Key=Name,Value=Alfa-Recovery-Directory-DomainJoin-Password \
                             Key=Company,Value=Alfa \
                             Key=Environment,Value=Recovery \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region eu-west-1 --output text


## Alfa LosAngeles Parameters #########################################################################################
profile=$management_profile

aws ssm put-parameter --name Alfa-LosAngeles-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Alfa-LosAngeles-Administrator-Password \
                             Key=Company,Value=Alfa \
                             Key=Location,Value=LosAngeles \
                             Key=Environment,Value=Network \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text


## Alfa Miami Parameters ##############################################################################################
profile=$management_profile

aws ssm put-parameter --name Alfa-Miami-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Alfa-Miami-Administrator-Password \
                             Key=Company,Value=Alfa \
                             Key=Location,Value=Miami \
                             Key=Environment,Value=Network \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text


## Zulu Dallas Parameters #############################################################################################
profile=$management_profile

aws ssm put-parameter --name Zulu-Dallas-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=Zulu-Dallas-Administrator-Password \
                             Key=Company,Value=Zulu \
                             Key=Location,Value=Dallas \
                             Key=Environment,Value=Network \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text


## CaMeLz SantaBarbara Parameters #####################################################################################
profile=$management_profile

aws ssm put-parameter --name CaMeLz-SantaBarbara-Administrator-Password \
                      --description 'Administrator Password for Windows Instances' \
                      --value "$CAMELZ_ADMINISTRATOR_PASSWORD" \
                      --type SecureString \
                      --tags Key=Name,Value=CaMeLz-SantaBarbara-Administrator-Password \
                             Key=Company,Value=CaMeLz \
                             Key=Location,Value=SantaBarbara \
                             Key=Environment,Value=Network \
                             Key=Project,Value=CaMeLz-POC-4 \
                      --profile $profile --region us-east-2 --output text
