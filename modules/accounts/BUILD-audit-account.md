# Modules:Accounts:Audit Account

This module confirms the Profile and gets the Account ID in the AWS Virginia (us-east-1) Region within the
CaMeLz-Audit Account.

This is a placeholder until a more comprehensive document describing what must be done here can be written.

## Dependencies

**TODO**: Determine Dependencies and list.

## Account

1. **Set Profile for Audit Account**

    ```bash
    profile=$audit_profile
    ```

1.  **Obtain Audit Account ID**

    ```bash
    audit_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                   --profile $profile --region us-east-1 --output text)
    camelz-variable audit_account_id
    ```
