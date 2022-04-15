# Certificates:PKI Infrastructure

This document describes the CaMeLz PKI Infrastructure used to generate
private TLS certificates for development and testing.

**TODO**: More description coming

## Dependencies

**TODO**: Determine Module Pre-Requisites and List here
- I'm initially creating the PKI Instances used for the CAs, cert generation ran
  publishing of the certs and other web-based websites by hand, in the Management
  Account, Default-VPC. But, this eventually needs to be formalized. Until then
  I'm describing some basic simple pre-requisites here
- The PKI CA Instance needs to exist. The directory structure and files described
  below are created on that server.
- The PKI Web Server Instance needs to exist. The certificates reference websites
  for the Certification Authority Issuer, Certificate Revocation List, and  
  Online Certificate Status Protocol websites which should be running while
  testing certificate use.

## Build PKI Infrastructure

All the steps below are to be run on the cmlue1mpkica01.camelz.io Instance,
created in the Default-VPC within the CaMeLz-Management Account.

Initially! Eventually, this needs to be formalized, and the CAs will need to be
split up to mulitple servers, so the root can be taken off-line when not in use,
and all CAs keep their data on separate EBS volumes for backup purposes, and also
so these can be attached to Instances which may not run except while in use to
lower the security exposure.

### Create Volumes Disks and Attach to Instance

Perform these steps in the AWS EC2 Console while in the CaMeLz-Management Account, us-east-1 Region.

1. **Create CaMeLz Root Certification Authority Volume**

    Create a 2GB gp3 Volume, Encrypt with the default EBS KMS key, and Tag
    - Name = Default-PKI-CertificateAuthorityInstance:/var/lib/pki/CA/CaMeLzRootCertificationAuthority
    - Hostname = cmlue1mpkica01
    - Mountpoint = /var/lib/pki/CA/CaMeLzRootCertificationAuthority

1. **Attach CaMeLz Root Certification Authority Volume to Default-PKI-CertificateAuthority Instance**

    Attach the volume to the instance as device /dev/sdf, which should show up in the OS as /dev/nvme1n1

1. **Create CaMeLz TLS Certification Authority Volume**

    Create a 2GB gp3 Volume, Encrypt with the default EBS KMS key, and Tag
    - Name = Default-PKI-CertificateAuthorityInstance:/var/lib/pki/CA/CaMeLzTLSCertificationAuthority
    - Hostname = cmlue1mpkica01
    - Mountpoint = /var/lib/pki/CA/CaMeLzTLSCertificationAuthority

1. **Attach CaMeLz TLS Certification Authority Volume to Default-PKI-CertificateAuthority Instance**

    Attach the volume to the instance as device /dev/sdg, which should show up in the OS as /dev/nvme2n1

1. **Create CaMeLz User Certification Authority Volume**

    Create a 1GB gp3 Volume, Encrypt with the default EBS KMS key, and Tag
    - Name = Default-PKI-CertificateAuthorityInstance:/var/lib/pki/CA/CaMeLzUserCertificationAuthority
    - Hostname = cmlue1mpkica01
    - Mountpoint = /var/lib/pki/CA/CaMeLzUserCertificationAuthority

1. **Attach CaMeLz User Certification Authority Volume to Default-PKI-CertificateAuthority Instance**

    Attach the volume to the instance as device /dev/sdh, which should show up in the OS as /dev/nvme3n1

1. **Create CaMeLz Software Certification Authority Volume**

    Create a 1GB gp3 Volume, Encrypt with the default EBS KMS key, and Tag
    - Name       = Default-PKI-CertificateAuthorityInstance:/var/lib/pki/CA/CaMeLzSoftwareCertificationAuthority
    - Hostname   = cmlue1mpkica01
    - Mountpoint = /var/lib/pki/CA/CaMeLzSoftwareCertificationAuthority

1. **Attach CaMeLz Software Certification Authority Volume to Default-PKI-CertificateAuthority Instance**

    Attach the volume to the instance as device /dev/sdi, which should show up in the OS as /dev/nvme4n1

### Format Volumes and Mount Filesystems

Perform these steps while logged in as root to the Default-PKI-CertificateAuthority Instance.

1. **Format & Mount CaMeLz Root Certification Authority Volume**

    ```bash
    device=nvme1n1
    mountpoint=/var/lib/pki/CA/CaMeLzRootCertificationAuthority

    mkfs -t xfs /dev/$device
    xfs_admin -L ${mountpoint##*/} /dev/$device

    UUID=$(blkid -s UUID -o value /dev/$device)
    sed -i -e "/^UUID=$UUID/d" /etc/fstab
    sed -i -e "\$aUUID=$UUID    $mountpoint    xfs    defaults,noatime  1   1" /etc/fstab

    mkdir -p $mountpoint
    mount $mountpoint
    ```

1. **Format & Mount CaMeLz TLS Certification Authority Volume**

    ```bash
    device=nvme2n1
    mountpoint=/var/lib/pki/CA/CaMeLzTLSCertificationAuthority

    mkfs -t xfs /dev/$device
    xfs_admin -L ${mountpoint##*/} /dev/$device

    UUID=$(blkid -s UUID -o value /dev/$device)
    sed -i -e "/^UUID=$UUID/d" /etc/fstab
    sed -i -e "\$aUUID=$UUID    $mountpoint    xfs    defaults,noatime  1   1" /etc/fstab

    mkdir -p $mountpoint
    mount $mountpoint
    ```

1. **Format & Mount CaMeLz User Certification Authority Volume**

    ```bash
    device=nvme3n1
    mountpoint=/var/lib/pki/CA/CaMeLzUserCertificationAuthority

    mkfs -t xfs /dev/$device
    xfs_admin -L ${mountpoint##*/} /dev/$device

    UUID=$(blkid -s UUID -o value /dev/$device)
    sed -i -e "/^UUID=$UUID/d" /etc/fstab
    sed -i -e "\$aUUID=$UUID    $mountpoint    xfs    defaults,noatime  1   1" /etc/fstab

    mkdir -p $mountpoint
    mount $mountpoint
    ```

1. **Format & Mount CaMeLz Software Certification Authority Volume**

    ```bash
    device=nvme4n1
    mountpoint=/var/lib/pki/CA/CaMeLzSoftwareCertificationAuthority

    mkfs -t xfs /dev/$device
    xfs_admin -L ${mountpoint##*/} /dev/$device

    UUID=$(blkid -s UUID -o value /dev/$device)
    sed -i -e "/^UUID=$UUID/d" /etc/fstab
    sed -i -e "\$aUUID=$UUID    $mountpoint    xfs    defaults,noatime  1   1" /etc/fstab

    mkdir -p $mountpoint
    mount $mountpoint
    ```

### Setup the Build Environment

Perform these steps while logged in as root to the Default-PKI-CertificateAuthority Instance.

1. **Define Environment**

    ```bash
    export CAMELZ_DOMAIN=camelz.io

    export CAMELZ_PKI_HOME=/var/lib/pki

    export CAMELZ_PKI_ROOT_CA=CaMeLzRootCertificationAuthority
    export CAMELZ_PKI_ROOT_CA_HOME=$CAMELZ_PKI_HOME/CA/$CAMELZ_PKI_ROOT_CA

    export CAMELZ_PKI_TLS_CA=CaMeLzTLSCertificationAuthority
    export CAMELZ_PKI_TLS_CA_HOME=$CAMELZ_PKI_HOME/CA/$CAMELZ_PKI_TLS_CA

    export CAMELZ_PKI_USER_CA=CaMeLzUserCertificationAuthority
    export CAMELZ_PKI_USER_CA_HOME=$CAMELZ_PKI_HOME/CA/$CAMELZ_PKI_USER_CA

    export CAMELZ_PKI_SOFTWARE_CA=CaMeLzSoftwareCertificationAuthority
    export CAMELZ_PKI_SOFTWARE_CA_HOME=$CAMELZ_PKI_HOME/CA/$CAMELZ_PKI_SOFTWARE_CA
    ```

### Create the CaMeLz Root Certification Authority

Perform these steps while logged in as root to the Default-PKI-CertificateAuthority Instance.

