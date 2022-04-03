# Modules:Topics:Alfa Recovery Account:Oregon:Alfa Recovery Topics

This module creates Alfa-Recovery Topics & Subscriptions in the AWS Oregon (us-west-2) Region within the
Alfa-CaMeLz-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Alfa-Recovery Topics

1. **Set Profile for Alfa-Recovery Account**

    ```bash
    profile=$alfa_recovery_profile
    ```

1. **Create Alfa-Recovery Events Topic**

    ```bash
    alfa_oregon_recovery_events_topic_arn=$(aws sns create-topic --name Events \
                                                                 --attributes "DisplayName=ALFR Events" \
                                                                 --tags Key=Name,Value=Alfa-Recovery-Events-Topic Key=Company,Value=Alfa Key=Environment,Value=Recovery \
                                                                 --query 'TopicArn' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_events_topic_arn
    ```

1. **Create Alfa-Recovery Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_oregon_recovery_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```

1. **Create Alfa-Recovery Alarms Topic**

    ```bash
    alfa_oregon_recovery_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                                 --attributes "DisplayName=ALFR Alarms" \
                                                                 --tags Key=Name,Value=Alfa-Recovery-Alarms-Topic Key=Company,Value=Alfa Key=Environment,Value=Recovery \
                                                                 --query 'TopicArn' \
                                                                 --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_recovery_alarms_topic_arn
    ```

1. **Create Alfa-Recovery Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_oregon_recovery_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```
