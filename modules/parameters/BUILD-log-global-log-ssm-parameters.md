# Modules:SSM Parameters:Log Account:Global

This module builds SSM Parameters in the AWS Virginia (us-east-1) Region within the
CaMeLz-Log Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## SSM Parameters

1. **Set Profile for Log Account**

    ```bash
    profile=$log_profile
    ```

1. **Create Log Instance SSM Parameters**

    ```bash
    aws ssm put-parameter --name Log-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Log-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Log \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
