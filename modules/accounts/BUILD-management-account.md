# Modules:Accounts:Management Account

This module confirms the Profile and gets the Account ID in the AWS Virginia (us-east-1) Region within the
CaMeLz-Management Account.

This is a placeholder until a more comprehensive document describing what must be done here can be written.

## Dependencies

**TODO**: Determine Dependencies and list.

## Account

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1.  **Obtain Management Account ID**

    ```bash
    management_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                        --profile $profile --region us-east-1 --output text)
    camelz-variable management_account_id
    ```
