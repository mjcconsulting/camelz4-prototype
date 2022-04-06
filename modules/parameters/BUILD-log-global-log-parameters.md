# Modules:SSM Parameters:Log Account:Global:Log Parameters

This module creates Log Parameters in the AWS Virginia (us-east-1) Region within the
CaMeLz-Log Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Log Parameters

1. **Set Profile for Log Account**

    ```bash
    profile=$log_profile
    ```

1. **Create Log Instance Parameters**

    ```bash
    aws ssm put-parameter --name Log-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$log_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Log-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Log \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
