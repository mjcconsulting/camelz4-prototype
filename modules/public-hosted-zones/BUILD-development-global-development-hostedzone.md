# Modules:Public Hosted Zones:Development Account:Global:Development Hosted Zone

This module creates the Development Public Hosted Zone in the AWS Virginia (us-east-1) Region within the
CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Development Hosted Zone

1. **Set Profile for Development Account**

    ```bash
    profile=$development_profile
    ```

1. **Create Development Public Hosted Zone**

    ```bash
    global_development_public_hostedzone_id=$(aws route53 create-hosted-zone --name $global_development_public_domain \
                                                                             --hosted-zone-config Comment="Public Zone for $global_development_public_domain",PrivateZone=false \
                                                                             --caller-reference $(date +%s) \
                                                                             --query 'HostedZone.Id' \
                                                                             --profile $profile --region us-east-1 --output text | cut -f3 -d /)
    camelz-variable global_development_public_hostedzone_id

    aws route53 change-tags-for-resource --resource-type hostedzone \
                                         --resource-id $global_development_public_hostedzone_id \
                                         --add-tags Key=Name,Value=Development-PublicHostedZone Key=Company,Value=CaMeLz Key=Environment,Value=Development \
                                         --profile $profile --region us-east-1 --output text
    ```

1. **Get Domain Name Servers**

    ```bash
    nameservers=$(aws route53 get-hosted-zone --id $global_development_public_hostedzone_id \
                                              --query 'DelegationSet.NameServers' \
                                              --profile $profile --region us-east-1 --output text)
    nameservers_array=($(echo $nameservers | tr "\t" "\n"))
    ```

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Configure Sub-Domain Name Servers in the Parent Hosted Zone**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/global-development-ns-$$.json
    sed -e "s/@name@/$global_development_public_domain/g" \
        -e "s/@ns1@/$nameservers_array[1]/g" \
        -e "s/@ns2@/$nameservers_array[2]/g" \
        -e "s/@ns3@/$nameservers_array[3]/g" \
        -e "s/@ns4@/$nameservers_array[4]/g" \
        $CAMELZ_HOME/templates/route53-upsert-ns.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $global_management_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```

1. **Set Profile for Development Account**

    ```bash
    profile=$development_profile
    ```

1. **Create Check TXT Record in Public Hosted Zone and Confirm**

   Create a TXT record named `check` in the hosted zone, and then validate it is returned, to confirm the hosted zone is
   properly setup in the public DNS hierarchy.

    ```bash
    value=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 32)

    tmpfile=$CAMELZ_HOME/tmp/global-development-txt-check-$$.json
    sed -e "s/@name@/check.$global_development_public_domain/g" \
        -e "s/@value@/$value/g" \
        $CAMELZ_HOME/templates/route53-upsert-txt.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $global_development_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text

    sleep 15

    [ "$(dig +short -t TXT check.$global_development_public_domain)" = "\"$value\"" ] && echo "Check confirmed" || echo "Check failed"
    ```
