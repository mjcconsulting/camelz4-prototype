# Modules:Budgets:Alfa Development Account

This module creates Budgets in the AWS Virginia (us-east-1) Region within the
Alfa-CaMeLz-Development Account.

## Dependencies

**TODO**: Determine Dependencies and list.

## Global Alfa-Development Budgets Topic

1. **Set Profile for Alfa-Development Account**

    ```bash
    profile=$alfa_development_profile
    ```

1. **Create Alfa-Development Budgets Topic**

    ```bash
    alfa_global_development_budgets_topic_arn=$(aws sns create-topic --name Budgets \
                                                                     --attributes "DisplayName=ALFD Budgets" \
                                                                     --tags Key=Name,Value=Alfa-Development-Budgets-Topic Key=Company,Value=Alfa Key=Environment,Value=Development \
                                                                     --query 'TopicArn' \
                                                                     --profile $profile --region us-east-1 --output text)
    camelz-variable alfa_global_development_budgets_topic_arn

    tmpfile=$CAMELZ_HOME/tmp/alfa-global-development-budgets-topic-$$.json
    sed -e "s/@topicarn@/$alfa_global_development_budgets_topic_arn/g" \
        $CAMELZ_HOME/policies/BudgetsTopicPolicy-Template.json > $tmpfile

    aws sns set-topic-attributes --topic-arn $alfa_global_development_budgets_topic_arn \
                                 --attribute-name Policy \
                                 --attribute-value file://$tmpfile \
                                 --profile $profile --region us-east-1
    ```

1. **Create Alfa-Development Budgets Subscriptions**

    ```bash
    aws sns subscribe --topic-arn $alfa_global_development_budgets_topic_arn \
                      --protocol email \
                      --notification-endpoint $user_email \
                      --profile $profile --region us-east-1 --output text
    ```

1. **Create Alfa-Development Budget**

    We will create a simple monthly cost budget for the amount described in `constants`. Then, we will add the following
    notifications:

    - 100% of actual
    - 75% of actual
    - 50% of actual
    - 100% of forecast
    - 75% of forecast

    ```bash
    aws budgets create-budget --account-id $alfa_development_account_id \
                              --budget "BudgetName=$alfa_development_account_budget_name,BudgetType=COST,TimeUnit=MONTHLY,BudgetLimit={Amount=$alfa_development_account_budget_amount,Unit=USD}" \
                              --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $alfa_development_account_id \
                                    --budget-name $alfa_development_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$alfa_global_development_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $alfa_development_account_id \
                                    --budget-name $alfa_development_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=75,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$alfa_global_development_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $alfa_development_account_id \
                                    --budget-name $alfa_development_account_budget_name \
                                    --notification "NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=50,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$alfa_global_development_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $alfa_development_account_id \
                                    --budget-name $alfa_development_account_budget_name \
                                    --notification "NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$alfa_global_development_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text

    aws budgets create-notification --account-id $alfa_development_account_id \
                                    --budget-name $alfa_development_account_budget_name \
                                    --notification "NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=75,ThresholdType=PERCENTAGE" \
                                    --subscriber "SubscriptionType=SNS,Address=$alfa_global_development_budgets_topic_arn" \
                                    --profile $profile --region us-east-1 --output text
    ```
