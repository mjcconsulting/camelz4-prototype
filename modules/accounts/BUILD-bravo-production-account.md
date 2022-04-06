# Modules:Accounts:Bravo Production Account

This module confirms the Profile and gets the Account ID in the AWS Virginia (us-east-1) Region within the
CaMeLz-Bravo-Production Account.

This is a placeholder until a more comprehensive document describing what must be done here can be written.

## Dependencies

**TODO**: Determine Dependencies and list.

## Account

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create Bravo-Production Account**

    This code is not yet working, due to account limits, can't create the account.

    ```bash
    bravo_production_account_id=$(aws organizations create-account --email $bravo_production_account_email \
                                                                   --account-name $bravo_production_account_name \
                                                                   --iam-user-access-to-billing true \
                                                                   --tags Key=Name,Value=$bravo_production_account_name Key=Company,Value=Alfa \
                                                                   --profile $profile --region us-east-1)
    ```

    This will return a creation request id, which we'll need to poll until it shows account creation is complete.

1. **Move Bravo-Production Account to Workloads-Production OU**

    ```bash
    aws organizations move-account --account-id $bravo_production_account_id \
                                   --source-parent-id $root_id \
                                   --destination-parent-id $workloads_production_ou_id \
                                   --profile $profile --region us-east-1 --output text
    ```

1. **Re-Enroll the Workloads-Production OU into Control Tower**

    AFAIK, there is still no API for Control Tower, so at this point, we need to use the Console to re-enroll the
    OU into which we move any new Accounts, to make Control Tower Aware of them.

    **TODO**: Document the steps to make this happen.

1. **Perform Additional Manual Account Setup & Configuration Steps**

    I perform these additional steps for each new account
    - Setup an AWS-Account entry in 1Password, to store all Account-related information
    - Go through the Account Password-Recovery Process to setup an Account root password, store in 1Password.
    - Configure Account Security Questions, store in 1Password.
    - Configure MFA on the root for the Account, store OTP in 1Password.
    - Set Account Password Complexity Rules, 24 character minimum
    - Set the IAM Account Alias to camelzp-bravo
    - (Optional) Create BootstrapAdministrators Group, associate with AdminAccess ManagedPolicy
    - (Optional) Create BootstrapReaders Group, associate with ReadOnlyAccess ManagedPolicy
    - (Optional) Create bootstrapadministrator User, member of BootstrapAdministrators, set password, MFA, create access
      key, store in 1Password
    - (Optional) Create bootstrapreader User, member of BootstrapReaders, set password, MFA, create access
      key, store in 1Password
    - (Optional) Create profiles for camelzp-bravo-bootstrapadministrator and camelzp-bravo-bootstrapreader
      in ~/.aws/config, referencing credentials stored in aws-vault, add access keys to aws-vault
    - Create profiles for camelzp-bravo-administrator and camelzp-bravo-reader profiles
      in ~/.aws/config, using SSO login details (See existing entries and clone)

1. **Set Profile for Management Account**

    ```bash
    profile=$bravo_production_profile
    ```

1.  **Obtain Bravo-Production Account ID**

    You need to wait until the Account is visible and working before confirming via this step.

    ```bash
    bravo_production_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                              --profile $profile --region us-east-1 --output text)
    camelz-variable bravo_production_account_id
    ```
