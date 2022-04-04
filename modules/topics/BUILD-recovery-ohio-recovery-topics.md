# Modules:Topics:Recovery Account:Ohio:Recovery Topics

This module creates Recovery Topics & Subscriptions in the AWS Ohio (us-east-2) Region within the
CaMeLz-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Recovery Topics

1. **Set Profile for Recovery Account**

    ```bash
    profile=$recovery_profile
    ```

1. **Create Recovery Events Topic**

    ```bash
    ohio_recovery_events_topic_arn=$(aws sns create-topic --name Recovery-Events \
                                                          --attributes "DisplayName=CMLR Events" \
                                                          --tags Key=Name,Value=Recovery-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Recovery \
                                                          --query 'TopicArn' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_recovery_events_topic_arn
    ```

1. **Create Recovery Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_recovery_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```

1. **Create Recovery Alarms Topic**

    ```bash
    ohio_recovery_alarms_topic_arn=$(aws sns create-topic --name Recovery-Alarms \
                                                          --attributes "DisplayName=CMLR Alarms" \
                                                          --tags Key=Name,Value=Recovery-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Recovery \
                                                          --query 'TopicArn' \
                                                          --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_recovery_alarms_topic_arn
    ```

1. **Create Recovery Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_recovery_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```
