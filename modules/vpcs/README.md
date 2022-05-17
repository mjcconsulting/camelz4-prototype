# Modules:VPCs

This Module builds VPCs

**TODO**: More description coming

## Dependencies

**TODO**: Determine Module Pre-Requisites and List here

## Build VPCs

This is the list of VPCs to be created, along with a description of what should be in each of them. More of these will
be created initially than we may want to keep, just so we insure all will work if it turns out we need them in the
future.

### **Management Account**

#### **Global**

1. **[Management-VPC](./BUILD-management-global-management-vpc.md)** (camelz.io)
    - Global Directory Service
    - Global AD Management Workstation
    - Other Resources which require Organization Sharing and have Global Scope

#### **Ohio Region**

1. **[Management-VPC](./BUILD-management-ohio-management-vpc.md)** (us-east-2.camelz.io)
    - Region Directory Service in Ohio, or this may be Region DCs for Global Directory Service
    - Region AD Management Workstation
    - Other Resources which require Organization Sharing and have Region Scope
1. **[Alfa-Management-VPC](./BUILD-management-ohio-alfa-management-vpc.md)** (us-east-2.alfa.camelz.io)
    - Region Directory Service for Alfa in Ohio
    - Region AD Management Workstation for Alfa in Ohio
    - This will run here if one directory for all Environments, or in each Environment if separate
1. **[Zulu-Management-VPC](./BUILD-management-ohio-zulu-management-vpc.md)** (us-east-2.zulu.camelz.io)
    - Region Directory Service for Zulu in Ohio
    - Region AD Management Workstation for Zulu in Ohio
    - This will run here if one directory for all Environments, or in each Environment if separate

#### **Oregon Region**

1. **[Management-VPC](./BUILD-management-oregon-management-vpc.md)** (us-west-2.camelz.io)
    - Region Directory Service in Oregon, or this may be Region DCs for Global Directory Service
    - Region AD Management Workstation
    - Other Resources which require Organization Sharing and have Region Scope
1. **[Alfa-Management-VPC](./BUILD-management-oregon-alfa-management-vpc.md)** (us-west-2.alfa.camelz.io)
    - Region Directory Service for Alfa in Oregon
    - Region AD Management Workstation for Alfa in Oregon
    - This will run here if one directory for all Environments, or in each Environment if separate

### **Network Account**

#### **Global**

1. **[Network-VPC](./BUILD-network-global-network-vpc.md)** (n.camelz.io)
    - Ingress/Egress VPC in Global? Is this needed?

#### **Ohio Region**

1. **[Network-VPC](./BUILD-network-ohio-network-vpc.md)** (n.us-east-2.camelz.io)
    - Ingress/Egress VPC in Ohio
1. **[CaMeLz-SantaBarbara-DataCenter-VPC](./BUILD-network-ohio-santabarbara-datacenter-vpc.md)** (sba.camelz.io)
    - Resources for Simulated CaMeLz Data Center in Santa Barbara
1. **[Alfa-LosAngeles-DataCenter-VPC](./BUILD-network-ohio-losangeles-alfa-datacenter-vpc.md)** (lax.alfa.camelz.io)
    - Resources for Simulated Alfa Data Center in Los Angles
1. **[Alfa-Miami-DataCenter-VPC](./BUILD-network-ohio-miami-alfa-datacenter-vpc.md)** (mia.alfa.camelz.io)
    - Resources for Simulated Alfa Data Center in Miami
1. **[Zulu-Dallas-DataCenter-VPC](./BUILD-network-ohio-dallas-zulu-datacenter-vpc.md)** (dfw.zulu.camelz.io)
    - Resources for Simulated Zulu Data Center in Dallas

#### **Oregon Region**

1. **[Network-VPC](./BUILD-network-oregon-network-vpc.md)** (n.us-west-2.camelz.io)
    - Ingress/Egress VPC in Oregon

### **Core Account**

#### **Global**

