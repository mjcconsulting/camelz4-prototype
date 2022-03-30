# Modules:SSM Parameters:Management Account:Global

This module builds SSM Parameters in the AWS Virginia (us-east-1) Region within the
CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Roles

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create Management Instance SSM Parameters**

    ```bash
    aws ssm put-parameter --name Management-Administrator-Password \
                          --description 'Administrator Password for Windows Instances' \
                          --value "$administrator_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Management-Administrator-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```

1. **Create Management CaMeLz Directory Service SSM Parameters**

    This Directory Service is meant for Instances which are associated with the CaMeLz Organization, not specific to 
    a client such as Alfa or Zulu.

    ```bash
    aws ssm put-parameter --name Management-Directory-Domain \
                          --description 'Directory Domain' \
                          --value "$global_management_directory_domain" \
                          --type String \
                          --tags Key=Name,Value=Management-Directory-Domain \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text

    aws ssm put-parameter --name Management-Directory-DomainJoin-User \
                          --description 'User with permissions to Join Instances to the Directory Domain' \
                          --value "$global_management_directory_admin_user" \
                          --type String \
                          --tags Key=Name,Value=Management-Directory-DomainJoin-User \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text

    aws ssm put-parameter --name Management-Directory-DomainJoin-Password \
                          --description 'Password for User with permissions to Join Instances to the Directory Domain' \
                          --value "$global_management_directory_admin_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Management-Directory-DomainJoin-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text

    aws ssm put-parameter --name Management-Directory-OhioTrust-Password \
                          --description 'Password for Trust Relationship with Ohio Management Directory Service' \
                          --value "$global_management_directory_ohio_trust_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Management-Directory-OhioTrust-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text

    aws ssm put-parameter --name Management-Directory-OregonTrust-Password \
                          --description 'Password for Trust Relationship with Oregon Management Directory Service' \
                          --value "$global_management_directory_oregon_trust_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Management-Directory-OregonTrust-Password \
                                 Key=Company,Value=CaMeLz \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```

1. **Create Management Alfa Directory Service SSM Parameters**

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
                          --profile $profile --region us-east-1 --output text

    aws ssm put-parameter --name Alfa-Management-Directory-DomainJoin-User \
                          --description 'User with permissions to Join Instances to the Alfa Directory Domain' \
                          --value "$alfa_global_management_directory_admin_user" \
                          --type String \
                          --tags Key=Name,Value=Alfa-Management-Directory-DomainJoin-User \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text

    aws ssm put-parameter --name Alfa-Management-Directory-DomainJoin-Password \
                          --description 'Password for User with permissions to Join Instances to the Alfa Directory Domain' \
                          --value "$alfa_global_management_directory_admin_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Alfa-Management-Directory-DomainJoin-Password \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text

    aws ssm put-parameter --name Alfa-Management-Directory-OhioTrust-Password \
                          --description 'Password for Trust Relationship with Alfa Ohio Management Directory Service' \
                          --value "$alfa_global_management_directory_ohio_trust_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Alfa-Management-Directory-OhioTrust-Password \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text

    aws ssm put-parameter --name Alfa-Management-Directory-OregonTrust-Password \
                          --description 'Password for Trust Relationship with Alfa Oregon Management Directory Service' \
                          --value "$alfa_global_management_directory_oregon_trust_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Alfa-Management-Directory-OregonTrust-Password \
                                 Key=Company,Value=Alfa \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```

1. **Create Management Alfa Directory Service SSM Parameters**

    This Directory Service is meant for Instances which are associated with the Alfa Client.

    ```bash
    aws ssm put-parameter --name Zulu-Management-Directory-Domain \
                          --description 'Zulu Directory Domain' \
                          --value "$zulu_global_management_directory_domain" \
                          --type String \
                          --tags Key=Name,Value=Zulu-Management-Directory-Domain \
                                 Key=Company,Value=Zulu \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text

    aws ssm put-parameter --name Zulu-Management-Directory-DomainJoin-User \
                          --description 'User with permissions to Join Instances to the Zulu Directory Domain' \
                          --value "$zulu_global_management_directory_admin_user" \
                          --type String \
                          --tags Key=Name,Value=Zulu-Management-Directory-DomainJoin-User \
                                 Key=Company,Value=Zulu \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text

    aws ssm put-parameter --name Zulu-Management-Directory-DomainJoin-Password \
                          --description 'Password for User with permissions to Join Instances to the Zulu Directory Domain' \
                          --value "$zulu_global_management_directory_admin_password" \
                          --type SecureString \
                          --tags Key=Name,Value=Zulu-Management-Directory-DomainJoin-Password \
                                 Key=Company,Value=Zulu \
                                 Key=Environment,Value=Management \
                                 Key=Project,Value=CaMeLz-POC-4 \
                          --profile $profile --region us-east-1 --output text
    ```