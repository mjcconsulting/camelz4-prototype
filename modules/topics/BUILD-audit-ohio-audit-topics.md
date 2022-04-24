# Modules:Topics:Audit Account:Ohio:Audit Topics

This module creates Audit Topics & Subscriptions in the AWS Ohio (us-east-2) Region within the
CaMeLz-Audit Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Ohio Audit Topics

1. **Set Profile for Audit Account**

    ```bash
    profile=$audit_profile
    ```

1. **Create Audit Events Topic**

    ```bash
    ohio_audit_events_topic_arn=$(aws sns create-topic --name Audit-Events \
                                                       --attributes "DisplayName=CMLA Events" \
                                                       --tags Key=Name,Value=Audit-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Audit \
                                                       --query 'TopicArn' \
                                                       --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_audit_events_topic_arn
    ```

1. **Create Audit Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_audit_events_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-a-events@camelz.io \
                      --profile $profile --region us-east-2 --output text
    ```

1. **Create Audit Alarms Topic**

    ```bash
    ohio_audit_alarms_topic_arn=$(aws sns create-topic --name Audit-Alarms \
                                                       --attributes "DisplayName=CMLA Alarms" \
                                                       --tags Key=Name,Value=Audit-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Audit \
                                                       --query 'TopicArn' \
                                                       --profile $profile --region us-east-2 --output text)
    camelz-variable ohio_audit_alarms_topic_arn
    ```

1. **Create Audit Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $ohio_audit_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-a-alarms@camelz.io \
                      --profile $profile --region us-east-2 --output text
    ```
