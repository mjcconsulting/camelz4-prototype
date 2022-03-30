# Modules:Roles:Build Account:Global

This module builds IAM Roles in the AWS Virginia (us-east-1) Region within the CaMeLz-Build Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Roles

1. **Set Profile for Build Account**

    ```bash
    profile=$build_profile
    ```

1.  **Create ManagedInstance Role & Instance Profile**

    ```bash
    aws iam create-role --role-name ManagedInstance \
                        --description 'Role which allows an Instance to be managed by SSM, join a Domain, and write to CloudWatch' \
                        --assume-role-policy-document file://$CAMELZ_HOME/policies/Ec2AssumeRole.json \
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

    aws iam create-instance-profile --instance-profile-name ManagedInstance \
                                    --profile $profile --region us-east-1 --output text

    aws iam add-role-to-instance-profile --instance-profile-name ManagedInstance \
                                         --role-name ManagedInstance \
                                         --profile $profile --region us-east-1 --output text
    ```

1.  **Create FlowLog Role**

    ```bash
    aws iam create-role --role-name FlowLog \
                        --description 'Role which allows a VPC to write Flow Logs' \
                        --assume-role-policy-document file://$CAMELZ_HOME/policies/VpcFlowLogsAssumeRole.json \
                        --query 'Role.RoleName' \
                        --profile $profile --region us-east-1 --output text

    aws iam put-role-policy --role-name FlowLog \
                            --policy-name FlowLogPolicy \
                            --policy-document file://$CAMELZ_HOME/policies/VpcFlowLogs.json \
                            --profile $profile --region us-east-1 --output text
    ```
