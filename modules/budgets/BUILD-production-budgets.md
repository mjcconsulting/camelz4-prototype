# Modules:Budgets:Production Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
CaMeLz-Production Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Production Budgets Topic

1. **Set Profile for Production Account**

    ```bash
    profile=$production_profile
    ```

1. **Create Production Budgets Topic**

    ```bash
    global_production_budgets_topic_arn=$(aws sns create-topic --name Budgets \
                                                               --attributes "DisplayName=CMLP Budgets" \
                                                               --tags Key=Name,Value=Production-Budgets-Topic Key=Company,Value=CaMeLz Key=Environment,Value=Production \
                                                               --query 'TopicArn' \
                                                               --profile $profile --region us-east-1 --output text)
    camelz-variable global_production_budgets_topic_arn

    tmpfile=$CAMELZ_HOME/tmp/global-production-budgets-topic-$$.json
    sed -e "s/@topicarn@/$global_production_budgets_topic_arn/g" \
        $CAMELZ_HOME/policies/BudgetsTopicPolicy-Template.json > $tmpfile

    aws sns set-topic-attributes --topic-arn $global_production_budgets_topic_arn \
                                 --attribute-name Policy \
                                 --attribute-value file://$tmpfile \
                                 --profile $profile --region us-east-1
    ```

1. **Create Production Budgets Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $global_production_budgets_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Production Budget**

    We will create a simple monthly cost budget for the amount described in `constants`. Then, we will add the following
    notifications:

    - 100% of actual
    - 75% of actual
    - 50% of actual
    - 100% of forecast
    - 75% of forecast

    ```bash
    aws budgets create-budget --account-id $production_account_id \
                              --budget "BudgetName=$production_account_budget_name,BudgetType=COST,TimeUnit=MONTHLY,BudgetLimit={Amount=$production_account_budget_amount,Unit=USD}" \
                              --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $production_account_id \
                                    --budget-name $production_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_production_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $production_account_id \
                                    --budget-name $production_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=75,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_production_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $production_account_id \
                                    --budget-name $production_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=50,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_production_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $production_account_id \
                                    --budget-name $production_account_budget_name \
                                    --notification "NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_production_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $production_account_id \
                                    --budget-name $production_account_budget_name \
                                    --notification "NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=75,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$global_production_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text
    ```