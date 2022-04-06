# Modules:Key Pairs:Network Account

This module imports Key Pairs in the AWS Virginia (us-east-1), AWS Ohio (us-east-2) & AWS Oregon (us-west-2) Regions
within the CaMeLz-Network Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Network Key Pairs

1. **Set Profile for Network Account**

    ```bash
    profile=$network_profile
    ```

1. **Create Key Pairs**

    ```bash
    regions=(us-east-1 us-east-2 us-west-2)
    keypairs=(bootstrap bootstrapadministrator bootstrapuser administrator developer manager user demo example mcrawford)

    for region in $regions; do
      echo "- Region: $region"
      for keypair in $keypairs; do
        echo "  - KeyPair: $keypair"
        aws ec2 import-key-pair --key-name $keypair \
                                --public-key-material fileb://$CAMELZ_HOME/keys/camelz_${keypair}_id_rsa.pub \
                                --profile $profile --region $region --output text | sed 's/.*/    - &/'
      done
    done
    ```

1. **Confirm Key Pairs**

    ```bash
    regions=(us-east-1 us-east-2 us-west-2)

    for region in $regions; do
      echo "- Region: $region"
        aws ec2 describe-key-pairs --query "KeyPairs[].[KeyFingerprint,KeyName]" \
                                   --profile $profile --region $region --output text | sed 's/.*/  - &/'
    done
    ```
