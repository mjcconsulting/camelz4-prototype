# Modules:SSM Parameters:Production Account:Global

This module builds SSM Parameters in the AWS Virginia (us-east-1) Region within the
CaMeLz-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## SSM Parameters

1. **Set Profile for Production Account**

    ```bash
    profile=$production_profile
    ```

1. **Create Production Instance SSM Parameters**

    ```bash
    aws ssm put-parameter --name Production-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Production-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Production \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
