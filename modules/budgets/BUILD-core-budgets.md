# Modules:Budgets:Core Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
CaMeLz-Core Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Core Bills Topic

1. **Set Profile for Core Account**

    ```bash
    profile=$core_profile
    ```

1. **Create Core Bills Topic**

    ```bash
    global_core_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                       --attributes "DisplayName=CMLC Bills" \
                                                       --tags Key=Name,Value=Core-Bills-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Core \
                                                       --query 'TopicArn' \
                                                       --profile $profile --region us-east-1 --output text)
    camelz-variable global_core_bills_topic_arn
    ```

1. **Create Core Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_core_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Core Budget**
