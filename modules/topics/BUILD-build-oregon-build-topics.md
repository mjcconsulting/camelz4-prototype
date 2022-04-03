# Modules:Topics:Build Account:Oregon:Build Topics

This module creates Build Topics & Subscriptions in the AWS Oregon (us-west-2) Region within the
CaMeLz-Build Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Build Topics

1. **Set Profile for Build Account**

    ```bash
    profile=$build_profile
    ```

1. **Create Build Events Topic**

    ```bash
    oregon_build_events_topic_arn=$(aws sns create-topic --name Events \
                                                         --attributes "DisplayName=CMLB Events" \
                                                         --tags Key=Name,Value=Build-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Build \
                                                         --query 'TopicArn' \
                                                         --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_build_events_topic_arn
    ```

1. **Create Build Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $oregon_build_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```

1. **Create Build Alarms Topic**

    ```bash
    oregon_build_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                         --attributes "DisplayName=CMLB Alarms" \
                                                         --tags Key=Name,Value=Build-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Build \
                                                         --query 'TopicArn' \
                                                         --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_build_alarms_topic_arn
    ```

1. **Create Build Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $oregon_build_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```
