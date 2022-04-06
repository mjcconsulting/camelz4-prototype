# Modules:Customer Gateways:Network Account:Ohio:Alfa Customer Gateways

This module builds the Alfa Customer Gateways in the AWS Ohio (us-east-2) Region within the
CaMeLz-Network Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Alfa Customer Gateways

1. **Set Profile for Network Account**

    ```bash
    profile=$network_profile
    ```

1. **Create Alfa-LosAngeles Customer Gateway**

    ```bash
    ohio_network_alfa_lax_cgw_id=$(aws ec2 create-customer-gateway --type ipsec.1 \
                                                                   --bgp-asn $alfa_lax_cgw_asn \
                                                                   --public-ip $alfa_lax_csr_instancea_public_ip \
                                                                   --tag-specifications "ResourceType=customer-gateway,Tags=[{Key=Name,Value=Network-AlfaLosAngelesCustomerGateway},{Key=Company,Value=Alfa},{Key=Location,Value=LosAngeles},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'CustomerGateway.CustomerGatewayId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_alfa_lax_cgw_id
    ```

1. **Create Alfa-Miami Customer Gateway**

    ```bash
    ohio_network_alfa_mia_cgw_id=$(aws ec2 create-customer-gateway --type ipsec.1 \
                                                                   --bgp-asn $alfa_mia_cgw_asn \
                                                                   --public-ip $alfa_mia_csr_instancea_public_ip \
                                                                   --tag-specifications "ResourceType=customer-gateway,Tags=[{Key=Name,Value=Network-AlfaMiamiCustomerGateway},{Key=Company,Value=Alfa},{Key=Location,Value=Miami},{Key=Environment,Value=Network},{Key=Project,Value=CaMeLz-POC-4}]" \
                                                                   --query 'CustomerGateway.CustomerGatewayId' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_alfa_mia_cgw_id
    ```
