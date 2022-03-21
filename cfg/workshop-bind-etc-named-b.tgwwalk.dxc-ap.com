$TTL 86400
@       IN      SOA     tgwwalk.camelz.io. admin.tgwwalk.camelz.io. (
            3         ; Serial
            604800     ; Refresh
            86400     ; Retry
            2419200     ; Expire
            604800 )   ; Negative Cache TTL

        ; name servers - NS records
@        IN      NS      ns1.tgwwalk.camelz.io.com.

; name servers - A records
ns1          IN      A       10.4.12.79
test        IN      A      10.4.12.79

; other servers
dc1         IN      A      10.4.16.10

$ORIGIN aws.tgwwalk.camelz.io.
@       IN      NS      ep1.aws.tgwwalk.camelz.io.

        IN      NS      ep2.aws.tgwwalk.camelz.io.

ep1 IN      A       10.0.8.11
ep2 IN      A       10.0.16.11
