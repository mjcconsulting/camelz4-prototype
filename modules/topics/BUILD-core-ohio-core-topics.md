# Modules:Topics:Core Account:Ohio:Core Topics

This module creates Core Topics & Subscriptions in the AWS Ohio (us-east-2) Region within the
CaMeLz-Core Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Core Topics

1. **Set Profile for Core Account**

    ```bash
    profile=$core_profile
    ```

1. **Create Core Events Topic**

    ```bash
    ohio_core_events_topic_arn=$(aws sns create-topic --name Events \
                                                      --attributes "DisplayName=CMLC Events" \
                                                      --tags Key=Name,Value=Core-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Core \
                                                      --query 'TopicArn' \
                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_core_events_topic_arn
    ```

1. **Create Core Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_core_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```

1. **Create Core Alarms Topic**

    ```bash
    ohio_core_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                      --attributes "DisplayName=CMLC Alarms" \
                                                      --tags Key=Name,Value=Core-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Core \
                                                      --query 'TopicArn' \
                                                      --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_core_alarms_topic_arn
    ```

1. **Create Core Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_core_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```
