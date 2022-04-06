# Modules:Parameters:Alfa Production Account:Ohio:Alfa Production Parameters

This module creates Alfa-Production Parameters in the AWS Ohio (us-east-2) Region within the
CaMeLz-Alfa-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Alfa-Production Parameters

1. **Set Profile for Alfa-Production Account**

    ```bash
    profile=$alfa_production_profile
    ```

1. **Create Alfa-Production Instance Parameters**

    ```bash
    aws ssm put-parameter --name Alfa-Production-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$alfa_production_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Alfa-Production-Administrator-Password \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Production \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-2 --output text
    ```
