# Notes on PKI Setup

## Original MJC Consulting Root Certification Authority

This is a CA I setup in 2013, in the MJC Consulting Legacy Account. THis was created manually via openssl.

### Details
#### Subject Name
- County or Region: US
- State/Province: California
- Locality: San Jose
- Organization: MJC Consulting
- Organizational Unit: Certification Authority
- Common Name: MJC Consulting Root Certification Authority
- Email Address: certificates@mjcconsulting.com

#### Issuer Name
- County or Region: US
- State/Province: California
- Locality: San Jose
- Organization: MJC Consulting
- Organizational Unit: Certification Authority
- Common Name: MJC Consulting Root Certification Authority
- Email Address: certificates@mjcconsulting.com

- Serial Number: 0
- Version: 3
- Signature Algorithm: SHA-1 with RSA Encryption
- Parameters: None

- Not Valid Before: Tuesday, July 2, 2013
- Not Valid After: Monday, June 27, 2033


## MJC Consulting Root CA 1

This is a new CA I setup in 2020, in virtual machine within the MJC Organization Account.

This was created via the OpenVPN easy-rsa program.

### Details
#### Subject Name
- County or Region: US
- State/Province: <blank>
- Locality: <blank>
- Organization: MJC Consulting
- Organizational Unit: Certification Authority
- Common Name: MJC Consulting Root CA 1
- Email Address: <blank>

#### Issuer Name
- County or Region: US
- State/Province: <blank>
- Locality: <blank>
- Organization: MJC Consulting
- Organizational Unit: Certification Authority
- Common Name: MJC Consulting Root CA 1
- Email Address: <blank>

- Serial Number: 0
- Version: 3
- Signature Algorithm: SHA-256 with RSA Encryption
- Parameters: None

- Not Valid Before:
- Not Valid After: (+30 years)

#### Public Key Info
- Algorithm: RSA Encryption
- Parameters: None
- Public Key: 256 bytes
- Key Size: 2,048 bits
- Key Usage: Verify

- Extension: Key Usage
  - Critical: YES
  - Usage: Digital Signature, Key Cert Sign, CRL Sign

- Extension: Basic Constraints
  - Critical: YES
  - Certificate Authority: YES
  - Path Length Constraint: 2

- Extension: Subject Key Identifier
  - Critical: NO
  - Key ID:

- Fingerprints
  - SHA-256:
  - SHA-1:


## DXC Analytics Platform Root CA

This is a new CA I setup in 2020, in virtual machine within the DAP Core Account.

This was created via the OpenVPN easy-rsa program.

This is an initial iteration to be used for testing. We need to re-create this within the
DAP Management Account for more permanent use.

### Details
#### Subject Name
- County or Region: US
- State/Province: <blank>
- Locality: <blank>
- Organization: DXC Technology Company
- Organizational Unit: DXC Analytics Platform
- Common Name: DXC Analytics Platform Root CA
- Email Address: <blank>

#### Issuer Name
- County or Region: US
- State/Province: <blank>
- Locality: <blank>
- Organization: DXC Technology Company
- Organizational Unit: DXC Analytics Platform
- Common Name: DXC Analytics Platform Root CA
- Email Address: <blank>

- Serial Number: 0
- Version: 3
- Signature Algorithm: SHA-256 with RSA Encryption
- Parameters: None

- Not Valid Before:
- Not Valid After: (+30 years)

#### Public Key Info
- Algorithm: RSA Encryption
- Parameters: None
- Public Key: 512 bytes
- Key Size: 4,096 bits
- Key Usage: Verify

- Extension: Key Usage
  - Critical: YES
  - Usage: Digital Signature, Key Cert Sign, CRL Sign

- Extension: Basic Constraints
  - Critical: YES
  - Certificate Authority: YES
  - Path Length Constraint: 2

- Extension: Subject Key Identifier
  - Critical: NO
  - Key ID:

- Fingerprints
  - SHA-256:
  - SHA-1:

