# Modules:Topics:Production Account:Ohio:Production Topics

This module creates Production Topics & Subscriptions in the AWS Ohio (us-east-2) Region within the
CaMeLz-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Production Topics

1. **Set Profile for Production Account**

    ```bash
    profile=$production_profile
    ```

1. **Create Production Events Topic**

    ```bash
    ohio_production_events_topic_arn=$(aws sns create-topic --name Events \
                                                            --attributes "DisplayName=CMLP Events" \
                                                            --tags Key=Name,Value=Production-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Production \
                                                            --query 'TopicArn' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_events_topic_arn
    ```

1. **Create Production Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_production_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```

1. **Create Production Alarms Topic**

    ```bash
    ohio_production_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                            --attributes "DisplayName=CMLP Alarms" \
                                                            --tags Key=Name,Value=Production-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Production \
                                                            --query 'TopicArn' \
                                                            --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_production_alarms_topic_arn
    ```

1. **Create Production Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_production_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-2 --output text
    ```
