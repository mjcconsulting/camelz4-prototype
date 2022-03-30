# Modules:Accounts:Log Account

This module confirms the Profile and gets the Account ID in the AWS Virginia (us-east-1) Region within the
CaMeLz-Log Account.

This is a placeholder until a more comprehensive document describing what must be done here can be written.

## Dependencies

**TODO**: Determine Dependencies and list.

## Account

1. **Set Profile for Log Account**

    ```bash
    profile=$log_profile
    ```

1.  **Obtain Log Account ID**

    ```bash
    log_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                 --profile $profile --region us-east-1 --output text)
    camelz-variable log_account_id
    ```
