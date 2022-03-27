# Modules:Organization
This Module builds the Organization and Organizational Units.

TODO: More description coming

Since all configuration of Control Tower, Organizations and Accounts was done by hand for the initial CaMeLz-POC-4
implementation, we need to come back and capture the manual steps (Control Tower does not have an API or CLI section) 
at a later point in time.

Now, we just need to confirm the management profile works and save the Organization, Root and OU Identifiers in the
variables file. It's simpler to just do all this in this top section instead of breaking them out, so that's what will
initially be done here.

## Management Account

1. **Set Profile for Management Account**
    ```bash
    profile=$management_profile
    ```

1.  **Get Organization ID**
    ```bash
    org_id=$(aws organizations describe-organization --query 'Organization.Id' \
                                                     --profile $profile --region us-east-1 --output text)
    camelz-variable org_id
    ```

1.  **Get Organization Root ID**
    ```bash
    root_id=$(aws organizations list-roots --query 'Roots[0].Id' \
                                          --profile $profile --region us-east-1 --output text)
    camelz-variable root_id
    ```

1.  **Get Security Organization Unit ID**
    ```bash
    security_ou_id$(aws organizations list-organizational-units-for-parent --parent-id $root_id \
                                                                           --query 'OrganizationalUnits[?Name==`Security`].Id' \
                                                                           --profile $profile --region us-east-1 --output text)
    camelz-variable security_ou_id
    ```

1.  **Get Infrastructure Organization Unit ID**
    ```bash
    infrastructure_ou_id$(aws organizations list-organizational-units-for-parent --parent-id $root_id \
                                                                                 --query 'OrganizationalUnits[?Name==`Infrastructure`].Id' \
                                                                                 --profile $profile --region us-east-1 --output text)
    camelz-variable infrastructure_ou_id
    ```

1.  **Get Sandbox Organization Unit ID**
    ```bash
    sandbox_ou_id$(aws organizations list-organizational-units-for-parent --parent-id $root_id \
                                                                          --query 'OrganizationalUnits[?Name==`Sandbox`].Id' \
                                                                          --profile $profile --region us-east-1 --output text)
    camelz-variable sandbox_ou_id
    ```

1.  **Get Workloads Organization Unit ID**
    ```bash
    workloads_ou_id$(aws organizations list-organizational-units-for-parent --parent-id $root_id \
                                                                            --query 'OrganizationalUnits[?Name==`Workloads`].Id' \
                                                                            --profile $profile --region us-east-1 --output text)
    camelz-variable workloads_ou_id
    ```

1.  **Get Workloads>Production Organization Unit ID**
    ```bash
    workloads_production_ou_id$(aws organizations list-organizational-units-for-parent --parent-id $workloads_ou_id \
                                                                                       --query 'OrganizationalUnits[?Name==`Production`].Id' \
                                                                                       --profile $profile --region us-east-1 --output text)
    camelz-variable workloads_production_ou_id
    ```

1.  **Get Workloads>NonProduction Organization Unit ID**
    ```bash
    workloads_nonproduction_ou_id$(aws organizations list-organizational-units-for-parent --parent-id $workloads_ou_id \
                                                                                          --query 'OrganizationalUnits[?Name==`NonProduction`].Id' \
                                                                                          --profile $profile --region us-east-1 --output text)
    camelz-variable workloads_nonproduction_ou_id
    ```

1.  **Get Deployments Organization Unit ID**
    ```bash
    deployments_ou_id$(aws organizations list-organizational-units-for-parent --parent-id $root_id \
                                                                              --query 'OrganizationalUnits[?Name==`Deployments`].Id' \
                                                                              --profile $profile --region us-east-1 --output text)
    camelz-variable deployments_ou_id
    ```

1.  **Get Deployments>Production Organization Unit ID**
    ```bash
    deployments_production_ou_id$(aws organizations list-organizational-units-for-parent --parent-id $deployments_ou_id \
                                                                                         --query 'OrganizationalUnits[?Name==`Production`].Id' \
                                                                                         --profile $profile --region us-east-1 --output text)
    camelz-variable deployments_production_ou_id
    ```