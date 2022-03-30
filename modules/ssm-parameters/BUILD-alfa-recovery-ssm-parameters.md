# Modules:SSM Parameters:Alfa Recovery Account:Global

This module builds SSM Parameters in the AWS Virginia (us-east-1) Region within the
Alfa-CaMeLz-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Roles

1. **Set Profile for Alfa-Recovery Account**

    ```bash
    profile=$alfa_recovery_profile
    ```

1. **Create Alfa-Recovery Instance SSM Parameters**

    ```bash
    aws ssm put-parameter --name Alfa-Recovery-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Alfa-Recovery-Administrator-Password \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Recovery \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
