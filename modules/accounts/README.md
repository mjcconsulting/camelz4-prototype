# Modules:Accounts
This Module builds Accounts.

TODO: More description coming

Since all configuration of Control Tower, Organizations and Accounts was done by hand for the initial CaMeLz-POC-4
implementation, we need to come back and capture the manual steps (Control Tower does not have an API or CLI section) 
at a later point in time.

Now, we just need to confirm the profiles work and save the account numbers in the variables file. It's simpler to just
do all accounts in this top section instead of breaking them out, so that's what will initially be done here.

## Management Account

1. **Set Profile for Management Account**
    ```bash
    profile=$management_profile
    ```

1.  **Confirm Management Profile works and Obtain Management Account ID**
    ```bash
    management_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                        --profile $profile --region us-east-1 --output text)
    camelz-variable management_account_id
    ```

## Log Account

1. **Set Profile for Log Account**
    ```bash
    profile=$log_profile
    ```

1.  **Confirm log Profile works and Obtain Log Account ID**
    ```bash
    log_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                 --profile $profile --region us-east-1 --output text)
    camelz-variable log_account_id
    ```

## Audit Account

1. **Set Profile for Management Account**
    ```bash
    profile=$audit_profile
    ```

1.  **Confirm Audit Profile works and Obtain Audit Account ID**
    ```bash
    audit_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                   --profile $profile --region us-east-1 --output text)
    camelz-variable audit_account_id
    ```

## Network Account

1. **Set Profile for Network Account**
    ```bash
    profile=$network_profile
    ```

1.  **Confirm Network Profile works and Obtain Network Account ID**
    ```bash
    network_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                     --profile $profile --region us-east-1 --output text)
    camelz-variable network_account_id
    ```

## Core Account

1. **Set Profile for Core Account**
    ```bash
    profile=$core_profile
    ```

1.  **Confirm Core Profile works and Obtain Core Account ID**
    ```bash
    core_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                  --profile $profile --region us-east-1 --output text)
    camelz-variable core_account_id
    ```

## Build Account

1. **Set Profile for Build Account**
    ```bash
    profile=$build_profile
    ```

1.  **Confirm Build Profile works and Obtain Build Account ID**
    ```bash
    build_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                   --profile $profile --region us-east-1 --output text)
    camelz-variable build_account_id
    ```

## Production Account

1. **Set Profile for Production Account**
    ```bash
    profile=$production_profile
    ```

1.  **Confirm Production Profile works and Obtain Production Account ID**
    ```bash
    production_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                        --profile $profile --region us-east-1 --output text)
    camelz-variable production_account_id
    ```

## Recovery Account

1. **Set Profile for Recovery Account**
    ```bash
    profile=$recovery_profile
    ```

1.  **Confirm Recovery Profile works and Obtain Recovery Account ID**
    ```bash
    recovery_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                      --profile $profile --region us-east-1 --output text)
    camelz-variable recovery_account_id
    ```

## Development Account

1. **Set Profile for Development Account**
    ```bash
    profile=$development_profile
    ```

1.  **Confirm Development Profile works and Obtain Development Account ID**
    ```bash
    development_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                         --profile $profile --region us-east-1 --output text)
    camelz-variable development_account_id
    ```

## Alfa-Production Account

1. **Set Profile for Alfa-Production Account**
    ```bash
    profile=$alfa_production_profile
    ```

1.  **Confirm Alfa-Production Profile works and Obtain Afla-Production Account ID**
    ```bash
    alfa_production_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                             --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_production_account_id
    ```

## Alfa-Recovery Account

1. **Set Profile for Alfa-Recovery Account**
    ```bash
    profile=$alfa_recovery_profile
    ```

1.  **Confirm Alfa-Recovery Profile works and Obtain Alfa-Recovery Account ID**
    ```bash
    alfa_recovery_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                           --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_recovery_account_id
    ```

## Alfa-Development Account

1. **Set Profile for Alfa-Development Account**
    ```bash
    profile=$alfa_development_profile
    ```

1.  **Confirm Alfa-Development Profile works and Obtain Alfa-Development Account ID**
    ```bash
    alfa_development_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                              --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_development_account_id
    ```

## Zulu-Production Account

1. **Set Profile for Zulu-Production Account**
    ```bash
    profile=$zulu_production_profile
    ```

1.  **Confirm Zulu-Production Profile works and Obtain Zulu-Production Account ID**
    ```bash
    zulu_production_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                             --profile $profile --region us-east-1 --output text)
    camelz-variable zulu_production_account_id
    ```

## Zulu-Development Account

1. **Set Profile for Zulu-Development Account**
    ```bash
    profile=$zulu_development_profile
    ```

1.  **Confirm Zulu-Development Profile works and Obtain Zulu-Development Account ID**
    ```bash
    zulu_development_account_id=$(aws sts get-caller-identity --query 'Account' \
                                                              --profile $profile --region us-east-1 --output text)
    camelz-variable zulu_development_account_id
    ```



**DO NOT USE BELOW THIS POINT**

## Sub-Modules

1.  **[Management](./management/)**
1.  **[Audit](./audit/)**
1.  **[Network](./network/)**
1.  **[Core Services](./core/)**
1.  **[Production](./production/)**
1.  **[Testing](./testing/)**
1.  **[Development](./development/)**
1.  **[Build](./build/)**

