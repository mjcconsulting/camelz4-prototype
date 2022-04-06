# Modules:Parameters:Zulu Production Account:Oregon:Zulu Production Parameters

This module creates Zulu-Production Parameters in the AWS Oregon (us-west-2) Region within the
CaMeLz-Zulu-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Zulu-Production Parameters

1. **Set Profile for Zulu-Production Account**

    ```bash
    profile=$zulu_production_profile
    ```

1. **Create Zulu-Production Instance Parameters**

    ```bash
    aws ssm put-parameter --name Zulu-Production-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$zulu_production_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Zulu-Production-Administrator-Password \
                                 Key=Company,Value=Zulu \
                                 Key=Environment,Value=Production \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text
    ```
