#!/bin/bash
# Set the timezone
TIMEZONE='Australia/Adelaide'
echo "${TIMEZONE}" > /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# Install the Openstack (OS) API clients using pip
apt-get update
apt-get install -y python-pip python-dev libffi-dev libssl-dev build-essential
pip install python-novaclient python-swiftclient python-keystoneclient python-glanceclient

# Install parallel-ssh
apt-get install -y pssh

