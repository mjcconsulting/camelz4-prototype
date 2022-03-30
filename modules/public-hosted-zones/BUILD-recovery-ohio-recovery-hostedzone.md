# Modules:Public Hosted Zones:Recovery Account:Ohio:Recovery Hosted Zone

This module builds the Recovery Public Hosted Zone in the AWS Ohio (us-east-2) Region within the
CaMeLz-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Recovery Hosted Zone

1. **Set Profile for Recovery Account**

    ```bash
    profile=$recovery_profile
    ```

1. **Create Recovery Public Hosted Zone**

    ```bash
    ohio_recovery_public_hostedzone_id=$(aws route53 create-hosted-zone --name $ohio_recovery_public_domain \
                                                                        --hosted-zone-config Comment="Public Zone for $ohio_recovery_public_domain",PrivateZone=false \
                                                                        --caller-reference $(date +%s) \
                                                                        --query 'HostedZone.Id' \
                                                                        --profile $profile --region us-east-1 --output text | cut -f3 -d /)
    camelz-variable ohio_recovery_public_hostedzone_id

    aws route53 change-tags-for-resource --resource-type hostedzone \
                                         --resource-id $ohio_recovery_public_hostedzone_id \
                                         --add-tags Key=Name,Value=Recovery-PublicHostedZone Key=Company,Value=CaMeLz Key=Environment,Value=Recovery \
                                         --profile $profile --region us-east-1 --output text
    ```

1. **Get Domain Name Servers**

    ```bash
    nameservers=$(aws route53 get-hosted-zone --id $ohio_recovery_public_hostedzone_id \
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
    tmpfile=$CAMELZ_HOME/tmp/ohio-recovery-ns-$$.json
    sed -e "s/@subdomain@/$ohio_recovery_public_domain/g" \
        -e "s/@ns1@/$nameservers_array[1]/g" \
        -e "s/@ns2@/$nameservers_array[2]/g" \
        -e "s/@ns3@/$nameservers_array[3]/g" \
        -e "s/@ns4@/$nameservers_array[4]/g" \
        $CAMELZ_HOME/templates/route53-upsert-ns.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $ohio_management_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```

1. **Set Profile for Recovery Account**

    ```bash
    profile=$recovery_profile
    ```

1. **Create Check TXT Record in Public Hosted Zone and Confirm**

   Create a TXT record named `check` in the hosted zone, and then validate it is returned, to confirm the hosted zone is
   properly setup in the public DNS hierarchy.

    ```bash
    txtvalue=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 32)

    tmpfile=$CAMELZ_HOME/tmp/ohio-recovery-txt-check-$$.json
    sed -e "s/@txtname@/check.$ohio_recovery_public_domain/g" \
        -e "s/@txtvalue@/$txtvalue/g" \
        $CAMELZ_HOME/templates/route53-upsert-txt.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $ohio_recovery_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text

    sleep 10

    [ $(dig +short -t TXT check.$ohio_recovery_public_domain) = "\"$txtvalue\"" ] && echo "Check confirmed"
    ```
