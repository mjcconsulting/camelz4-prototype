# Modules:Topics:Development Account:Ohio:Testing Topics

This module creates Testing Topics & Subscriptions in the AWS Ohio (us-east-2) Region within the
CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Testing Topics

1. **Set Profile for Development Account**

    ```bash
    profile=$development_profile
    ```

1. **Create Testing Events Topic**

    ```bash
    ohio_testing_events_topic_arn=$(aws sns create-topic --name Testing-Events \
                                                         --attributes "DisplayName=CMLT Events" \
                                                         --tags Key=Name,Value=Testing-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Testing \
                                                         --query 'TopicArn' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_testing_events_topic_arn
    ```

1. **Create Testing Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_testing_events_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-t-events@camelz.io \
                      --profile $profile --region us-east-2 --output text
    ```

1. **Create Testing Alarms Topic**

    ```bash
    ohio_testing_alarms_topic_arn=$(aws sns create-topic --name Testing-Alarms \
                                                         --attributes "DisplayName=CMLT Alarms" \
                                                         --tags Key=Name,Value=Testing-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Testing \
                                                         --query 'TopicArn' \
                                                         --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_testing_alarms_topic_arn
    ```

1. **Create Testing Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_testing_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-t-alarms@camelz.io \
                      --profile $profile --region us-east-2 --output text
    ```
