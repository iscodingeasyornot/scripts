#!/bin/bash

# Check if the user is root or sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "You do not have root privileges. Exiting."
    exit 1
fi

# Default to stable repository
isMainline=""

# Parse command line options
while getopts "m" opt; do
  case $opt in
    m)
      isMainline="/mainline"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
# Check distribution
if [[ -f /etc/os-release ]]; then
    source /etc/os-release

    case $ID in
        debian)
            # Install prerequisites for Debian
            apt-get install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring
            # Fetch nginx signing key
            curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
            # Verify the downloaded key
            gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
            # Set up apt repository
            echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages$isMainline/debian $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
            # Set up repository pinning
            echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx
            # Install nginx
            apt-get update
            apt-get install -y nginx
            ;;

        ubuntu)
            # Install prerequisites for Ubuntu
            apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
            # Fetch nginx signing key
            curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
            # Verify the downloaded key
            gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
            # Set up apt repository
            echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages$isMainline/ubuntu $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
            # Set up repository pinning
            echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx
            # Install nginx
            apt-get update
            apt-get install -y nginx
            ;;

        alpine)
            # Install prerequisites for Alpine
            apk add openssl curl ca-certificates
            # Set up apk repository
            printf "%s%s%s%s\n" "@nginx " "http://nginx.org/packages$isMainline/alpine/v$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)/main" | tee -a /etc/apk/repositories
            # Fetch nginx signing key
            curl -o /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub
            # Verify the downloaded key
            openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout
            # Move the key to apk trusted keys storage
            mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/
            # Install nginx
            apk add nginx@nginx
            ;;
            
        *)
            echo "This distribution is not supported."
            exit 1
            ;;
    esac
else
    echo "Could not determine distribution."
    exit 1
fi
