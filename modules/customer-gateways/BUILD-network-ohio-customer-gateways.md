# Modules:Customer Gateways:Network Account:Ohio:Customer Gateways

This module builds the CaMeLz Customer Gateways in the AWS Ohio (us-east-2) Region within the
CaMeLz-Network Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Customer Gateways

1. **Set Profile for Network Account**

    ```bash
    profile=$network_profile
    ```

1. **Create CaMeLz-SantaBarbara Customer Gateway**

    ```bash
    ohio_network_cml_sba_cgw_id=$(aws ec2 create-customer-gateway --type ipsec.1 \
                                                                  --bgp-asn $cml_sba_cgw_asn \
                                                                  --public-ip $cml_sba_csr_instancea_public_ip \
                                                                  --tag-specifications "ResourceType=customer-gateway,Tags=[{Key=Name,Value=Network-CaMeLzSantaBarbaraCustomerGateway},{Key=Company,Value=CaMeLz},{Key=Location,Value=SantaBarbara},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                  --query 'CustomerGateway.CustomerGatewayId' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_cml_sba_cgw_id
    ```
