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
## Directory Service SSM Documents - PerClient Model ##################################################################
#######################################################################################################################
## Note: These could not be created sooner, as they depend on the Directories created just before this script is run ##
## Note: It's unclear if I really need to create the Seamless Domain Join Documents, as they are created             ##
##       automatically when this feature is used. But, just doing it for practice, and for reference on how.         ##
#######################################################################################################################

## Create Alfa Global Management Seamless Domain Join SSM Document ####################################################
profile=$management_profile

if ! aws ssm get-document --name awsconfig_Domain_${alfa_global_management_directory_id}_${alfa_global_management_directory_domain} \
                          --profile $profile --region us-east-1 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${alfa_global_management_directory_id}_${alfa_global_management_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/alfa-global-management-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$alfa_global_management_directory_dc_ips"
  sed -e "s/@directory_id@/$alfa_global_management_directory_id/g" \
      -e "s/@directory_domain@/$alfa_global_management_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${alfa_global_management_directory_id}_${alfa_global_management_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-1 --output text
else
  echo "SSM Document: awsconfig_Domain_${alfa_global_management_directory_id}_${alfa_global_management_directory_domain} exists, skipping"
fi


## Create Alfa Ohio Management Seamless Domain Join SSM Document ######################################################
profile=$management_profile

if ! aws ssm get-document --name awsconfig_Domain_${alfa_ohio_management_directory_id}_${alfa_ohio_management_directory_domain} \
                          --profile $profile --region us-east-2 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${alfa_ohio_management_directory_id}_${alfa_ohio_management_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/alfa-ohio-management-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$alfa_ohio_management_directory_dc_ips"
  sed -e "s/@directory_id@/$alfa_ohio_management_directory_id/g" \
      -e "s/@directory_domain@/$alfa_ohio_management_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${alfa_ohio_management_directory_id}_${alfa_ohio_management_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-2 --output text
else
  echo "SSM Document: awsconfig_Domain_${alfa_ohio_management_directory_id}_${alfa_ohio_management_directory_domain} exists, skipping"
fi


## Create Alfa Ohio Production Seamless Domain Join SSM Document ######################################################
profile=$production_profile

if ! aws ssm get-document --name awsconfig_Domain_${alfa_ohio_production_directory_id}_${alfa_ohio_production_directory_domain} \
                          --profile $profile --region us-east-2 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${alfa_ohio_production_directory_id}_${alfa_ohio_production_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/alfa-ohio-production-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$alfa_ohio_production_directory_dc_ips"
  sed -e "s/@directory_id@/$alfa_ohio_production_directory_id/g" \
      -e "s/@directory_domain@/$alfa_ohio_production_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${alfa_ohio_production_directory_id}_${alfa_ohio_production_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-2 --output text
else
  echo "SSM Document: awsconfig_Domain_${alfa_ohio_production_directory_id}_${alfa_ohio_production_directory_domain} exists, skipping"
fi


## Create Alfa Ohio Testing Seamless Domain Join SSM Document #########################################################
profile=$testing_profile

if ! aws ssm get-document --name awsconfig_Domain_${alfa_ohio_testing_directory_id}_${alfa_ohio_testing_directory_domain} \
                          --profile $profile --region us-east-2 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${alfa_ohio_testing_directory_id}_${alfa_ohio_testing_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/alfa-ohio-testing-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$alfa_ohio_testing_directory_dc_ips"
  sed -e "s/@directory_id@/$alfa_ohio_testing_directory_id/g" \
      -e "s/@directory_domain@/$alfa_ohio_testing_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${alfa_ohio_testing_directory_id}_${alfa_ohio_testing_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-2 --output text
else
  echo "SSM Document: awsconfig_Domain_${alfa_ohio_testing_directory_id}_${alfa_ohio_testing_directory_domain} exists, skipping"
fi


## Create Alfa Ohio Development Seamless Domain Join SSM Document #####################################################
profile=$development_profile

if ! aws ssm get-document --name awsconfig_Domain_${alfa_ohio_development_directory_id}_${alfa_ohio_development_directory_domain} \
                          --profile $profile --region us-east-2 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${alfa_ohio_development_directory_id}_${alfa_ohio_development_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/alfa-ohio-development-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$alfa_ohio_development_directory_dc_ips"
  sed -e "s/@directory_id@/$alfa_ohio_development_directory_id/g" \
      -e "s/@directory_domain@/$alfa_ohio_development_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${alfa_ohio_development_directory_id}_${alfa_ohio_development_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-2 --output text
else
  echo "SSM Document: awsconfig_Domain_${alfa_ohio_development_directory_id}_${alfa_ohio_development_directory_domain} exists, skipping"
fi


## Create Zulu Ohio Management Seamless Domain Join SSM Document ######################################################
profile=$management_profile

if ! aws ssm get-document --name awsconfig_Domain_${zulu_ohio_management_directory_id}_${zulu_ohio_management_directory_domain} \
                          --profile $profile --region us-east-2 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${zulu_ohio_management_directory_id}_${zulu_ohio_management_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/zulu-ohio-management-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$zulu_ohio_management_directory_dc_ips"
  sed -e "s/@directory_id@/$zulu_ohio_management_directory_id/g" \
      -e "s/@directory_domain@/$zulu_ohio_management_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${zulu_ohio_management_directory_id}_${zulu_ohio_management_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-2 --output text
else
  echo "SSM Document: awsconfig_Domain_${zulu_ohio_management_directory_id}_${zulu_ohio_management_directory_domain} exists, skipping"
fi


## Create Zulu Ohio Production Seamless Domain Join SSM Document ######################################################
profile=$production_profile

if ! aws ssm get-document --name awsconfig_Domain_${zulu_ohio_production_directory_id}_${zulu_ohio_production_directory_domain} \
                          --profile $profile --region us-east-2 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${zulu_ohio_production_directory_id}_${zulu_ohio_production_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/zulu-ohio-production-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$zulu_ohio_production_directory_dc_ips"
  sed -e "s/@directory_id@/$zulu_ohio_production_directory_id/g" \
      -e "s/@directory_domain@/$zulu_ohio_production_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${zulu_ohio_production_directory_id}_${zulu_ohio_production_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-2 --output text
else
  echo "SSM Document: awsconfig_Domain_${zulu_ohio_production_directory_id}_${zulu_ohio_production_directory_domain} exists, skipping"
fi


## Create Zulu Ohio Development Seamless Domain Join SSM Document #####################################################
profile=$development_profile

if ! aws ssm get-document --name awsconfig_Domain_${zulu_ohio_development_directory_id}_${zulu_ohio_development_directory_domain} \
                          --profile $profile --region us-east-2 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${zulu_ohio_development_directory_id}_${zulu_ohio_development_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/zulu-ohio-development-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$zulu_ohio_development_directory_dc_ips"
  sed -e "s/@directory_id@/$zulu_ohio_development_directory_id/g" \
      -e "s/@directory_domain@/$zulu_ohio_development_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${zulu_ohio_development_directory_id}_${zulu_ohio_development_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region us-east-2 --output text
else
  echo "SSM Document: awsconfig_Domain_${zulu_ohio_development_directory_id}_${zulu_ohio_development_directory_domain} exists, skipping"
fi


## Create Alfa Ireland Management Seamless Domain Join SSM Document ###################################################
profile=$management_profile

if ! aws ssm get-document --name awsconfig_Domain_${alfa_ireland_management_directory_id}_${alfa_ireland_management_directory_domain} \
                          --profile $profile --region eu-west-1 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${alfa_ireland_management_directory_id}_${alfa_ireland_management_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/alfa-ireland-management-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$alfa_ireland_management_directory_dc_ips"
  sed -e "s/@directory_id@/$alfa_ireland_management_directory_id/g" \
      -e "s/@directory_domain@/$alfa_ireland_management_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${alfa_ireland_management_directory_id}_${alfa_ireland_management_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region eu-west-1 --output text
else
  echo "SSM Document: awsconfig_Domain_${alfa_ireland_management_directory_id}_${alfa_ireland_management_directory_domain} exists, skipping"
fi


## Create Alfa Ireland Recovery Seamless Domain Join SSM Document #####################################################
profile=$recovery_profile

if ! aws ssm get-document --name awsconfig_Domain_${alfa_ireland_recovery_directory_id}_${alfa_ireland_recovery_directory_domain} \
                          --profile $profile --region eu-west-1 &> /dev/null; then
  echo "SSM Document: awsconfig_Domain_${alfa_ireland_recovery_directory_id}_${alfa_ireland_recovery_directory_domain} does not exist, creating"
  tmpfile=$tmpdir/alfa-ireland-recovery-ssm-seamlessdomainjoin-document-$$.json
  IFS=$',' read -r dc_ip1 dc_ip2 dc_ip3 dc_ip4 <<< "$alfa_ireland_recovery_directory_dc_ips"
  sed -e "s/@directory_id@/$alfa_ireland_recovery_directory_id/g" \
      -e "s/@directory_domain@/$alfa_ireland_recovery_directory_domain/g" \
      -e "s/@directory_dc_ip1@/$dc_ip1/g" \
      -e "s/@directory_dc_ip2@/$dc_ip2/g" \
      $documentsdir/CAMELZ-SeamlessDomainJoin.json > $tmpfile

  aws ssm create-document --name awsconfig_Domain_${alfa_ireland_recovery_directory_id}_${alfa_ireland_recovery_directory_domain} \
                          --content file://$tmpfile \
                          --document-type Command \
                          --query 'DocumentDescription.Status' \
                          --profile $profile --region eu-west-1 --output text
else
  echo "SSM Document: awsconfig_Domain_${alfa_ireland_recovery_directory_id}_${alfa_ireland_recovery_directory_domain} exists, skipping"
fi
