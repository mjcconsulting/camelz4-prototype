# Modules:SSM Parameters:MCrawford Sandbox Account:Global

This module builds SSM Parameters in the AWS Virginia (us-east-1) Region within the
MCrawford-CaMeLz Sandbox Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Roles

1. **Set Profile for MCrawford-Sandbox Account**

    ```bash
    profile=$mcrawford_sandbox_profile
    ```

1. **Create MCrawford-Sandbox Instance SSM Parameters**

    ```bash
    aws ssm put-parameter --name MCrawford-Sandbox-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=MCrawford-Sandbox-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Sandbox \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```
