# Modules:Public Hosted Zones

This Module builds Route 53 Public Hosted Zones

**TODO**: More description coming

## Dependencies

**TODO**: Determine Module Pre-Requisites and List here

## Build Public Hosted Zones

This is the list of Public Hosted Zones to be created.
More of these will be created initially than we may want to keep, just so we insure all will work if it turns out we
need them in the future.

### **Management Account**

#### **Global**

1. **[Management-HostedZone](./BUILD-management-global-management-hostedzone.md)** (camelz.io)
1. **[Alfa-Management-HostedZone](./BUILD-management-global-alfa-management-hostedzone.md)** (alfa.camelz.io)
1. **[Zulu-Management-HostedZone](./BUILD-management-global-zulu-management-hostedzone.md)** (zulu.camelz.io)

#### **Ohio Region**

1. **[Management-HostedZone](./BUILD-management-ohio-management-hostedzone.md)** (us-east-2.camelz.io)
1. **[Alfa-Management-HostedZone](./BUILD-management-ohio-alfa-management-hostedzone.md)** (us-east-2.alfa.camelz.io)
1. **[Zulu-Management-HostedZone](./BUILD-management-ohio-zulu-management-hostedzone.md)** (us-east-2.zulu.camelz.io)

#### **Oregon Region**

1. **[Management-HostedZone](./BUILD-management-oregon-management-hostedzone.md)** (us-west-2.camelz.io)
1. **[Alfa-Management-HostedZone](./BUILD-management-oregon-alfa-management-hostedzone.md)** (us-west-2.alfa.camelz.io)

### **Log Account**

Skip creating these initially. I think we'll only have S3 Buckets in this account, by intent.

#### **Global**

1. **[Log-HostedZone](./BUILD-log-global-log-hostedzone.md)** (l.camelz.io)

#### **Ohio Region**

1. **[Log-HostedZone](./BUILD-log-ohio-log-hostedzone.md)** (l.us-east-2.camelz.io)

#### **Oregon Region**

1. **[Log-HostedZone](./BUILD-log-oregon-log-hostedzone.md)** (l.us-west-2.camelz.io)

### **Audit Account**

#### **Global**

1. **[Audit-HostedZone](./BUILD-audit-global-audit-hostedzone.md)** (a.camelz.io)

#### **Ohio Region**

1. **[Audit-HostedZone](./BUILD-audit-ohio-audit-hostedzone.md)** (a.us-east-2.camelz.io)

#### **Oregon Region**

1. **[Audit-HostedZone](./BUILD-audit-oregon-audit-hostedzone.md)** (a.us-west-2.camelz.io)

### **Network Account**

#### **Global**

1. **[Network-HostedZone](./BUILD-network-global-network-hostedzone.md)** (n.camelz.io)

#### **Ohio Region**

1. **[Network-HostedZone](./BUILD-network-ohio-network-hostedzone.md)** (n.us-east-2.camelz.io)
1. **[CaMeLz-SantaBarbara-DataCenter-HostedZone](./BUILD-network-ohio-santabarbara-datacenter-hostedzone.md)** (sba.camelz.io)
1. **[Alfa-LosAngeles-DataCenter-HostedZone](./BUILD-network-ohio-alfa-losangeles-datacenter-hostedzone.md)** (lax.alfa.camelz.io)
1. **[Alfa-Miami-DataCenter-HostedZone](./BUILD-network-ohio-alfa-miami-datacenter-hostedzone.md)** (mia.alfa.camelz.io)
1. **[Zulu-Dallas-DataCenter-HostedZone](./BUILD-network-ohio-zulu-dallas-datacenter-hostedzone.md)** (dfw.zulu.camelz.io)

#### **Oregon Region**

1. **[Network-HostedZone](./BUILD-network-oregon-network-hostedzone.md)** (n.us-west-2.camelz.io)

### **Core Account**

#### **Global**

1. **[Core-HostedZone](./BUILD-core-global-core-hostedzone.md)** (c.camelz.io)

#### **Ohio Region**

1. **[Core-HostedZone](./BUILD-core-ohio-core-hostedzone.md)** (c.us-east-2.camelz.io)

