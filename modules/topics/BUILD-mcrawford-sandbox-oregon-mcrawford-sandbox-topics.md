# Modules:Topics:MCrawford Sandbox Account:Oregon:MCrawford Sandbox Topics

This module creates MCrawford-Sandbox Topics & Subscriptions in the AWS Oregon (us-west-2) Region within the
CaMeLz-MCrawford-Sandbox Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon MCrawford-Sandbox Topics

1. **Set Profile for MCrawford-Sandbox Account**

    ```bash
    profile=$mcrawford_sandbox_profile
    ```

1. **Create MCrawford-Sandbox Events Topic**

    ```bash
    oregon_mcrawford_sandbox_events_topic_arn=$(aws sns create-topic --name Events \
                                                                     --attributes "DisplayName=MJCX Events" \
                                                                     --tags Key=Name,Value=MCrawford-Sandbox-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Sandbox \
                                                                     --query 'TopicArn' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_mcrawford_sandbox_events_topic_arn
    ```

1. **Create MCrawford-Sandbox Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $oregon_mcrawford_sandbox_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```

1. **Create MCrawford-Sandbox Alarms Topic**

    ```bash
    oregon_mcrawford_sandbox_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                                     --attributes "DisplayName=MJCX Alarms" \
                                                                     --tags Key=Name,Value=MCrawford-Sandbox-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Sandbox \
                                                                     --query 'TopicArn' \
                                                                     --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_mcrawford_sandbox_alarms_topic_arn
    ```

1. **Create MCrawford-Sandbox Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $oregon_mcrawford_sandbox_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```
