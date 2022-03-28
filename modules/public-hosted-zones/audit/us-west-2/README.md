# Modules:Public-Hosted-Zones:Audit:Oregon

This module builds Route 53 Public Hosted Zones in the AWS Oregon (us-west-2) Region within the CaMeLz-Audit Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Audit Public Hosted Zones

1. **Set Profile for Audit Account**
    ```bash
    profile=$audit_profile
    ```

1.  **Create Public Hosted Zone**
    ```bash
    oregon_audit_public_hostedzone_id=$(aws route53 create-hosted-zone --name $oregon_audit_public_domain \
                                                                       --hosted-zone-config Comment="Public Zone for $oregon_audit_public_domain",PrivateZone=false \
                                                                       --caller-reference $(date +%s) \
                                                                       --query 'HostedZone.Id' \
                                                                       --profile $profile --region us-east-1 --output text | cut -f3 -d /)
    camelz-variable oregon_audit_public_hostedzone_id

    aws route53 change-tags-for-resource --resource-type hostedzone \
                                         --resource-id $oregon_audit_public_hostedzone_id \
                                         --add-tags Key=Name,Value=Audit-PublicHostedZone Key=Company,Value=CaMeLz Key=Environment,Value=Audit \
                                         --profile $profile --region us-east-1 --output text
    ```

1.  **Get Domain Name Servers**
    ```bash
    nameservers=$(aws route53 get-hosted-zone --id $oregon_audit_public_hostedzone_id \
                                              --query 'DelegationSet.NameServers' \
                                              --profile $profile --region us-east-1 --output text)
    nameservers_array=($(echo $nameservers | tr "\t" "\n"))
    ```


1. **Set Profile for Management Account**
    ```bash
    profile=$management_profile
    ```

1.  **Configure Sub-Domain Name Servers in the Parent Hosted Zone**
    ```bash
    tmpfile=$CAMELZ_HOME/tmp/oregon-audit-ns-$$.sh
    sed -e "s/@subdomain@/$oregon_audit_public_domain/g" \
        -e "s/@ns1@/$nameservers_array[1]/g" \
        -e "s/@ns2@/$nameservers_array[2]/g" \
        -e "s/@ns3@/$nameservers_array[3]/g" \
        -e "s/@ns4@/$nameservers_array[4]/g" \
        $CAMELZ_HOME/templates/route53-upsert-ns.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $oregon_management_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```