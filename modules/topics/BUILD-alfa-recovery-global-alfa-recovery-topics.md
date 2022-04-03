# Modules:Topics:Alfa Recovery Account:Global:Alfa Recovery Topics

This module creates Alfa-Recovery Topics & Subscriptions in the AWS Virginia (us-east-1) Region within the
Alfa-CaMeLz-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Alfa-Recovery Topics

1. **Set Profile for Alfa-Recovery Account**

    ```bash
    profile=$alfa_recovery_profile
    ```

1. **Create Alfa-Recovery Events Topic**

    ```bash
    alfa_global_recovery_events_topic_arn=$(aws sns create-topic --name Events \
                                                                 --attributes "DisplayName=ALFR Events" \
                                                                 --tags Key=Name,Value=Alfa-Recovery-Events-Topic Key=Company,Value=Alfa Key=Environment,Value=Recovery \
                                                                 --query 'TopicArn' \
                                                                 --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_global_recovery_events_topic_arn
    ```

1. **Create Alfa-Recovery Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_global_recovery_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Alfa-Recovery Alarms Topic**

    ```bash
    alfa_global_recovery_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                                 --attributes "DisplayName=ALFR Alarms" \
                                                                 --tags Key=Name,Value=Alfa-Recovery-Alarms-Topic Key=Company,Value=Alfa Key=Environment,Value=Recovery \
                                                                 --query 'TopicArn' \
                                                                 --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_global_recovery_alarms_topic_arn
    ```

1. **Create Alfa-Recovery Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_global_recovery_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```
