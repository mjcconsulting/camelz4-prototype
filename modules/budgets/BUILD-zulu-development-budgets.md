# Modules:Budgets:Zulu Development Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
CaMeLz-Zulu-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Zulu-Development Budgets Topic

1. **Set Profile for Zulu-Development Account**

    ```bash
    profile=$zulu_development_profile
    ```

1. **Create Zulu-Development Budgets Topic**

    ```bash
    zulu_global_development_budgets_topic_arn=$(aws sns create-topic --name Budgets \
                                                                     --attributes "DisplayName=ZULD Budgets" \
                                                                     --tags Key=Name,Value=Zulu-Development-Budgets-Topic Key=Company,Value=Zulu Key=Environment,Value=Development \
                                                                     --query 'TopicArn' \
                                                                     --profile $profile --region us-east-1 --output text)
    camelz-variable zulu_global_development_budgets_topic_arn

    tmpfile=$CAMELZ_HOME/tmp/zulu-global-development-budgets-topic-$$.json
    sed -e "s/@topicarn@/$zulu_global_development_budgets_topic_arn/g" \
        $CAMELZ_HOME/policies/BudgetsTopicPolicy-Template.json > $tmpfile

    aws sns set-topic-attributes --topic-arn $zulu_global_development_budgets_topic_arn \
                                 --attribute-name Policy \
                                 --attribute-value file://$tmpfile \
                                 --profile $profile --region us-east-1
    ```

1. **Create Zulu-Development Budgets Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $zulu_global_development_budgets_topic_arn \
                      --protocol email \
                      --notification-endpoint aws-d-zulu-budgets@camelz.io \
                      --profile $profile --region us-east-1 --output text
    ```

## Global Zulu-Development Budgets

1. **Create Zulu-Development Budget**

    We will create a simple monthly cost budget for the amount described in `constants`. Then, we will add the following
    notifications:

    - 100% of actual
    - 75% of actual
    - 50% of actual
    - 100% of forecast
    - 75% of forecast

    ```bash
    aws budgets create-budget --account-id $zulu_development_account_id \
                              --budget "BudgetName=$zulu_development_account_budget_name,BudgetType=COST,TimeUnit=MONTHLY,BudgetLimit={Amount=$zulu_development_account_budget_amount,Unit=USD}" \
                              --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $zulu_development_account_id \
                                    --budget-name $zulu_development_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$zulu_global_development_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $zulu_development_account_id \
                                    --budget-name $zulu_development_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=75,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$zulu_global_development_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $zulu_development_account_id \
                                    --budget-name $zulu_development_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=50,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$zulu_global_development_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $zulu_development_account_id \
                                    --budget-name $zulu_development_account_budget_name \
                                    --notification "NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$zulu_global_development_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $zulu_development_account_id \
                                    --budget-name $zulu_development_account_budget_name \
                                    --notification "NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=75,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$zulu_global_development_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text
    ```
