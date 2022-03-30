# Modules:SSM Parameters:Recovery Account:Global

This module builds SSM Parameters in the AWS Virginia (us-east-1) Region within the
CaMeLz-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Roles

1. **Set Profile for Recovery Account**

    ```bash
    profile=$recovery_profile
    ```

1. **Create Recovery Instance SSM Parameters**

    ```bash
    aws ssm put-parameter --name Recovery-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Recovery-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Recovery \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
