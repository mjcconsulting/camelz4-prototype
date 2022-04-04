# Modules:Topics:Development Account:Ohio:Development Topics

This module creates Development Topics & Subscriptions in the AWS Ohio (us-east-2) Region within the
CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Development Topics

1. **Set Profile for Development Account**

    ```bash
    profile=$development_profile
    ```

1. **Create Development Events Topic**

    ```bash
    ohio_development_events_topic_arn=$(aws sns create-topic --name Development-Events \
                                                             --attributes "DisplayName=CMLD Events" \
                                                             --tags Key=Name,Value=Development-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Development \
                                                             --query 'TopicArn' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_development_events_topic_arn
    ```

1. **Create Development Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_development_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```

1. **Create Development Alarms Topic**

    ```bash
    ohio_development_alarms_topic_arn=$(aws sns create-topic --name Development-Alarms \
                                                             --attributes "DisplayName=CMLD Alarms" \
                                                             --tags Key=Name,Value=Development-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Development \
                                                             --query 'TopicArn' \
                                                             --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_development_alarms_topic_arn
    ```

1. **Create Development Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_development_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```