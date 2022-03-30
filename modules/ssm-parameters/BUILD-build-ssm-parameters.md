# Modules:SSM Parameters:Build Account:Global

This module builds SSM Parameters in the AWS Virginia (us-east-1) Region within the
CaMeLz-Build Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Roles

1. **Set Profile for Build Account**

    ```bash
    profile=$build_profile
    ```

1. **Create Build Instance SSM Parameters**

    ```bash
    aws ssm put-parameter --name Build-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Build-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Build \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