1. **Create CA directory structure**

    ```bash
    cd $CAMELZ_PKI_HOME

    mkdir -p $CAMELZ_PKI_ROOT_CA_HOME/db
    mkdir -p $CAMELZ_PKI_ROOT_CA_HOME/private
    mkdir -p $CAMELZ_PKI_ROOT_CA_HOME/certs

    chmod 700 $CAMELZ_PKI_ROOT_CA_HOME/private

    mkdir -p $CAMELZ_PKI_HOME/private
    mkdir -p $CAMELZ_PKI_HOME/certs
    mkdir -p $CAMELZ_PKI_HOME/crls

    chmod 700 $CAMELZ_PKI_HOME/private
    ```

1. **Create CA database**

    ```bash
    cp /dev/null $CAMELZ_PKI_ROOT_CA_HOME/db/$CAMELZ_PKI_ROOT_CA.index
    cp /dev/null $CAMELZ_PKI_ROOT_CA_HOME/db/$CAMELZ_PKI_ROOT_CA.index.attr
    openssl rand -hex 16  > $CAMELZ_PKI_ROOT_CA_HOME/db/$CAMELZ_PKI_ROOT_CA.crt.serial
    echo 1001 > $CAMELZ_PKI_ROOT_CA_HOME/db/$CAMELZ_PKI_ROOT_CA.crl.serial
    ```

1. **Copy the CA configuration file**

    This currently shows how to do this from the developer workstation containing a copy of the camels4-prototype repo,
    located at $CAMELZ_HOME. I may modify this to do a git clone on the PKI Instance, to /root/src/mjcconsulting/camelz4-prototype,
    so a local copy can be done.

    - Copy $CAMELZ_HOME/certificates/CaMeLzRootCertificationAuthority.conf  
      to $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.conf

1. **Create CA request**

    ```bash
    openssl req -new \
                -config $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.conf \
                -out $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.csr \
                -keyout $CAMELZ_PKI_ROOT_CA_HOME/private/$CAMELZ_PKI_ROOT_CA.key
    ```

1. **Verify CA request**

    Verify the Subject and Extensions are correct.

    ```bash
    openssl req -in $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.csr -text -noout
    ```

1. **Create CA certificate**

    When self-signing the Root CA certificate, we need to explicitly set the expiration date for 25 years on the
    command line. We can't set this inside the config file, as we want the value there to be the shorter 10 years
    used by default when issuing subordinate CA certificates.

    ```bash
    openssl ca -selfsign -days 9131 \
               -config $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.conf \
               -in $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.csr \
               -out $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.crt \
               -extensions ca_ext
    ```

1. **Verify CA certificate**

    Verify the Issuer, Validity Date Range, Subject, Public Key Size, Extensions, and CA Issuer, CRL and OCSP
    URLs are correct.

    For this Root Certification Authority certificate, the file saved from this command is what we install to have all
    certificates issued by this PKI trusted on any systems which will use these certificates.

    ```bash
    openssl x509 -in $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.crt -text
    ```

1. **Publish CA certificate**

    Once we verify the CA certificate is correct, we need to publish it to the CA Issuer website in DER format.

    The commands below assume we have setup the appropriate AWS security groups to allow the rsync operation from the
    Default-PKI-CertificateAuthorityInstance (cmlue1mpkica01) Instance to the Default-PKI-Instance (cmlue1pki01)
    Instance, where the crt.camelz.io website is hosted, and the certificate needs to be copied as shown in the command
    below.

    Note you can't actually DO this without a lot more setup than is efficient to setup here, due to needing to run
    portions of this as root, which isn't setup for SSH. So, it's best to copy the crt to /tmp as root, then rsync
    as ec2-user, then copy on the receiving end to the correct location as root again, and then fix permissions. Use
    this command as a guide to where the result should be located when you're done.

    ```bash
    openssl x509 -in $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.crt \
                 -out /var/tmp/$CAMELZ_PKI_ROOT_CA.crt \
                 -outform der

    rsync -avzP /var/tmp/$CAMELZ_PKI_ROOT_CA.crt cmlue1mpki01:/var/www/crt.camels.io/html/$CAMELZ_PKI_ROOT_CA.crt
    ```

1. **Create initial CRL**

    Explicitly set the expiration date for 1 year. We can't set this inside the config file as we want the value
    there to be the shorter 30 day value used for subordinate CAs.

    When creating a Root CA CRL, we need to explicitly set the expiration date for 1 year on the
    command line. We can't set this inside the config file, as we want the value there to be the shorter 30 days
    used by default when issuing subordinate CA certificates.

    ```bash
    openssl ca -gencrl -crldays 365 \
               -config $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.conf \
               -out $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.crl
    ```

1. **Verify initial CRL**

    Verify the Issuer, Validity Date Range, Extensions, and CA Issuer & OCSP URLs are correct. Also that initially there
    are no revoked certificates.

    ```bash
    openssl crl -in $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.crl -text
    ```

