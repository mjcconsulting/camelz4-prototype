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

1.  **Confirm Management Profile works and Obtain Management Account Number**
    ```bash
    management_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                             --profile $profile --region us-east-1 --output text)
    camelz-variable management_account_number
    ```

## Log Account

1. **Set Profile for Log Account**
    ```bash
    profile=$log_profile
    ```

1.  **Confirm log Profile works and Obtain Log Account Number**
    ```bash
    log_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                     --profile $profile --region us-east-1 --output text)
    camelz-variable log_account_number
    ```

## Audit Account

1. **Set Profile for Management Account**
    ```bash
    profile=$audit_profile
    ```

1.  **Confirm Audit Profile works and Obtain Audit Account Number**
    ```bash
    audit_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                       --profile $profile --region us-east-1 --output text)
    camelz-variable audit_account_number
    ```

## Network Account

1. **Set Profile for Network Account**
    ```bash
    profile=$network_profile
    ```

1.  **Confirm Network Profile works and Obtain Network Account Number**
    ```bash
    network_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                         --profile $profile --region us-east-1 --output text)
    camelz-variable network_account_number
    ```

## Core Account

1. **Set Profile for Core Account**
    ```bash
    profile=$core_profile
    ```

1.  **Confirm Core Profile works and Obtain Core Account Number**
    ```bash
    core_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                      --profile $profile --region us-east-1 --output text)
    camelz-variable core_account_number
    ```

## Build Account

1. **Set Profile for Build Account**
    ```bash
    profile=$build_profile
    ```

1.  **Confirm Build Profile works and Obtain Build Account Number**
    ```bash
    build_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                       --profile $profile --region us-east-1 --output text)
    camelz-variable build_account_number
    ```

## Production Account

1. **Set Profile for Production Account**
    ```bash
    profile=$production_profile
    ```

1.  **Confirm Production Profile works and Obtain Production Account Number**
    ```bash
    production_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                            --profile $profile --region us-east-1 --output text)
    camelz-variable production_account_number
    ```

## Recovery Account

1. **Set Profile for Recovery Account**
    ```bash
    profile=$recovery_profile
    ```

1.  **Confirm Recovery Profile works and Obtain Recovery Account Number**
    ```bash
    recovery_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                          --profile $profile --region us-east-1 --output text)
    camelz-variable recovery_account_number
    ```

## Development Account

1. **Set Profile for Development Account**
    ```bash
    profile=$development_profile
    ```

1.  **Confirm Development Profile works and Obtain Development Account Number**
    ```bash
    development_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                             --profile $profile --region us-east-1 --output text)
    camelz-variable development_account_number
    ```

## Alfa-Production Account

1. **Set Profile for Alfa-Production Account**
    ```bash
    profile=$alfa_production_profile
    ```

1.  **Confirm Alfa-Production Profile works and Obtain Afla-Production Account Number**
    ```bash
    alfa_production_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                                 --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_production_account_number
    ```

## Alfa-Recovery Account

1. **Set Profile for Alfa-Recovery Account**
    ```bash
    profile=$alfa_recovery_profile
    ```

1.  **Confirm Alfa-Recovery Profile works and Obtain Alfa-Recovery Account Number**
    ```bash
    alfa_recovery_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                               --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_recovery_account_number
    ```

## Alfa-Development Account

1. **Set Profile for Alfa-Development Account**
    ```bash
    profile=$alfa_development_profile
    ```

1.  **Confirm Alfa-Development Profile works and Obtain Alfa-Development Account Number**
    ```bash
    alfa_development_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                                  --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_development_account_number
    ```

## Zulu-Production Account

1. **Set Profile for Zulu-Production Account**
    ```bash
    profile=$zulu_production_profile
    ```

1.  **Confirm Zulu-Production Profile works and Obtain Zulu-Production Account Number**
    ```bash
    zulu_production_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                                 --profile $profile --region us-east-1 --output text)
    camelz-variable zulu_production_account_number
    ```

## Zulu-Development Account

1. **Set Profile for Zulu-Development Account**
    ```bash
    profile=$zulu_development_profile
    ```

1.  **Confirm Zulu-Development Profile works and Obtain Zulu-Development Account Number**
    ```bash
    zulu_development_account_number=$(aws sts get-caller-identity --query 'Account' \
                                                                  --profile $profile --region us-east-1 --output text)
    camelz-variable zulu_development_account_number
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

