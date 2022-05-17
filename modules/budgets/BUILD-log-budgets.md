# Modules:Budgets:Log Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
CaMeLz-Log Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Log Budgets Topic

1. **Set Profile for Log Account**

    ```bash
    profile=$log_profile
    ```

1. **Create Log Budgets Topic**

    ```bash
    global_log_budgets_topic_arn=$(aws sns create-topic --name Budgets \
                                                        --attributes "DisplayName=CMLL Budgets" \
                                                        --tags Key=Name,Value=Log-Budgets-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Log \
                                                        --query 'TopicArn' \
                                                        --profile $profile --region us-east-1 --output text)
    camelz-variable global_log_budgets_topic_arn

    tmpfile=$CAMELZ_HOME/tmp/global-log-budgets-topic-$$.json
    sed -e "s/@topicarn@/$global_log_budgets_topic_arn/g" \
        $CAMELZ_HOME/policies/BudgetsTopicPolicy-Template.json > $tmpfile

    aws sns set-topic-attributes --topic-arn $global_log_budgets_topic_arn \
                                 --attribute-name Policy \
                                 --attribute-value file://$tmpfile \
                                 --profile $profile --region us-east-1
    ```

1. **Create Log Budgets Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_log_budgets_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-la-budgets@camelz.io \
                      --profile $profile --region us-east-1 --output text
    ```

## Global Log Budgets

1. **Create Log Budget**

    We will create a simple monthly cost budget for the amount described in `constants`. Then, we will add the following
    notifications:

    - 100% of actual
    - 75% of actual
    - 50% of actual
    - 100% of forecast
    - 75% of forecast

    ```bash
    aws budgets create-budget --account-id $log_account_id \
                              --budget "BudgetName=$log_account_budget_name,BudgetType=COST,TimeUnit=MONTHLY,BudgetLimit={Amount=$log_account_budget_amount,Unit=USD}" \
                              --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $log_account_id \
                                    --budget-name $log_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_log_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $log_account_id \
                                    --budget-name $log_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=75,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_log_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $log_account_id \
                                    --budget-name $log_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=50,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_log_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $log_account_id \
                                    --budget-name $log_account_budget_name \
                                    --notification "NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_log_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $log_account_id \
                                    --budget-name $log_account_budget_name \
                                    --notification "NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=75,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_log_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text
    ```
