# Modules:Accounts:MCrawford Sandbox Account

This module confirms the Profile and gets the Account ID in the AWS Virginia (us-east-1) Region within the
MCrawford-CaMeLz-Sandbox Account.

This is a placeholder until a more comprehensive document describing what must be done here can be written.

## Dependencies

**TODO**: Determine Dependencies and list.

## Account

1. **Set Profile for MCrawford-Sandbox Account**

    ```bash
    profile=$mcrawford_sandbox_profile
    ```

1.  **Obtain MCrawford-Sandbox Account ID**

    ```bash
    mcrawford_sandbox_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                               --profile $profile --region us-east-1 --output text)
    camelz-variable mcrawford_sandbox_account_id
    ```
