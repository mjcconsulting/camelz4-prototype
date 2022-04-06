# Modules:SSM Associations

This Module builds SSM Associations

Some Associations reference Application Software Installers which are assumed to have been uploaded to the
installers-camelzm S3 bucket in a prior build step.

**CAUTION**: Do not run this yet. This section has not been tested, so it may have unknown interactions with explicit
installation of the same applications done via cloud-init.

**TODO**: More description coming

## Dependencies

**TODO**: Determine Module Pre-Requisites and List here

## Build SSM Associations

This is the list of SSM Associations to be created within the Management Account.

**WIP**: This is initially a copy of some partially working code from the CaMeLz3-Prototype that was not used, in case
we may want to use it here. This needs more work and testing before it's ready for use.

### **Management Account**

#### **Global**

1. **[SSM Associations](./BUILD-management-global-ssm-associations.md)**

#### **Ohio Region**

1. **[SSM Associations](./BUILD-management-ohio-ssm-associations.md)**

#### **Oregon Region**

1. **[SSM Associations](./BUILD-management-oregon-ssm-associations.md)**

**NOTE**: I think we need to create the SSM Associations explicitly in each Account, can't share globally like Documents.
