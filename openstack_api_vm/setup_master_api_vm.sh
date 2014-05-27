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
echo "Setting up users:"
for user in "${users[@]}"; do
  password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-${PASSWORD_LENGTH}};echo;)

  echo -ne "\t${user}:${password} ... "
  useradd --shell /bin/bash --create-home ${user}
  echo -e "${user}:${password}" | chpasswd
  echo "DONE"
done

echo "Commands for copying your public SSH keys to this VM and disabling password login:"
for user in "${users[@]}"; do
  echo -e "\tssh-copy-id ${user}@$(ifconfig eth0 | awk -F'[: ]+' '/inet addr:/ {print $4}') && ssh ${user}@$(ifconfig eth0 | awk -F'[: ]+' '/inet addr:/ {print $4}') passwd --delete ${user}"
done

# Setup SSH keys for each user so they can add the public key to the NeCTAR dashboard.
# This will mean they can use that key to launch their own VM's on the cloud
echo "Setting up SSH keys for users:"
for user in "${users[@]}"; do
  su - "${user}" -c 'bash -c "ssh-keygen -t rsa -q -N \"\" -f $HOME/.ssh/id_rsa"'
  echo -e "\t${user}\n$(cat /home/${user}/.ssh/id_rsa.pub)\n-----"
done

