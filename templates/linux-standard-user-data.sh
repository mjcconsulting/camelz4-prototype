#!/bin/bash -xe
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1
yum update -y
hostnamectl set-hostname @hostname@
echo -e '#!/bin/sh\ncat << EOF\n\n@motd@\n\nEOF' > /etc/update-motd.d/30-banner
update-motd
cat > /etc/profile.d/local.sh << EOF
alias lsa='ls -lAF'
alias ip4='ip addr | grep " inet "'
EOF
