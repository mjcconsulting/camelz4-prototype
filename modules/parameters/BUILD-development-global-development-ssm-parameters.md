# Modules:SSM Parameters:Development Account:Global

This module builds SSM Parameters in the AWS Virginia (us-east-1) Region within the
CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## SSM Parameters

1. **Set Profile for Development Account**

    ```bash
    profile=$development_profile
    ```

1. **Create Development Instance SSM Parameters**

    ```bash
    aws ssm put-parameter --name Development-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Development-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Development \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
