# Modules:Topics:MCrawford Sandbox Account:Ohio:MCrawford Sandbox Topics

This module creates MCrawford-Sandbox Topics & Subscriptions in the AWS Ohio (us-east-2) Region within the
CaMeLz-MCrawford-Sandbox Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio MCrawford-Sandbox Topics

1. **Set Profile for MCrawford-Sandbox Account**

    ```bash
    profile=$mcrawford_sandbox_profile
    ```

1. **Create MCrawford-Sandbox Events Topic**

    ```bash
    mcrawford_ohio_sandbox_events_topic_arn=$(aws sns create-topic --name MCrawford-Sandbox-Events \
                                                                   --attributes "DisplayName=MJCX Events" \
                                                                   --tags Key=Name,Value=MCrawford-Sandbox-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Sandbox \
                                                                   --query 'TopicArn' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable mcrawford_ohio_sandbox_events_topic_arn
    ```

1. **Create MCrawford-Sandbox Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $mcrawford_ohio_sandbox_events_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-x-mcrawford-events@camelz.io \
                      --profile $profile --region us-east-2 --output text
    ```

1. **Create MCrawford-Sandbox Alarms Topic**

    ```bash
    mcrawford_ohio_sandbox_alarms_topic_arn=$(aws sns create-topic --name MCrawford-Sandbox-Alarms \
                                                                   --attributes "DisplayName=MJCX Alarms" \
                                                                   --tags Key=Name,Value=MCrawford-Sandbox-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Sandbox \
                                                                   --query 'TopicArn' \
                                                                   --profile $profile --region us-east-2 --output text)
    camelz-variable mcrawford_ohio_sandbox_alarms_topic_arn
    ```

1. **Create MCrawford-Sandbox Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $mcrawford_ohio_sandbox_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-x-mcrawford-alarms@camelz.io \
                      --profile $profile --region us-east-2 --output text
    ```
