# Modules:Parameters:Zulu Development Account:Oregon:Zulu Development Parameters

This module creates Zulu-Development Parameters in the AWS Oregon (us-west-2) Region within the
CaMeLz-Zulu-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Zulu-Development Parameters

1. **Set Profile for Zulu-Development Account**

    ```bash
    profile=$zulu_development_profile
    ```

1. **Create Zulu-Development Instance Parameters**

    ```bash
    aws ssm put-parameter --name Zulu-Development-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$zulu_development_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Zulu-Development-Administrator-Password \
                                 Key=Company,Value=Zulu \
                                 Key=Environment,Value=Development \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text
    ```