## Steps to use easy-rsa to create Root CA, Issuing CA and Client and Server Certificates

1.  Created a new temp host (to be replaced once details worked out), in the DAP
    Core Account, Ohio, Default-VPC, named Default-PKI-RootCertificateAuthorityInstance.

2.  Setup a Route53 DNS name to reach this host, root.pki.us-east-2.m1.dxc-ap.com

3.  Setup source code directory under root: /root/src/OpenSSL

4.  Did a git checkout of the easy-rsa code inside of this new directory.
    ```bash
    sudo su -
    cd /root/src/OpenSSL
    git clone https://github.com/OpenVPN/easy-rsa.git
    ```

5.  Changed to the directory where we need to run commands.
    ```bash
    cd easy-rsa/easyrsa3
    ```

6.  Created a vars file for the Root CA
    See Example of this file within this directory. The location of the root PKI will be
    /root/etc/pki/DXC_Analytics_Platform_Root_CA/pki

7.  Modified the default openssl-easyrsa.cnf configuration file
    - The original was renamed with a .orig extension, compare with new file to see changes

8.  Modified the default ca type configuration
    - The original was renamed with a .orig extension, compare with new file to see changes

9.  Modified the default COMMON type configuration
    - The original was renamed with a .orig extension, compare with new file to see changes

10. Initialize the Root PKI
    ```bash
    ./easyrsa --vars=./vars.root init-pki
    ```

11. Create the Root CA
    - Used password stored in 1Password with name: DXC Analytics Platform Root CA
    - For Common Name, use: DXC Analytics Platform Root CA
    ```bash
    ./easyrsa --vars=./vars.root build-ca
    ```

12. Copy the new Root CA Certificate file (with a standard name) to the location used for
    additional trusted root CAs on an Enterprise Linux host, and install, verify then
    enable.
    ```bash
    update-ca-trust enable

    cp /root/etc/pki/DXC_Analytics_Platform_Root_CA/pki/ca.crt /etc/pki/ca-trust/source/anchors/DXC_Analytics_Platform_Root_CA.crt

    openssl x509 -in /etc/pki/ca-trust/source/anchors/DXC_Analytics_Platform_Root_CA.crt -text -noout

    update-ca-trust extract
    ```

13. Copy the new Root CA Certificate to the DAP Management Account pki-dxcapm bucket
    - We will use this location as the standard location to store the PKI certificates and
      certificate revocation lists (.crl).

14. Import the Root CA Certificate into the local laptop trusted Root CA certificate
    stores for any developer laptops which will need to trust certificates issued by
    this PKI
    - On a mac, this means importing to the System KeyChain via the KeyChain Manager.

15. Created a vars file for the Issuing CA
    See Example of this file within this directory. The location of the root PKI will be
    /root/etc/pki/DXC_Analytics_Platform_Issuing_CA/pki

16. Initialize the Issuing PKI
    ```bash
    ./easyrsa --vars=./vars.issuing init-pki
    ```

17. Create the Issuing CA CSR (Certificate Signing Request)
    - Used password stored in 1Password with name: DXC Analytics Platform Issuing CA
    - For Common Name, use: DXC Analytics Platform Issuing CA
    ```bash
    ./easyrsa --vars=./vars.issuing build-ca subca
    ```

18. Import the Issuing CA CSR on the Root CA
    ```bash
    ./easyrsa --vars=./vars.root import-req /root/etc/pki/DXC_Analytics_Platform_Issuing_CA/pki/reqs/ca.req issuing
    ```

19. Sign the CSR on the Root CA
    ```bash
    ./easyrsa --vars=./vars.root  sign-req ca issuing
    ```

20. Install the Signed Issuing CA Certificate
    ```bash
    cp /root/etc/pki/DXC_Analytics_Platform_Root_CA/pki/issued/issuing.crt /root/etc/pki/DXC_Analytics_Platform_Issuing_CA/pki/ca.crt
    ```

