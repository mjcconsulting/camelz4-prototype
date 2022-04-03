# Modules:Topics:Management Account:Oregon:Management Topics

This module creates Management Topics & Subscriptions in the AWS Oregon (us-west-2) Region within the
CaMeLz-Management Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Management Topics

1. **Set Profile for Management Account**

    ```bash
    profile=$management_profile
    ```

1. **Create Management Events Topic**

    ```bash
    oregon_management_events_topic_arn=$(aws sns create-topic --name Events \
                                                              --attributes "DisplayName=CMLM Events" \
                                                              --tags Key=Name,Value=Management-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Management \
                                                              --query 'TopicArn' \
                                                              --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_events_topic_arn
    ```

1. **Create Management Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $oregon_management_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```

1. **Create Management Alarms Topic**

    ```bash
    oregon_management_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                              --attributes "DisplayName=CMLM Alarms" \
                                                              --tags Key=Name,Value=Management-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Management \
                                                              --query 'TopicArn' \
                                                              --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_management_alarms_topic_arn
    ```

1. **Create Management Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $oregon_management_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```
