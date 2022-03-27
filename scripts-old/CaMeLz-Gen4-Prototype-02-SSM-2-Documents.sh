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
## Baseline SSM Documents #############################################################################################
#######################################################################################################################

## Global Management CAMELZ-ChangeAdministratorPassword SSM Command Document ############################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ChangeAdministratorPassword \
                        --content file://$documentsdir/CAMELZ-ChangeAdministratorPassword.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ChangeAdministratorPassword \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-1 --output text


## Global Management CAMELZ-RenameComputer SSM Command Document #########################################################
profile=$management_profile

# Create SSM Command Document
aws ssm create-document --name CAMELZ-RenameComputer \
                        --content file://$documentsdir/CAMELZ-RenameComputer.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-RenameComputer \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-1 --output text


## Global Management CAMELZ-InstallActiveDirectoryManagementTools SSM Command Document ##################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-InstallActiveDirectoryManagementTools \
                        --content file://$documentsdir/CAMELZ-InstallActiveDirectoryManagementTools.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-InstallActiveDirectoryManagementTools \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-1 --output text


## Global Management CAMELZ-InstallGoogleChrome SSM Command Document ####################################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-InstallGoogleChrome \
                        --content file://$documentsdir/CAMELZ-InstallGoogleChrome.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-InstallGoogleChrome \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-1 --output text


## Global Management CAMELZ-InstallRoyalTS SSM Command Document #########################################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-InstallRoyalTS \
                        --content file://$documentsdir/CAMELZ-InstallRoyalTS.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-InstallRoyalTS \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-1 --output text


## Global Management CAMELZ-ConfigureWindowsProfile SSM Command Document ################################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ConfigureWindowsProfile \
                        --content file://$documentsdir/CAMELZ-ConfigureWindowsProfile.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ConfigureWindowsProfile \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-1 --output text


## Global Management CAMELZ-ConfigureLinuxProfile SSM Command Document ##################################################
profile=$management_profile

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ConfigureLinuxProfile \
                        --content file://$documentsdir/CAMELZ-ConfigureLinuxprofile.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ConfigureLinuxProfile \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-1 --output text


## Global Management CAMELZ-ConfigureWindowsStartMenu SSM Command Document ##############################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ConfigureWindowsStartMenu \
                        --content file://$documentsdir/CAMELZ-ConfigureWindowsStartMenu.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ConfigureWindowsStartMenu \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-1 --output text


## Global Management CAMELZ-ProvisionWindowsBastion SSM Command Document ################################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ProvisionWindowsBastion \
                        --content file://$documentsdir/CAMELZ-ProvisionWindowsBastion.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ProvisionWindowsBastion \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-1 --output text


## Global Management CAMELZ-ProvisionActiveDirectoryManagement SSM Command Document #####################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ProvisionActiveDirectoryManagement \
                        --content file://$documentsdir/CAMELZ-ProvisionActiveDirectoryManagement.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ProvisionActiveDirectoryManagement \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-1 --output text


## Ohio Management CAMELZ-ChangeAdministratorPassword SSM Command Document ##############################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ChangeAdministratorPassword \
                        --content file://$documentsdir/CAMELZ-ChangeAdministratorPassword.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-2 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ChangeAdministratorPassword \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-2 --output text


## Ohio Management CAMELZ-RenameComputer SSM Command Document ###########################################################
profile=$management_profile

# Create SSM Command Document
aws ssm create-document --name CAMELZ-RenameComputer \
                        --content file://$documentsdir/CAMELZ-RenameComputer.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-2 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-RenameComputer \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-2 --output text


## Ohio Management CAMELZ-InstallActiveDirectoryManagementTools SSM Command Document ####################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-InstallActiveDirectoryManagementTools \
                        --content file://$documentsdir/CAMELZ-InstallActiveDirectoryManagementTools.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-2 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-InstallActiveDirectoryManagementTools \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-2 --output text


## Ohio Management CAMELZ-InstallGoogleChrome SSM Command Document ######################################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-InstallGoogleChrome \
                        --content file://$documentsdir/CAMELZ-InstallGoogleChrome.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-2 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-InstallGoogleChrome \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-2 --output text


## Ohio Management CAMELZ-InstallRoyalTS SSM Command Document ###########################################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-InstallRoyalTS \
                        --content file://$documentsdir/CAMELZ-InstallRoyalTS.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-2 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-InstallRoyalTS \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-2 --output text


## Ohio Management CAMELZ-ConfigureWindowsProfile SSM Command Document ##################################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ConfigureWindowsProfile \
                        --content file://$documentsdir/CAMELZ-ConfigureWindowsProfile.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-2 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ConfigureWindowsProfile \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-2 --output text


