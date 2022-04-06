# Modules:Customer Gateways:Network Account:Ohio:Zulu Customer Gateways

This module builds the Zulu Customer Gateways in the AWS Ohio (us-east-2) Region within the
CaMeLz-Network Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Zulu Customer Gateways

1. **Set Profile for Network Account**

    ```bash
    profile=$network_profile
    ```

1. **Create Zulu-Dallas Customer Gateway**

    ```bash
    ohio_network_zulu_dfw_cgw_id=$(aws ec2 create-customer-gateway --type ipsec.1 \
                                                                   --bgp-asn $zulu_dfw_cgw_asn \
                                                                   --public-ip $zulu_dfw_csr_instancea_public_ip \
                                                                   --tag-specifications "ResourceType=customer-gateway,Tags=[{Key=Name,Value=Network-ZuluDallasCustomerGateway},{Key=Company,Value=Zulu},{Key=Location,Value=Dallas},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'CustomerGateway.CustomerGatewayId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_zulu_dfw_cgw_id
    ```
