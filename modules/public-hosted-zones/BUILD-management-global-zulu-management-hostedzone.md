# Modules:Public Hosted Zones:Management Account:Global:Zulu Management Hosted Zone

This module builds the Zulu-Management Public Hosted Zone in the AWS Virginia (us-east-1) Region within the
CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Zulu-Management Hosted Zone

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create Zulu-Management Public Hosted Zone**

    ```bash
    zulu_global_management_public_hostedzone_id=$(aws route53 create-hosted-zone --name $zulu_global_management_public_domain \
                                                                                 --hosted-zone-config Comment="Public Zone for $zulu_global_management_public_domain",PrivateZone=false \
                                                                                 --caller-reference $(date +%s) \
                                                                                 --query 'HostedZone.Id' \
                                                                                 --profile $profile --region us-east-1 --output text | cut -f3 -d /)
    camelz-variable zulu_global_management_public_hostedzone_id

    aws route53 change-tags-for-resource --resource-type hostedzone \
                                         --resource-id $zulu_global_management_public_hostedzone_id \
                                         --add-tags Key=Name,Value=Zulu-Management-PublicHostedZone Key=Company,Value=Zulu Key=Environment,Value=Management \
                                         --profile $profile --region us-east-1 --output text
    ```

1. **Get Domain Name Servers**

    ```bash
    nameservers=$(aws route53 get-hosted-zone --id $zulu_global_management_public_hostedzone_id \
                                              --query 'DelegationSet.NameServers' \
                                              --profile $profile --region us-east-1 --output text)
    nameservers_array=($(echo $nameservers | tr "\t" "\n"))
    ```

1. **Configure Sub-Domain Name Servers in the Parent Hosted Zone**

    ```bash
    tmpfile=$CAMELZ_HOME/tmp/zulu-global-management-ns-$$.json
    sed -e "s/@subdomain@/$zulu_global_management_public_domain/g" \
        -e "s/@ns1@/$nameservers_array[1]/g" \
        -e "s/@ns2@/$nameservers_array[2]/g" \
        -e "s/@ns3@/$nameservers_array[3]/g" \
        -e "s/@ns4@/$nameservers_array[4]/g" \
        $CAMELZ_HOME/templates/route53-upsert-ns.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $global_management_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```

1. **Create Check TXT Record in Public Hosted Zone and Confirm**

   Create a TXT record named `check` in the hosted zone, and then validate it is returned, to confirm the hosted zone is
   properly setup in the public DNS hierarchy.

    ```bash
    txtvalue=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 32)

    tmpfile=$CAMELZ_HOME/tmp/zulu-global-management-txt-check-$$.json
    sed -e "s/@txtname@/check.$zulu_global_management_public_domain/g" \
        -e "s/@txtvalue@/$txtvalue/g" \
        $CAMELZ_HOME/templates/route53-upsert-txt.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $zulu_global_management_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text

    sleep 10

    [ $(dig +short -t TXT check.$zulu_global_management_public_domain) = "\"$txtvalue\"" ] && echo "Check confirmed"
    ```
