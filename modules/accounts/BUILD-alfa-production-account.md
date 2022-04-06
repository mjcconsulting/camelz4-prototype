# Modules:Accounts:Alfa Production Account

This module confirms the Profile and gets the Account ID in the AWS Virginia (us-east-1) Region within the
Alfa-CaMeLz-Production Account.

This is a placeholder until a more comprehensive document describing what must be done here can be written.

## Dependencies

**TODO**: Determine Dependencies and list.

## Account

1. **Set Profile for Alfa-Production Account**

    ```bash
    profile=$alfa_production_profile
    ```

1.  **Obtain Alfa-Production Account ID**

    ```bash
    alfa_production_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                             --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_production_account_id
    ```