1. **[Core-VPC](./BUILD-core-global-core-vpc.md)** (c.camelz.io)
    - Global Shared Infrastructure, which should not be in Management Account
    - Not sure anything exists in this category, it should be regional, not global

#### **Ohio Region**

1. **[Core-VPC](./BUILD-core-ohio-core-vpc.md)** (c.us-east-2.camelz.io)
    - Shared Services Instances in Ohio

#### **Oregon Region**

1. **[Core-VPC](./BUILD-core-oregon-core-vpc.md)** (c.us-west-2.camelz.io)
    - Shared Services Instances in Oregon

### **Sandbox Accounts**

#### **Oregon**

1. **[MCrawford-Sandbox-VPC](./BUILD-mcrawford-sandbox-oregon-mcrawford-sandbox-vpc.md)** (mcrawford.x.us-west-2.camelz.io)
    - Sandbox Instances for MCrawford Developer in Oregon

### **Build Account**

#### **Global**

1. **[Build-VPC](./BUILD-build-global-build-vpc.md)** (b.camelz.io)
    - Build & Deployment Instances in Global

#### **Ohio Region**

1. **[Build-VPC](./BUILD-build-ohio-build-vpc.md)** (b.us-east-2.camelz.io)
    - Build & Deployment Instances in Ohio, but will publish to all regions
    - We will likely have only this or the global build VPC

### **Production Account**

#### **Ohio Region**

1. **[Production-VPC](./BUILD-production-ohio-production-vpc.md)** (p.us-east-2.camelz.io)
    - Production Instances in Ohio

#### **Oregon Region**

1. **[Production-VPC](./BUILD-production-oregon-production-vpc.md)** (p.us-west-2.camelz.io)
    - Production Instances in Oregon

### **Recovery Account**

#### **Oregon Region**

1. **[Recovery-VPC](./BUILD-recovery-oregon-recovery-vpc.md)** (r.us-west-2.camelz.io)
    - Recovery Instances in Oregon

### **Development Account**

#### **Ohio Region**

1. **[Testing-VPC](./BUILD-development-ohio-testing-vpc.md)** (t.us-east-2.camelz.io)
    - Testing Instances in Ohio
1. **[Development-VPC](./BUILD-development-ohio-development-vpc.md)** (d.us-east-2.camelz.io)
    - Development Instances in Ohio

### **Alfa-Production Account**

#### **Ohio Region**

1. **[Alfa-Production-VPC](./BUILD-alfa-production-ohio-alfa-production-vpc.md)** (p.us-east-2.alfa.camelz.io)
    - Production Instances for Alfa in Ohio

#### **Oregon Region**

1. **[Alfa-Production-VPC](./BUILD-alfa-production-oregon-alfa-production-vpc.md)** (p.us-west-2.alfa.camelz.io)
    - Production Instances for Alfa in Oregon

### **Alfa-Recovery Account**

#### **Oregon Region**

1. **[Alfa-Recovery-VPC](./BUILD-alfa-recovery-oregon-alfa-recovery-vpc.md)** (r.us-west-2.alfa.camelz.io)
    - Recovery Instances for Alfa in Oregon

### **Alfa-Development Account**

#### **Ohio Region**

1. **[Alfa-Testing-VPC](./BUILD-alfa-development-ohio-alfa-testing-vpc.md)** (t.us-east-2.alfa.camelz.io)
    - Testing Instances for Alfa in Ohio
1. **[Alfa-Development-VPC](./BUILD-alfa-development-ohio-alfa-development-vpc.md)** (d.us-east-2.alfa.camelz.io)
    - Development Instances for Alfa in Ohio

### **Zulu-Production Account**

#### **Ohio Region**

1. **[Zulu-Production-VPC](./BUILD-zulu-production-ohio-zulu-production-vpc.md)** (p.us-east-2.zulu.camelz.io)
    - Production Instances for Zulu in Ohio

### **Zulu-Development Account**

#### **Ohio Region**

