# Variables:
# thiszone=tgwwalk.dxc-ap.com
# thisserver=$(!GetAtt BindENI.PrimaryPrivateIpAddress)
#
#!/bin/bash
yum install -y bind bind-libs bind-utils
chkconfig named on
cp  /etc/named.conf /etc/named.conf.Bk
echo >  /etc/named.conf
cat << 'EOF' >> /etc/named.conf
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
# i.e. Do not cache DNS query failure.
 max-ncache-ttl 1200; # 3 seconds
# Disable non-relevant operations
 allow-transfer { none; };
 allow-update-forwarding { none; };
 allow-notify { none; };
 allow-recursion { any; };
};
zone "${thiszone}" in {
type master;
file "/etc/named/db.${thiszone}";
allow-update { none; };
};
zone "aws.${thiszone}" in {
type forward;
forwarders { 10.0.8.11; 10.0.16.11; };
};
EOF
echo >  /etc/named/db.${thiszone}
cat << 'EOF' >> /etc/named/db.${thiszone}
$TTL 86400
@       IN      SOA     ${thiszone}. admin.${thiszone}. (
            3         ; Serial
            604800     ; Refresh
            86400     ; Retry
            2419200     ; Expire
            604800 )   ; Negative Cache TTL

        ; name servers - NS records
@        IN      NS      ns1.${thiszone}.com.

; name servers - A records
ns1          IN      A       ${thisserver}
test        IN      A      ${thisserver}

; other servers
dc1         IN      A      10.4.16.10

$ORIGIN aws.${thiszone}.
@       IN      NS      ep1.aws.${thiszone}.

        IN      NS      ep2.aws.${thiszone}.

ep1 IN      A       10.0.8.11
ep2 IN      A       10.0.16.11
EOF

systemctl start named