## Ohio Management CAMELZ-ConfigureLinuxProfile SSM Command Document ####################################################
profile=$management_profile

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ConfigureLinuxProfile \
                        --content file://$documentsdir/CAMELZ-ConfigureLinuxprofile.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-2 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ConfigureLinuxProfile \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-2 --output text


## Ohio Management CAMELZ-ConfigureWindowsStartMenu SSM Command Document ################################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ConfigureWindowsStartMenu \
                        --content file://$documentsdir/CAMELZ-ConfigureWindowsStartMenu.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-2 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ConfigureWindowsStartMenu \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-2 --output text


## Ohio Management CAMELZ-ProvisionWindowsBastion SSM Command Document ##################################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ProvisionWindowsBastion \
                        --content file://$documentsdir/CAMELZ-ProvisionWindowsBastion.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-2 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ProvisionWindowsBastion \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-2 --output text


## Ohio Management CAMELZ-ProvisionActiveDirectoryManagement SSM Command Document #######################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ProvisionActiveDirectoryManagement \
                        --content file://$documentsdir/CAMELZ-ProvisionActiveDirectoryManagement.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region us-east-2 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ProvisionActiveDirectoryManagement \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region us-east-2 --output text


## Ireland Management CAMELZ-ChangeAdministratorPassword SSM Command Document ###########################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ChangeAdministratorPassword \
                        --content file://$documentsdir/CAMELZ-ChangeAdministratorPassword.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region eu-west-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ChangeAdministratorPassword \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region eu-west-1 --output text


## Ireland Management CAMELZ-RenameComputer SSM Command Document ########################################################
profile=$management_profile

# Create SSM Command Document
aws ssm create-document --name CAMELZ-RenameComputer \
                        --content file://$documentsdir/CAMELZ-RenameComputer.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region eu-west-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-RenameComputer \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region eu-west-1 --output text


## Ireland Management CAMELZ-InstallActiveDirectoryManagementTools SSM Command Document #################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-InstallActiveDirectoryManagementTools \
                        --content file://$documentsdir/CAMELZ-InstallActiveDirectoryManagementTools.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region eu-west-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-InstallActiveDirectoryManagementTools \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region eu-west-1 --output text


## Ireland Management CAMELZ-InstallGoogleChrome SSM Command Document ###################################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-InstallGoogleChrome \
                        --content file://$documentsdir/CAMELZ-InstallGoogleChrome.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region eu-west-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-InstallGoogleChrome \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region eu-west-1 --output text


## Ireland Management CAMELZ-InstallRoyalTS SSM Command Document ########################################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-InstallRoyalTS \
                        --content file://$documentsdir/CAMELZ-InstallRoyalTS.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region eu-west-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-InstallRoyalTS \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region eu-west-1 --output text


## Ireland Management CAMELZ-ConfigureWindowsProfile SSM Command Document ###############################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ConfigureWindowsProfile \
                        --content file://$documentsdir/CAMELZ-ConfigureWindowsProfile.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region eu-west-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ConfigureWindowsProfile \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region eu-west-1 --output text


## Ireland Management CAMELZ-ConfigureLinuxProfile SSM Command Document #################################################
profile=$management_profile

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ConfigureLinuxProfile \
                        --content file://$documentsdir/CAMELZ-ConfigureLinuxprofile.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region eu-west-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ConfigureLinuxProfile \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region eu-west-1 --output text


## Ireland Management CAMELZ-ConfigureWindowsStartMenu SSM Command Document #############################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ConfigureWindowsStartMenu \
                        --content file://$documentsdir/CAMELZ-ConfigureWindowsStartMenu.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region eu-west-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ConfigureWindowsStartMenu \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region eu-west-1 --output text


## Ireland Management CAMELZ-ProvisionWindowsBastion SSM Command Document ###############################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ProvisionWindowsBastion \
                        --content file://$documentsdir/CAMELZ-ProvisionWindowsBastion.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region eu-west-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ProvisionWindowsBastion \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region eu-west-1 --output text


## Ireland Management CAMELZ-ProvisionActiveDirectoryManagement SSM Command Document ####################################

# Create SSM Command Document
aws ssm create-document --name CAMELZ-ProvisionActiveDirectoryManagement \
                        --content file://$documentsdir/CAMELZ-ProvisionActiveDirectoryManagement.yaml \
                        --document-type Command \
                        --document-format YAML \
                        --query 'DocumentDescription.Status' \
                        --profile $profile --region eu-west-1 --output text

# Share SSM Command Document
aws ssm modify-document-permission --name CAMELZ-ProvisionActiveDirectoryManagement \
                                   --permission-type Share \
                                   --account-ids-to-add $core_account_id $log_account_id $production_account_id $recovery_account_id $testing_account_id $development_account_id \
                                   --profile $profile --region eu-west-1 --output text
