
# Modules:Topics:Alfa Recovery Account:Ohio:Alfa Recovery Topics

This module creates Alfa-Recovery Topics & Subscriptions in the AWS Ohio (us-east-2) Region within the
CaMeLz-Alfa-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Alfa-Recovery Topics

1. **Set Profile for Alfa-Recovery Account**

    ```bash
    profile=$alfa_recovery_profile
    ```

1. **Create Alfa-Recovery Events Topic**

    ```bash
    alfa_ohio_recovery_events_topic_arn=$(aws sns create-topic --name Alfa-Recovery-Events \
                                                               --attributes "DisplayName=ALFR Events" \
                                                               --tags Key=Name,Value=Alfa-Recovery-Events-Topic Key=Company,Value=Alfa Key=Environment,Value=Recovery \
                                                               --query 'TopicArn' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_recovery_events_topic_arn
    ```

1. **Create Alfa-Recovery Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_ohio_recovery_events_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-r-alfa-events@camelz.io \
                      --profile $profile --region us-east-2 --output text
    ```

1. **Create Alfa-Recovery Alarms Topic**

    ```bash
    alfa_ohio_recovery_alarms_topic_arn=$(aws sns create-topic --name Alfa-Recovery-Alarms \
                                                               --attributes "DisplayName=ALFR Alarms" \
                                                               --tags Key=Name,Value=Alfa-Recovery-Alarms-Topic Key=Company,Value=Alfa Key=Environment,Value=Recovery \
                                                               --query 'TopicArn' \
                                                               --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_recovery_alarms_topic_arn
    ```

1. **Create Alfa-Recovery Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_ohio_recovery_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-r-alfa-alarms@camelz.io \
                      --profile $profile --region us-east-2 --output text
    ```
