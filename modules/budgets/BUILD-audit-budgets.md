# Modules:Budgets:Audit Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
CaMeLz-Audit Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Audit Bills Topic

1. **Set Profile for Audit Account**

    ```bash
    profile=$audit_profile
    ```

1. **Create Audit Bills Topic**

    ```bash
    global_audit_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                        --attributes "DisplayName=CMLA Bills" \
                                                        --tags Key=Name,Value=Audit-Bills-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Audit \
                                                        --query 'TopicArn' \
                                                        --profile $profile --region us-east-1 --output text)
    camelz-variable global_audit_bills_topic_arn
    ```

1. **Create Audit Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_audit_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Audit Budget**
