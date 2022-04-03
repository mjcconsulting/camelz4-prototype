# Modules:Topics:Recovery Account:Global:Recovery Topics

This module creates Recovery Topics & Subscriptions in the AWS Virginia (us-east-1) Region within the
CaMeLz-Recovery Account.


## Dependencies

**TODO**: Determine Dependencies and list.

## Global Recovery Topics

1. **Set Profile for Recovery Account**

    ```bash
    profile=$recovery_profile
    ```

1. **Create Recovery Events Topic**

    ```bash
    global_recovery_events_topic_arn=$(aws sns create-topic --name Events \
                                                            --attributes "DisplayName=CMLR Events" \
                                                            --tags Key=Name,Value=Recovery-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Recovery \
                                                            --query 'TopicArn' \
                                                            --profile $profile --region us-east-1 --output text)
    camelz-variable global_recovery_events_topic_arn
    ```

1. **Create Recovery Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_recovery_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Recovery Alarms Topic**

    ```bash
    global_recovery_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                            --attributes "DisplayName=CMLR Alarms" \
                                                            --tags Key=Name,Value=Recovery-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Recovery \
                                                            --query 'TopicArn' \
                                                            --profile $profile --region us-east-1 --output text)
    camelz-variable global_recovery_alarms_topic_arn
    ```

1. **Create Recovery Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_recovery_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```