#### **Oregon Region**

1. **[Core-HostedZone](./BUILD-core-oregon-core-hostedzone.md)** (c.us-west-2.camelz.io)

### **Sandbox Accounts**

#### **Oregon**

1. **[MCrawford-Sandbox-HostedZone](./BUILD-mcrawford-sandbox-oregon-mcrawford-sandbox-hostedzone.md)** (mcrawford.x.us-west-2.camelz.io)

### **Build Account**

#### **Global**

1. **[Build-HostedZone](./BUILD-build-global-build-hostedzone.md)** (b.camelz.io)

#### **Ohio Region**

1. **[Build-HostedZone](./BUILD-build-ohio-build-hostedzone.md)** (b.us-east-2.camelz.io)

#### **Oregon Region**

1. **[Build-HostedZone](./BUILD-build-oregon-build-hostedzone.md)** (b.us-west-2.camelz.io)

### **Production Account**

#### **Global**

Do not create

1. **[Production-HostedZone](./BUILD-production-global-production-hostedzone.md)** (p.camelz.io)

#### **Ohio Region**

1. **[Production-HostedZone](./BUILD-production-ohio-production-hostedzone.md)** (p.us-east-2.camelz.io)

#### **Oregon Region**

1. **[Production-HostedZone](./BUILD-production-oregon-production-hostedzone.md)** (p.us-west-2.camelz.io)

### **Recovery Account**

#### **Global**

Do not create

1. **[Recovery-HostedZone](./BUILD-recovery-global-recovery-hostedzone.md)** (r.camelz.io)

#### **Ohio Region**

Do not create

1. **[Recovery-HostedZone](./BUILD-recovery-ohio-recovery-hostedzone.md)** (r.us-east-2.camelz.io)

#### **Oregon Region**

1. **[Recovery-HostedZone](./BUILD-recovery-oregon-recovery-hostedzone.md)** (r.us-west-2.camelz.io)

### **Development Account**

#### **Global**

Do not create

1. **[Testing-HostedZone](./BUILD-development-global-testing-hostedzone.md)** (t.camelz.io)
1. **[Development-HostedZone](./BUILD-development-global-development-hostedzone.md)** (d.camelz.io)

#### **Ohio Region**

1. **[Testing-HostedZone](./BUILD-development-ohio-testing-hostedzone.md)** (t.us-east-2.camelz.io)
1. **[Development-HostedZone](./BUILD-development-ohio-development-hostedzone.md)** (d.us-east-2.camelz.io)

#### **Oregon Region**

Do not create

1. **[Testing-HostedZone](./BUILD-development-oregon-testing-hostedzone.md)** (t.us-west-2.camelz.io)
1. **[Development-HostedZone](./BUILD-development-oregon-development-hostedzone.md)** (d.us-west-2.camelz.io)

### **Alfa-Production Account**

#### **Ohio Region**

1. **[Alfa-Production-HostedZone](./BUILD-alfa-production-ohio-alfa-production-hostedzone.md)** (p.us-east-2.alfa.camelz.io)

### **Alfa-Recovery Account**

#### **Oregon Region**

1. **[Alfa-Recovery-HostedZone](./BUILD-alfa-recovery-oregon-alfa-recovery-hostedzone.md)** (r.us-west-2.alfa.camelz.io)

### **Alfa-Development Account**

#### **Ohio Region**

1. **[Alfa-Testing-HostedZone](./BUILD-alfa-development-ohio-alfa-testing-hostedzone.md)** (t.us-east-2.alfa.camelz.io)
1. **[Alfa-Development-HostedZone](./BUILD-alfa-development-ohio-alfa-development-hostedzone.md)** (d.us-east-2.alfa.camelz.io)

### **Zulu-Production Account**

#### **Ohio Region**

1. **[Zulu-Production-HostedZone](./BUILD-zulu-production-ohio-zulu-production-hostedzone.md)** (p.us-east-2.zulu.camelz.io)

### **Zulu-Development Account**

#### **Ohio Region**

1. **[Zulu-Development HostedZone](./BUILD-zulu-development-ohio-zulu-development-hostedzone.md)** (d.us-east-2.zulu.camelz.io)
