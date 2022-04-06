# Modules:Parameters:Management Account:Ohio:Management Parameters

This module creates Management Parameters in the AWS Ohio (us-east-2) Region within the
CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Management Parameters

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create Management Instance Parameters**

    ```bash
    aws ssm put-parameter --name Management-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$management_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Management-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-2 --output text
    ```

1. **Create Management Directory Service Parameters**

    This Directory Service is meant for Instances which are associated with the CaMeLz Organization, not specific to
    clients.

    ```bash
    aws ssm put-parameter --name Management-Directory-Domain \
                          --description 'Directory Domain' \
                          --value "$global_management_directory_domain" \
                          --type String \
                          --tags Key=Name,Value=Management-Directory-Domain \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-2 --output text

    aws ssm put-parameter --name Management-Directory-DomainJoin-User \
                          --description 'User with permissions to Join Instances to the Directory Domain' \
                          --value "$global_management_directory_admin_user" \
                          --type String \
                          --tags Key=Name,Value=Management-Directory-DomainJoin-User \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-2 --output text

    aws ssm put-parameter --name Management-Directory-DomainJoin-Password \
                          --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                          --value "$global_management_directory_admin_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Management-Directory-DomainJoin-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-2 --output text

    aws ssm put-parameter --name Management-Directory-OhioTrust-Password \
                          --description 'Password for Trust Relationship with Ohio Management Directory Service' \
                          --value "$global_management_directory_ohio_trust_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Management-Directory-OhioTrust-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-2 --output text

    aws ssm put-parameter --name Management-Directory-OregonTrust-Password \
                          --description 'Password for Trust Relationship with Oregon Management Directory Service' \
                          --value "$global_management_directory_oregon_trust_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Management-Directory-OregonTrust-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-2 --output text
    ```
