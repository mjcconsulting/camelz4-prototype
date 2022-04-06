# Modules:Parameters:Audit Account:Ohio:Audit Parameters

This module creates Audit Parameters in the AWS Ohio (us-east-2) Region within the
CaMeLz-Audit Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Audit Parameters

1. **Set Profile for Audit Account**

    ```bash
    profile=$audit_profile
    ```

1. **Create Audit Instance Parameters**

    ```bash
    aws ssm put-parameter --name Audit-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$audit_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Audit-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Audit \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-2 --output text
    ```
