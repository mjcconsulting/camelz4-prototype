# Modules:SSM Documents:Management Account:Ohio

This module builds & shares SSM Documents in the AWS Ohio (us-east-2) Region within the
CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## SSM Documents

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create & Share CaMeLz-ChangeAdministratorPassword SSM Command Document**

    ```bash
    aws ssm create-document --name CaMeLz-ChangeAdministratorPassword \
                            --content file://$CAMELZ_HOME/documents/CaMeLz-ChangeAdministratorPassword.yaml \
                            --document-type Command \
                            --document-format YAML \
                            --query 'DocumentDescription.Status' \
                            --profile $profile --region us-east-2 --output text

    aws ssm modify-document-permission --name CaMeLz-ChangeAdministratorPassword \
                                       --permission-type Share \
                                       --account-ids-to-add All \
                                       --profile $profile --region us-east-2 --output text
    ```

1. **Create & Share CaMeLz-RenameComputer SSM Command Document**

    ```bash
    aws ssm create-document --name CaMeLz-RenameComputer \
                            --content file://$CAMELZ_HOME/documents/CaMeLz-RenameComputer.yaml \
                            --document-type Command \
                            --document-format YAML \
                            --query 'DocumentDescription.Status' \
                            --profile $profile --region us-east-2 --output text

    aws ssm modify-document-permission --name CaMeLz-RenameComputer \
                                       --permission-type Share \
                                       --account-ids-to-add All \
                                       --profile $profile --region us-east-2 --output text


1. **Create & Share CaMeLz-InstallActiveDirectoryManagementTools SSM Command Document**

    ```bash
    aws ssm create-document --name CaMeLz-InstallActiveDirectoryManagementTools \
                            --content file://$CAMELZ_HOME/documents/CaMeLz-InstallActiveDirectoryManagementTools.yaml \
                            --document-type Command \
                            --document-format YAML \
                            --query 'DocumentDescription.Status' \
                            --profile $profile --region us-east-2 --output text

    aws ssm modify-document-permission --name CaMeLz-InstallActiveDirectoryManagementTools \
                                       --permission-type Share \
                                       --account-ids-to-add All \
                                       --profile $profile --region us-east-2 --output text
    ```

1. **Create & Share CaMeLz-InstallGoogleChrome SSM Command Document**

    ```bash
    aws ssm create-document --name CaMeLz-InstallGoogleChrome \
                            --content file://$CAMELZ_HOME/documents/CaMeLz-InstallGoogleChrome.yaml \
                            --document-type Command \
                            --document-format YAML \
                            --query 'DocumentDescription.Status' \
                            --profile $profile --region us-east-2 --output text

    aws ssm modify-document-permission --name CaMeLz-InstallGoogleChrome \
                                       --permission-type Share \
                                       --account-ids-to-add All \
                                       --profile $profile --region us-east-2 --output text
    ```

1. **Create & Share CaMeLz-InstallRoyalTS SSM Command Document**

    ```bash
    aws ssm create-document --name CaMeLz-InstallRoyalTS \
                            --content file://$CAMELZ_HOME/documents/CaMeLz-InstallRoyalTS.yaml \
                            --document-type Command \
                            --document-format YAML \
                            --query 'DocumentDescription.Status' \
                            --profile $profile --region us-east-2 --output text

    aws ssm modify-document-permission --name CaMeLz-InstallRoyalTS \
                                       --permission-type Share \
                                       --account-ids-to-add All \
                                       --profile $profile --region us-east-2 --output text
    ```

1. **Create & Share CaMeLz-ConfigureWindowsProfile SSM Command Document**

    ```bash
    aws ssm create-document --name CaMeLz-ConfigureWindowsProfile \
                            --content file://$CAMELZ_HOME/documents/CaMeLz-ConfigureWindowsProfile.yaml \
                            --document-type Command \
                            --document-format YAML \
                            --query 'DocumentDescription.Status' \
                            --profile $profile --region us-east-2 --output text

    aws ssm modify-document-permission --name CaMeLz-ConfigureWindowsProfile \
                                       --permission-type Share \
                                       --account-ids-to-add All \
                                       --profile $profile --region us-east-2 --output text
    ```

1. **Create & Share CaMeLz-ConfigureLinuxProfile SSM Command Document**

    ```bash
    aws ssm create-document --name CaMeLz-ConfigureLinuxProfile \
                            --content file://$CAMELZ_HOME/documents/CaMeLz-ConfigureLinuxprofile.yaml \
                            --document-type Command \
                            --document-format YAML \
                            --query 'DocumentDescription.Status' \
                            --profile $profile --region us-east-2 --output text

    aws ssm modify-document-permission --name CaMeLz-ConfigureLinuxProfile \
                                       --permission-type Share \
                                       --account-ids-to-add All \
                                       --profile $profile --region us-east-2 --output text
    ```

1. **Create & Share CaMeLz-ConfigureWindowsStartMenu SSM Command Document**

    ```bash
    aws ssm create-document --name CaMeLz-ConfigureWindowsStartMenu \
                            --content file://$CAMELZ_HOME/documents/CaMeLz-ConfigureWindowsStartMenu.yaml \
                            --document-type Command \
                            --document-format YAML \
                            --query 'DocumentDescription.Status' \
                            --profile $profile --region us-east-2 --output text

    aws ssm modify-document-permission --name CaMeLz-ConfigureWindowsStartMenu \
                                       --permission-type Share \
                                       --account-ids-to-add All \
                                       --profile $profile --region us-east-2 --output text
    ```

1. **Create & Share CaMeLz-ProvisionWindowsBastion SSM Command Document**

    ```bash
    aws ssm create-document --name CaMeLz-ProvisionWindowsBastion \
                            --content file://$CAMELZ_HOME/documents/CaMeLz-ProvisionWindowsBastion.yaml \
                            --document-type Command \
                            --document-format YAML \
                            --query 'DocumentDescription.Status' \
                            --profile $profile --region us-east-2 --output text

    aws ssm modify-document-permission --name CaMeLz-ProvisionWindowsBastion \
                                       --permission-type Share \
                                       --account-ids-to-add All \
                                       --profile $profile --region us-east-2 --output text
    ```

1. **Create & Share CaMeLz-ProvisionActiveDirectoryManagement SSM Command Document**

    ```bash
    aws ssm create-document --name CaMeLz-ProvisionActiveDirectoryManagement \
                            --content file://$CAMELZ_HOME/documents/CaMeLz-ProvisionActiveDirectoryManagement.yaml \
                            --document-type Command \
                            --document-format YAML \
                            --query 'DocumentDescription.Status' \
                            --profile $profile --region us-east-2 --output text

    aws ssm modify-document-permission --name CaMeLz-ProvisionActiveDirectoryManagement \
                                       --permission-type Share \
                                       --account-ids-to-add All \
                                       --profile $profile --region us-east-2 --output text
    ```