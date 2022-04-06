# Modules:Parameters:Alfa Development Account:Oregon:Alfa Development Parameters

This module creates Alfa-Development Parameters in the AWS Oregon (us-west-2) Region within the
CaMeLz-Alfa-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Alfa-Development Parameters

1. **Set Profile for Alfa-Development Account**

    ```bash
    profile=$alfa_development_profile
    ```

1. **Create Alfa-Development Instance Parameters**

    ```bash
    aws ssm put-parameter --name Alfa-Development-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$alfa_development_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Alfa-Development-Administrator-Password \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Development \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text
    ```
