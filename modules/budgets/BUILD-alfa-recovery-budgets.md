# Modules:Budgets:Alfa Recovery Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
Alfa-CaMeLz-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Alfa-Recovery Bills Topic

1. **Set Profile for Alfa-Recovery Account**

    ```bash
    profile=$alfa_recovery_profile
    ```

1. **Create Alfa-Recovery Bills Topic**

    ```bash
    alfa_global_recovery_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                                --attributes "DisplayName=ALFR Bills" \
                                                                --tags Key=Name,Value=Alfa-Recovery-Bills-Topic Key=Company,Value=Alfa Key=Environment,Value=Recovery \
                                                                --query 'TopicArn' \
                                                                --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_global_management_bills_topic_arn
    ```

1. **Create Alfa-Recovery Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_global_recovery_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Alfa-Recovery Budget**