1. **[Zulu-Development VPC](./BUILD-zulu-development-ohio-zulu-development-vpc.md)** (d.us-east-2.zulu.camelz.io)
    - Development Instances for Zulu in Ohio

## Tag Default-VPCs

This section tags existing Default-VPCs, so their Resources appear tagged and are sortable in lists.

### **Management Account**

#### **Global**

1. **[Default-VPC](./TAG-management-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-management-ohio-default-vpc.md)**

#### **Oregon Region**

1. **[Default-VPC](./TAG-management-oregon-default-vpc.md)**

### **Audit Account**

#### **Global**

1. **[Default-VPC](./TAG-audit-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-audit-ohio-default-vpc.md)**

#### **Oregon Region**

1. **[Default-VPC](./TAG-audit-oregon-default-vpc.md)**

### **Network Account**

#### **Global**

1. **[Default-VPC](./TAG-network-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-network-ohio-default-vpc.md)**

#### **Oregon Region**

1. **[Default-VPC](./TAG-network-oregon-default-vpc.md)**

### **Core Account**

#### **Global**

1. **[Default-VPC](./TAG-core-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-core-ohio-default-vpc.md)**

#### **Oregon Region**

1. **[Default-VPC](./TAG-core-oregon-default-vpc.md)**

### **Sandbox Accounts**

#### **Global**

1. **[Default-VPC](./TAG-mcrawford-sandbox-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-mcrawford-sandbox-ohio-default-vpc.md)**

#### **Oregon Region**

1. **[Default-VPC](./TAG-mcrawford-sandbox-oregon-default-vpc.md)**

### **Build Account**

#### **Global**

1. **[Default-VPC](./TAG-build-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-build-ohio-default-vpc.md)**

#### **Oregon**

1. **[Default-VPC](./TAG-build-oregon-default-vpc.md)**

### **Production Account**

#### **Global**

1. **[Default-VPC](./TAG-production-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-production-ohio-default-vpc.md)**

#### **Oregon Region**

1. **[Default-VPC](./TAG-production-oregon-default-vpc.md)**

### **Recovery Account**

#### **Global**

1. **[Default-VPC](./TAG-recovery-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-recovery-ohio-default-vpc.md)**

#### **Oregon Region**

1. **[Default-VPC](./TAG-recovery-oregon-default-vpc.md)**

### **Development Account**

#### **Global**

1. **[Default-VPC](./TAG-development-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-development-ohio-default-vpc.md)**

#### **Oregon Region**

1. **[Default-VPC](./TAG-development-oregon-default-vpc.md)**

### **Alfa-Production Account**

#### **Global**

1. **[Default-VPC](./TAG-alfa-production-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-alfa-production-ohio-default-vpc.md)**

#### **Oregon Region**

1. **[Default-VPC](./TAG-alfa-production-oregon-default-vpc.md)**

### **Alfa-Recovery Account**

#### **Global**

1. **[Default-VPC](./TAG-alfa-recovery-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-alfa-recovery-ohio-default-vpc.md)**

#### **Oregon Region**

1. **[Default-VPC](./TAG-alfa-recovery-oregon-default-vpc.md)**

### **Alfa-Development Account**

1. **[Default-VPC](./TAG-alfa-development-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-alfa-development-ohio-default-vpc.md)**

#### **Oregon Region**

1. **[Default-VPC](./TAG-alfa-development-oregon-default-vpc.md)**

### **Zulu-Production Account**

1. **[Default-VPC](./TAG-zulu-production-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-zulu-production-ohio-default-vpc.md)**

#### **Oregon Region**

1. **[Default-VPC](./TAG-zulu-production-oregon-default-vpc.md)**

### **Zulu-Development Account**

1. **[Default-VPC](./TAG-zulu-development-global-default-vpc.md)**

#### **Ohio Region**

1. **[Default-VPC](./TAG-zulu-development-ohio-default-vpc.md)**

#### **Oregon Region**

1. **[Default-VPC](./TAG-zulu-development-oregon-default-vpc.md)**
