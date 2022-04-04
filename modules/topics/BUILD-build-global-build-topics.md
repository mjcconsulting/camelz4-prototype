# Modules:Topics:Build Account:Global:Build Topics

This module creates Build Topics & Subscriptions in the AWS Virginia (us-east-1) Region within the
CaMeLz-Build Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Build Topics

1. **Set Profile for Build Account**

    ```bash
    profile=$build_profile
    ```

1. **Create Build Events Topic**

    ```bash
    global_build_events_topic_arn=$(aws sns create-topic --name Build-Events \
                                                         --attributes "DisplayName=CMLB Events" \
                                                         --tags Key=Name,Value=Build-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Build \
                                                         --query 'TopicArn' \
                                                         --profile $profile --region us-east-1 --output text)
    camelz-variable global_build_events_topic_arn
    ```

1. **Create Build Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_build_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Build Alarms Topic**

    ```bash
    global_build_alarms_topic_arn=$(aws sns create-topic --name Build-Alarms \
                                                         --attributes "DisplayName=CMLB Alarms" \
                                                         --tags Key=Name,Value=Build-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Build \
                                                         --query 'TopicArn' \
                                                         --profile $profile --region us-east-1 --output text)
    camelz-variable global_build_alarms_topic_arn
    ```

1. **Create Build Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_build_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```
