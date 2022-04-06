# Modules:Parameters:Build Account:Oregon:Build Parameters

This module creates Build Parameters in the AWS Oregon (us-west-2) Region within the
CaMeLz-Build Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Build Parameters

1. **Set Profile for Build Account**

    ```bash
    profile=$build_profile
    ```

1. **Create Build Instance Parameters**

    ```bash
    aws ssm put-parameter --name Build-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$build_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Build-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Build \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text
    ```
