# Modules:SSM Associations:Management Account:Ohio:Management Associations

This module creates Management Associations based on Tags in the AWS Ohio (us-east-2) Region within the
CaMeLz-Management Account.

Some Associations reference Application Software Installers which are assumed to have been uploaded to the
installers-camelzm S3 bucket in a prior build step.

**CAUTION**: Do not run this yet. This section has not been tested, so it may have unknown interactions with explicit
installation of the same applications done via cloud-init.

## Dependencies

**TODO**: Determine Dependencies and list.

## Management Associations

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create SystemAssociationForSsmAgentUpdate Association**

    ```bash
    if [ -z $(aws ssm list-associations --association-filter-list key=AssociationName,value=SystemAssociationForSsmAgentUpdate \
                                        --query 'Associations[?Name==`AWS-UpdateSSMAgent`].Name' \
                                        --profile $profile --region us-east-2 --output text) ]; then
      echo "Association: SystemAssociationForSsmAgentUpdate does not exist, creating"
      aws ssm create-association --association-name SystemAssociationForSsmAgentUpdate \
                                 --name AWS-UpdateSSMAgent \
                                 --targets Key=InstanceIds,Values=* \
                                 --schedule-expression "rate(14 days)" \
                                 --query 'AssociationDescription.Overview.DetailedStatus' \
                                 --profile $profile --region us-east-2 --output text
    else
      echo "Association: SystemAssociationForSsmAgentUpdate exists, skipping"
    fi
    ```

1. **Create SystemAssociationForLinuxProfile Association**

    ```bash
    if [ -z $(aws ssm list-associations --association-filter-list key=AssociationName,value=SystemAssociationForLinuxProfile \
                                        --query 'Associations[?Name==`CaMeLz-ConfigureLinuxProfile`].Name' \
                                        --profile $profile --region us-east-2 --output text) ]; then
      echo "Association: SystemAssociationForLinuxProfile does not exist, creating"
      aws ssm create-association --association-name SystemAssociationForLinuxProfile \
                                 --name CaMeLz-ConfigureLinuxProfile \
                                 --targets Key=tag:Project,Values=CaMeLz-POC-4 \
                                 --schedule-expression "rate(3 days)" \
                                 --query 'AssociationDescription.Overview.DetailedStatus' \
                                 --profile $profile --region us-east-2 --output text
    else
      echo "Association: SystemAssociationForLinuxProfile exists, skipping"
    fi
    ```

1. **Create SystemAssociationForWindowsGoogleChrome Association**

    ```bash
    if [ -z $(aws ssm list-associations --association-filter-list key=AssociationName,value=SystemAssociationForWindowsGoogleChrome \
                                        --query 'Associations[?Name==`AWS-InstallApplication`].Name' \
                                        --profile $profile --region us-east-2 --output text) ]; then
      echo "Association: SystemAssociationForWindowsGoogleChrome does not exist, creating"
      aws ssm create-association --association-name SystemAssociationForWindowsGoogleChrome \
                                 --name AWS-InstallApplication \
                                 --parameters source=$chrome_installer_url,sourceHash=$chrome_installer_sha256 \
                                 --targets Key=tag:Project,Values=CaMeLz-POC-4 \
                                 --query 'AssociationDescription.Overview.DetailedStatus' \
                                 --profile $profile --region us-east-2 --output text
    else
      echo "Association: SystemAssociationForWindowsGoogleChrome exists, skipping"
    fi
    ```

1. **Create WindowsBastionsAssociationForRoyalTS Association**

    ```bash
    if [ -z $(aws ssm list-associations --association-filter-list key=AssociationName,value=WindowsBastionsAssociationForRoyalTS \
                                        --query 'Associations[?Name==`AWS-InstallApplication`].Name' \
                                        --profile $profile --region us-east-2 --output text) ]; then
      echo "Association: WindowsBastionsAssociationForRoyalTS does not exist, creating"
      aws ssm create-association --association-name WindowsBastionsAssociationForRoyalTS \
                                 --name AWS-InstallApplication \
                                 --parameters source=$royalts_installer_url,sourceHash=$royalts_installer_sha256 \
                                 --targets Key=tag:Project,Values=CaMeLz-POC-4 Key=tag:Utility,Values=WindowsBastion \
                                 --query 'AssociationDescription.Overview.DetailedStatus' \
                                 --profile $profile --region us-east-2 --output text
    else
      echo "Association: WindowsBastionsAssociationForRoyalTS exists, skipping"
    fi
    ```

1. **Create WindowsBastionAssociationForWindowsStartMenu Association**

    ```bash
    if [ -z $(aws ssm list-associations --association-filter-list key=AssociationName,value=WindowsBastionAssociationForWindowsStartMenu \
                                        --query 'Associations[?Name==`CaMeLz-ConfigureWindowsStartMenu`].Name' \
                                        --profile $profile --region us-east-2 --output text) ]; then
      echo "Association: WindowsBastionAssociationForWindowsStartMenu does not exist, creating"
      aws ssm create-association --association-name SystemAssociationForWindowsStartMenu \
                                 --name CaMeLz-ConfigureWindowsStartMenu \
                                 --parameters action=Install,source=$royalts_installer_url,sourceHash=$royalts_installer_sha256,parameters="\quiet" \
                                 --targets Key=tag:Project,Values=CaMeLz-POC-4 Key=tag:Utility,Values=WindowsBastion \
                                 --query 'AssociationDescription.Overview.DetailedStatus' \
                                 --profile $profile --region us-east-2 --output text
    else
      echo "Association: WindowsBastionAssociationForWindowsStartMenu exists, skipping"
    fi
    ```
