# Modules:Parameters:Management Account:Oregon:Zulu Management Parameters

This module creates Zulu-Management Parameters in the AWS Oregon (us-west-2) Region within the
CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Zulu-Management Parameters

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create Zulu-Management Instance Parameters**

    ```bash
    aws ssm put-parameter --name Zulu-Management-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$zulu_management_administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Zulu-Management-Administrator-Password \
                                 Key=Company,Value=Zulu \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text
    ```

1. **Create Zulu-Management Directory Service Parameters**

    This Directory Service is meant for Instances which are associated with the Zulu Client.

    ```bash
    aws ssm put-parameter --name Zulu-Management-Directory-Domain \
                          --description 'Zulu Directory Domain' \
                          --value "$zulu_global_management_directory_domain" \
                          --type String \
                          --tags Key=Name,Value=Zulu-Management-Directory-Domain \
                                 Key=Company,Value=Zulu \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text

    aws ssm put-parameter --name Zulu-Management-Directory-DomainJoin-User \
                          --description 'User with permissions to Join Instances to the Zulu Directory Domain' \
                          --value "$zulu_global_management_directory_admin_user" \
                          --type String \
                          --tags Key=Name,Value=Zulu-Management-Directory-DomainJoin-User \
                                 Key=Company,Value=Zulu \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text

    aws ssm put-parameter --name Zulu-Management-Directory-DomainJoin-Password \
                          --description 'Password for User with permissions to Join Instances to the Zulu Directory Domain' \
                          --value "$zulu_global_management_directory_admin_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Zulu-Management-Directory-DomainJoin-Password \
                                 Key=Company,Value=Zulu \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-west-2 --output text
    ```
