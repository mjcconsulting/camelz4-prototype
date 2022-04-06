# Modules:Parameters:Alfa Recovery Account:Global:Alfa Recovery Parameters

This module creates Alfa-Recovery Parameters in the AWS Virginia (us-east-1) Region within the
CaMeLz-Alfa-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Alfa-Recovery Parameters

1. **Set Profile for Alfa-Recovery Account**

    ```bash
    profile=$alfa_recovery_profile
    ```

1. **Create Alfa-Recovery Instance Parameters**

    ```bash
    aws ssm put-parameter --name Alfa-Recovery-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$alfa_recovery_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Alfa-Recovery-Administrator-Password \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Recovery \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
