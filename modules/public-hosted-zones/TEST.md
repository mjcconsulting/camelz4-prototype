# Modules:Public Hosted Zones - Test

This Page tests all Route 53 Public Hosted Zones

**TODO**: More description coming

## Dependencies

**TODO**: Determine Module Pre-Requisites and List here

## Test Public Hosted Zones

Test check records are returned for all public zones in a single script block.

```bash

hostedzones="\
$global_management_public_domain \
$global_log_public_domain \
$global_audit_public_domain \
$global_network_public_domain \
$global_core_public_domain \
$global_build_public_domain \
$global_production_public_domain \
$global_recovery_public_domain \
$global_staging_public_domain \
$global_testing_public_domain \
$global_development_public_domain \
$ohio_management_public_domain \
$ohio_log_public_domain \
$ohio_audit_public_domain \
$ohio_network_public_domain \
$ohio_core_public_domain \
$ohio_production_public_domain \
$ohio_recovery_public_domain \
$ohio_staging_public_domain \
$ohio_testing_public_domain \
$ohio_development_public_domain \
$alfa_ohio_production_public_domain \
$alfa_ohio_testing_public_domain \
$alfa_ohio_development_public_domain \
$zulu_ohio_production_public_domain \
$zulu_ohio_development_public_domain \
$oregon_management_public_domain \
$oregon_log_public_domain \
$oregon_audit_public_domain \
$oregon_network_public_domain \
$oregon_core_public_domain \
$oregon_production_public_domain \
$oregon_recovery_public_domain \
$oregon_staging_public_domain \
$oregon_testing_public_domain \
$oregon_development_public_domain \
$alfa_global_management_public_domain \
$alfa_ohio_management_public_domain \
$alfa_ohio_production_private_domain \
$alfa_ohio_testing_public_domain \
$alfa_ohio_development_public_domain \
$alfa_oregon_management_public_domain \
$alfa_oregon_recovery_public_domain \
$zulu_global_management_public_domain \
$zulu_ohio_management_public_domain \
$zulu_ohio_production_public_domain \
$zulu_ohio_development_public_domain \
$cml_sba_public_domain \
$alfa_lax_public_domain \
$alfa_mia_public_domain \
$zulu_dfw_public_domain"

for hz in $(echo $hostedzones); do
    if [ -z $(dig +short -t TXT check.$hz) ]; then
        printf '%30s Does not resolve or missing check record\n' $hz
    else
        printf '%30s OK\n' $hz
    fi
done
```