# Modules:Topics:Production Account:Global:Production Topics

This module creates Production Topics & Subscriptions in the AWS Virginia (us-east-1) Region within the
CaMeLz-Production Account.


## Dependencies

**TODO**: Determine Dependencies and list.

## Global Production Topics

1. **Set Profile for Production Account**

    ```bash
    profile=$production_profile
    ```

1. **Create Production Events Topic**

    ```bash
    global_production_events_topic_arn=$(aws sns create-topic --name Production-Events \
                                                              --attributes "DisplayName=CMLP Events" \
                                                              --tags Key=Name,Value=Production-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Production \
                                                              --query 'TopicArn' \
                                                              --profile $profile --region us-east-1 --output text)
    camelz-variable global_production_events_topic_arn
    ```

1. **Create Production Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_production_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Production Alarms Topic**

    ```bash
    global_production_alarms_topic_arn=$(aws sns create-topic --name Production-Alarms \
                                                              --attributes "DisplayName=CMLP Alarms" \
                                                              --tags Key=Name,Value=Production-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Production \
                                                              --query 'TopicArn' \
                                                              --profile $profile --region us-east-1 --output text)
    camelz-variable global_production_alarms_topic_arn
    ```

1. **Create Production Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_production_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```
