# Modules:Accounts:Alfa Development Account

This module confirms the Profile and gets the Account ID in the AWS Virginia (us-east-1) Region within the
Alfa-CaMeLz-Development Account.

This is a placeholder until a more comprehensive document describing what must be done here can be written.

## Dependencies

**TODO**: Determine Dependencies and list.

## Account

1. **Set Profile for Alfa-Development Account**

    ```bash
    profile=$alfa_development_profile
    ```

1.  **Obtain Alfa-Development Account ID**

    ```bash
    alfa_development_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                              --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_development_account_id
    ```
