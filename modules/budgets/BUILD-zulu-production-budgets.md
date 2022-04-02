# Modules:Budgets:Zulu Production Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
Zulu-CaMeLz-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Zulu-Production Bills Topic

1. **Set Profile for Zulu-Production Account**

    ```bash
    profile=$zulu_production_profile
    ```

1. **Create Zulu-Production Bills Topic**

    ```bash
    zulu_global_production_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                                   --attributes "DisplayName=ZULP Bills" \
                                                                   --tags Key=Name,Value=Zulu-Production-Bills-Topic Key=Company,Value=Zulu Key=Environment,Value=Production \
                                                                   --query 'TopicArn' \
                                                                   --profile $profile --region us-east-1 --output text)
    camelz-variable zulu_global_management_bills_topic_arn
    ```

1. **Create Zulu-Production Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $zulu_global_production_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Zulu-Production Budget**
