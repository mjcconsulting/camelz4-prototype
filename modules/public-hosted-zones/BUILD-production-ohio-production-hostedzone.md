# Modules:Public Hosted Zones:Production Account:Ohio:Production Hosted Zone

This module creates the Production Public Hosted Zone in the AWS Ohio (us-east-2) Region within the
CaMeLz-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Production Hosted Zone

1. **Set Profile for Production Account**

    ```bash
    profile=$production_profile
    ```

1. **Create Production Public Hosted Zone**

    ```bash
    ohio_production_public_hostedzone_id=$(aws route53 create-hosted-zone --name $ohio_production_public_domain \
                                                                          --hosted-zone-config Comment="Public Zone for $ohio_production_public_domain",PrivateZone=false \
                                                                          --caller-reference $(date +%s) \
                                                                          --query 'HostedZone.Id' \
                                                                          --profile $profile --region us-east-1 --output text | cut -f3 -d /)
    camelz-variable ohio_production_public_hostedzone_id

    aws route53 change-tags-for-resource --resource-type hostedzone \
                                         --resource-id $ohio_production_public_hostedzone_id \
                                         --add-tags Key=Name,Value=Production-PublicHostedZone Key=Company,Value=CaMeLz Key=Environment,Value=Production \
                                         --profile $profile --region us-east-1 --output text
    ```

1. **Get Domain Name Servers**

    ```bash
    nameservers=$(aws route53 get-hosted-zone --id $ohio_production_public_hostedzone_id \
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
    tmpfile=$CAMELZ_HOME/tmp/ohio-production-ns-$$.json
    sed -e "s/@name@/$ohio_production_public_domain/g" \
        -e "s/@ns1@/$nameservers_array[1]/g" \
        -e "s/@ns2@/$nameservers_array[2]/g" \
        -e "s/@ns3@/$nameservers_array[3]/g" \
        -e "s/@ns4@/$nameservers_array[4]/g" \
        $CAMELZ_HOME/templates/route53-upsert-ns.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $ohio_management_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```

1. **Set Profile for Production Account**

    ```bash
    profile=$production_profile
    ```

1. **Create Check TXT Record in Public Hosted Zone and Confirm**

   Create a TXT record named `check` in the hosted zone, and then validate it is returned, to confirm the hosted zone is
   properly setup in the public DNS hierarchy.

    ```bash
    value=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 32)

    tmpfile=$CAMELZ_HOME/tmp/ohio-production-txt-check-$$.json
    sed -e "s/@name@/check.$ohio_production_public_domain/g" \
        -e "s/@value@/$value/g" \
        $CAMELZ_HOME/templates/route53-upsert-txt.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $ohio_production_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text

    sleep 15

    [ "$(dig +short -t TXT check.$ohio_production_public_domain)" = "\"$value\"" ] && echo "Check confirmed" || echo "Check failed"
    ```
