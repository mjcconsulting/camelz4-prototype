# Modules:SSM Parameters:Recovery Account:Global:Recovery Parameters

This module creates Recovery Parameters in the AWS Virginia (us-east-1) Region within the
CaMeLz-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Recovery Parameters

1. **Set Profile for Recovery Account**

    ```bash
    profile=$recovery_profile
    ```

1. **Create Recovery Instance Parameters**

    ```bash
    aws ssm put-parameter --name Recovery-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$recovery_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Recovery-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Recovery \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
