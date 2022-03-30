# Modules:Accounts:Zulu Development Account

This module confirms the Profile and gets the Account ID in the AWS Virginia (us-east-1) Region within the
Zulu-CaMeLz-Development Account.

This is a placeholder until a more comprehensive document describing what must be done here can be written.

## Dependencies

**TODO**: Determine Dependencies and list.

## Account

1. **Set Profile for Zulu-Development Account**

    ```bash
    profile=$zulu_development_profile
    ```

1.  **Obtain Zulu-Development Account ID**

    ```bash
    zulu_development_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                              --profile $profile --region us-east-1 --output text)
    camelz-variable zulu_development_account_id
    ```
