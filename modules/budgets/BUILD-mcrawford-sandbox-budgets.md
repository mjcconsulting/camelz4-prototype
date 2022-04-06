# Modules:Budgets:MCrawford Sandbox Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
MCrawford-CaMeLz-Sandbox Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global MCrawford-Sandbox Budgets Topic

1. **Set Profile for MCrawford-Sandbox Account**

    ```bash
    profile=$mcrawford_sandbox_profile
    ```

1. **Create MCrawford-Sandbox Budgets Topic**

    ```bash
    mcrawford_global_sandbox_budgets_topic_arn=$(aws sns create-topic --name Budgets \
                                                                      --attributes "DisplayName=MJCX Budgets" \
                                                                      --tags Key=Name,Value=MCrawford-Sandbox-Budgets-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Sandbox \
                                                                      --query 'TopicArn' \
                                                                      --profile $profile --region us-east-1 --output text)
    camelz-variable mcrawford_global_sandbox_budgets_topic_arn

    tmpfile=$CAMELZ_HOME/tmp/mcrawford-global-sandbox-budgets-topic-$$.json
    sed -e "s/@topicarn@/$mcrawford_global_sandbox_budgets_topic_arn/g" \
        $CAMELZ_HOME/policies/BudgetsTopicPolicy-Template.json > $tmpfile

    aws sns set-topic-attributes --topic-arn $mcrawford_global_sandbox_budgets_topic_arn \
                                 --attribute-name Policy \
                                 --attribute-value file://$tmpfile \
                                 --profile $profile --region us-east-1
    ```

1. **Create MCrawford-Sandbox Budgets Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $mcrawford_global_sandbox_budgets_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create MCrawford-Sandbox Budget**

    We will create a simple monthly cost budget for the amount described in `constants`. Then, we will add the following
    notifications:

    - 100% of actual
    - 75% of actual
    - 50% of actual
    - 100% of forecast
    - 75% of forecast

    ```bash
    aws budgets create-budget --account-id $mcrawford_sandbox_account_id \
                              --budget "BudgetName=$mcrawford_sandbox_account_budget_name,BudgetType=COST,TimeUnit=MONTHLY,BudgetLimit={Amount=$mcrawford_sandbox_account_budget_amount,Unit=USD}" \
                              --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $mcrawford_sandbox_account_id \
                                    --budget-name $mcrawford_sandbox_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$mcrawford_global_sandbox_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $mcrawford_sandbox_account_id \
                                    --budget-name $mcrawford_sandbox_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=75,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$mcrawford_global_sandbox_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $mcrawford_sandbox_account_id \
                                    --budget-name $mcrawford_sandbox_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=50,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$mcrawford_global_sandbox_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $mcrawford_sandbox_account_id \
                                    --budget-name $mcrawford_sandbox_account_budget_name \
                                    --notification "NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$mcrawford_global_sandbox_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $mcrawford_sandbox_account_id \
                                    --budget-name $mcrawford_sandbox_account_budget_name \
                                    --notification "NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=75,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$mcrawford_global_sandbox_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text
    ```
