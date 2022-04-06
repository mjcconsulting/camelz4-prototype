# Modules:Parameters:Network Account:Ohio:Network Parameters

This module creates Network Parameters in the AWS Ohio (us-east-2) Region within the
CaMeLz-Network Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Network Parameters

1. **Set Profile for Network Account**

    ```bash
    profile=$network_profile
    ```

1. **Create Network Instance Parameters**

    ```bash
    aws ssm put-parameter --name Network-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$network_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Network-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Network \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-2 --output text
    ```
