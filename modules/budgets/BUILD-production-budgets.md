# Modules:Budgets:Production Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
CaMeLz-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Production Bills Topic

1. **Set Profile for Production Account**

    ```bash
    profile=$production_profile
    ```

1. **Create Production Bills Topic**

    ```bash
    global_production_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                             --attributes "DisplayName=CMLP Bills" \
                                                             --tags Key=Name,Value=Production-Bills-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Production \
                                                             --query 'TopicArn' \
                                                             --profile $profile --region us-east-1 --output text)
    camelz-variable global_production_bills_topic_arn
    ```

1. **Create Production Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_production_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Production Budget**
