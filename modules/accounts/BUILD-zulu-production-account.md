# Modules:Accounts:Zulu Production Account

This module confirms the Profile and gets the Account ID in the AWS Virginia (us-east-1) Region within the
Zulu-CaMeLz-Production Account.

This is a placeholder until a more comprehensive document describing what must be done here can be written.

## Dependencies

**TODO**: Determine Dependencies and list.

## Account

1. **Set Profile for Zulu-Production Account**

    ```bash
    profile=$zulu_production_profile
    ```

1.  **Obtain Zulu-Production Account ID**

    ```bash
    zulu_production_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                             --profile $profile --region us-east-1 --output text)
    camelz-variable zulu_production_account_id
    ```
