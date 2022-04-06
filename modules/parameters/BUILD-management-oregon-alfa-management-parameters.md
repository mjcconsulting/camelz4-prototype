# Modules:Parameters:Management Account:Oregon:Alfa Management Parameters

This module creates Alfa-Management Parameters in the AWS Oregon (us-west-2) Region within the
CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Alfa-Management Parameters

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create Alfa-Management Instance Parameters**

    ```bash
    aws ssm put-parameter --name Alfa-Management-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$alfa_management_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Alfa-Management-Administrator-Password \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text
    ```

1. **Create Alfa-Management Directory Service Parameters**

    This Directory Service is meant for Instances which are associated with the Alfa Client.

    ```bash
    aws ssm put-parameter --name Alfa-Management-Directory-Domain \
                          --description 'Alfa Directory Domain' \
                          --value "$alfa_global_management_directory_domain" \
                          --type String \
                          --tags Key=Name,Value=Alfa-Management-Directory-Domain \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text

    aws ssm put-parameter --name Alfa-Management-Directory-DomainJoin-User \
                          --description 'User with permissions to Join Instances to the Alfa Directory Domain' \
                          --value "$alfa_global_management_directory_admin_user" \
                          --type String \
                          --tags Key=Name,Value=Alfa-Management-Directory-DomainJoin-User \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text

    aws ssm put-parameter --name Alfa-Management-Directory-DomainJoin-Password \
                          --description 'Password for User with permissions to Join Instances to the Alfa Directory Domain' \
                          --value "$alfa_global_management_directory_admin_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Alfa-Management-Directory-DomainJoin-Password \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text

    aws ssm put-parameter --name Alfa-Management-Directory-OhioTrust-Password \
                          --description 'Password for Trust Relationship with Alfa Ohio Management Directory Service' \
                          --value "$alfa_global_management_directory_ohio_trust_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Alfa-Management-Directory-OhioTrust-Password \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text

    aws ssm put-parameter --name Alfa-Management-Directory-OregonTrust-Password \
                          --description 'Password for Trust Relationship with Alfa Oregon Management Directory Service' \
                          --value "$alfa_global_management_directory_oregon_trust_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Alfa-Management-Directory-OregonTrust-Password \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text
    ```
