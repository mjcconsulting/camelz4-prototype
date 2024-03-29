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
## Roles ##############################################################################################################
#######################################################################################################################

## Write Policies #####################################################################################################
tmpfile1=$tmpdir/ec2-assume-role-policy-$$.json
cat > $tmpfile1 << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

tmpfile2=$tmpdir/flowlog-assume-role-policy-$$.json
cat > $tmpfile2 << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

tmpfile3=$tmpdir/flowlog-role-policy-$$.json
cat > $tmpfile3 << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*",
            "Effect": "Allow"
        }
    ]
}
EOF


## Management ManagedInstance Role ####################################################################################
#  - This is also used for the simulated client on-prem VPCs, which are created in the Management Account
profile=$management_profile

# Create ManagedInstance Role
aws iam create-role --role-name ManagedInstance \
                    --description 'Role which allows an Instance to be managed by SSM, join a Domain, and write to CloudWatch' \
                    --assume-role-policy-document file://$tmpfile1 \
                    --profile $profile --region us-east-1 --output text

aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy' \
                           --profile $profile --region us-east-1 --output text

# Create ManagedInstance InstanceProfile
aws iam create-instance-profile --instance-profile-name ManagedInstance \
                                --profile $profile --region us-east-1 --output text

aws iam add-role-to-instance-profile --instance-profile-name ManagedInstance \
                                     --role-name ManagedInstance \
                                     --profile $profile --region us-east-1 --output text


## Management FlowLog Role ############################################################################################
# Create FlowLog Role
aws iam create-role --role-name FlowLog \
                    --description 'Role which allows a VPC to write Flow Logs' \
                    --assume-role-policy-document file://$tmpfile2 \
                    --query 'Role.RoleName' \
                    --profile $profile --region us-east-1 --output text

aws iam put-role-policy --role-name FlowLog \
                        --policy-name FlowLogPolicy \
                        --policy-document file://$tmpfile3 \
                        --profile $profile --region us-east-1 --output text


## Core ManagedInstance Role ##########################################################################################
profile=$core_profile

# Create ManagedInstance Role
aws iam create-role --role-name ManagedInstance \
                    --description 'Role which allows an Instance to be managed by SSM, join a Domain, and write to CloudWatch' \
                    --assume-role-policy-document file://$tmpfile1 \
                    --profile $profile --region us-east-1 --output text

aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy' \
                           --profile $profile --region us-east-1 --output text

# Create ManagedInstance InstanceProfile
aws iam create-instance-profile --instance-profile-name ManagedInstance \
                                --profile $profile --region us-east-1 --output text

aws iam add-role-to-instance-profile --instance-profile-name ManagedInstance \
                                     --role-name ManagedInstance \
                                     --profile $profile --region us-east-1 --output text


## Core FlowLog Role ##################################################################################################
# Create FlowLog Role
aws iam create-role --role-name FlowLog \
                    --description 'Role which allows a VPC to write Flow Logs' \
                    --assume-role-policy-document file://$tmpfile2 \
                    --query 'Role.RoleName' \
                    --profile $profile --region us-east-1 --output text

aws iam put-role-policy --role-name FlowLog \
                        --policy-name FlowLogPolicy \
                        --policy-document file://$tmpfile3 \
                        --profile $profile --region us-east-1 --output text


## Log ManagedInstance Role ###########################################################################################
profile=$log_profile

# Create ManagedInstance Role
aws iam create-role --role-name ManagedInstance \
                    --description 'Role which allows an Instance to be managed by SSM, join a Domain, and write to CloudWatch' \
                    --assume-role-policy-document file://$tmpfile1 \
                    --profile $profile --region us-east-1 --output text

aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy' \
                           --profile $profile --region us-east-1 --output text

# Create ManagedInstance InstanceProfile
aws iam create-instance-profile --instance-profile-name ManagedInstance \
                                --profile $profile --region us-east-1 --output text

aws iam add-role-to-instance-profile --instance-profile-name ManagedInstance \
                                     --role-name ManagedInstance \
                                     --profile $profile --region us-east-1 --output text


## Log FlowLog Role ###################################################################################################
# Create FlowLog Role
aws iam create-role --role-name FlowLog \
                    --description 'Role which allows a VPC to write Flow Logs' \
                    --assume-role-policy-document file://$tmpfile2 \
                    --query 'Role.RoleName' \
                    --profile $profile --region us-east-1 --output text

aws iam put-role-policy --role-name FlowLog \
                        --policy-name FlowLogPolicy \
                        --policy-document file://$tmpfile3 \
                        --profile $profile --region us-east-1 --output text


## Production ManagedInstance Role ####################################################################################
profile=$production_profile

# Create ManagedInstance Role
aws iam create-role --role-name ManagedInstance \
                    --description 'Role which allows an Instance to be managed by SSM, join a Domain, and write to CloudWatch' \
                    --assume-role-policy-document file://$tmpfile1 \
                    --profile $profile --region us-east-1 --output text

aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy' \
                           --profile $profile --region us-east-1 --output text

# Create ManagedInstance InstanceProfile
aws iam create-instance-profile --instance-profile-name ManagedInstance \
                                --profile $profile --region us-east-1 --output text

aws iam add-role-to-instance-profile --instance-profile-name ManagedInstance \
                                     --role-name ManagedInstance \
                                     --profile $profile --region us-east-1 --output text


## Production FlowLog Role ############################################################################################
# Create FlowLog Role
aws iam create-role --role-name FlowLog \
                    --description 'Role which allows a VPC to write Flow Logs' \
                    --assume-role-policy-document file://$tmpfile2 \
                    --query 'Role.RoleName' \
                    --profile $profile --region us-east-1 --output text

aws iam put-role-policy --role-name FlowLog \
                        --policy-name FlowLogPolicy \
                        --policy-document file://$tmpfile3 \
                        --profile $profile --region us-east-1 --output text


## Recovery ManagedInstance Role ######################################################################################
profile=$recovery_profile

# Create ManagedInstance Role
aws iam create-role --role-name ManagedInstance \
                    --description 'Role which allows an Instance to be managed by SSM, join a Domain, and write to CloudWatch' \
                    --assume-role-policy-document file://$tmpfile1 \
                    --profile $profile --region us-east-1 --output text

aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy' \
                           --profile $profile --region us-east-1 --output text

# Create ManagedInstance InstanceProfile
aws iam create-instance-profile --instance-profile-name ManagedInstance \
                                --profile $profile --region us-east-1 --output text

aws iam add-role-to-instance-profile --instance-profile-name ManagedInstance \
                                     --role-name ManagedInstance \
                                     --profile $profile --region us-east-1 --output text


## Production FlowLog Role ############################################################################################
# Create FlowLog Role
aws iam create-role --role-name FlowLog \
                    --description 'Role which allows a VPC to write Flow Logs' \
                    --assume-role-policy-document file://$tmpfile2 \
                    --query 'Role.RoleName' \
                    --profile $profile --region us-east-1 --output text

aws iam put-role-policy --role-name FlowLog \
                        --policy-name FlowLogPolicy \
                        --policy-document file://$tmpfile3 \
                        --profile $profile --region us-east-1 --output text


## Testing ManagedInstance Role #######################################################################################
profile=$testing_profile

# Create ManagedInstance Role
aws iam create-role --role-name ManagedInstance \
                    --description 'Role which allows an Instance to be managed by SSM, join a Domain, and write to CloudWatch' \
                    --assume-role-policy-document file://$tmpfile1 \
                    --profile $profile --region us-east-1 --output text

aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy' \
                           --profile $profile --region us-east-1 --output text

# Create ManagedInstance InstanceProfile
aws iam create-instance-profile --instance-profile-name ManagedInstance \
                                --profile $profile --region us-east-1 --output text

aws iam add-role-to-instance-profile --instance-profile-name ManagedInstance \
                                     --role-name ManagedInstance \
                                     --profile $profile --region us-east-1 --output text


## Testing FlowLog Role ############################################################################################
# Create FlowLog Role
aws iam create-role --role-name FlowLog \
                    --description 'Role which allows a VPC to write Flow Logs' \
                    --assume-role-policy-document file://$tmpfile2 \
                    --query 'Role.RoleName' \
                    --profile $profile --region us-east-1 --output text

aws iam put-role-policy --role-name FlowLog \
                        --policy-name FlowLogPolicy \
                        --policy-document file://$tmpfile3 \
                        --profile $profile --region us-east-1 --output text


## Development ManagedInstance Role ###################################################################################
profile=$development_profile

# Create ManagedInstance Role
aws iam create-role --role-name ManagedInstance \
                    --description 'Role which allows an Instance to be managed by SSM, join a Domain, and write to CloudWatch' \
                    --assume-role-policy-document file://$tmpfile1 \
                    --profile $profile --region us-east-1 --output text

aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess' \
                           --profile $profile --region us-east-1 --output text
aws iam attach-role-policy --role-name ManagedInstance \
                           --policy-arn 'arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy' \
                           --profile $profile --region us-east-1 --output text

# Create ManagedInstance InstanceProfile
aws iam create-instance-profile --instance-profile-name ManagedInstance \
                                --profile $profile --region us-east-1 --output text

aws iam add-role-to-instance-profile --instance-profile-name ManagedInstance \
                                     --role-name ManagedInstance \
                                     --profile $profile --region us-east-1 --output text


## Development FlowLog Role ############################################################################################
# Create FlowLog Role
aws iam create-role --role-name FlowLog \
                    --description 'Role which allows a VPC to write Flow Logs' \
                    --assume-role-policy-document file://$tmpfile2 \
                    --query 'Role.RoleName' \
                    --profile $profile --region us-east-1 --output text

aws iam put-role-policy --role-name FlowLog \
                        --policy-name FlowLogPolicy \
                        --policy-document file://$tmpfile3 \
                        --profile $profile --region us-east-1 --output text
