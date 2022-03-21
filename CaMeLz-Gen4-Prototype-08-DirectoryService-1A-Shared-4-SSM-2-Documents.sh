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
## Directory Service SSM Documents - OneGlobal (Shared) Model #########################################################
#######################################################################################################################
## Note: These could not be created sooner, as they depend on the Directories created just before this script is run ##
## Note: It's unclear if I really need to create the Seamless Domain Join Documents, as they are created             ##
##       automatically when this feature is used. But, just doing it for practice, and for reference on how.         ##
#######################################################################################################################

## Create Global Management Seamless Domain Join SSM Document #########################################################
profile=$management_profile

if ! aws ssm get-document --name awsconfig_Domain_${global_management_directory_id}_${global_management_directory_domain} \
                          --profile $profile --region us-east-1 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${global_management_directory_id}_${global_management_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/global-management-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$global_management_directory_dc_ips"
  sed -e "s/@directory_id@/$global_management_directory_id/g" \
      -e "s/@directory_domain@/$global_management_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${global_management_directory_id}_${global_management_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-1 --output text
else
  echo "SSM Document: awsconfig_Domain_${global_management_directory_id}_${global_management_directory_domain} exists, skipping"
fi


## Create Global Core Seamless Domain Join SSM Document ###############################################################
profile=$core_profile

if ! aws ssm get-document --name awsconfig_Domain_${global_core_directory_id}_${global_core_directory_domain} \
                          --profile $profile --region us-east-1 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${global_core_directory_id}_${global_core_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/global-core-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$global_core_directory_dc_ips"
  sed -e "s/@directory_id@/$global_core_directory_id/g" \
      -e "s/@directory_domain@/$global_core_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${global_core_directory_id}_${global_core_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-1 --output text
else
  echo "SSM Document: awsconfig_Domain_${global_core_directory_id}_${global_core_directory_domain} exists, skipping"
fi


## Create Global Log Seamless Domain Join SSM Document ################################################################
profile=$log_profile

if ! aws ssm get-document --name awsconfig_Domain_${global_log_directory_id}_${global_log_directory_domain} \
                          --profile $profile --region us-east-1 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${global_log_directory_id}_${global_log_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/global-log-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$global_log_directory_dc_ips"
  sed -e "s/@directory_id@/$global_log_directory_id/g" \
      -e "s/@directory_domain@/$global_log_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${global_log_directory_id}_${global_log_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-1 --output text
else
  echo "SSM Document: awsconfig_Domain_${global_log_directory_id}_${global_log_directory_domain} exists, skipping"
fi


## Create Ohio Management Seamless Domain Join SSM Document ###########################################################
profile=$management_profile

if ! aws ssm get-document --name awsconfig_Domain_${ohio_management_directory_id}_${ohio_management_directory_domain} \
                          --profile $profile --region us-east-2 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${ohio_management_directory_id}_${ohio_management_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/ohio-management-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ohio_management_directory_dc_ips"
  sed -e "s/@directory_id@/$ohio_management_directory_id/g" \
      -e "s/@directory_domain@/$ohio_management_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${ohio_management_directory_id}_${ohio_management_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-2 --output text
else
  echo "SSM Document: awsconfig_Domain_${ohio_management_directory_id}_${ohio_management_directory_domain} exists, skipping"
fi


## Create Ohio Core Seamless Domain Join SSM Document #################################################################
profile=$core_profile

if ! aws ssm get-document --name awsconfig_Domain_${ohio_core_directory_id}_${ohio_core_directory_domain} \
                          --profile $profile --region us-east-2 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${ohio_core_directory_id}_${ohio_core_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/ohio-core-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ohio_core_directory_dc_ips"
  sed -e "s/@directory_id@/$ohio_core_directory_id/g" \
      -e "s/@directory_domain@/$ohio_core_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${ohio_core_directory_id}_${ohio_core_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-2 --output text
else
  echo "SSM Document: awsconfig_Domain_${ohio_core_directory_id}_${ohio_core_directory_domain} exists, skipping"
fi


## Create Ohio Log Seamless Domain Join SSM Document ##################################################################
profile=$log_profile

if ! aws ssm get-document --name awsconfig_Domain_${ohio_log_directory_id}_${ohio_log_directory_domain} \
                          --profile $profile --region us-east-2 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${ohio_log_directory_id}_${ohio_log_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/ohio-log-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ohio_log_directory_dc_ips"
  sed -e "s/@directory_id@/$ohio_log_directory_id/g" \
      -e "s/@directory_domain@/$ohio_log_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${ohio_log_directory_id}_${ohio_log_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-2 --output text
else
  echo "SSM Document: awsconfig_Domain_${ohio_log_directory_id}_${ohio_log_directory_domain} exists, skipping"
fi


## Create Ohio Production Seamless Domain Join SSM Document ###########################################################
profile=$production_profile

if ! aws ssm get-document --name awsconfig_Domain_${ohio_production_directory_id}_${ohio_production_directory_domain} \
                          --profile $profile --region us-east-2 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${ohio_production_directory_id}_${ohio_production_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/ohio-production-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ohio_production_directory_dc_ips"
  sed -e "s/@directory_id@/$ohio_production_directory_id/g" \
      -e "s/@directory_domain@/$ohio_production_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${ohio_production_directory_id}_${ohio_production_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-2 --output text
else
  echo "SSM Document: awsconfig_Domain_${ohio_production_directory_id}_${ohio_production_directory_domain} exists, skipping"
fi


## Create Ohio Testing Seamless Domain Join SSM Document ##############################################################
profile=$testing_profile

if ! aws ssm get-document --name awsconfig_Domain_${ohio_testing_directory_id}_${ohio_testing_directory_domain} \
                          --profile $profile --region us-east-2 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${ohio_testing_directory_id}_${ohio_testing_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/ohio-testing-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ohio_testing_directory_dc_ips"
  sed -e "s/@directory_id@/$ohio_testing_directory_id/g" \
      -e "s/@directory_domain@/$ohio_testing_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${ohio_testing_directory_id}_${ohio_testing_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-2 --output text
else
  echo "SSM Document: awsconfig_Domain_${ohio_testing_directory_id}_${ohio_testing_directory_domain} exists, skipping"
fi


## Create Ohio Development Seamless Domain Join SSM Document ##########################################################
profile=$development_profile

if ! aws ssm get-document --name awsconfig_Domain_${ohio_development_directory_id}_${ohio_development_directory_domain} \
                          --profile $profile --region us-east-2 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${ohio_development_directory_id}_${ohio_development_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/ohio-development-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ohio_development_directory_dc_ips"
  sed -e "s/@directory_id@/$ohio_development_directory_id/g" \
      -e "s/@directory_domain@/$ohio_development_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${ohio_development_directory_id}_${ohio_development_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-2 --output text
else
  echo "SSM Document: awsconfig_Domain_${ohio_development_directory_id}_${ohio_development_directory_domain} exists, skipping"
fi


## Create Ireland Management Seamless Domain Join SSM Document ########################################################
profile=$management_profile

if ! aws ssm get-document --name awsconfig_Domain_${ireland_management_directory_id}_${ireland_management_directory_domain} \
                          --profile $profile --region eu-west-1 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${ireland_management_directory_id}_${ireland_management_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/ireland-management-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ireland_management_directory_dc_ips"
  sed -e "s/@directory_id@/$ireland_management_directory_id/g" \
      -e "s/@directory_domain@/$ireland_management_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${ireland_management_directory_id}_${ireland_management_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region eu-west-1 --output text
else
  echo "SSM Document: awsconfig_Domain_${ireland_management_directory_id}_${ireland_management_directory_domain} exists, skipping"
fi


## Create Ireland Core Seamless Domain Join SSM Document ##############################################################
profile=$core_profile

if ! aws ssm get-document --name awsconfig_Domain_${ireland_core_directory_id}_${ireland_core_directory_domain} \
                          --profile $profile --region eu-west-1 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${ireland_core_directory_id}_${ireland_core_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/ireland-core-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ireland_core_directory_dc_ips"
  sed -e "s/@directory_id@/$ireland_core_directory_id/g" \
      -e "s/@directory_domain@/$ireland_core_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${ireland_core_directory_id}_${ireland_core_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region eu-west-1 --output text
else
  echo "SSM Document: awsconfig_Domain_${ireland_core_directory_id}_${ireland_core_directory_domain} exists, skipping"
fi


## Create Ireland Log Seamless Domain Join SSM Document ###############################################################
profile=$log_profile

if ! aws ssm get-document --name awsconfig_Domain_${ireland_log_directory_id}_${ireland_log_directory_domain} \
                          --profile $profile --region eu-west-1 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${ireland_log_directory_id}_${ireland_log_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/ireland-log-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ireland_log_directory_dc_ips"
  sed -e "s/@directory_id@/$ireland_log_directory_id/g" \
      -e "s/@directory_domain@/$ireland_log_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${ireland_log_directory_id}_${ireland_log_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region eu-west-1 --output text
else
  echo "SSM Document: awsconfig_Domain_${ireland_log_directory_id}_${ireland_log_directory_domain} exists, skipping"
fi


## Create Ireland Production Seamless Domain Join SSM Document ########################################################
profile=$production_profile

if ! aws ssm get-document --name awsconfig_Domain_${ireland_production_directory_id}_${ireland_production_directory_domain} \
                          --profile $profile --region eu-west-1 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${ireland_production_directory_id}_${ireland_production_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/ireland-production-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ireland_production_directory_dc_ips"
  sed -e "s/@directory_id@/$ireland_production_directory_id/g" \
      -e "s/@directory_domain@/$ireland_production_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${ireland_production_directory_id}_${ireland_production_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region eu-west-1 --output text
else
  echo "SSM Document: awsconfig_Domain_${ireland_production_directory_id}_${ireland_production_directory_domain} exists, skipping"
fi


## Create Ireland Recovery Seamless Domain Join SSM Document ##########################################################
profile=$recovery_profile

if ! aws ssm get-document --name awsconfig_Domain_${ireland_recovery_directory_id}_${ireland_recovery_directory_domain} \
                          --profile $profile --region eu-west-1 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${ireland_recovery_directory_id}_${ireland_recovery_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/ireland-recovery-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ireland_recovery_directory_dc_ips"
  sed -e "s/@directory_id@/$ireland_recovery_directory_id/g" \
      -e "s/@directory_domain@/$ireland_recovery_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${ireland_recovery_directory_id}_${ireland_recovery_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region eu-west-1 --output text
else
  echo "SSM Document: awsconfig_Domain_${ireland_recovery_directory_id}_${ireland_recovery_directory_domain} exists, skipping"
fi


## Create Ireland Development Seamless Domain Join SSM Document #######################################################
profile=$development_profile

if ! aws ssm get-document --name awsconfig_Domain_${ireland_development_directory_id}_${ireland_development_directory_domain} \
                          --profile $profile --region eu-west-1 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${ireland_development_directory_id}_${ireland_development_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/ireland-development-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$ireland_development_directory_dc_ips"
  sed -e "s/@directory_id@/$ireland_development_directory_id/g" \
      -e "s/@directory_domain@/$ireland_development_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${ireland_development_directory_id}_${ireland_development_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region eu-west-1 --output text
else
  echo "SSM Document: awsconfig_Domain_${ireland_development_directory_id}_${ireland_development_directory_domain} exists, skipping"
fi
