# Modules:Topics:Development Account:Global:Testing Topics

This module creates Testing Topics & Subscriptions in the AWS Virginia (us-east-1) Region within the
CaMeLz-Development Account.


## Dependencies

**TODO**: Determine Dependencies and list.

## Global Testing Topics

1. **Set Profile for Development Account**

    ```bash
    profile=$development_profile
    ```

1. **Create Testing Events Topic**

    ```bash
    global_testing_events_topic_arn=$(aws sns create-topic --name Events \
                                                           --attributes "DisplayName=CMLT Events" \
                                                           --tags Key=Name,Value=Testing-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Testing \
                                                           --query 'TopicArn' \
                                                           --profile $profile --region us-east-1 --output text)
    camelz-variable global_testing_events_topic_arn
    ```

1. **Create Testing Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_testing_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Testing Alarms Topic**

    ```bash
    global_testing_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                           --attributes "DisplayName=CMLT Alarms" \
                                                           --tags Key=Name,Value=Testing-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Testing \
                                                           --query 'TopicArn' \
                                                           --profile $profile --region us-east-1 --output text)
    camelz-variable global_testing_alarms_topic_arn
    ```

1. **Create Testing Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_testing_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```
