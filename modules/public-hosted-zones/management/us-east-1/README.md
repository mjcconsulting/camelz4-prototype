# Modules:Public-Hosted-Zones:Management:Global

This module builds Route 53 Public Hosted Zones in the AWS Virginia (us-east-1) Region within the CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Management Public Hosted Zones

1. **Set Profile for Management Account**
    ```bash
    profile=$management_profile
    ```

1.  **Create Public Hosted Zone**
    ```bash
    global_management_public_hostedzone_id=$(aws route53 create-hosted-zone --name $global_management_public_domain \
                                                                            --hosted-zone-config Comment="Public Zone for $global_management_public_domain",PrivateZone=false \
                                                                            --caller-reference $(date +%s) \
                                                                            --query 'HostedZone.Id' \
                                                                            --profile $profile --region us-east-1 --output text | cut -f3 -d /)
    camelz-state global_management_public_hostedzone_id

    aws route53 change-tags-for-resource --resource-type hostedzone \
                                         --resource-id $global_management_public_hostedzone_id \
                                         --add-tags Key=Name,Value=Management-PublicHostedZone Key=Company,Value=CaMeLz Key=Environment,Value=Management \
                                         --profile $profile --region us-east-1 --output text
    ```

1.  **Configure Root Name Servers for this Top-Level Domain**
    ```bash
    nameservers=$(aws route53 get-hosted-zone --id $global_management_public_hostedzone_id \
                                              --query 'DelegationSet.NameServers' \
                                              --profile $profile --region us-east-1 --output text)
    nameservers_list=$(for ns in $(echo $nameservers); do echo -n "Name=$ns "; done)


    aws route53domains update-domain-nameservers --domain-name $global_management_public_domain \
                                                 --nameservers $nameservers_list --profile $profile --region us-east-1
    ```