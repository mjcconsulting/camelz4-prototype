# Modules:SSM Parameters:Network Account:Global

This module builds SSM Parameters in the AWS Virginia (us-east-1) Region within the
CaMeLz-Network Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Roles

1. **Set Profile for Network Account**

    ```bash
    profile=$network_profile
    ```

1. **Create Network Instance SSM Parameters**

    ```bash
    aws ssm put-parameter --name Network-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Network-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Network \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
