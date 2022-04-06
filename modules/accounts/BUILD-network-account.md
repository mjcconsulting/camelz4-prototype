# Modules:Accounts:Network Account

This module confirms the Profile and gets the Account ID in the AWS Virginia (us-east-1) Region within the
CaMeLz-Network Account.

This is a placeholder until a more comprehensive document describing what must be done here can be written.

## Dependencies

**TODO**: Determine Dependencies and list.

## Account

1. **Set Profile for Network Account**

    ```bash
    profile=$network_profile
    ```

1.  **Obtain Network Account ID**

    ```bash
    network_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                     --profile $profile --region us-east-1 --output text)
    camelz-variable network_account_id
    ```
