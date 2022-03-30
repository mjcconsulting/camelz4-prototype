# Modules:SSM Parameters:Zulu Production Account:Global

This module builds SSM Parameters in the AWS Virginia (us-east-1) Region within the
Zulu-CaMeLz-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Roles

1. **Set Profile for Zulu-Production Account**

    ```bash
    profile=$zulu_production_profile
    ```

1. **Create Zulu-Production Instance SSM Parameters**

    ```bash
    aws ssm put-parameter --name Zulu-Production-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Zulu-Production-Administrator-Password \
                                 Key=Company,Value=Zulu \
                                 Key=Environment,Value=Production \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