21. Copy the new Issuing CA Certificate file (with a standard name) to the location used for
    additional trusted root CAs on an Enterprise Linux host, and install, verify then
    enable.
    ```bash
    cp /root/etc/pki/DXC_Analytics_Platform_Issuing_CA/pki/ca.crt /etc/pki/ca-trust/source/anchors/DXC_Analytics_Platform_Issuing_CA.crt

    openssl x509 -in /etc/pki/ca-trust/source/anchors/DXC_Analytics_Platform_Issuing_CA.crt -text -noout

    update-ca-trust extract
    ```

22. Copy the new Issuing CA Certificate to the DAP Management Account pki-dxcapm bucket
    - We will use this location as the standard location to store the PKI certificates and
      certificate revocation lists (.crl).

23. Generate the VPN Server Certificate and Key using the Issuing CA
    - This is not the best way to do this, but it's a quick one to get this initially tested
    ```bash
    ./easyrsa --vars=./vars.issuing build-server-full vpn.c.us-east-2.m1.dxc-ap.com nopass
    ```

24. Generate an mcrawford client Certificate and Key using the Issuing CA
    - This is not the best way to do this, but it's a quick one to get this initially tested
    ```bash
    ./easyrsa --vars=./vars.issuing build-client-full mcrawford.c.us-east-2.m1.dxc-ap.com nopass
    ```

25. Create a directory and collect all the relevant files there for further processing
    ```bash
    mkdir -p /var/tmp/vpn.c.us-east-2.m1.dxc-ap.com/
    cp /root/etc/pki/DXC_Analytics_Platform_Root_CA/pki/ca.crt /var/tmp/vpn.c.us-east-2.m1.dxc-ap.com/DXC_Analytics_Platform_Root_CA.crt
    cp /root/etc/pki/DXC_Analytics_Platform_Issuing_CA/pki/ca.crt /var/tmp/vpn.c.us-east-2.m1.dxc-ap.com/DXC_Analytics_Platform_Issuing_CA.crt
    cp /root/etc/pki/DXC_Analytics_Platform_Issuing_CA/pki/issued/vpn.c.us-east-2.m1.dxc-ap.com.crt /var/tmp/vpn.c.us-east-2.m1.dxc-ap.com/
    cp /root/etc/pki/DXC_Analytics_Platform_Issuing_CA/pki/private/vpn.c.us-east-2.m1.dxc-ap.com.key /var/tmp/vpn.c.us-east-2.m1.dxc-ap.com/
    cp /root/etc/pki/DXC_Analytics_Platform_Issuing_CA/pki/issued/mcrawford.c.us-east-2.m1.dxc-ap.com.crt /var/tmp/vpn.c.us-east-2.m1.dxc-ap.com/
    cp /root/etc/pki/DXC_Analytics_Platform_Issuing_CA/pki/private/mcrawford.c.us-east-2.m1.dxc-ap.com.key /var/tmp/vpn.c.us-east-2.m1.dxc-ap.com/
    cd /var/tmp/vpn.c.us-east-2.m1.dxc-ap.com/
    cat DXC_Analytics_Platform_Issuing_CA.crt DXC_Analytics_Platform_Root_CA.crt > DXC_Analytics_Platform_Chain.crt
    ```

26. Import the Certificates into AWS Certificate Manager
    ```bash
    aws acm import-certificate --certificate file://vpn.us-east-2.m1.dxc-ap.com.crt \
                               --private-key file://vpn.us-east-2.m1.dxc-ap.com.key \
                               --certificate-chain file://DXC_Analytics_Platform_Chain.crt \
                               --profile dxcapc-administrator --region us-east-2

    aws acm import-certificate --certificate file://mcrawford.vpn.us-east-2.m1.dxc-ap.com.crt \
                               --private-key file://mcrawford.vpn.us-east-2.m1.dxc-ap.com.key \
                               --certificate-chain file://DXC_Analytics_Platform_Chain.crt \
                                --profile dxcapc-administrator --region us-east-2
    ```
