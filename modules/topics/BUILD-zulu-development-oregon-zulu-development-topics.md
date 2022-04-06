# Modules:Topics:Zulu Development Account:Oregon:Zulu Development Topics

This module creates Zulu-Development Topics & Subscriptions in the AWS Oregon (us-west-2) Region within the
Zulu-CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Zulu-Development Topics

1. **Set Profile for Zulu-Development Account**

    ```bash
    profile=$zulu_development_profile
    ```

1. **Create Zulu-Development Events Topic**

    ```bash
    zulu_oregon_development_events_topic_arn=$(aws sns create-topic --name Zulu-Development-Events \
                                                                    --attributes "DisplayName=ZULD Events" \
                                                                    --tags Key=Name,Value=Zulu-Development-Events-Topic Key=Company,Value=Zulu Key=Environment,Value=Development \
                                                                    --query 'TopicArn' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable zulu_oregon_development_events_topic_arn
    ```

1. **Create Zulu-Development Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $zulu_oregon_development_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```

1. **Create Zulu-Development Alarms Topic**

    ```bash
    zulu_oregon_development_alarms_topic_arn=$(aws sns create-topic --name Zulu-Development-Alarms \
                                                                    --attributes "DisplayName=ZULD Alarms" \
                                                                    --tags Key=Name,Value=Zulu-Development-Alarms-Topic Key=Company,Value=Zulu Key=Environment,Value=Development \
                                                                    --query 'TopicArn' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable zulu_oregon_development_alarms_topic_arn
    ```

1. **Create Zulu-Development Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $zulu_oregon_development_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```
