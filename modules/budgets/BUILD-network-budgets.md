# Modules:Budgets:Network Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
CaMeLz-Network Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Network Bills Topic

1. **Set Profile for Network Account**

    ```bash
    profile=$network_profile
    ```

1. **Create Network Bills Topic**

    ```bash
    global_network_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                          --attributes "DisplayName=CMLN Bills" \
                                                          --tags Key=Name,Value=Network-Bills-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Network \
                                                          --query 'TopicArn' \
                                                          --profile $profile --region us-east-1 --output text)
    camelz-variable global_network_bills_topic_arn
    ```

1. **Create Network Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_network_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Network Budget**
