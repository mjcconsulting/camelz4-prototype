# Modules:SSM Parameters:Alfa Development Account:Global:Alfa Testing Parameters

This module creates Alfa-Testing Parameters in the AWS Virginia (us-east-1) Region within the
Alfa-CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Alfa-Testing Parameters

1. **Set Profile for Alfa-Development Account**

    ```bash
    profile=$alfa_development_profile
    ```

1. **Create Alfa-Testing Instance Parameters**

    ```bash
    aws ssm put-parameter --name Alfa-Testing-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$alfa_testing_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Alfa-Testing-Administrator-Password \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Testing \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
