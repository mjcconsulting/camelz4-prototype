# Modules:Budgets:Alfa Production Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
Alfa-CaMeLz-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Alfa-Production Bills Topic

1. **Set Profile for Alfa-Production Account**

    ```bash
    profile=$alfa_production_profile
    ```

1. **Create Alfa-Production Bills Topic**

    ```bash
    alfa_global_production_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                                  --attributes "DisplayName=ALFP Bills" \
                                                                  --tags Key=Name,Value=Alfa-Production-Bills-Topic Key=Company,Value=Alfa Key=Environment,Value=Production \
                                                                  --query 'TopicArn' \
                                                                  --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_global_management_bills_topic_arn
    ```

1. **Create Alfa-Production Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_global_production_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Alfa-Production Budget**
