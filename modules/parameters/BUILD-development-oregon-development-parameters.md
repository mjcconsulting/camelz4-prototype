# Modules:Parameters:Development Account:Oregon:Development Parameters

This module creates Development Parameters in the AWS Oregon (us-west-2) Region within the
CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Development Parameters

1. **Set Profile for Development Account**

    ```bash
    profile=$development_profile
    ```

1. **Create Development Instance Parameters**

    ```bash
    aws ssm put-parameter --name Development-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$development_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Development-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Development \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text
    ```
