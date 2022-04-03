# Modules:Topics:Network Account:Ohio:Network Topics

This module creates Network Topics & Subscriptions in the AWS Ohio (us-east-2) Region within the
CaMeLz-Network Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Network Topics

1. **Set Profile for Network Account**

    ```bash
    profile=$network_profile
    ```

1. **Create Network Events Topic**

    ```bash
    ohio_network_events_topic_arn=$(aws sns create-topic --name Events \
                                                         --attributes "DisplayName=CMLN Events" \
                                                         --tags Key=Name,Value=Network-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Network \
                                                         --query 'TopicArn' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_events_topic_arn
    ```

1. **Create Network Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_network_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```

1. **Create Network Alarms Topic**

    ```bash
    ohio_network_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                         --attributes "DisplayName=CMLN Alarms" \
                                                         --tags Key=Name,Value=Network-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Network \
                                                         --query 'TopicArn' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_network_alarms_topic_arn
    ```

1. **Create Network Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_network_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```
