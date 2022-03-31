# Modules:Public Hosted Zones:Management Account:Global:Management Hosted Zone

This module builds the Management Public Hosted Zone in the AWS Virginia (us-east-1) Region within the
CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Management Hosted Zone

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create Management Public Hosted Zone**

    ```bash
    global_management_public_hostedzone_id=$(aws route53 create-hosted-zone --name $global_management_public_domain \
                                                                            --hosted-zone-config Comment="Public Zone for $global_management_public_domain",PrivateZone=false \
                                                                            --caller-reference $(date +%s) \
                                                                            --query 'HostedZone.Id' \
                                                                            --profile $profile --region us-east-1 --output text | cut -f3 -d /)
    camelz-variable global_management_public_hostedzone_id

    aws route53 change-tags-for-resource --resource-type hostedzone \
                                         --resource-id $global_management_public_hostedzone_id \
                                         --add-tags Key=Name,Value=Management-PublicHostedZone Key=Company,Value=CaMeLz Key=Environment,Value=Management \
                                         --profile $profile --region us-east-1 --output text
    ```

1. **Configure Root Name Servers for this Top-Level Domain**

    ```bash
    nameservers=$(aws route53 get-hosted-zone --id $global_management_public_hostedzone_id \
                                              --query 'DelegationSet.NameServers' \
                                              --profile $profile --region us-east-1 --output text)
    nameservers_list=$(for ns in $(echo $nameservers); do echo -n "Name=$ns "; done)


    aws route53domains update-domain-nameservers --domain-name $global_management_public_domain \
                                                 --nameservers $(echo $nameservers_list) --profile $profile --region us-east-1
    ```

1. **Create Check TXT Record in Public Hosted Zone and Confirm**

   Create a TXT record named `check` in the hosted zone, and then validate it is returned, to confirm the hosted zone is
   properly setup in the public DNS hierarchy.

    ```bash
    value=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 32)

    tmpfile=$CAMELZ_HOME/tmp/global-management-txt-check-$$.json
    sed -e "s/@name@/check.$global_management_public_domain/g" \
        -e "s/@value@/$value/g" \
        $CAMELZ_HOME/templates/route53-upsert-txt.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $global_management_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text

    sleep 15

    [ "$(dig +short -t TXT check.$global_management_public_domain)" = "\"$value\"" ] && echo "Check confirmed" || echo "Check failed"
    ```

1. **Create MX and SPF Records in Public Hosted Zone**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/global-management-mx-gmail-$$.json
    sed -e "s/@name@/$global_management_public_domain/g" \
        $CAMELZ_HOME/templates/route53-upsert-mx-gmail.json > $tmpfile


    aws route53 change-resource-record-sets --hosted-zone-id $global_management_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text

    tmpfile=$CAMELZ_HOME/tmp/global-management-txt-spf-$$.json
    sed -e "s/@name@/$global_management_public_domain/g" \
        -e "s/@value@/v=spf1 mx ~all/g" \
        $CAMELZ_HOME/templates/route53-upsert-txt.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $global_management_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```
