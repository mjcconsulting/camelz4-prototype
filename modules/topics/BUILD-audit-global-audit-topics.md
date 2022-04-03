# Modules:Topics:Audit Account:Global:Audit Topics

This module creates Audit Topics & Subscriptions in the AWS Virginia (us-east-1) Region within the
CaMeLz-Audit Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Audit Topics

1. **Set Profile for Audit Account**

    ```bash
    profile=$audit_profile
    ```

1. **Create Audit Events Topic**

    ```bash
    global_audit_events_topic_arn=$(aws sns create-topic --name Events \
                                                         --attributes "DisplayName=CMLA Events" \
                                                         --tags Key=Name,Value=Audit-Events-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Audit \
                                                         --query 'TopicArn' \
                                                         --profile $profile --region us-east-1 --output text)
    camelz-variable global_audit_events_topic_arn
    ```

1. **Create Audit Events Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_audit_events_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Audit Alarms Topic**

    ```bash
    global_audit_alarms_topic_arn=$(aws sns create-topic --name Alarms \
                                                         --attributes "DisplayName=CMLA Alarms" \
                                                         --tags Key=Name,Value=Audit-Alarms-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Audit \
                                                         --query 'TopicArn' \
                                                         --profile $profile --region us-east-1 --output text)
    camelz-variable global_audit_alarms_topic_arn
    ```

1. **Create Audit Alarms Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_audit_alarms_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```
