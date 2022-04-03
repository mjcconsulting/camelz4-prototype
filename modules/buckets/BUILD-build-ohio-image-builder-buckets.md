# Modules:Buckets:Build Account:Ohio:Image Builder Buckets

This module builds the Image Builder Buckets in the AWS Ohio (us-east-2) Region within the
CaMeLz-Build Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Image Builder Buckets

1. **Set Profile for Build Account**

    ```bash
    profile=$build_profile
    ```

1. **Create Image Builder Bucket**

    ```bash
    ohio_build_image_builder_bucket_name=ec2imagebuilder-$build_account_alias-us-east-2

    aws s3api create-bucket --bucket $ohio_build_image_builder_bucket_name \
                            --create-bucket-configuration LocationConstraint=us-east-2 \
                            --object-ownership BucketOwnerEnforced \
                            --profile $profile --region us-east-1 --output text
    camelz-variable ohio_build_image_builder_bucket_name

    aws s3api put-public-access-block --bucket $ohio_build_image_builder_bucket_name \
                                      --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
                                      --profile $profile --region us-east-1 --output text

    aws s3api put-bucket-encryption --bucket $ohio_build_image_builder_bucket_name \
                                    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}' \
                                    --profile $profile --region us-east-1 --output text

    tmpfile=$CAMELZ_HOME/tmp/ohio-build-image-builder-bucket-policy-$$.json
    sed -e "s/@bucketname@/$ohio_build_image_builder_bucket_name/g" \
        -e "s/@orgid@/$org_id/g" \
        $CAMELZ_HOME/policies/S3OrganizationReadBucketPolicy-Template.json > $tmpfile

    aws s3api put-bucket-policy --bucket $ohio_build_image_builder_bucket_name \
                                --policy file://$tmpfile \
                                --profile $profile --region us-east-1

    aws s3api put-bucket-tagging --bucket $ohio_build_image_builder_bucket_name \
                                 --tagging "TagSet=[{Key=Name,Value=Build-ImageBuilderBucket},{Key=Company,Value=CaMeLz},{Key=Environment,Value=Build}]" \
                                 --profile $profile --region us-east-1 --output text
    ```

1. **Upload Installers to Image Builder Bucket**

    ```bash
    aws s3api put-object -- $ohio_build_image_builder_bucket_name \
                         --key installers/
                         --body <value>
                         --profile $profile --region us-east-1 --output text
    ```

## WIP Below this point

These are the existing installers, but these are old versions, get new ones, and figure out a way to describe how to 
download, get checksum, upload into the new bucket above.

```bash
chrome_installer_url=http://installers-camelzm.s3-website-us-east-1.amazonaws.com/GoogleChromeStandaloneEnterprise64.msi
chrome_installer_sha256=82bc081286f48148dce2c81f97bdb849b38680b7bb3435221fa470adcf75aa5b

royalts_installer_url=http://installers-camelzm.s3-website-us-east-1.amazonaws.com/RoyalTSInstaller_5.02.60410.0.msi
royalts_installer_sha256=699ef4391df99f1864d53baf0ce7c637576e6fec50c5677c64e686f3a2050130
```
