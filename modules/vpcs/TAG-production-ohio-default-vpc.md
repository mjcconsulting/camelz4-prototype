# Modules:VPCs:Production Account:Ohio:Default VPC

This module tags the Default-VPC in the AWS Ohio (us-east-2) Region within the CaMeLz-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Production Account - Default-VPC

1. **Set Profile for Production Account**

    ```bash
    profile=$production_profile
    ```

1.  **Tag Default-VPC Resources**

    We tag the Default-VPC resources so that they appear with a similar naming convention in list displays, and it's
    easy to differentiate them from CaMeLz-POC-4 Resources.

    ```bash
    # Tag Default-VPC
    ohio_default_vpc_id=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true \
                                                --query 'Vpcs[0].VpcId' \
                                                --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $ohio_default_vpc_id \
                        --tags Key=Name,Value=Default-VPC \
                               Key=Company,Value=Default \
                               Key=Environment,Value=Default \
                               Key=Project,Value=Default \
                        --profile $profile --region us-east-2 --output text

    # Tag Default-Subnets
    ohio_default_default_subnet_tuples=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$ohio_default_vpc_id \
                                                                  --query 'Subnets[].[SubnetId,AvailabilityZone]' \
                                                                  --profile $profile --region=us-east-2 --output text \
                                         | tr '\t' ',' | tr '\n' ' ')

    for tuple in $(echo $ohio_default_default_subnet_tuples); do
        subnet_id=${tuple%,*}
        az=${tuple#*,}; az=${az: -1}; az=$(echo $az | tr '[:lower:]' '[:upper:]')
        aws ec2 create-tags --resources $subnet_id \
                            --tags Key=Name,Value=Default-DefaultSubnet$az \
                                   Key=Company,Value=Default \
                                   Key=Environment,Value=Default \
                                   Key=Project,Value=Default\
                            --profile $profile --region us-east-2 --output text
    done

    # Tag Default-MainRouteTable
    ohio_default_main_rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$ohio_default_vpc_id \
                                                                       Name=association.main,Values=true \
                                                             --query 'RouteTables[0].RouteTableId' \
                                                             --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $ohio_default_main_rtb_id \
                        --tags Key=Name,Value=Default-MainRouteTable \
                               Key=Company,Value=Default \
                               Key=Environment,Value=Default \
                               Key=Project,Value=Default\
                        --profile $profile --region us-east-2 --output text

    # Tag Default-InternetGateway
    ohio_default_igw_id=$(aws ec2 describe-internet-gateways --filter Name=attachment.vpc-id,Values=$ohio_default_vpc_id \
                                                             --query='InternetGateways[0].InternetGatewayId' \
                                                             --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $ohio_default_igw_id \
                        --tags Key=Name,Value=Default-InternetGateway \
                               Key=Company,Value=Default \
                               Key=Environment,Value=Default \
                               Key=Project,Value=Default \
                        --profile $profile --region us-east-2 --output text

    # Tag Default-DHCPOptions
    ohio_default_dopt_id=$(aws ec2 describe-vpcs --vpc-id=$ohio_default_vpc_id \
                                                 --query 'Vpcs[0].DhcpOptionsId' \
                                                 --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $ohio_default_dopt_id \
                        --tags Key=Name,Value=Default-DHCPOptions \
                               Key=Company,Value=Default \
                               Key=Environment,Value=Default \
                               Key=Project,Value=Default \
                        --profile $profile --region us-east-2 --output text

    # Tag Default-DefaultNetworkAcl
    ohio_default_default_nacl_id=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$ohio_default_vpc_id \
                                                                           Name=default,Values=true \
                                                                 --query 'NetworkAcls[0].NetworkAclId' \
                                                                 --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $ohio_default_default_nacl_id \
                        --tags Key=Name,Value=Default-DefaultNetworkAcl \
                               Key=Company,Value=Default \
                               Key=Environment,Value=Default \
                               Key=Project,Value=Default \
                        --profile $profile --region us-east-2 --output text

    # Tag Default-DefaultSecurityGroup
    ohio_default_default_sg_id=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$ohio_default_vpc_id \
                                                                            Name=group-name,Values=default \
                                                                  --query 'SecurityGroups[0].GroupId' \
                                                                  --profile $profile --region us-east-2 --output text)

    aws ec2 create-tags --resources $ohio_default_default_sg_id \
                        --tags Key=Name,Value=Default-DefaultSecurityGroup \
                               Key=Company,Value=Default \
                               Key=Environment,Value=Default \
                               Key=Project,Value=Default \
                        --profile $profile --region us-east-2 --output text
    ```
