# Modules:Public Hosted Zones:Build Account:Global:Build Hosted Zone

This module builds the Build Public Hosted Zone in the AWS Virginia (us-east-1) Region within the
CaMeLz-Build Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Build Hosted Zone

1. **Set Profile for Build Account**

    ```bash
    profile=$build_profile
    ```

1. **Create Build Public Hosted Zone**

    ```bash
    global_build_public_hostedzone_id=$(aws route53 create-hosted-zone --name $global_build_public_domain \
                                                                       --hosted-zone-config Comment="Public Zone for $global_build_public_domain",PrivateZone=false \
                                                                       --caller-reference $(date +%s) \
                                                                       --query 'HostedZone.Id' \
                                                                       --profile $profile --region us-east-1 --output text | cut -f3 -d /)
    camelz-variable global_build_public_hostedzone_id

    aws route53 change-tags-for-resource --resource-type hostedzone \
                                         --resource-id $global_build_public_hostedzone_id \
                                         --add-tags Key=Name,Value=Build-PublicHostedZone Key=Company,Value=CaMeLz Key=Environment,Value=Build \
                                         --profile $profile --region us-east-1 --output text
    ```

1. **Get Domain Name Servers**

    ```bash
    nameservers=$(aws route53 get-hosted-zone --id $global_build_public_hostedzone_id \
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
    tmpfile=$CAMELZ_HOME/tmp/global-build-ns-$$.sh
    sed -e "s/@subdomain@/$global_build_public_domain/g" \
        -e "s/@ns1@/$nameservers_array[1]/g" \
        -e "s/@ns2@/$nameservers_array[2]/g" \
        -e "s/@ns3@/$nameservers_array[3]/g" \
        -e "s/@ns4@/$nameservers_array[4]/g" \
        $CAMELZ_HOME/templates/route53-upsert-ns.json > $tmpfile

    aws route53 change-resource-record-sets --hosted-zone-id $global_management_public_hostedzone_id \
                                            --change-batch file://$tmpfile \
                                            --profile $profile --region us-east-1 --output text
    ```
