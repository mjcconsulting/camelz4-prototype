# Modules:Budgets:MCrawfordSandbox Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
MCrawford-CaMeLz-Sandbox Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global MCrawford-Sandbox Bills Topic

1. **Set Profile for MCrawford-Sandbox Account**

    ```bash
    profile=$mcrawford_sandbox_profile
    ```

1. **Create MCrawford-Sandbox Bills Topic**

    ```bash
    mcrawford_global_sandbox_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                                    --attributes "DisplayName=MJCX Bills" \
                                                                    --tags Key=Name,Value=MCrawford-Sandbox-Bills-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Sandbox \
                                                                    --query 'TopicArn' \
                                                                    --profile $profile --region us-east-1 --output text)
    camelz-variable mcrawford_global_sandbox_bills_topic_arn
    ```

1. **Create MCrawford-Sandbox Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $mcrawford_global_sandbox_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create MCrawford-Sandbox Budget**
