# CaMeLz Gen4 Prototype
This contains the scripts used to prototype Cross-Account Multi-Environment Landing Zone Gen IV

WIP: In the middle of restructuring this...

## Modules
The CaMeLz POC 4 System is build in a modular design.

WIP: Converting the code from the prior script-based sequence of Modules to something closer to how
AWS structures it's on-line workshops and training (See links below).

1.  **[DNS](./modules/dns/)**
1.  **[VPC](./modules/vpc/)**
1.  **[Instances](./modules/instances/)**


## Links
Collecting here some links for how we might want to restructure this, based on the techniques
used in AWS Workshops and Labs

### [AWS Workshops](https://workshops.aws)
#### Best Examples
- [WELCOME TO INNOVATOR ISLAND!](https://www.eventbox.dev/published/lesson/innovator-island/)
  - [GitHub: aws-samples/aws-serverless-workshop-innovator-island](https://github.com/aws-samples/aws-serverless-workshop-innovator-island)
  - This is the best example, probably, showing what's possible when you use both GitHub for most code, but then have this separate
    website AWS uses for workshops (they use a few) which has a navigation sidebar in addition to the main pane. We'll start out with
    using just Github to come close to the Main Pane format.
- [Wild Rydes Serverless Workshops](https://github.com/aws-samples/aws-serverless-workshops/tree/master)
  - This appears to be an older version of Innovator Island, and contains some interesting
    structure within a GitHub project. Lots to reference here.
- [Serverless Security Workshop](https://github.com/aws-samples/aws-serverless-security-workshop)
  - This is referenced within Wild Rydes, good internal structure within GitHub.
- [Multi-Account Security Governance Workshop](https://catalog.us-east-1.prod.workshops.aws/workshops/d3f60827-89f2-46a8-9be7-6e7185bd7665/en-US)
  - Great example of the format we want to use, except this pre-dates Control Tower and replicates much of it's work.
  - But, how this shows steps mostly based on use of CLI commands and scripts from a cloned GitHub repo is exactly what we want.
  - Uses this repo: https://github.com/aws-samples/multi-account-security-governance-workshop
- [Build your first CRUD API in 45 minutes or less!](https://catalog.us-east-1.prod.workshops.aws/workshops/2c8321cb-812c-45a9-927d-206eea3a500f/en-US)
  - Simple showing mixture of GUI and CLI copy blocks
- [AWS NETWORK FIREWALL WORKSHOP](https://networkfirewall.workshop.aws)
- [Hands-on Network Firewall Workshop](https://catalog.us-east-1.prod.workshops.aws/workshops/d071f444-e854-4f3f-98c8-025fa0d1de2f/en-US/)
- [NETWORKING IMMERSION DAY](https://networking.workshop.aws)
    - Lots of complex networking topics. I used an earlier version of this a few years back to learn TGW.
- [AWS Tools GitFlow Workshop](https://catalog.us-east-1.prod.workshops.aws/workshops/484a7839-1887-43e8-a541-a8c014cd5b18/en-US/)
- [Amazon Athena Workshop :: Hands on Labs](https://catalog.us-east-1.prod.workshops.aws/workshops/9981f1a1-abdc-49b5-8387-cb01d238bb78/en-US/)
  - Well-structured walkthrough with next buttons. Wish I knew how they built this.
- [AWS Serverless Airline Booking](https://github.com/aws-samples/aws-serverless-airline-booking)
  - AWS GitHub Example
#### Other Examples
- [SIEM ON AMAZON OPENSEARCH SERVICE WORKSHOP](https://security-log-analysis-platform.workshop.aws/en/)
- [ETL ON AMAZON EMR WORKSHOP](https://emr-etl.workshop.aws)
- [SCALING YOUR ENCRYPTION AT REST CAPABILITIES WITH AWS KMS](https://kms-encryption-at-rest.workshop.aws)
  - Good section on EBS encrypion basics
- [CI/CD workshop for Amazon ECS](https://catalog.us-east-1.prod.workshops.aws/workshops/869f7eee-d3a2-490b-bf9a-ac90a8fb2d36/en-US/)
- [Implementing DDoS Resiliency](https://catalog.us-east-1.prod.workshops.aws/workshops/4d0b27bc-9f48-4356-8242-d13ca057fff2/en-US/)
- [Building a Cross-account CI/CD Pipeline](https://catalog.us-east-1.prod.workshops.aws/workshops/00bc829e-fd7c-4204-9da1-faea3cf8bd88/en-US/)
- [AWS Data Protection Workshops](https://github.com/aws-samples/data-protection)

## Network Links
- [Deployment models for AWS Network Firewall with VPC routing enhancements](https://aws.amazon.com/blogs/networking-and-content-delivery/deployment-models-for-aws-network-firewall-with-vpc-routing-enhancements/)
- [Hands-on walkthrough of the AWS Network Firewall flexible rules engine – Part 1](https://aws.amazon.com/blogs/security/hands-on-walkthrough-of-the-aws-network-firewall-flexible-rules-engine/)
- [Hands-on walkthrough of the AWS Network Firewall flexible rules engine – Part 2](https://aws.amazon.com/blogs/security/hands-on-walkthrough-of-the-aws-network-firewall-flexible-rules-engine-part-2/?nc1=b_rp)
- [Building a global network using AWS Transit Gateway Inter-Region peering](https://aws.amazon.com/blogs/networking-and-content-delivery/building-a-global-network-using-aws-transit-gateway-inter-region-peering/)
- [Design your firewall deployment for Internet ingress traffic flows](https://aws.amazon.com/blogs/networking-and-content-delivery/design-your-firewall-deployment-for-internet-ingress-traffic-flows/)
- [Scaling network traffic inspection using AWS Gateway Load Balancer](https://aws.amazon.com/blogs/networking-and-content-delivery/scaling-network-traffic-inspection-using-aws-gateway-load-balancer/)
- [Centralized inspection architecture with AWS Gateway Load Balancer and AWS Transit Gateway](https://aws.amazon.com/blogs/networking-and-content-delivery/centralized-inspection-architecture-with-aws-gateway-load-balancer-and-aws-transit-gateway/)
- [New – VPC Ingress Routing – Simplifying Integration of Third-Party Appliances](https://aws.amazon.com/blogs/aws/new-vpc-ingress-routing-simplifying-integration-of-third-party-appliances/)
- [Configuring Cisco Security with Amazon VPC Ingress Routing](https://blogs.cisco.com/security/configuring-cisco-security-with-amazon-vpc-ingress-routing?ccid=cc000155&dtid=odiprl000517&oid=pstsc019678)
- [Cisco Adaptive Security Virtual Appliance (ASAv) - BYOL](https://aws.amazon.com/marketplace/pp/prodview-sltshxd3bzqbg?sr=0-3&ref_=beagle&applicationId=AWSMPContessa)
- [Design your firewall deployment for Internet ingress traffic flows](https://aws.amazon.com/blogs/networking-and-content-delivery/design-your-firewall-deployment-for-internet-ingress-traffic-flows/)
- [Securely scale multi-account architecture with AWS Network Firewall and AWS Control Tower](https://aws.amazon.com/blogs/mt/scale-multi-account-architecture-aws-network-firewall-and-aws-control-tower/)
- [Extending your Control Tower Network security with Amazon Route 53 DNS Firewall](https://aws.amazon.com/blogs/mt/extending-your-control-tower-network-security-with-aws-route-53-dns-firewall/?nc1=b_rp)
- [Building a global network using AWS Transit Gateway Inter-Region peering](https://aws.amazon.com/blogs/networking-and-content-delivery/building-a-global-network-using-aws-transit-gateway-inter-region-peering/)
