# Modules:Budgets:Log Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
CaMeLz-Log Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Log Bills Topic

1. **Set Profile for Log Account**

    ```bash
    profile=$log_profile
    ```

1. **Create Log Bills Topic**

    ```bash
    global_log_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                      --attributes "DisplayName=CMLL Bills" \
                                                      --tags Key=Name,Value=Log-Bills-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Log \
                                                      --query 'TopicArn' \
                                                      --profile $profile --region us-east-1 --output text)
    camelz-variable global_log_bills_topic_arn
    ```

1. **Create Log Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_log_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Log Budget**
