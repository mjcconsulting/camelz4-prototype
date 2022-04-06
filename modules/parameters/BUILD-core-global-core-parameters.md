# Modules:SSM Parameters:Core Account:Global:Core Parameters

This module creates Core Parameters in the AWS Virginia (us-east-1) Region within the
CaMeLz-Core Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Core Parameters

1. **Set Profile for Core Account**

    ```bash
    profile=$core_profile
    ```

1. **Create Core Instance Parameters**

    ```bash
    aws ssm put-parameter --name Core-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$core_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Core-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Core \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
