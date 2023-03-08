#!/bin/bash

#Install AWS_CLI
sudo apt-get update
sudo apt-get install -y awscli jq

sudo mkdir /opt/tfe

PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)

cat > /tmp/tfe_settings.json <<EOF
{
    "enc_password": {
        "value": "${tfe-pwd}"
    },
    "hairpin_addressing": {
        "value": "0"
    },
    "hostname": {
        "value": "$PUBLIC_DNS"
    },
    "production_type": {
        "value": "disk"
    },
    "disk_path": {
        "value": "/opt/tfe"
    }
}
EOF

json=/tmp/tfe_settings.json

jq -r . $json
if [ $? -ne 0 ] ; then
    echo ERR: $json is not a valid json
    exit 1
fi

# create replicated unattended installer config
cat > /etc/replicated.conf <<EOF
{
  "DaemonAuthenticationType": "password",
  "DaemonAuthenticationPassword": "${tfe-pwd}",
  "TlsBootstrapType": "self-signed",
  "TlsBootstrapHostname": "$PUBLIC_DNS",
  "LogLevel": "debug",
  "ImportSettingsFrom": "/tmp/tfe_settings.json",
  "LicenseFileLocation": "/tmp/license.rli",
  "BypassPreflightChecks": true
}
EOF

json=/etc/replicated.conf
jq -r . $json
if [ $? -ne 0 ] ; then
    echo ERR: $json is not a valid json
    exit 1
fi

# install replicated
curl -Ls -o /tmp/install.sh https://install.terraform.io/ptfe/stable
sudo bash /tmp/install.sh \
        release-sequence=${tfe_release_sequence} \
        no-proxy \
        private-address=$PRIVATE_IP \
        public-address=$PUBLIC_IP