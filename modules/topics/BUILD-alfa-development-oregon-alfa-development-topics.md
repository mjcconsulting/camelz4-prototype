# Modules:Topics:Alfa Development Account:Oregon:Alfa Development Topics

This module creates Build Topics & Subscriptions in the AWS Oregon (us-west-2) Region within the
Alfa-CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Alfa-Development Topics

1. **Set Profile for Alfa-Development Account**

    ```bash
    profile=$alfa_development_profile
    ```

1. **Create Alfa-Development Events Topic**

    ```bash
    alfa_oregon_development_events_topic_arn=$(aws sns create-topic --name Events \
                                                                    --attributes "DisplayName=ALFD Events" \
                                                                    --tags Key=Name,Value=Alfa-Development-Events-Topic Key=Company,Value=Alfa Key=Environment,Value=Development \
                                                                    --query 'TopicArn' \
                                                                    --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_development_events_topic_arn
    ```

1. **Create Alfa-Development Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_oregon_development_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```

1. **Create Alfa-Development Alarms Topic**

    ```bash
    alfa_oregon_development_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                              --attributes "DisplayName=ALFD Alarms" \
                                                              --tags Key=Name,Value=Alfa-Development-Alarms-Topic Key=Company,Value=Alfa Key=Environment,Value=Development \
                                                              --query 'TopicArn' \
                                                              --profile $profile --region us-west-2 --output text)
    camelz-variable alfa_oregon_development_alarms_topic_arn
    ```

1. **Create Alfa-Development Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_oregon_development_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-west-2 --output text
    ```
