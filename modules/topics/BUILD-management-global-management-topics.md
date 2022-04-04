# Modules:Topics:Management Account:Global:Management Topics

This module creates Management Topics & Subscriptions in the AWS Virginia (us-east-1) Region within the
CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Management Topics

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create Management Events Topic**

    ```bash
    global_management_events_topic_arn=$(aws sns create-topic --name Management-Events \
                                                              --attributes "DisplayName=CMLM Events" \
                                                              --tags Key=Name,Value=Management-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Management \
                                                              --query 'TopicArn' \
                                                              --profile $profile --region us-east-1 --output text)
    camelz-variable global_management_events_topic_arn
    ```

1. **Create Management Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_management_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Management Alarms Topic**

    ```bash
    global_management_alarms_topic_arn=$(aws sns create-topic --name Management-Alarms \
                                                              --attributes "DisplayName=CMLM Alarms" \
                                                              --tags Key=Name,Value=Management-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Management \
                                                              --query 'TopicArn' \
                                                              --profile $profile --region us-east-1 --output text)
    camelz-variable global_management_alarms_topic_arn
    ```

1. **Create Management Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_management_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```
