
# Modules:Topics:Development Account:Oregon:Testing Topics

This module creates Testing Topics & Subscriptions in the AWS Oregon (us-west-2) Region within the
CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Oregon Testing Topics

1. **Set Profile for Development Account**

    ```bash
    profile=$development_profile
    ```

1. **Create Testing Events Topic**

    ```bash
    oregon_testing_events_topic_arn=$(aws sns create-topic --name Testing-Events \
                                                           --attributes "DisplayName=CMLT Events" \
                                                           --tags Key=Name,Value=Testing-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Testing \
                                                           --query 'TopicArn' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_testing_events_topic_arn
    ```

1. **Create Testing Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $oregon_testing_events_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-t-events@camelz.io \
                      --profile $profile --region us-west-2 --output text
    ```

1. **Create Testing Alarms Topic**

    ```bash
    oregon_testing_alarms_topic_arn=$(aws sns create-topic --name Testing-Alarms \
                                                           --attributes "DisplayName=CMLT Alarms" \
                                                           --tags Key=Name,Value=Testing-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Testing \
                                                           --query 'TopicArn' \
                                                           --profile $profile --region us-west-2 --output text)
    camelz-variable oregon_testing_alarms_topic_arn
    ```

1. **Create Testing Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $oregon_testing_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-t-alarms@camelz.io \
                      --profile $profile --region us-west-2 --output text
    ```
