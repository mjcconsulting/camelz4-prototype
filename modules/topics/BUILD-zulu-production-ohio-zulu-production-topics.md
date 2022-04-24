# Modules:Topics:Zulu Production Account:Ohio:Zulu Production Topics

This module creates Zulu-Production Topics & Subscriptions in the AWS Ohio (us-east-2) Region within the
CaMeLz-Zulu-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Zulu-Production Topics

1. **Set Profile for Zulu-Production Account**

    ```bash
    profile=$zulu_production_profile
    ```

1. **Create Zulu-Production Events Topic**

    ```bash
    zulu_ohio_production_events_topic_arn=$(aws sns create-topic --name Zulu-Production-Events \
                                                                 --attributes "DisplayName=ZULP Events" \
                                                                 --tags Key=Name,Value=Zulu-Production-Events-Topic Key=Company,Value=Zulu Key=Environment,Value=Production \
                                                                 --query 'TopicArn' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_events_topic_arn
    ```

1. **Create Zulu-Production Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $zulu_ohio_production_events_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-p-zulu-events@camelz.io \
                      --profile $profile --region us-east-2 --output text
    ```

1. **Create Zulu-Production Alarms Topic**

    ```bash
    zulu_ohio_production_alarms_topic_arn=$(aws sns create-topic --name Zulu-Production-Alarms \
                                                                 --attributes "DisplayName=ZULP Alarms" \
                                                                 --tags Key=Name,Value=Zulu-Production-Alarms-Topic Key=Company,Value=Zulu Key=Environment,Value=Production \
                                                                 --query 'TopicArn' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable zulu_ohio_production_alarms_topic_arn
    ```

1. **Create Zulu-Production Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $zulu_ohio_production_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-p-zulu-alarms@camelz.io \
                      --profile $profile --region us-east-2 --output text
    ```
