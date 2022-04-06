# Modules:SSM Parameters:Production Account:Global:Production Parameters

This module creates Production Parameters in the AWS Virginia (us-east-1) Region within the
CaMeLz-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Production Parameters

1. **Set Profile for Production Account**

    ```bash
    profile=$production_profile
    ```

1. **Create Production Instance Parameters**

    ```bash
    aws ssm put-parameter --name Production-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$production_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Production-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Production \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
