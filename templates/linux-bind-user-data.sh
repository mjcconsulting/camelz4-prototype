#!/bin/bash -xe
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

yum install -y bind bind-libs bind-utils
yum update -y

hostnamectl set-hostname @hostname@

echo -e '#!/bin/sh\ncat << EOF\n\n@motd@\n\nEOF' > /etc/update-motd.d/30-banner
update-motd

cat > /etc/profile.d/local.sh << EOF
alias lsa='ls -lAF'
alias ip4='ip addr | grep " inet "'
EOF

cp -a  /etc/named.conf /etc/named.conf.orig
cat > /etc/named.conf << EOF
options {
  directory "/var/named";
  version "not currently available";
  # Listen to the loopback device only
  listen-on { any; };
  listen-on-v6 { ::1; };
  # Do not query from the specified source port range
  # (Adjust depending your firewall configuration)
  avoid-v4-udp-ports { range 1 32767; };
  avoid-v6-udp-ports { range 1 32767; };
  # Forward all DNS queries to the Google Public DNS.
  forwarders { 8.8.8.8;4.2.2.5; };
  # forward only;
  # Expire negative answer ASAP.
  max-ncache-ttl 1200; # 3 seconds
  # Disable non-relevant operations
  allow-transfer { none; };
  allow-update-forwarding { none; };
  allow-notify { none; };
  allow-recursion { any; };
};

zone "@domainname@" in {
  type master;
  file "/etc/named/db.@domainname@";
  allow-update { none; };
};

zone "aws.@domainname@" in {
  type forward;
  forwarders { 10.0.8.11; 10.0.16.11; };
};
EOF

cat >> /etc/named/db.@domainname@ << EOF
$TTL 86400
@       IN      SOA     @domainname@. admin.@domainname@. (
            3         ; Serial
            604800     ; Refresh
            86400     ; Retry
            2419200     ; Expire
            604800 )   ; Negative Cache TTL

        ; name servers - NS records
@        IN      NS      ns1.@domainname@.com.

; name servers - A records
ns1          IN      A       ${thisserver}
test        IN      A      ${thisserver}

; other servers
dc1         IN      A      10.4.16.10

$ORIGIN aws.@domainname@.
@       IN      NS      ep1.aws.@domainname@.

        IN      NS      ep2.aws.@domainname@.

ep1 IN      A       10.0.8.11
ep2 IN      A       10.0.16.11
EOF

chkconfig named on

systemctl start named
