# Modules:Topics:Log Account:Oregon:Log Topics

This module creates Log Topics & Subscriptions in the AWS Oregon (us-west-2) Region within the
CaMeLz-Log Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Log Topics

1. **Set Profile for Log Account**

    ```bash
    profile=$log_profile
    ```

1. **Create Log Events Topic**

    ```bash
    oregon_log_events_topic_arn=$(aws sns create-topic --name Log-Events \
                                                       --attributes "DisplayName=CMLL Events" \
                                                       --tags Key=Name,Value=Log-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Log \
                                                       --query 'TopicArn' \
                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_log_events_topic_arn
    ```

1. **Create Log Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $oregon_log_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```

1. **Create Log Alarms Topic**

    ```bash
    oregon_log_alarms_topic_arn=$(aws sns create-topic --name Log-Alarms \
                                                       --attributes "DisplayName=CMLL Alarms" \
                                                       --tags Key=Name,Value=Log-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Log \
                                                       --query 'TopicArn' \
                                                       --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_log_alarms_topic_arn
    ```

1. **Create Log Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $oregon_log_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```
