# Modules:SSM Parameters:Audit Account:Global

This module builds SSM Parameters in the AWS Virginia (us-east-1) Region within the
CaMeLz-Audit Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## SSM Parameters

1. **Set Profile for Audit Account**

    ```bash
    profile=$audit_profile
    ```

1. **Create Audit Instance SSM Parameters**

    ```bash
    aws ssm put-parameter --name Audit-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Audit-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Audit \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
