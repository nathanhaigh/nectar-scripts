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

# For each user that needs to login to this VM, create a user account and generate an SSH key
PASSWORD_LENGTH=10
users=(
  user1
  user2
  user3
  user4
)
echo "Setting up users on this VM:"
for user in "${users[@]}"; do
  password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-${PASSWORD_LENGTH}};echo;)

  echo -ne "\t${user}:${password} ... "
  useradd --shell /bin/bash --create-home ${user}
  echo -e "${user}:${password}" | chpasswd
  echo "DONE"
done

echo "Commands for creating a key and copying its public SSH key to this VM:"
for user in "${users[@]}"; do
  echo -e "\tssh-keygen -t rsa -C 'NeCTAR API VM' -N 'your_secret_passphrase' -f \$HOME/.ssh/nectar_api_vm && ssh-copy-id -i \$HOME/.ssh/nectar_api_vm ${user}@$(ifconfig eth0 | awk -F'[: ]+' '/inet addr:/ {print $4}')"
done
echo "=================================================================================="
echo "After enabling SSH key access for the above users, disable password authentication"
echo -e "\tsed -i -e '$aPasswordAuthentication no' /etc/ssh/sshd_config"
echo "=================================================================================="

# Setup SSH keys for each user so they can add the public key to the NeCTAR dashboard.
# This will mean they can use that key to launch their own VM's on the cloud
echo "Add these public keys to the NeCTAR dashboard. This will allow you to use OpenStack API's from this VM"
for user in "${users[@]}"; do
  su - "${user}" -c 'bash -c "ssh-keygen -t rsa -q -N \"\" -f $HOME/.ssh/id_rsa"'
  echo -e "\t${user}\n$(cat /home/${user}/.ssh/id_rsa.pub)\n-----"
done

