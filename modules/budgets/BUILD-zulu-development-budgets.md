# Modules:Budgets:Zulu Development Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
Zulu-CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Zulu-Development Bills Topic

1. **Set Profile for Zulu-Development Account**

    ```bash
    profile=$zulu_development_profile
    ```

1. **Create Zulu-Development Bills Topic**

    ```bash
    zulu_global_development_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                                   --attributes "DisplayName=ZULD Bills" \
                                                                   --tags Key=Name,Value=Zulu-Development-Bills-Topic Key=Company,Value=Zulu Key=Environment,Value=Development \
                                                                   --query 'TopicArn' \
                                                                   --profile $profile --region us-east-1 --output text)
    camelz-variable zulu_global_management_bills_topic_arn
    ```

1. **Create Zulu-Development Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $zulu_global_development_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Zulu-Development Budget**
