# Modules:Topics:Core Account:Global:Core Topics

This module creates Core Topics & Subscriptions in the AWS Virginia (us-east-1) Region within the
CaMeLz-Core Account.


## Dependencies

**TODO**: Determine Dependencies and list.

## Global Core Topics

1. **Set Profile for Core Account**

    ```bash
    profile=$core_profile
    ```

1. **Create Core Events Topic**

    ```bash
    global_core_events_topic_arn=$(aws sns create-topic --name Core-Events \
                                                        --attributes "DisplayName=CMLC Events" \
                                                        --tags Key=Name,Value=Core-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Core \
                                                        --query 'TopicArn' \
                                                        --profile $profile --region us-east-1 --output text)
    camelz-variable global_core_events_topic_arn
    ```

1. **Create Core Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_core_events_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-c-events@camelz.io \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Core Alarms Topic**

    ```bash
    global_core_alarms_topic_arn=$(aws sns create-topic --name Core-Alarms \
                                                        --attributes "DisplayName=CMLC Alarms" \
                                                        --tags Key=Name,Value=Core-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Core \
                                                        --query 'TopicArn' \
                                                        --profile $profile --region us-east-1 --output text)
    camelz-variable global_core_alarms_topic_arn
    ```

1. **Create Core Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_core_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-c-alarms@camelz.io \
                      --profile $profile --region us-east-1 --output text
    ```
