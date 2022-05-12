# CIDR Calculations

This page contains notes on how CIDR calculations are done. This extracts the calculations from the
CaMeLz-SubnetCalculator-20220427-Partial.xlsx version of the Subnet Calculator Spreadsheet which goes back quite a few
years, used in all prior versions of this framework, but modified a bit to add an extra column to the left.

## SubnetCalculator Spreadsheet Notes

Here's notes on how I setup the original SubnetCalculator spreadsheet to allow for arbitrary subnet size, tier count and
zones when creating the original CaMeLz multi-account VPC connectivity using CloudFormation Templates. These calculations
form the basis of the newer fixed tier variant set of subnets in the latest design.

#### Subnet Calculations

B4 (VPCCIDR) =10.31.192.0/20

C4 (Addresses) =64
D4 (Tiers) =16
E4 (Zones) =4

F4 (VPCAddressesNeeded) =Addresses * Tiers * Zones
G4 (VPCNetmaskNeeded) =32-LOG(VPCAddressesNeeded,2)

#### Convert CIDR to IP Address and Netmask
H4 (VPCAddress) =LEFT(VPCCIDR, FIND("/", VPCCIDR) - 1)
I4 (VPCNetmask) =RIGHT(VPCCIDR, LEN(VPCCIDR) - SEARCH("/", VPCCIDR, 1))

#### Convert IP Address to Decimal value
-- Original ---------
J4 (VPCAddressOctet1) =LEFT(VPCAddress, SEARCH(".", VPCAddress, 1) - 1)
K4 (VPCAddressOctet2) =MID(VPCAddress, SEARCH(".", VPCAddress, 1) + 1, (SEARCH(".", VPCAddress, SEARCH(".", VPCAddress, 1) + 1) - 1) - SEARCH(".", VPCAddress, 1))
L4 (VPCAddressOctet3) =MID(VPCAddress,SEARCH(".",VPCAddress,SEARCH(".",VPCAddress,1)+1)+1,SEARCH(".",VPCAddress,SEARCH(".",VPCAddress,SEARCH(".",VPCAddress,1)+1)+1)-SEARCH(".",VPCAddress,SEARCH(".",VPCAddress,1)+1)-1)
M4 (VPCAddressOctet4) =RIGHT(VPCAddress,LEN(VPCAddress)-SEARCH(".",VPCAddress,SEARCH(".",VPCAddress,SEARCH(".",VPCAddress,1)+1)+1))
N4 (VPCStart) =VPCAddressOctet1*(256*256*256) + VPCAddressOctet2*(256*256) + VPCAddressOctet3*256 + VPCAddressOctet4
-- Alternative 1 ----
J4 (VPCAddressOctet1) =LEFT(VPCAddress,FIND(".",VPCAddress)-1)
K4 (VPCAddressOctet2) =MID(VPCAddress,FIND(".",VPCAddress)+1,FIND(".",VPCAddress,FIND(".",VPCAddress)+1)-FIND(".",VPCAddress)-1)
L4 (VPCAddressOctet3) =MID(VPCAddress,FIND(".",VPCAddress,FIND(".",VPCAddress)+1)+1,FIND(".",VPCAddress,FIND(".",VPCAddress,FIND(".",VPCAddress)+1)+1)-(FIND(".",VPCAddress,FIND(".",VPCAddress)+1)+1))
M4 (VPCAddressOctet4) =MID(VPCAddress,FIND(".",VPCAddress,FIND(".",VPCAddress,FIND(".",VPCAddress)+1)+1)+1,LEN(VPCAddress)-FIND(".",VPCAddress,FIND(".",VPCAddress,FIND(".",VPCAddress)+1)+1))
N4 (VPCStart) =VPCAddressOctet1*(256*256*256) + VPCAddressOctet2*(256*256) + VPCAddressOctet3*256 + VPCAddressOctet4
-- Alternative 2 - now using this ----
N4 (VPCStart) =SUMPRODUCT(TRIM(MID(SUBSTITUTE(VPCAddress,".",REPT(" ",100)),ROW($1:$4)*100-99,100))*256^(4-ROW($1:$4)))
-------------------

#### Convert Decimal Value to IP Address
=CONCAT(BITRSHIFT(VPCStart,24),".",BITAND(BITRSHIFT(VPCStart,16),255),".",BITAND(BITRSHIFT(VPCStart,8),255),".",BITAND(VPCStart,255))

#### Validate VPCAddress and VPCNetmask
O4 (VPCAddressValid) =IF(MOD(VPCStart,VPCAddressesNeeded)=0,"true","false")
P4 (VPCNetmaskValid) =IF(EXACT(VPCNetmask,VPCNetmaskNeeded),"true","false")

=IF(MOD(AZADigitalAddress,2^(32-VPCNetmaskRequired))=0,"valid","invalid")
2^(32-VPCNetmaskRequired)

=QUOTIENT(AZADigitalAddress,2^(32-VPCNetmaskRequired))
=AZADecimalAddress-(MOD(AZADecimalAddress,2^(32-VPCNetmaskRequired)))

### Calculate Per-AZ Start Addresses and CIDRs
N6 (AZAStart) =VPCStart
N7 (AZBStart) =AZAStart+(2^(32-(VPCNetmask+2)))
N8 (AZCStart) =AZBStart+(2^(32-(VPCNetmask+2)))
N9 (AZDStart) =AZCStart+(2^(32-(VPCNetmask+2)))

