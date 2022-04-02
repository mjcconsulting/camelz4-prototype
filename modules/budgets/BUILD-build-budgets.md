# Modules:Budgets:Build Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
CaMeLz-Build Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Build Bills Topic

1. **Set Profile for Build Account**

    ```bash
    profile=$build_profile
    ```

1. **Create Build Bills Topic**

    ```bash
    global_build_bills_topic_arn=$(aws sns create-topic --name Bills \
                                                        --attributes "DisplayName=CMLB Bills" \
                                                        --tags Key=Name,Value=Build-Bills-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Build \
                                                        --query 'TopicArn' \
                                                        --profile $profile --region us-east-1 --output text)
    camelz-variable global_build_bills_topic_arn
    ```

1. **Create Build Bills Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_build_bills_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Build Budget**
