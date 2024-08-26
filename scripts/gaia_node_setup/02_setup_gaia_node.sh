# Background:
# Setup Gaia Testnet node on a new Ubuntu server.

# Steps:
# 1. Install Go
# 2. Build gaiad binary from source
# 3. Install Cosmovisor
# 4. Setup Gaia Testnet service
# 5. Run node and verify journalctl logs

# Constants:
APP_USER_NAME=$1
APP_USER_HOME_DIR="/home/$APP_USER_NAME"
GO_INSTALL_URL="https://go.dev/dl/go1.22.5.linux-amd64.tar.gz"
COSMOVISOR_PACKAGE_URL="cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.5.0"
GAIA_LATEST_VERSION=$(curl -s https://api.github.com/repos/cosmos/gaia/releases/latest | jq -r '.tag_name')
GAIA_GITHUB_REPO="https://github.com/cosmos/gaia.git"
GAIA_SERVICE_NAME="gaia-testnet"
NODE_CHAIN_ID="theta-testnet-001"
NODE_DATA_DIR="/home/$APP_USER_NAME/.gaia"
NODE_MONIKER="my-node"
NODE_GENESIS_URL="https://github.com/cosmos/testnets/raw/master/release/genesis.json.gz"
NODE_SYNC_RPC_1=https://rpc.state-sync-01.theta-testnet.polypore.xyz:443
NODE_SYNC_RPC_2=https://rpc.state-sync-02.theta-testnet.polypore.xyz:443
NODE_SYNC_RPC_SERVERS="$NODE_SYNC_RPC_1,$NODE_SYNC_RPC_2"

### 1. Install Go
echo "##############################################"
echo "Installing Go"
echo "##############################################"
cd $APP_USER_HOME_DIR
wget $GO_INSTALL_URL
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf $(basename $GO_INSTALL_URL)
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin
go version

### 2. Build gaiad from source and setup
echo "##############################################"
echo "Building gaiad from source"
echo "##############################################"
cd $APP_USER_HOME_DIR
sudo rm -rf gaia
git clone $GAIA_GITHUB_REPO
cd gaia
git checkout $GAIA_LATEST_VERSION
make install
echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
export PATH=$PATH:$HOME/go/bin
gaiad init $NODE_MONIKER --chain-id $NODE_CHAIN_ID --home $NODE_DATA_DIR
gaiad config set client chain-id $NODE_CHAIN_ID --home $NODE_DATA_DIR
gaiad config set client keyring-backend test --home $NODE_DATA_DIR

# Prepare the genesis file
echo "##############################################"
echo "Downloading genesis file"
echo "##############################################"
cd $APP_USER_HOME_DIR
wget $NODE_GENESIS_URL
gzip -d genesis.json.gz
mv genesis.json $NODE_DATA_DIR/config/genesis.json
# Set minimum gas price & peers
cd $NODE_DATA_DIR/config
sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "0.005uatom"/' app.toml
sed -i 's/seeds = ""/seeds = "639d50339d7045436c756a042906b9a69970913f@seed-01.theta-testnet.polypore.xyz:26656,3e506472683ceb7ed75c1578d092c79785c27857@seed-02.theta-testnet.polypore.xyz:26656"/' config.toml

# State Sync Setup
echo "##############################################"
echo "Setting up State Sync"
echo "##############################################"
CURRENT_BLOCK=$(curl -s $NODE_SYNC_RPC_1/block | jq -r '.result.block.header.height')
TRUST_HEIGHT=$(($CURRENT_BLOCK - 1000))
TRUST_BLOCK=$(curl -s $NODE_SYNC_RPC_1/block\?height\=$TRUST_HEIGHT)
TRUST_HASH=$(echo $TRUST_BLOCK | jq -r '.result.block_id.hash')
sed -i -e '/enable =/ s/= .*/= true/' $NODE_DATA_DIR/config/config.toml
sed -i -e '/trust_period =/ s/= .*/= "8h0m0s"/' $NODE_DATA_DIR/config/config.toml
sed -i -e "/trust_height =/ s/= .*/= $TRUST_HEIGHT/" $NODE_DATA_DIR/config/config.toml
sed -i -e "/trust_hash =/ s/= .*/= \"$TRUST_HASH\"/" $NODE_DATA_DIR/config/config.toml
sed -i -e "/rpc_servers =/ s^= .*^= \"$NODE_SYNC_RPC_SERVERS\"^" $NODE_DATA_DIR/config/config.toml

### 3. Setup Cosmovisor
echo "##############################################"
echo "Installing Cosmovisor"
echo "##############################################"
go install $COSMOVISOR_PACKAGE_URL
mkdir -p $NODE_DATA_DIR/cosmovisor/genesis/bin
cp $APP_USER_HOME_DIR/go/bin/gaiad $NODE_DATA_DIR/cosmovisor/genesis/bin/ # setup Cosmovisor genesis bin as current gaiad

### 4. Set service file

# setup number of open files limit
echo "* soft nofile 400000" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 500000" | sudo tee -a /etc/security/limits.conf

# setup service file
echo "##############################################"
echo "Setting up Gaia Testnet service"
echo "##############################################"
sudo tee /etc/systemd/system/$GAIA_SERVICE_NAME.service >/dev/null <<EOF
[Unit]
Description=Gaiad Testnet Daemon (cosmovisor)
After=network-online.target

[Service]
User=$APP_USER_NAME
ExecStart=/home/$APP_USER_NAME/go/bin/cosmovisor run start --home $NODE_DATA_DIR --x-crisis-skip-assert-invariants
Restart=always
RestartSec=3
LimitNOFILE=20000
Environment="DAEMON_NAME=gaiad"
Environment="DAEMON_HOME=$NODE_DATA_DIR"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_LOG_BUFFER_SIZE=512"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target
EOF

# Enable service
sudo systemctl daemon-reload

### 5. Run node and verify journalctl logs
echo "##############################################"
echo "Starting Gaia Testnet service"
echo "##############################################"
sudo systemctl start $GAIA_SERVICE_NAME
# journalctl -u $GAIA_SERVICE_NAME -f
