# Modules:Topics:Log Account:Ohio:Log Topics

This module creates Log Topics & Subscriptions in the AWS Ohio (us-east-2) Region within the
CaMeLz-Log Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Log Topics

1. **Set Profile for Log Account**

    ```bash
    profile=$log_profile
    ```

1. **Create Log Events Topic**

    ```bash
    ohio_log_events_topic_arn=$(aws sns create-topic --name Events \
                                                     --attributes "DisplayName=CMLL Events" \
                                                     --tags Key=Name,Value=Log-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Log \
                                                     --query 'TopicArn' \
                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_log_events_topic_arn
    ```

1. **Create Log Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_log_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```

1. **Create Log Alarms Topic**

    ```bash
    ohio_log_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                     --attributes "DisplayName=CMLL Alarms" \
                                                     --tags Key=Name,Value=Log-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Log \
                                                     --query 'TopicArn' \
                                                     --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_log_alarms_topic_arn
    ```

1. **Create Log Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_log_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```
