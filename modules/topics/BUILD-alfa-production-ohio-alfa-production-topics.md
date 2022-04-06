# Modules:Topics:Alfa Production Account:Ohio:Alfa Production Topics

This module creates Alfa-Production Topics & Subscriptions in the AWS Ohio (us-east-2) Region within the
CaMeLz-Alfa-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Alfa-Production Topics

1. **Set Profile for Alfa-Production Account**

    ```bash
    profile=$alfa_production_profile
    ```

1. **Create Alfa-Production Events Topic**

    ```bash
    alfa_ohio_production_events_topic_arn=$(aws sns create-topic --name Alfa-Production-Events \
                                                                 --attributes "DisplayName=ALFP Events" \
                                                                 --tags Key=Name,Value=Alfa-Production-Events-Topic Key=Company,Value=Alfa Key=Environment,Value=Production \
                                                                 --query 'TopicArn' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_production_events_topic_arn
    ```

1. **Create Alfa-Production Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_ohio_production_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```

1. **Create Alfa-Production Alarms Topic**

    ```bash
    alfa_ohio_production_alarms_topic_arn=$(aws sns create-topic --name Alfa-Production-Alarms \
                                                                 --attributes "DisplayName=ALFP Alarms" \
                                                                 --tags Key=Name,Value=Alfa-Production-Alarms-Topic Key=Company,Value=Alfa Key=Environment,Value=Production \
                                                                 --query 'TopicArn' \
                                                                 --profile $profile --region us-east-2 --output text)
    camelz-variable alfa_ohio_production_alarms_topic_arn
    ```

1. **Create Alfa-Production Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_ohio_production_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```