B6 (AZACIDR) =CONCAT(BITRSHIFT(AZAStart,24),".",BITAND(BITRSHIFT(AZAStart,16),255),".",BITAND(BITRSHIFT(AZAStart,8),255),".",BITAND(AZAStart,255),"/",(VPCNetmask+2))
B7 (AZBCIDR) =CONCAT(BITRSHIFT(AZBStart,24),".",BITAND(BITRSHIFT(AZBStart,16),255),".",BITAND(BITRSHIFT(AZBStart,8),255),".",BITAND(AZBStart,255),"/",(VPCNetmask+2))
B8 (AZCCIDR) =CONCAT(BITRSHIFT(AZCStart,24),".",BITAND(BITRSHIFT(AZCStart,16),255),".",BITAND(BITRSHIFT(AZCStart,8),255),".",BITAND(AZCStart,255),"/",(VPCNetmask+2))
B9 (AZDCIDR) =CONCAT(BITRSHIFT(AZDStart,24),".",BITAND(BITRSHIFT(AZDStart,16),255),".",BITAND(BITRSHIFT(AZDStart,8),255),".",BITAND(AZDStart,255),"/",(VPCNetmask+2))

B6 (AZACIDR) =CONCAT(BITRSHIFT((VPCDecimalAddress-(MOD(VPCDecimalAddress,2^(32-VPCNetmaskRequired)))),24),".",BITAND(BITRSHIFT((VPCDecimalAddress-(MOD(VPCDecimalAddress,2^(32-VPCNetmaskRequired)))),16),255),".",BITAND(BITRSHIFT((VPCDecimalAddress-(MOD(VPCDecimalAddress,2^(32-VPCNetmaskRequired)))),8),255),".",BITAND((VPCDecimalAddress-(MOD(VPCDecimalAddress,2^(32-VPCNetmaskRequired)))),255),"/",(VPCNetmask+2))

=IF(AND(true,true),"","<- invalid")

=IF(AND(MOD(AZADecimalAddress,2^(32-VPCNetmaskRequired))=0,EXACT(VPCNetmask,VPCNetmaskRequired)),"","<- invalid")

MOD(AZADecimalAddress,2^(32-VPCNetmaskRequired))=0
EXACT(VPCNetmask,VPCNetmaskRequired)

## Required VPCs By Account and Region

1. CaMeLz-Management
    1. Global
       - Management-VPC [XL] 10.15.192.0/19
    1. Ohio
       - Management-VPC [XL] 10.31.192.0/19
    1. Oregon
       - Management-VPC [XL] 10.47.192.0/19

1. CaMeLz-Log-Archive
    1. Global
       - N/A

1. CaMeLz-Audit
    1. Global
       - N/A

1. CaMeLz-Network
    1. Global
       - Network-VPC [L] 10.15.128.0/20
    1. Ohio
       - Network-VPC [L] 10.31.128.0/20
    1. Oregon
       - Network-VPC [L] 10.47.128.0/20
       - CaMeLz-SantaBarbara-VPC [2XS] 172.23.0.0/24
       - Alfa-LosAngeles-VPC [2XS] 172.24.0.0/24
       - Alfa-Miami-VPC [2XS] 172.24.1.0/24
       - Zulu-Dallas-VPC [2XS] 172.30.0.0/24

1. CaMeLz-Core
    1. Global
       - Core-VPC [XL] 10.15.64.0/19
    1. Ohio
       - Core-VPC [XL] 10.31.64.0/19
    1. Oregon
       - Core-VPC [XL] 10.47.64.0/19

1. CaMeLz-MCrawford-Sandbox
    1. Ohio
       - MCrawford-Sandbox-VPC [S] 10.30.192.0/22

1. CaMeLz-Build
    1. Global
       - Build-VPC [M] 10.15.0.0/21
    1. Ohio
       - Build-VPC [M] 10.31.0.0/21

1. CaMeLz-Production
    1. Ohio
       - Production-VPC [L] 10.16.0.0/20
    1. Oregon
       - Production-VPC [L] 10.32.0.0/20

1. CaMeLz-Recovery
    1. Oregon
       - Recovery-VPC [L] 10.32.16.0/20

1. CaMeLz-Development
    1. Ohio
       - Testing-VPC [L] 10.16.128.0/20
       - Development-VPC [L] 10.16.192.0/20

1. CaMeLz-Alfa-Production
    1. Ohio
       - Alfa-Production-VPC [L] 10.17.0.0/20
    1. Oregon
       - Alfa-Production-VPC [L] 10.33.0.0/20

1. CaMeLz-Alfa-Recovery
    1. Oregon
       - Alfa-Recovery-VPC [L] 10.33.16.0/20

1. CaMeLz-Alfa-Development
    1. Ohio
       - Alfa-Testing-VPC [L] 10.17.32.0/20
       - Alfa-Development-VPC [L] 10.17.48.0/20

1. CaMeLz-Zulu-Production
    1. Ohio
       - Zulu-Production-VPC [XL] 10.24.0.0/19

1. CaMeLz-Zulu-Development
    1. Ohio
       - Zulu-Development-VPC [L] 10.24.48.0/20
