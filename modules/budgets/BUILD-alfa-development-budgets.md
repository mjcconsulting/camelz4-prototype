# Modules:Budgets:Alfa Development Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
Alfa-CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Alfa-Development Bills Topic

1. **Set Profile for Alfa-Development Account**

    ```bash
    profile=$alfa_development_profile
    ```

1. **Create Alfa-Development Bills Topic**

    ```bash
    alfa_global_development_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                                   --attributes "DisplayName=ALFD Bills" \
                                                                   --tags Key=Name,Value=Alfa-Development-Bills-Topic Key=Company,Value=Alfa Key=Environment,Value=Development \
                                                                   --query 'TopicArn' \
                                                                   --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_global_management_bills_topic_arn
    ```

1. **Create Alfa-Development Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_global_development_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Alfa-Development Budget**
