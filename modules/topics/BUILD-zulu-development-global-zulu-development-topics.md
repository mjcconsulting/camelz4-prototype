# Modules:Topics:Zulu Development Account:Global:Zulu Development Topics

This module creates Zulu-Development Topics & Subscriptions in the AWS Virginia (us-east-1) Region within the
CaMeLz-Zulu-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Management Topics

1. **Set Profile for Zulu-Development Account**

    ```bash
    profile=$zulu_development_profile
    ```

1. **Create Zulu-Development Events Topic**

    ```bash
    zulu_global_development_events_topic_arn=$(aws sns create-topic --name Zulu-Development-Events \
                                                                    --attributes "DisplayName=ZULD Events" \
                                                                    --tags Key=Name,Value=Zulu-Development-Events-Topic Key=Company,Value=Zulu Key=Environment,Value=Development \
                                                                    --query 'TopicArn' \
                                                                    --profile $profile --region us-east-1 --output text)
    camelz-variable zulu_global_development_events_topic_arn
    ```

1. **Create Zulu-Development Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $zulu_global_development_events_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-d-zulu-events@camelz.io \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Zulu-Development Alarms Topic**

    ```bash
    zulu_global_development_alarms_topic_arn=$(aws sns create-topic --name Zulu-Development-Alarms \
                                                                    --attributes "DisplayName=ZULD Alarms" \
                                                                    --tags Key=Name,Value=Zulu-Development-Alarms-Topic Key=Company,Value=Zulu Key=Environment,Value=Development \
                                                                    --query 'TopicArn' \
                                                                    --profile $profile --region us-east-1 --output text)
    camelz-variable zulu_global_development_alarms_topic_arn
    ```

1. **Create Zulu-Development Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $zulu_global_development_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-d-zulu-alarms@camelz.io \
                      --profile $profile --region us-east-1 --output text
    ```
