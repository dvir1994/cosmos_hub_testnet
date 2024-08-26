# Background:
# Setup Gaia Testnet node on a new Ubuntu server.

# Steps:
# 1. Pre-flight checks
# 2. Run apt-get update and upgrade
# 3. Disable root user
# 4. Disable password authentication and only allow SSH key authentication

### 1. Pre-flight checks

# usage function
usage() {
    echo "Missing argument for script execution"
    echo "Usage: $0 <app_user_name>"
    echo "---------------------------------"
    exit 1
}
# check the amount of memory available, shoule be more than 8GB
total_memory=$(free -m | awk '/^Mem:/{print $2}')
if [ $total_memory -lt 8000 ]; then
    echo "Not enough memory, please use a server with at least 8GB of memory"
    exit 1
fi
# check the amount of free disk space, should be more than 300GB
total_disk_space=$(df -h / | awk '/\//{print $4}')
if [ ${total_disk_space::-1} -lt 100 ]; then
    echo "Not enough disk space, please use a server with at least 100GB of disk space"
    exit 1
fi
# check if password is provided
if [ -z "$1" ]; then
    usage
fi

### 2. Run apt-get update and upgrade, and build-essential to build gaiad
echo "Running apt-get update and upgrade"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt install -y curl wget build-essential jq make gcc git

# Constants:
APP_USER_NAME=$1

### 3. Disable root user
echo "Disabling root user"
sudo passwd -l root

### 4. Disable password authentication and only allow SSH key authentication
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sudo systemctl restart ssh.service
