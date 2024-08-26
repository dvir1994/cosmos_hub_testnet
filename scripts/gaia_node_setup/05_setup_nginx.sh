# Constants
APP_USER_NAME=$1
NGINX_CONFIG_PATH=/home/$APP_USER_NAME/p2p_org_solana/config

echo "##############################################"
echo "Installing nginx"
echo "##############################################"

# Install nginx
sudo apt-get install -y nginx apache2-utils
# preparations for certbot:
# sudo apt install certbot python3-certbot-nginx -y
# sudo certbot --nginx -d domain.com
# echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -


# Generate a random credentials for basic auth
nginx_username=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 42 | head -n 1)
secret_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 42 | head -n 1)

echo $nginx_username $secret_password >>/tmp/basic_auth_users.txt
echo "Basic auth:$nginx_username $secret_password"
echo "User:$nginx_username"
echo "Password:$secret_password"

# Create a new user for nginx basic auth
sudo htpasswd -b -c /etc/nginx/.htpasswd $nginx_username $secret_password

sudo cp $NGINX_CONFIG_PATH/nginx_config.conf /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

echo "Nginx installed and configured"
