# Setup a Gaia Testnet node

# usage function
usage() {
    echo "Missing app_user_name argument - needed to avoid using root"
    echo "Usage: $0 <app_user_name>"
    echo "---------------------------------"
    exit 1
}

# check if app user name is provided
if [ -z "$1" ]; then
    usage
fi

APP_USER_NAME=$1
ALLOWED_PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFxFhO7cTS+ZDoKXb6seleZrcThCOEvkoAbbEbEy60IK dvir@Dvirs-MacBook-Pro.local"

### Create an app user
adduser --disabled-password --gecos "" $APP_USER_NAME
usermod -aG sudo $APP_USER_NAME
echo "$APP_USER_NAME ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$APP_USER_NAME
sudo chmod 0440 /etc/sudoers.d/$APP_USER_NAME
mkdir -p /home/$APP_USER_NAME/.ssh
ssh-keygen -t rsa -N "" -f /home/$APP_USER_NAME/.ssh/id_rsa <<<y
echo $ALLOWED_PUBLIC_KEY >>/home/$APP_USER_NAME/.ssh/authorized_keys

# Run the scripts by order by the newly created app user
sudo -i -u $APP_USER_NAME bash <<EOF
cd ~
git clone https://github.com/dvir1994/p2p_org_solana.git && cd p2p_org_solana

./scripts/gaia_node_setup/01_init.sh $APP_USER_NAME
./scripts/gaia_node_setup/02_setup_gaia_node.sh $APP_USER_NAME
./scripts/gaia_node_setup/03_check_sync_status.sh
./scripts/gaia_node_setup/04_setup_exporter.sh $APP_USER_NAME
./scripts/gaia_node_setup/05_setup_nginx.sh $APP_USER_NAME
./scripts/gaia_node_setup/06_security_implementations.sh
EOF

# Switch to use the app user
su - $APP_USER_NAME
cd /home/$APP_USER_NAME
