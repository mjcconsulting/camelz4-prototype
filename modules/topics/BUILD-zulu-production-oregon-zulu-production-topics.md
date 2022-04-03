# Modules:Topics:Zulu Production Account:Oregon:Zulu Production Topics

This module creates Zulu-Production Topics & Subscriptions in the AWS Oregon (us-west-2) Region within the
Zulu-CaMeLz-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Zulu-Production Topics

1. **Set Profile for Zulu-Production Account**

    ```bash
    profile=$zulu_production_profile
    ```

1. **Create Zulu-Production Events Topic**

    ```bash
    zulu_oregon_production_events_topic_arn=$(aws sns create-topic --name Events \
                                                                   --attributes "DisplayName=ZULP Events" \
                                                                   --tags Key=Name,Value=Zulu-Production-Events-Topic Key=Company,Value=Zulu Key=Environment,Value=Production \
                                                                   --query 'TopicArn' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable zulu_oregon_production_events_topic_arn
    ```

1. **Create Zulu-Production Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $zulu_oregon_production_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```

1. **Create Zulu-Production Alarms Topic**

    ```bash
    zulu_oregon_production_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                                   --attributes "DisplayName=ZULP Alarms" \
                                                                   --tags Key=Name,Value=Zulu-Production-Alarms-Topic Key=Company,Value=Zulu Key=Environment,Value=Production \
                                                                   --query 'TopicArn' \
                                                                   --profile $profile --region us-west-2 --output text)
    camelz-variable zulu_oregon_production_alarms_topic_arn
    ```

1. **Create Zulu-Production Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $zulu_oregon_production_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```
