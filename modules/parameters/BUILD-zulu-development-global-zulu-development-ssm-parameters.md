# Modules:SSM Parameters:Zulu Development Account:Global

This module builds SSM Parameters in the AWS Virginia (us-east-1) Region within the
Zulu-CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## SSM Parameters

1. **Set Profile for Zulu-Development Account**

    ```bash
    profile=$zulu_development_profile
    ```

1. **Create Zulu-Development Instance SSM Parameters**

    ```bash
    aws ssm put-parameter --name Zulu-Development-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Zulu-Development-Administrator-Password \
                                 Key=Company,Value=Zulu \
                                 Key=Environment,Value=Development \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
