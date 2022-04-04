# Modules:Topics:MCrawford Sandbox Account:Global:MCrawford Sandbox Topics

This module creates MCrawford-Sandbox Topics & Subscriptions in the AWS Virginia (us-east-1) Region within the
CaMeLz-Management Account.


## Dependencies

**TODO**: Determine Dependencies and list.

## Global MCrawford-Sandbox Topics

1. **Set Profile for MCrawford-Sandbox Account**

    ```bash
    profile=$mcrawford_sandbox_profile
    ```

1. **Create MCrawford-Sandbox Events Topic**

    ```bash
    mcrawford_global_sandbox_events_topic_arn=$(aws sns create-topic --name Events \
                                                                     --attributes "DisplayName=MJCX Events" \
                                                                     --tags Key=Name,Value=MCrawford-Sandbox-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Sandbox \
                                                                     --query 'TopicArn' \
                                                                     --profile $profile --region us-east-1 --output text)
    camelz-variable mcrawford_global_sandbox_events_topic_arn
    ```

1. **Create MCrawford-Sandbox Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $mcrawford_global_sandbox_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create MCrawford-Sandbox Alarms Topic**

    ```bash
    mcrawford_global_sandbox_alarms_topic_arn=$(aws sns create-topic --name MCrawford-Sandbox-Alarms \
                                                                     --attributes "DisplayName=MJCX Alarms" \
                                                                     --tags Key=Name,Value=MCrawford-Sandbox-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Sandbox \
                                                                     --query 'TopicArn' \
                                                                     --profile $profile --region us-east-1 --output text)
    camelz-variable mcrawford_global_sandbox_alarms_topic_arn
    ```

1. **Create MCrawford-Sandbox Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $mcrawford_global_sandbox_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```
