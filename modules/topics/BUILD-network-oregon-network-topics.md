# Modules:Topics:Network Account:Oregon:Network Topics

This module creates Network Topics & Subscriptions in the AWS Oregon (us-west-2) Region within the
CaMeLz-Network Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Network Topics

1. **Set Profile for Network Account**

    ```bash
    profile=$network_profile
    ```

1. **Create Network Events Topic**

    ```bash
    oregon_network_events_topic_arn=$(aws sns create-topic --name Network-Events \
                                                           --attributes "DisplayName=CMLN Events" \
                                                           --tags Key=Name,Value=Network-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Network \
                                                           --query 'TopicArn' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_network_events_topic_arn
    ```

1. **Create Network Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $oregon_network_events_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-n-events@camelz.io \
                      --profile $profile --region us-west-2 --output text
    ```

1. **Create Network Alarms Topic**

    ```bash
    oregon_network_alarms_topic_arn=$(aws sns create-topic --name Network-Alarms \
                                                           --attributes "DisplayName=CMLN Alarms" \
                                                           --tags Key=Name,Value=Network-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Network \
                                                           --query 'TopicArn' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_network_alarms_topic_arn
    ```

1. **Create Network Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $oregon_network_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-n-alarms@camelz.io \
                      --profile $profile --region us-west-2 --output text
    ```