1. **Publish initial CRL**

    All published CRLs must be in DER format. MIME type: application/pkix-crl. [RFC 2585#section-4.2]

    The commands below assume we have setup the appropriate AWS security groups to allow the rsync operation from the
    Default-PKI-CertificateAuthorityInstance (cmlue1mpkica01) Instance to the Default-PKI-Instance (cmlue1pki01)
    Instance, where the crt.camelz.io website is hosted, and the certificate needs to be copied as shown in the command
    below.

    Note you can't actually DO this without a lot more setup than is efficient to setup here, due to needing to run
    portions of this as root, which isn't setup for SSH. So, it's best to copy the crt to /tmp as root, then rsync
    as ec2-user, then copy on the receiving end to the correct location as root again, and then fix permissions. Use
    this command as a guide to where the result should be located when you're done.

    ```bash
    openssl crl -in $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.crl \
                -out -in /var/tmp/$CAMELZ_PKI_ROOT_CA.crl \
                -outform der

    rsync -avzP /var/tmp/$CAMELZ_PKI_ROOT_CA.crl cmlue1mpki01:/var/www/crl.camels.io/html/$CAMELZ_PKI_ROOT_CA.crl
    ```

### Create the CaMeLz TLS Certification Authority

Perform these steps while logged in as root to the Default-PKI-CertificateAuthority Instance.

1. **Create CA directory structure**

    ```bash
    cd $CAMELZ_PKI_HOME

    mkdir -p $CAMELZ_PKI_TLS_CA_HOME/db
    mkdir -p $CAMELZ_PKI_TLS_CA_HOME/private
    mkdir -p $CAMELZ_PKI_TLS_CA_HOME/certs

    chmod 700 $CAMELZ_PKI_TLS_CA_HOME/private
    ```

1. **Create CA database**

    ```bash
    cp /dev/null $CAMELZ_PKI_TLS_CA_HOME/db/$CAMELZ_PKI_TLS_CA.index
    cp /dev/null $CAMELZ_PKI_TLS_CA_HOME/db/$CAMELZ_PKI_TLS_CA.index.attr
    openssl rand -hex 16  > $CAMELZ_PKI_TLS_CA_HOME/db/$CAMELZ_PKI_TLS_CA.crt.serial
    echo 1001 > $CAMELZ_PKI_TLS_CA_HOME//db/$CAMELZ_PKI_TLS_CA.crl.serial
    ```

1. **Copy the CA configuration file**

    This currently shows how to do this from the developer workstation containing a copy of the camels4-prototype repo,
    located at $CAMELZ_HOME. I may modify this to do a git clone on the PKI Instance, to /root/src/mjcconsulting/camelz4-prototype,
    so a local copy can be done.

    - Copy $CAMELZ_HOME/certificates/CaMeLzTLSCertificationAuthority.conf  
      to $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.conf

1. **Create CA request**

    ```bash
    openssl req -new \
                -config $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.conf \
                -out $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.csr \
                -keyout $CAMELZ_PKI_TLS_CA_HOME/private/$CAMELZ_PKI_TLS_CA.key
    ```

1. **Verify CA request**

    Verify the Subject and Extensions are correct.

    ```bash
    openssl req -in $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.csr -text -noout
    ```

1. **Create CA certificate**

    We use the Root Certification Authority to issue the TLS Certification Authority certificate.

    ```bash
    openssl ca -config $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.conf \
               -in $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.csr \
               -out $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.crt \
               -extensions sub_tls_ca_ext
    ```

1. **Verify CA certificate**

    Verify the Issuer, Validity Date Range, Subject, Public Key Size, Extensions, and CA Issuer, CRL and OCSP
    URLs are correct.

    This command is also used to save the certificate for publication on the CA Issuer website.

    ```bash
    openssl x509 -in $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.crt -text
    ```

1. **Publish CA certificate**

    Once we verify the CA certificate is correct, we need to publish it to the CA Issuer website in DER format.

    The commands below assume we have setup the appropriate AWS security groups to allow the rsync operation from the
    Default-PKI-CertificateAuthorityInstance (cmlue1mpkica01) Instance to the Default-PKI-Instance (cmlue1pki01)
    Instance, where the crt.camelz.io website is hosted, and the certificate needs to be copied as shown in the command
    below.

    Note you can't actually DO this without a lot more setup than is efficient to setup here, due to needing to run
    portions of this as root, which isn't setup for SSH. So, it's best to copy the crt to /tmp as root, then rsync
    as ec2-user, then copy on the receiving end to the correct location as root again, and then fix permissions. Use
    this command as a guide to where the result should be located when you're done.

    ```bash
    openssl x509 -in $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.crt \
                 -out /var/tmp/$CAMELZ_PKI_TLS_CA.crt \
                 -outform der

    rsync -avzP /var/tmp/$CAMELZ_PKI_TLS_CA.crt cmlue1mpki01:/var/www/crt.camels.io/html/$CAMELZ_PKI_TLS_CA.crt
    ```

1. **Create initial CRL**

    ```bash
    openssl ca -gencrl \
               -config $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.conf \
               -out $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.crl
    ```

1. **Verify initial CRL**

    Verify the Issuer, Validity Date Range, Extensions, and CA Issuer & OCSP URLs are correct. Also that initially there
    are no revoked certificates.

    ```bash
    openssl crl -in $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.crl -text -noout
    ```

1. **Publish initial CRL**

    All published CRLs must be in DER format. MIME type: application/pkix-crl. [RFC 2585#section-4.2]

    The commands below assume we have setup the appropriate AWS security groups to allow the rsync operation from the
    Default-PKI-CertificateAuthorityInstance (cmlue1mpkica01) Instance to the Default-PKI-Instance (cmlue1pki01)
    Instance, where the crt.camelz.io website is hosted, and the certificate needs to be copied as shown in the command
    below.

    Note you can't actually DO this without a lot more setup than is efficient to setup here, due to needing to run
    portions of this as root, which isn't setup for SSH. So, it's best to copy the crt to /tmp as root, then rsync
    as ec2-user, then copy on the receiving end to the correct location as root again, and then fix permissions. Use
    this command as a guide to where the result should be located when you're done.

    ```bash
    openssl crl -in $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.crl \
                -out -in /var/tmp/$CAMELZ_PKI_TLS_CA.crl \
                -outform der

    rsync -avzP /var/tmp/$CAMELZ_PKI_TLS_CA.crl cmlue1mpki01:/var/www/crl.camels.io/html/$CAMELZ_PKI_TLS_CA.crl
    ```

1. **Create CA certificate chain**

    ```bash
    cat $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.crt $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.crt > \
        $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.chain.crt
    ```

### Create the CaMeLz User Certification Authority

Perform these steps while logged in as root to the Default-PKI-CertificateAuthority Instance.

1. **Create CA directory structure**

    ```bash
    cd $CAMELZ_PKI_HOME

    mkdir -p $CAMELZ_PKI_USER_CA_HOME/db
    mkdir -p $CAMELZ_PKI_USER_CA_HOME/private
    mkdir -p $CAMELZ_PKI_USER_CA_HOME/certs

    chmod 700 $CAMELZ_PKI_USER_CA_HOME/private
    ```

1. **Create CA database**

    ```bash
    cp /dev/null $CAMELZ_PKI_USER_CA_HOME/db/$CAMELZ_PKI_USER_CA.index
    cp /dev/null $CAMELZ_PKI_USER_CA_HOME/db/$CAMELZ_PKI_USER_CA.index.attr
    openssl rand -hex 16  > $CAMELZ_PKI_USER_CA_HOME/db/$CAMELZ_PKI_USER_CA.crt.serial
    echo 1001 > $CAMELZ_PKI_USER_CA_HOME//db/$CAMELZ_PKI_USER_CA.crl.serial
    ```

1. **Copy the CA configuration file**

    This currently shows how to do this from the developer workstation containing a copy of the camels4-prototype repo,
    located at $CAMELZ_HOME. I may modify this to do a git clone on the PKI Instance, to /root/src/mjcconsulting/camelz4-prototype,
    so a local copy can be done.

    - Copy $CAMELZ_HOME/certificates/CaMeLzUserCertificationAuthority.conf  
      to $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.conf

1. **Create CA request**

    ```bash
    openssl req -new \
                -config $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.conf \
                -out $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.csr \
                -keyout $CAMELZ_PKI_USER_CA_HOME/private/$CAMELZ_PKI_USER_CA.key
    ```

1. **Verify CA request**

    Verify the Subject and Extensions are correct.

    ```bash
    openssl req -in $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.csr -text -noout
    ```

1. **Create CA certificate**

    We use the Root Certification Authority to issue the User Certification Authority certificate.

    ```bash
    openssl ca -config $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.conf \
               -in $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.csr \
               -out $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.crt \
               -extensions sub_ca_ext
    ```

1. **Verify CA certificate**

    Verify the Issuer, Validity Date Range, Subject, Public Key Size, Extensions, and CA Issuer, CRL and OCSP
    URLs are correct.

    This command is also used to save the certificate for publication on the CA Issuer website.

    ```bash
    openssl x509 -in $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.crt -text
    ```

1. **Publish CA certificate**

    Once we verify the CA certificate is correct, we need to publish it to the CA Issuer website in DER format.

    The commands below assume we have setup the appropriate AWS security groups to allow the rsync operation from the
    Default-PKI-CertificateAuthorityInstance (cmlue1mpkica01) Instance to the Default-PKI-Instance (cmlue1pki01)
    Instance, where the crt.camelz.io website is hosted, and the certificate needs to be copied as shown in the command
    below.

    Note you can't actually DO this without a lot more setup than is efficient to setup here, due to needing to run
    portions of this as root, which isn't setup for SSH. So, it's best to copy the crt to /tmp as root, then rsync
    as ec2-user, then copy on the receiving end to the correct location as root again, and then fix permissions. Use
    this command as a guide to where the result should be located when you're done.

    ```bash
    openssl x509 -in $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.crt \
                 -out /var/tmp/$CAMELZ_PKI_USER_CA.crt \
                 -outform der

    rsync -avzP /var/tmp/$CAMELZ_PKI_USER_CA.crt cmlue1mpki01:/var/www/crt.camels.io/html/$CAMELZ_PKI_USER_CA.crt
    ```

1. **Create initial CRL**

    ```bash
    openssl ca -gencrl \
               -config $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.conf \
               -out $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.crl
    ```

1. **Verify initial CRL**

    Verify the Issuer, Validity Date Range, Extensions, and CA Issuer & OCSP URLs are correct. Also that initially there
    are no revoked certificates.

    ```bash
    openssl crl -in $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.crl -text -noout
    ```

1. **Publish initial CRL**

    All published CRLs must be in DER format. MIME type: application/pkix-crl. [RFC 2585#section-4.2]

    The commands below assume we have setup the appropriate AWS security groups to allow the rsync operation from the
    Default-PKI-CertificateAuthorityInstance (cmlue1mpkica01) Instance to the Default-PKI-Instance (cmlue1pki01)
    Instance, where the crt.camelz.io website is hosted, and the certificate needs to be copied as shown in the command
    below.

    Note you can't actually DO this without a lot more setup than is efficient to setup here, due to needing to run
    portions of this as root, which isn't setup for SSH. So, it's best to copy the crt to /tmp as root, then rsync
    as ec2-user, then copy on the receiving end to the correct location as root again, and then fix permissions. Use
    this command as a guide to where the result should be located when you're done.

    ```bash
    openssl crl -in $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.crl \
                -out -in /var/tmp/$CAMELZ_PKI_USER_CA.crl \
                -outform der

    rsync -avzP /var/tmp/$CAMELZ_PKI_USER_CA.crl cmlue1mpki01:/var/www/crl.camels.io/html/$CAMELZ_PKI_USER_CA.crl
    ```

1. **Create CA certificate chain**

    ```bash
    cat $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.crt $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.crt > \
        $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.chain.crt
    ```

### Create the CaMeLz Software Certification Authority

Perform these steps while logged in as root to the Default-PKI-CertificateAuthority Instance.

1. **Create CA directory structure**

    ```bash
    cd $CAMELZ_PKI_HOME

    mkdir -p $CAMELZ_PKI_SOFTWARE_CA_HOME/db
    mkdir -p $CAMELZ_PKI_SOFTWARE_CA_HOME/private
    mkdir -p $CAMELZ_PKI_SOFTWARE_CA_HOME/certs

    chmod 700 $CAMELZ_PKI_SOFTWARE_CA_HOME/private
    ```

1. **Create CA database**

    ```bash
    cp /dev/null $CAMELZ_PKI_SOFTWARE_CA_HOME/db/$CAMELZ_PKI_SOFTWARE_CA.index
    cp /dev/null $CAMELZ_PKI_SOFTWARE_CA_HOME/db/$CAMELZ_PKI_SOFTWARE_CA.index.attr
    openssl rand -hex 16  > $CAMELZ_PKI_SOFTWARE_CA_HOME/db/$CAMELZ_PKI_SOFTWARE_CA.crt.serial
    echo 1001 > $CAMELZ_PKI_SOFTWARE_CA_HOME//db/$CAMELZ_PKI_SOFTWARE_CA.crl.serial
    ```

1. **Copy the CA configuration file**

    This currently shows how to do this from the developer workstation containing a copy of the camels4-prototype repo,
    located at $CAMELZ_HOME. I may modify this to do a git clone on the PKI Instance, to /root/src/mjcconsulting/camelz4-prototype,
    so a local copy can be done.

    - Copy $CAMELZ_HOME/certificates/CaMeLzSoftwareCertificationAuthority.conf  
      to $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.conf

1. **Create CA request**

    ```bash
    openssl req -new \
                -config $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.conf \
                -out $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.csr \
                -keyout $CAMELZ_PKI_SOFTWARE_CA_HOME/private/$CAMELZ_PKI_SOFTWARE_CA.key
    ```

1. **Verify CA request**

    Verify the Subject and Extensions are correct.

    ```bash
    openssl req -in $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.csr -text -noout
    ```

1. **Create CA certificate**

    We use the Root Certification Authority to issue the Software Certification Authority certificate.

    ```bash
    openssl ca -config $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.conf \
               -in $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.csr \
               -out $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.crt \
               -extensions sub_ca_ext
    ```

1. **Verify CA certificate**

    Verify the Issuer, Validity Date Range, Subject, Public Key Size, Extensions, and CA Issuer, CRL and OCSP
    URLs are correct.

    This command is also used to save the certificate for publication on the CA Issuer website.

    ```bash
    openssl x509 -in $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.crt -text
    ```

1. **Publish CA certificate**

    Once we verify the CA certificate is correct, we need to publish it to the CA Issuer website in DER format.

    The commands below assume we have setup the appropriate AWS security groups to allow the rsync operation from the
    Default-PKI-CertificateAuthorityInstance (cmlue1mpkica01) Instance to the Default-PKI-Instance (cmlue1pki01)
    Instance, where the crt.camelz.io website is hosted, and the certificate needs to be copied as shown in the command
    below.

    Note you can't actually DO this without a lot more setup than is efficient to setup here, due to needing to run
    portions of this as root, which isn't setup for SSH. So, it's best to copy the crt to /tmp as root, then rsync
    as ec2-user, then copy on the receiving end to the correct location as root again, and then fix permissions. Use
    this command as a guide to where the result should be located when you're done.

    ```bash
    openssl x509 -in $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.crt \
                 -out /var/tmp/$CAMELZ_PKI_SOFTWARE_CA.crt \
                 -outform der

    rsync -avzP /var/tmp/$CAMELZ_PKI_SOFTWARE_CA.crt cmlue1mpki01:/var/www/crt.camels.io/html/$CAMELZ_PKI_SOFTWARE_CA.crt
    ```

1. **Create initial CRL**

    ```bash
    openssl ca -gencrl \
               -config $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.conf \
               -out $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.crl
    ```

1. **Verify initial CRL**

    Verify the Issuer, Validity Date Range, Extensions, and CA Issuer & OCSP URLs are correct. Also that initially there
    are no revoked certificates.

    ```bash
    openssl crl -in $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.crl -text -noout
    ```

1. **Publish initial CRL**

    All published CRLs must be in DER format. MIME type: application/pkix-crl. [RFC 2585#section-4.2]

    The commands below assume we have setup the appropriate AWS security groups to allow the rsync operation from the
    Default-PKI-CertificateAuthorityInstance (cmlue1mpkica01) Instance to the Default-PKI-Instance (cmlue1pki01)
    Instance, where the crt.camelz.io website is hosted, and the certificate needs to be copied as shown in the command
    below.

    Note you can't actually DO this without a lot more setup than is efficient to setup here, due to needing to run
    portions of this as root, which isn't setup for SSH. So, it's best to copy the crt to /tmp as root, then rsync
    as ec2-user, then copy on the receiving end to the correct location as root again, and then fix permissions. Use
    this command as a guide to where the result should be located when you're done.

    ```bash
    openssl crl -in $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.crl \
                -out -in /var/tmp/$CAMELZ_PKI_SOFTWARE_CA.crl \
                -outform der

    rsync -avzP /var/tmp/$CAMELZ_PKI_SOFTWARE_CA.crl cmlue1mpki01:/var/www/crl.camels.io/html/$CAMELZ_PKI_SOFTWARE_CA.crl
    ```

1. **Create CA certificate chain**

    ```bash
    cat $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.crt $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.crt > \
        $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.chain.crt
    ```

## Operate PKI Infrastructure

All the steps below are to be run on the cmlue1mpkica01.camelz.io Instance,
created in the Default-VPC within the CaMeLz-Management Account.

### Operate the CaMeLz TLS Certification Authority

Perform these steps while logged in as root to the Default-PKI-CertificateAuthority Instance.

1. **Copy the TLS Server configuration file**

    This currently shows how to do this from the developer workstation containing a copy of the camels4-prototype repo,
    located at $CAMELZ_HOME. I may modify this to do a git clone on the PKI Instance, to /root/src/mjcconsulting/camelz4-prototype,
    so a local copy can be done.

    - Copy $CAMELZ_HOME/certificates/tls-server.conf  
      to $CAMELZ_PKI_HOME/tls-server.conf

1. **Copy the TLS Client configuration file**

    This currently shows how to do this from the developer workstation containing a copy of the camels4-prototype repo,
    located at $CAMELZ_HOME. I may modify this to do a git clone on the PKI Instance, to /root/src/mjcconsulting/camelz4-prototype,
    so a local copy can be done.

    - Copy $CAMELZ_HOME/certificates/tls-client.conf  
      to $CAMELZ_PKI_HOME/tls-client.conf


#### Create the *.camelz.io wildcard TLS Server Certificate

1. **Create TLS server request**

    ```bash
    CAMELZ_PKI_CN=*.camelz.io \
    CAMELZ_PKI_SAN=DNS:*.camelz.io,DNS:*.p.camelz.io,DNS:*.r.camelz.io,DNS:*.us-east-2.camel.io,DNS:*.us-west-2.camel.io,DNS:*.p.us-east-2.camel.io,DNS:*.p.us-west-2.camel.io,,DNS:*.r.us-east-2.camel.io,DNS:*.r.us-west-2.camel.io \
    openssl req -new \
                -config $CAMELZ_PKI_HOME/tls-server.conf \
                -out $CAMELZ_PKI_HOME/certs/star.camelz.io.csr \
                -keyout $CAMELZ_PKI_HOME/private/star.camelz.io.key
    ```

1. **Verify TLS server request**

    ```bash
    openssl req -in $CAMELZ_PKI_HOME/certs/star.camelz.io.csr -text -noout
    ```

1. **Create TLS server certificate**

    ```bash
    openssl ca -config $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.conf \
               -in $CAMELZ_PKI_HOME/certs/star.camelz.io.csr \
               -out $CAMELZ_PKI_HOME/certs/star.camelz.io.crt \
               -extensions server_ext
    ```

1. **Verify TLS server certificate**

    ```bash
    openssl x509 -in $CAMELZ_PKI_HOME/certs/star.camelz.io.crt -text -noout
    ```

1. **Create ZIP bundle**

    This is the format used to deliver commercial certificates intended for installation in Apache.
    For additional security, since it copies the private key out of the more secure private directory,
    we will password protect this file.

    ```bash
    mkdir -p $CAMELZ_PKI_HOME/certs/star.camelz.io
    cp $CAMELZ_PKI_HOME/private/star.camelz.io.key $CAMELZ_PKI_HOME/certs/star.camelz.io
    cp $CAMELZ_PKI_HOME/certs/star.camelz.io.crt $CAMELZ_PKI_HOME/certs/star.camelz.io
    cp $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.chain.crt $CAMELZ_PKI_HOME/certs/star.camelz.io/star.camelz.io.chain.crt
    zip -e -r $CAMELZ_PKI_HOME/certs/star.camelz.io.zip $CAMELZ_PKI_HOME/certs/star.camelz.io
    rm -Rf $CAMELZ_PKI_HOME/certs/star.camelz.io
    ```

1. **Create PKCS#12 bundle**

    We pack the private key, the certificate, and the CA chain into a PKCS#12 bundle for distribution.

    ```bash
    openssl pkcs12 -export \
                   -name "star.camelz.io" \
                   -caname "CaMeLz TLS Certification Authority" \
                   -caname "CaMeLz Root Certification Authority" \
                   -inkey $CAMELZ_PKI_HOME/private/star.camelz.io.key \
                   -in $CAMELZ_PKI_HOME/certs/star.camelz.io.crt \
                   -certfile $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.chain.crt \
                   -out $CAMELZ_PKI_HOME/certs/star.camelz.io.pfx
    ```

1. **Extract files from PKCS#12 bundle**

    Apache wants separate files, so if we use that format to transfer to a Linux server, we need to split the bundle
    into separate files to use them.

    ```bash
    openssl pkcs12 -in star.camelz.io.pfx \
                   -out star.camelz.io.key \
                   -nocerts -nodes
    openssl pkcs12 -in star.camelz.io.pfx \
                   -out star.camelz.io.crt \
                   -clcerts -nokeys
    openssl pkcs12 -in star.camelz.io.pfx \
                   -out star.camelz.io.chain.crt \
                   -nodes -nokeys -cacerts
    ```

#### Create the crt.camelz.io TLS Server Certificate

1. **Create TLS server request**

    ```bash
    CAMELZ_PKI_CN=crt.camelz.io \
    CAMELZ_PKI_SAN=DNS:crt.camelz.io,DNS:crt.p.camel.io,DNS:crt.r.camel.io,DNS:crt.p.us-east-2.camel.io,DNS:crt.r.us-west-2.camel.io \
    openssl req -new \
                -config $CAMELZ_PKI_HOME/tls-server.conf \
                -out $CAMELZ_PKI_HOME/certs/crt.camelz.io.csr \
                -keyout $CAMELZ_PKI_HOME/private/crt.camelz.io.key
    ```

1. **Verify TLS server request**

    ```bash
    openssl req -in $CAMELZ_PKI_HOME/certs/crt.camelz.io.csr -text -noout
    ```

1. **Create TLS server certificate**

    ```bash
    openssl ca -config $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.conf \
               -in $CAMELZ_PKI_HOME/certs/crt.camelz.io.csr \
               -out $CAMELZ_PKI_HOME/certs/crt.camelz.io.crt \
               -extensions server_ext
    ```

1. **Verify TLS server certificate**

    ```bash
    openssl x509 -in $CAMELZ_PKI_HOME/certs/crt.camelz.io.crt -text -noout
    ```

1. **Create ZIP bundle**

    This is the format used to deliver commercial certificates intended for installation in Apache.
    For additional security, since it copies the private key out of the more secure private directory,
    we will password protect this file.

    ```bash
    mkdir -p $CAMELZ_PKI_HOME/certs/crt.camelz.io
    cp $CAMELZ_PKI_HOME/private/crt.camelz.io.key $CAMELZ_PKI_HOME/certs/crt.camelz.io
    cp $CAMELZ_PKI_HOME/certs/crt.camelz.io.crt $CAMELZ_PKI_HOME/certs/crt.camelz.io
    cp $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.chain.crt $CAMELZ_PKI_HOME/certs/star.camelz.io/crt.camelz.io.chain.crt
    zip -e -r $CAMELZ_PKI_HOME/certs/crt.camelz.io.zip $CAMELZ_PKI_HOME/certs/crt.camelz.io
    rm -Rf $CAMELZ_PKI_HOME/certs/crt.camelz.io
    ```

1. **Create PKCS#12 bundle**

    We pack the private key, the certificate, and the CA chain into a PKCS#12 bundle for distribution.

    ```bash
    openssl pkcs12 -export \
                   -name "crt.camelz.io" \
                   -caname "CaMeLz TLS Certification Authority" \
                   -caname "CaMeLz Root Certification Authority" \
                   -inkey $CAMELZ_PKI_HOME/private/crt.camelz.io.key \
                   -in $CAMELZ_PKI_HOME/certs/crt.camelz.io.crt \
                   -certfile $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.chain.crt \
                   -out $CAMELZ_PKI_HOME/certs/crt.camelz.io.pfx
    ```

1. **Extract files from PKCS#12 bundle**

    Apache wants separate files, so if we use that format to transfer to a Linux server, we need to split the bundle
    into separate files to use them.

    ```bash
    openssl pkcs12 -in crt.camelz.io.pfx \
                   -out crt.camelz.io.key \
                   -nocerts -nodes
    openssl pkcs12 -in crt.camelz.io.pfx \
                   -out crt.camelz.io.crt \
                   -clcerts -nokeys
    openssl pkcs12 -in crt.camelz.io.pfx \
                   -out crt.camelz.io.chain.crt \
                   -nodes -nokeys -cacerts
    ```

#### Create the crl.camelz.io TLS Server Certificate

1. **Create TLS server request**

    ```bash
    CAMELZ_PKI_CN=crl.camelz.io \
    CAMELZ_PKI_SAN=DNS:crl.camelz.io,DNS:crl.p.camel.io,DNS:crl.r.camel.io,DNS:crl.p.us-east-2.camel.io,DNS:crl.r.us-west-2.camel.io \
    openssl req -new \
                -config $CAMELZ_PKI_HOME/tls-server.conf \
                -out $CAMELZ_PKI_HOME/certs/crl.camelz.io.csr \
                -keyout $CAMELZ_PKI_HOME/private/crl.camelz.io.key
    ```

1. **Verify TLS server request**

    ```bash
    openssl req -in $CAMELZ_PKI_HOME/certs/crl.camelz.io.csr -text -noout
    ```

1. **Create TLS server certificate**

    ```bash
    openssl ca -config $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.conf \
               -in $CAMELZ_PKI_HOME/certs/crl.camelz.io.csr \
               -out $CAMELZ_PKI_HOME/certs/crl.camelz.io.crt \
               -extensions server_ext
    ```

1. **Verify TLS server certificate**

    ```bash
    openssl x509 -in $CAMELZ_PKI_HOME/certs/crl.camelz.io.crt -text -noout
    ```

1. **Create ZIP bundle**

    This is the format used to deliver commercial certificates intended for installation in Apache.
    For additional security, since it copies the private key out of the more secure private directory,
    we will password protect this file.

    ```bash
    mkdir -p $CAMELZ_PKI_HOME/certs/crl.camelz.io
    cp $CAMELZ_PKI_HOME/private/crl.camelz.io.key $CAMELZ_PKI_HOME/certs/crl.camelz.io
    cp $CAMELZ_PKI_HOME/certs/crl.camelz.io.crt $CAMELZ_PKI_HOME/certs/crl.camelz.io
    cp $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.chain.crt $CAMELZ_PKI_HOME/certs/crl.camelz.io/star.camelz.io.chain.crt
    zip -e -r $CAMELZ_PKI_HOME/certs/crl.camelz.io.zip $CAMELZ_PKI_HOME/certs/crl.camelz.io
    rm -Rf $CAMELZ_PKI_HOME/certs/crl.camelz.io
    ```

1. **Create PKCS#12 bundle**

    We pack the private key, the certificate, and the CA chain into a PKCS#12 bundle for distribution.

    ```bash
    openssl pkcs12 -export \
                   -name "crl.camelz.io" \
                   -caname "CaMeLz TLS Certification Authority" \
                   -caname "CaMeLz Root Certification Authority" \
                   -inkey $CAMELZ_PKI_HOME/private/crl.camelz.io.key \
                   -in $CAMELZ_PKI_HOME/certs/crl.camelz.io.crt \
                   -certfile $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.chain.crt \
                   -out $CAMELZ_PKI_HOME/certs/crl.camelz.io.pfx
    ```

1. **Extract files from PKCS#12 bundle**

    Apache wants separate files, so if we use that format to transfer to a Linux server, we need to split the bundle
    into separate files to use them.

    ```bash
    openssl pkcs12 -in crl.camelz.io.pfx \
                   -out crl.camelz.io.key \
                   -nocerts -nodes
    openssl pkcs12 -in crl.camelz.io.pfx \
                   -out crl.camelz.io.crt \
                   -clcerts -nokeys
    openssl pkcs12 -in crl.camelz.io.pfx \
                   -out crl.camelz.io.chain.crt \
                   -nodes -nokeys -cacerts
    ```

#### Create the ocsp.camelz.io TLS Server Certificate

1. **Create TLS server request**

    ```bash
    CAMELZ_PKI_CN=ocsp.camelz.io \
    CAMELZ_PKI_SAN=DNS:ocsp.camelz.io,DNS:ocsp.p.camel.io,DNS:ocsp.r.camel.io,DNS:ocsp.p.us-east-2.camel.io,DNS:ocsp.r.us-west-2.camel.io \
    openssl req -new \
                -config $CAMELZ_PKI_HOME/tls-server.conf \
                -out $CAMELZ_PKI_HOME/certs/ocsp.camelz.io.csr \
                -keyout $CAMELZ_PKI_HOME/private/ocsp.camelz.io.key
    ```

1. **Verify TLS server request**

    ```bash
    openssl req -in $CAMELZ_PKI_HOME/certs/ocsp.camelz.io.csr -text -noout
    ```

1. **Create TLS server certificate**

    ```bash
    openssl ca -config $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.conf \
               -in $CAMELZ_PKI_HOME/certs/ocsp.camelz.io.csr \
               -out $CAMELZ_PKI_HOME/certs/ocsp.camelz.io.crt \
               -extensions server_ext
    ```

1. **Verify TLS server certificate**

    ```bash
    openssl x509 -in $CAMELZ_PKI_HOME/certs/ocsp.camelz.io.crt -text -noout
    ```

1. **Create ZIP bundle**

    This is the format used to deliver commercial certificates intended for installation in Apache.
    For additional security, since it copies the private key out of the more secure private directory,
    we will password protect this file.

    ```bash
    mkdir -p $CAMELZ_PKI_HOME/certs/ocsp.camelz.io
    cp $CAMELZ_PKI_HOME/private/ocsp.camelz.io.key $CAMELZ_PKI_HOME/certs/ocsp.camelz.io
    cp $CAMELZ_PKI_HOME/certs/ocsp.camelz.io.crt $CAMELZ_PKI_HOME/certs/ocsp.camelz.io
    cp $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.chain.crt $CAMELZ_PKI_HOME/certs/ocsp.camelz.io/ocsp.camelz.io.chain.crt
    zip -e -r $CAMELZ_PKI_HOME/certs/ocsp.camelz.io.zip $CAMELZ_PKI_HOME/certs/ocsp.camelz.io
    rm -Rf $CAMELZ_PKI_HOME/certs/ocsp.camelz.io
    ```

1. **Create PKCS#12 bundle**

    We pack the private key, the certificate, and the CA chain into a PKCS#12 bundle for distribution.

    ```bash
    openssl pkcs12 -export \
                   -name "ocsp.camelz.io" \
                   -caname "CaMeLz TLS Certification Authority" \
                   -caname "CaMeLz Root Certification Authority" \
                   -inkey $CAMELZ_PKI_HOME/private/ocsp.camelz.io.key \
                   -in $CAMELZ_PKI_HOME/certs/ocsp.camelz.io.crt \
                   -certfile $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.chain.crt \
                   -out $CAMELZ_PKI_HOME/certs/ocsp.camelz.io.pfx
    ```

1. **Extract files from PKCS#12 bundle**

    Apache wants separate files, so if we use that format to transfer to a Linux server, we need to split the bundle
    into separate files to use them.

    ```bash
    openssl pkcs12 -in ocsp.camelz.io.pfx \
                   -out ocsp.camelz.io.key \
                   -nocerts -nodes
    openssl pkcs12 -in ocsp.camelz.io.pfx \
                   -out ocsp.camelz.io.crt \
                   -clcerts -nokeys
    openssl pkcs12 -in ocsp.camelz.io.pfx \
                   -out ocsp.camelz.io.chain.crt \
                   -nodes -nokeys -cacerts
    ```

#### Create the Michael Crawford TLS Client Certificate

1. **Create TLS client request**

    ```bash
    CAMELZ_PKI_ST=California \
    CAMELZ_PKI_L="Santa Barbara" \
    CAMELZ_PKI_OU="Development" \
    CAMELZ_PKI_CN="Michael Crawford" \
    CAMELZ_PKI_E=mcrawford@camelz.io \
    openssl req -new \
                -config $CAMELZ_PKI_HOME/tls-client.conf \
                -out $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io.csr \
                -keyout $CAMELZ_PKI_HOME/private/mcrawford@camelz.io.key
    ```

1. **Verify TLS client request**

    ```bash
    openssl req -in $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io.csr -text -noout
    ```

1. **Create TLS client certificate**

    ```bash
    openssl ca -config $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.conf \
               -in $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io.csr \
               -out $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io.crt \
               -extensions client_ext
    ```

1. **Verify TLS client certificate**

    ```bash
    openssl x509 -in $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io.crt -text -noout
    ```

1. **Create ZIP bundle**

    This is the format used to deliver commercial certificates intended for installation in Apache.
    For additional security, since it copies the private key out of the more secure private directory,
    we will password protect this file.

    ```bash
    mkdir -p $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io
    cp $CAMELZ_PKI_HOME/private/mcrawford@camelz.io.key $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io
    cp $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io.crt $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io
    cp $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.chain.crt $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io/mcrawford@camelz.io.chain.crt
    zip -e -r $CAMELZ_PKI_HOME/certs/smcrawford@camelz.io.zip $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io
    rm -Rf $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io
    ```

1. **Create PKCS#12 bundle**

    We pack the private key, the certificate, and the CA chain into a PKCS#12 bundle for distribution.

    ```bash
    openssl pkcs12 -export \
                   -name "mcrawford@camelz.io" \
                   -caname "CaMeLz TLS Certification Authority" \
                   -caname "CaMeLz Root Certification Authority" \
                   -inkey $CAMELZ_PKI_HOME/private/mcrawford@camelz.io.key \
                   -in $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io.crt \
                   -certfile $CAMELZ_PKI_TLS_CA_HOME/$CAMELZ_PKI_TLS_CA.chain.crt \
                   -out $CAMELZ_PKI_HOME/certs/mcrawford@camelz.io.pfx
    ```

1. **Extract files from PKCS#12 bundle**

    Apache wants separate files, so if we use that format to transfer to a Linux server, we need to split the bundle
    into separate files to use them.

    ```bash
    openssl pkcs12 -in mcrawford@camelz.io.pfx \
                   -out mcrawford@camelz.io.key \
                   -nocerts -nodes
    openssl pkcs12 -in mcrawford@camelz.io.pfx \
                   -out mcrawford@camelz.io.crt \
                   -clcerts -nokeys
    openssl pkcs12 -in mcrawford@camelz.io.pfx \
                   -out mcrawford@camelz.io.chain.crt \
                   -nodes -nokeys -cacerts
    ```

1. **Revoke certificate**

    When the support contract ends, we revoke the certificate.

    ```bash
    openssl ca -config etc/tls-ca.conf \
               -revoke ca/tls-ca/02.pem \
               -crl_reason affiliationChanged
    ```

1. **Create CRL**

    The next CRL contains the revoked certificate.

    ```bash
    openssl ca -gencrl \
               -config etc/tls-ca.conf \
               -out crl/tls-ca.crl
    ```

### Operate the CaMeLz User Certification Authority

Perform these steps while logged in as root to the Default-PKI-CertificateAuthority Instance.

1. **Copy the Email configuration file**

    This currently shows how to do this from the developer workstation containing a copy of the camels4-prototype repo,
    located at $CAMELZ_HOME. I may modify this to do a git clone on the PKI Instance, to /root/src/mjcconsulting/camelz4-prototype,
    so a local copy can be done.

    - Copy $CAMELZ_HOME/certificates/email.conf  
      to $CAMELZ_PKI_HOME/email.conf

## Create the ccrawford@camelz.io Email Certificate

1. **Create email request**

    ```bash
    CAMELZ_PKI_ST=California \
    CAMELZ_PKI_L="Santa Barbara" \
    CAMELZ_PKI_OU="Development" \
    CAMELZ_PKI_CN="Cayman Crawford" \
    CAMELZ_PKI_E=ccrawford@camelz.io \
    openssl req -new \
                -config $CAMELZ_PKI_HOME/email.conf \
                -out $CAMELZ_PKI_HOME/certs/ccrawford@camelz.io.csr \
                -keyout $CAMELZ_PKI_HOME/private/ccrawford@camelz.io.key
    ```

1. **Verify email request**

    ```bash
    openssl req -in $CAMELZ_PKI_HOME/certs/ccrawford@camelz.io.csr -text -noout
    ```

1. **Create email certificate**

    ```bash
    openssl ca -config $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.conf \
               -in $CAMELZ_PKI_HOME/certs/ccrawford@camelz.io.csr \
               -out $CAMELZ_PKI_HOME/certs/ccrawford@camelz.io.crt \
               -extensions email_ext
    ```

1. **Verify email certificate**

    ```bash
    openssl x509 -in $CAMELZ_PKI_HOME/certs/ccrawford@camelz.io.crt -text -noout
    ```

1. **Create PKCS#12 bundle**

    We pack the private key, the certificate, and the CA chain into a PKCS#12 bundle. This format (often with a .pfx extension) is used to distribute keys and certificates to end users. The friendly names help identify individual certificates within the bundle.

    ```bash
    openssl pkcs12 -export \
                   -name "Cayman Crawford <ccrawford@camelz.io>" \
                   -caname "CaMeLz User Certification Authority" \
                   -caname "CaMeLz Root Certification Authority" \
                   -inkey $CAMELZ_PKI_HOME/private/ccrawford@camelz.io.key \
                   -in $CAMELZ_PKI_HOME/certs/ccrawford@camelz.io.crt \
                   -certfile $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.chain.crt \
                   -out $CAMELZ_PKI_HOME/certs/ccrawford@camelz.io.pfx
    ```

1. **Extract files from PKCS#12 bundle**

    Apache wants separate files, so if we use that format to transfer to a Linux server, we need to split the bundle
    into separate files to use them.

    ```bash
    openssl pkcs12 -in ccrawford@camelz.io.pfx \
                   -out ccrawford@camelz.io.key \
                   -nocerts -nodes
    openssl pkcs12 -in ccrawford@camelz.io.pfx \
                   -out ccrawford@camelz.io.crt \
                   -clcerts -nokeys
    openssl pkcs12 -in ccrawford@camelz.io.pfx \
                   -out ccrawford@camelz.io.chain.crt \
                   -nodes -nokeys -cacerts
    ```

## Revoke the ccrawford@camelz.io Email Certificate

1. **Revoke certificate**

    When Cayman's laptop goes missing, we revoke his certificate.

    ```bash
    serial=$(openssl x509 -noout -serial -in ccrawford@camelz.io.crt | sed -e 's/^serial=//')

    openssl ca -config $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.conf \
               -revoke $CAMELZ_PKI_USER_CA_HOME/certs/$serial.pem \
               -crl_reason keyCompromise
    ```

1. **Create updated CRL**

    The updated CRL contains the revoked certificate.

    ```bash
    openssl ca -gencrl \
               -config $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.conf \
               -out $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.crl
    ```

1. **Verify updated CRL**

    Verify the Issuer, Validity Date Range, Extensions, and CA Issuer & OCSP URLs are correct.
    Also that now we should see the recently revoked certificate.

    ```bash
    openssl crl -in $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.crl -text -noout
    ```

1. **Publish updated CRL**

    All published CRLs must be in DER format. MIME type: application/pkix-crl. [RFC 2585#section-4.2]

    The commands below assume we have setup the appropriate AWS security groups to allow the rsync operation from the
    Default-PKI-CertificateAuthorityInstance (cmlue1mpkica01) Instance to the Default-PKI-Instance (cmlue1pki01)
    Instance, where the crt.camelz.io website is hosted, and the certificate needs to be copied as shown in the command
    below.

    Note you can't actually DO this without a lot more setup than is efficient to setup here, due to needing to run
    portions of this as root, which isn't setup for SSH. So, it's best to copy the crt to /tmp as root, then rsync
    as ec2-user, then copy on the receiving end to the correct location as root again, and then fix permissions. Use
    this command as a guide to where the result should be located when you're done.

    ```bash
    openssl crl -in $CAMELZ_PKI_USER_CA_HOME/$CAMELZ_PKI_USER_CA.crl \
                -out -in /var/tmp/$CAMELZ_PKI_USER_CA.crl \
                -outform der

    rsync -avzP /var/tmp/$CAMELZ_PKI_USER_CA.crl cmlue1mpki01:/var/www/crl.camels.io/html/$CAMELZ_PKI_USER_CA.crl
    ```

### Operate the CaMeLz Software Certification Authority

Perform these steps while logged in as root to the Default-PKI-CertificateAuthority Instance.

1. **Copy the Code Sign configuration file**

    This currently shows how to do this from the developer workstation containing a copy of the camels4-prototype repo,
    located at $CAMELZ_HOME. I may modify this to do a git clone on the PKI Instance, to /root/src/mjcconsulting/camelz4-prototype,
    so a local copy can be done.

    - Copy $CAMELZ_HOME/certificates/codesign.conf  
      to $CAMELZ_PKI_HOME/codesign.conf

## Create the CaMeLz Software Certificate

1. **Create code-signing request**

    We create the private key and CSR for a code-signing certificate using another request configuration file. When prompted enter these DN components:
     C=NO, O=Green AS, OU=Green Certificate Authority, CN=Green Software Certificate.

    ```bash
    CAMELZ_PKI_OU="CaMeLz Software" \
    CAMELZ_PKI_CN="CaMeLz Software" \
    openssl req -new \
                -config $CAMELZ_PKI_HOME/codesign.conf \
                -out $CAMELZ_PKI_HOME/certs/camelz-software.csr \
                -keyout $CAMELZ_PKI_HOME/private/camelz-software.key

    ```

1. **Verify code-signing request**

    ```bash
    openssl req -in $CAMELZ_PKI_HOME/certs/camelz-software.csr -text -noout
    ```

1. **Create code-signing certificate**

    ```bash
    openssl ca -config $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.conf \
               -in $CAMELZ_PKI_HOME/certs/camelz-software.csr \
               -out $CAMELZ_PKI_HOME/certs/camelz-software.crt \
               -extensions codesign_ext
    ```

1. **Verify code-signing certificate**

    ```bash
    openssl x509 -in $CAMELZ_PKI_HOME/certs/camelz-software.crt -text -noout
    ```

1. **Create PKCS#12 bundle**

    We create a PKCS#12 bundle for distribution.

    ```bash
    openssl pkcs12 -export \
                   -name "Green Software Certificate" \
                   -caname "Green Software CA" \
                   -caname "Green Root CA" \
                   -inkey certs/software.key \
                   -in certs/software.crt \
                   -certfile ca/software-ca-chain.pem \
                   -out certs/software.pfx
    ```

1. **Create PKCS#12 bundle**

    We pack the private key, the certificate, and the CA chain into a PKCS#12 bundle. This format (often with a .pfx extension) is used to distribute keys and certificates to end users. The friendly names help identify individual certificates within the bundle.

    ```bash
    openssl pkcs12 -export \
                   -name "CaMeLz Software" \
                   -caname "CaMeLz Software Certification Authority" \
                   -caname "CaMeLz Root Certification Authority" \
                   -inkey $CAMELZ_PKI_HOME/private/camelz-software.key \
                   -in $CAMELZ_PKI_HOME/certs/camelz-software.crt \
                   -certfile $CAMELZ_PKI_SOFTWARE_CA_HOME/$CAMELZ_PKI_SOFTWARE_CA.chain.crt \
                   -out $CAMELZ_PKI_HOME/certs/camelz-software.pfx
    ```

1. **Extract files from PKCS#12 bundle**

    Apache wants separate files, so if we use that format to transfer to a Linux server, we need to split the bundle
    into separate files to use them.

    ```bash
    openssl pkcs12 -in camelz-software.pfx \
                   -out camelz-software.key \
                   -nocerts -nodes
    openssl pkcs12 -in camelz-software.pfx \
                   -out camelz-software.crt \
                   -clcerts -nokeys
    openssl pkcs12 -in camelz-software.pfx \
                   -out camelz-software.chain.crt \
                   -nodes -nokeys -cacerts
    ```

## Publish Certificates

Showing specific publishing methods separately in this section, but these are above in more detail near where each
certificate is created.

1. **Create DER certificate**

    All published certificates must be in DER format. MIME type: application/pkix-cert. [RFC 2585#section-4.1]

    ```bash
    openssl x509 -in $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.crt \
                 -in /var/tmp/$CAMELZ_PKI_ROOT_CA.cer
                 -outform der
    ```

1. **Create DER CRL**

    All published CRLs must be in DER format. MIME type: application/pkix-crl. [RFC 2585#section-4.2]

    ```bash
    openssl crl -in $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.crl \
                -out -in /var/tmp/$CAMELZ_PKI_ROOT_CA.crl \
                -outform der
    ```

1. **Create PKCS#7 bundle**

    PKCS#7 is used to bundle two or more certificates. MIME type: application/pkcs7-mime. [RFC 5273#page-3]

    ```bash
    openssl crl2pkcs7 -nocrl \
                      -certfile $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.chain.crt \
                      -out $CAMELZ_PKI_ROOT_CA_HOME/$CAMELZ_PKI_ROOT_CA.chain.p7c \
                      -outform der
    ```

## Research Notes

### How to Download & Convert Examples

Use these commands to download & convert examples of certificates, CRLs & OCSP checks, to understand industry best
practices on how to setup a PKI.

1. ** Obtain Certificate Chains**

    ```bash
    sites=( "www.akamai.com" \
            "www.macys.com" \
            "www.nytimes.com" \
            "www.washingtonpost.com" )

    for site in $sites; do
      clear
      echo "Checking site $site ..."
      openssl s_client -showcerts -verify 5 -connect $site:443 < /dev/null
    done
    ```

1. ** Download & Convert CA Issuer certificates**

    These should be in DER format, so we must download, convert to PEM, then convert to Text.

    ```bash
    cd /tmp

    ca_issuer_urls=( "http://crt.rootca1.amazontrust.com/rootca1.cer" \
                     "http://crt.rootg2.amazontrust.com/rootg2.cer" \
                     "http://cacerts.digicert.com/DigiCertGlobalRootCA.crt" \
                     "http://secure.globalsign.com/cacert/root-r3.crt" \
                     "http://pki.goog/repo/certs/gtsr1.der" \
                     "http://crt.usertrust.com/USERTrustRSAAddTrustCA.crt" \
                     "http://crt.sectigo.com/SectigoRSAOrganizationValidationSecureServerCA.crt" \
                     "http://aia.entrust.net/l1m-chain256.cer" )

    for url in $ca_issuer_urls; do
      file=${url##*/}
      cer=${file%.*}.cer
      crt=${file%.*}.crt
      txt=${file%.*}.txt

      curl $url > $file
      mv $file $cer

      openssl x509 -inform der -in $cer -out $crt
      openssl x509 -text -in $crt > $txt
    done
    ```

1. ** Download & Convert CRLs**

    These should be in DER format, so we must download, convert to PEM, then convert to Text.

    Results:
    - Validity Period: 1 year for Root is common, 7 days for Issuing is common, but also see 21 days
    - Extensions: authorityKeyIdentifier only
    - CrlNumbers: 4040, 619, 4657, 17 are examples

    ```bash
    cd /tmp

    crl_urls=( "http://crl.rootca1.amazontrust.com/rootca1.crl" \
               "http://crl.rootg2.amazontrust.com/rootg2.crl" \
               "http://crl3.digicert.com/DigiCertGlobalRootCA.crl" \
               "http://crl.comodoca.com/COMODOCertificationAuthority.crl" \
               "http://crl.comodoca.com/AAACertificateServices.crl" \
               "http://crl.entrust.net/g2ca.crl" \
               "http://crl.globalsign.com/root-r3.crl" \
               "http://crl.godaddy.com/gdroot-g2.crl" \
               "http://crl.pki.goog/gtsr1/gtsr1.crl" \
               "http://crls.pki.goog/gts1c3/fVJxbV-Ktmk.crl" \
               "http://crl.usertrust.com/USERTrustRSACertificationAuthority.crl" \
               "http://crl.entrust.net/level1m.crl" )

    for url in $crl_urls; do
      crl=${url##*/}
      pem=${crl%.*}.crl.pem
      txt=${crl%.*}.crl.txt

      curl $url > $crl

      openssl x509 -inform der -in $cer -out $crt
      openssl x509 -text -in $crt > $txt

      openssl crl -inform der -in $crl -out $pem
      openssl crl -text -in $pem > $txt
    done
    ```

1. ** Verify OSCP Responses**

    ```bash
    sites=( "www.akamai.com" \
            "www.macys.com" \
            "www.nytimes.com" \
            "www.washingtonpost.com" )

    for site in $sites; do
      clear
      echo "Checking site $site ..."
      openssl s_client -connect $site:443 < /dev/null 2>&1 |  sed -n '/-----BEGIN/,/-----END/p' > $site.crt
      openssl s_client -showcerts -connect www.akamai.com:443 < /dev/null 2>&1 |  sed -n '/-----BEGIN/,/-----END/p' > $site.chain.crt

      ocsp_url=$(openssl x509 -noout -ocsp_uri -in $site.crt) && echo "ocsp url = $ocsp_url"

      openssl ocsp -issuer $site.chain.crt -cert $site.crt -text -url $ocsp_url
      sleep 5
    done
    ```

### Certification Authority Issuer URL Examples

- http://crt.rootca1.amazontrust.com/rootca1.cer
- http://crt.rootg2.amazontrust.com/rootg2.cer
- http://cacerts.digicert.com/DigiCertGlobalRootCA.crt
- http://secure.globalsign.com/cacert/root-r3.crt
- http://pki.goog/repo/certs/gtsr1.der
- http://crt.usertrust.com/USERTrustRSAAddTrustCA.crt
- http://crt.sectigo.com/SectigoRSAOrganizationValidationSecureServerCA.crt
- http://aia.entrust.net/l1m-chain256.cer

### Certificate Revocation List URL Examples

- http://crl.$domain_suffix/$name.crl
- http://crl.rootca1.amazontrust.com/rootca1.crl
- http://crl.rootg2.amazontrust.com/rootg2.crl
- http://crl3.digicert.com/DigiCertGlobalRootCA.crl
- http://crl.comodoca.com/COMODOCertificationAuthority.crl
- http://crl.comodoca.com/AAACertificateServices.crl
- http://crl.entrust.net/g2ca.crl
- http://crl.globalsign.com/root-r3.crl
- http://crl.godaddy.com/gdroot-g2.crl
- http://crl.pki.goog/gtsr1/gtsr1.crl
- http://crls.pki.goog/gts1c3/fVJxbV-Ktmk.crl
- http://crl.usertrust.com/USERTrustRSACertificationAuthority.crl
- http://crl.entrust.net/level1m.crl

### Online Certificate Status Protocol URL Examples

- http://ocsp.$domain_suffix
- http://ocsp.rootca1.amazontrust.com
- http://ocsp.rootg2.amazontrust.com
- http://ocsp.digicert.com
- http://ocsp.entrust.net
- http://ocsp2.globalsign.com/rootr3
- http://ocsp.godaddy.com/
- http://ocsp.pki.goog/gtsr1
- http://ocsp.usertrust.com
- http://ocsp.sectigo.com


## Fixes
1. Remove Extended key usage in TLS Certificate Authority - maybe? Some do have this, may need to have 2 separate sub_ca_ext sections, with for the TLS, without for the others
1. Add nameConstraint for email in TLS Certificate Authority
