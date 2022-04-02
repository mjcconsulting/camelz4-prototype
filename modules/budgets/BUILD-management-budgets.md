# Modules:Budgets:Management Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Management Bills Topic

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create Management Bills Topic**

    ```bash
    global_management_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                             --attributes "DisplayName=CMLM Bills" \
                                                             --tags Key=Name,Value=Management-Bills-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Management \
                                                             --query 'TopicArn' \
                                                             --profile $profile --region us-east-1 --output text)
    camelz-variable global_management_bills_topic_arn
    ```

1. **Create Management Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_management_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Management Budget**
