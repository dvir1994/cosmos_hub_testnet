echo "##############################################"
echo "Implementing security measures"
echo "##############################################"

# Avoid inbteractive termnial prompts
export DEBIAN_FRONTEND=noninteractive
sudo echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
sudo echo "postfix postfix/mailname string $(hostname -f)" | debconf-set-selections
sudo apt-get install -y postfix

### Add security updates to the sources list
echo "Adding security updates to the sources list"
sudo add-apt-repository -y "deb http://security.ubuntu.com/ubuntu $(lsb_release -sc)-security main"
sudo apt update

### Install fail2ban
echo "Installing fail2ban"
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

### Install ufw
echo "Installing ufw"
echo "y" | sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 26656/tcp
sudo ufw allow 26657/tcp
sudo ufw allow 9090/tcp
sudo ufw allow 6060/tcp
sudo ufw allow 80/tcp

### Sets password expiration policies
echo "Setting password expiration policies"
sudo sed -i 's/^PASS_MIN_DAYS\s\+[0-9]\+/PASS_MIN_DAYS   1/' /etc/login.defs
sudo sed -i 's/^PASS_MAX_DAYS\s\+[0-9]\+/PASS_MAX_DAYS   90/' /etc/login.defs

### Patch management
echo "Installing apt-show-versions"
sudo apt install -y apt-show-versions

### List all locked accounts and remove them
echo "Removing locked accounts"
for user in $(sudo awk -F: '$2 ~ /^\*/ {print $1}' /etc/shadow); do
    # do not delete the www-data user since it will be needed later for nginx
    if [[ "$user" != "www-data" ]]; then
        sudo deluser "$user"
    fi
done

### Harden SSH configurations
echo "Harden SSH configurations"
sudo sed -i '/^AllowTcpForwarding/c\AllowTcpForwarding no' /etc/ssh/sshd_config
sudo sed -i '/^ClientAliveCountMax/c\ClientAliveCountMax 2' /etc/ssh/sshd_config
sudo sed -i '/^LogLevel/c\LogLevel VERBOSE' /etc/ssh/sshd_config
sudo sed -i '/^MaxAuthTries/c\MaxAuthTries 3' /etc/ssh/sshd_config
sudo sed -i '/^MaxSessions/c\MaxSessions 2' /etc/ssh/sshd_config
sudo sed -i '/^Port/c\Port <your_custom_port>' /etc/ssh/sshd_config # Replace <your_custom_port> with a non-default port number
sudo sed -i '/^TCPKeepAlive/c\TCPKeepAlive no' /etc/ssh/sshd_config
sudo sed -i '/^X11Forwarding/c\X11Forwarding no' /etc/ssh/sshd_config
sudo sed -i '/^AllowAgentForwarding/c\AllowAgentForwarding no' /etc/ssh/sshd_config
# Restart SSH service to apply changes
sudo systemctl restart ssh

### Displays a warning message to unauthorized users
echo "Displaying a warning message to unauthorized users"
echo "Unauthorized access to this system is prohibited. All activities are monitored and recorded." | sudo tee /etc/issue
echo "Unauthorized access to this system is prohibited. All activities are monitored and recorded." | sudo tee /etc/issue.net

### Displays critical bugs before APT installations
echo "Installing apt-listbugs"
sudo apt-get install -y apt-listbugs

### Displays significant changes before APT upgrades
echo "Installing apt-listchanges"
sudo apt-get install -y apt-listchanges

### Verifies package integrity with a known-good database
echo "Installing debsums"
sudo apt-get install -y debsums

### Set $TMP and $TMPDIR for PAM sessions
echo "Setting $TMP and $TMPDIR for PAM sessions"
sudo apt install -y libpam-tmpdir

# Install chkrootkit
echo "Installing chkrootkit"
sudo apt install -y chkrootkit

### Collects system statistics
echo "Installing sysstat"
sudo apt install -y sysstat
sudo sed -i 's/^ENABLED=.*/ENABLED="true"/' /etc/default/sysstat # Enable sysstat data collection
sudo systemctl enable sysstat
sudo systemctl start sysstat

### Disable non-essential services
echo "Disabling non-essential services"
echo "blacklist usb-storage" | sudo tee /etc/modprobe.d/blacklist-usb-storage.conf
echo "blacklist dccp" | sudo tee /etc/modprobe.d/blacklist-dccp.conf
echo "blacklist sctp" | sudo tee /etc/modprobe.d/blacklist-sctp.conf
echo "blacklist rds" | sudo tee /etc/modprobe.d/blacklist-rds.conf
echo "blacklist tipc" | sudo tee /etc/modprobe.d/blacklist-tipc.conf
# Update the initramfs to apply changes
sudo update-initramfs -u

# Install the process accounting package
echo "Installing process accounting package"
sudo apt install -y acct
sudo accton /var/log/account/pacct
sudo systemctl enable acct
sudo systemctl start acct

# Install the auditd package
echo "Installing auditd package"
sudo apt install -y auditd
sudo systemctl enable auditd
sudo systemctl start auditd
sudo systemctl status auditd

# Install the AIDE package
echo "Installing AIDE package"
sudo apt install -y aide
sudo aideinit
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Restrict access to the gcc binary so only root can execute it
echo "Restricting access to the gcc binary"
sudo chmod 700 $(which gcc)

# Install the logwatch package
echo "Installing logwatch package"
sudo apt install -y logwatch
