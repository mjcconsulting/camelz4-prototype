# Modules:Budgets:Recovery Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
CaMeLz-Recovery Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Recovery Budgets Topic

1. **Set Profile for Recovery Account**

    ```bash
    profile=$recovery_profile
    ```

1. **Create Recovery Budgets Topic**

    ```bash
    global_recovery_budgets_topic_arn=$(aws sns create-topic --name Budgets \
                                                             --attributes "DisplayName=CMLR Budgets" \
                                                             --tags Key=Name,Value=Recovery-Budgets-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Recovery \
                                                             --query 'TopicArn' \
                                                             --profile $profile --region us-east-1 --output text)
    camelz-variable global_recovery_budgets_topic_arn

    tmpfile=$CAMELZ_HOME/tmp/global-recovery-budgets-topic-$$.json
    sed -e "s/@topicarn@/$global_recovery_budgets_topic_arn/g" \
        $CAMELZ_HOME/policies/BudgetsTopicPolicy-Template.json > $tmpfile

    aws sns set-topic-attributes --topic-arn $global_recovery_budgets_topic_arn \
                                 --attribute-name Policy \
                                 --attribute-value file://$tmpfile \
                                 --profile $profile --region us-east-1
    ```

1. **Create Recovery Budgets Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_recovery_budgets_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Recovery Budget**

    We will create a simple monthly cost budget for the amount described in `constants`. Then, we will add the following
    notifications:

    - 100% of actual
    - 75% of actual
    - 50% of actual
    - 100% of forecast
    - 75% of forecast

    ```bash
    aws budgets create-budget --account-id $recovery_account_id \
                              --budget "BudgetName=$recovery_account_budget_name,BudgetType=COST,TimeUnit=MONTHLY,BudgetLimit={Amount=$recovery_account_budget_amount,Unit=USD}" \
                              --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $recovery_account_id \
                                    --budget-name $recovery_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_recovery_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $recovery_account_id \
                                    --budget-name $recovery_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=75,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_recovery_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $recovery_account_id \
                                    --budget-name $recovery_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=50,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_recovery_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $recovery_account_id \
                                    --budget-name $recovery_account_budget_name \
                                    --notification "NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_recovery_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $recovery_account_id \
                                    --budget-name $recovery_account_budget_name \
                                    --notification "NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=75,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_recovery_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text
    ```
