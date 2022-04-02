# Modules:Budgets:Recovery Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
CaMeLz-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Recovery Bills Topic

1. **Set Profile for Recovery Account**

    ```bash
    profile=$recovery_profile
    ```

1. **Create Recovery Bills Topic**

    ```bash
    global_recovery_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                           --attributes "DisplayName=CMLR Bills" \
                                                           --tags Key=Name,Value=Recovery-Bills-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Recovery \
                                                           --query 'TopicArn' \
                                                           --profile $profile --region us-east-1 --output text)
    camelz-variable global_recovery_bills_topic_arn
    ```

1. **Create Recovery Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_recovery_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Recovery Budget**
