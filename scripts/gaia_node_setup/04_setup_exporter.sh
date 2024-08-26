# Constants
APP_USER_NAME=$1
EXPORTER_SERVICE_NAME=go-gaia-exporter
EXPORTER_PATH=/home/$APP_USER_NAME/p2p_org_solana/tools/gaia_node_exporter

# Setup go env for the script
cd $EXPORTER_PATH
echo "##############################################"
echo "Setting up go env"
echo "##############################################"
/usr/local/go/bin/go mod init gaia_node_exporter
/usr/local/go/bin/go mod tidy

# setup service file
echo "##############################################"
echo "Setting up the exporter service"
echo "##############################################"
sudo tee /etc/systemd/system/$EXPORTER_SERVICE_NAME.service >/dev/null <<EOF
[Unit]
Description=Gaiad Node Exporter
After=network-online.target

[Service]
User=$APP_USER_NAME
WorkingDirectory=$EXPORTER_PATH
ExecStart=/usr/local/go/bin/go run main.go
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable $EXPORTER_SERVICE_NAME

### 5. Run the exporter service
echo "##############################################"
echo "Starting the exporter service"
echo "##############################################"
sudo systemctl start $EXPORTER_SERVICE_NAME
