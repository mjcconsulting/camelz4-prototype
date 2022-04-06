# Modules:Parameters:Development Account:Oregon:Testing Parameters

This module creates Testing Parameters in the AWS Oregon (us-west-2) Region within the
CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Testing Parameters

1. **Set Profile for Development Account**

    ```bash
    profile=$development_profile
    ```

1. **Create Testing Instance Parameters**

    ```bash
    aws ssm put-parameter --name Testing-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$testing_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Testing-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Testing \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text
    ```
