# Modules:Topics:Alfa Development Account:Ohio:Alfa Development Topics

This module creates Build Topics & Subscriptions in the AWS Ohio (us-east-2) Region within the
CaMeLz-Alfa-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Alfa-Development Topics

1. **Set Profile for Alfa-Development Account**

    ```bash
    profile=$alfa_development_profile
    ```

1. **Create Alfa-Development Events Topic**

    ```bash
    alfa_ohio_development_events_topic_arn=$(aws sns create-topic --name Alfa-Development-Events \
                                                                  --attributes "DisplayName=ALFD Events" \
                                                                  --tags Key=Name,Value=Alfa-Development-Events-Topic Key=Company,Value=Alfa Key=Environment,Value=Development \
                                                                  --query 'TopicArn' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_development_events_topic_arn
    ```

1. **Create Alfa-Development Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_ohio_development_events_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-d-alfa-events@camelz.io \
                      --profile $profile --region us-east-2 --output text
    ```

1. **Create Alfa-Development Alarms Topic**

    ```bash
    alfa_ohio_development_alarms_topic_arn=$(aws sns create-topic --name Alfa-Development-Alarms \
                                                                  --attributes "DisplayName=ALFD Alarms" \
                                                                  --tags Key=Name,Value=Alfa-Development-Alarms-Topic Key=Company,Value=Alfa Key=Environment,Value=Development \
                                                                  --query 'TopicArn' \
                                                                  --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_development_alarms_topic_arn
    ```

1. **Create Alfa-Development Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_ohio_development_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-d-alfa-alarms@camelz.io \
                      --profile $profile --region us-east-2 --output text
    ```
