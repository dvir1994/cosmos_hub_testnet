# p2p.org - Home assignment

Task:
------------
1. Deploy a Cosmos Hub testnet node.

2. Develop a Prometheus exporter in Go to collect metrics from the Cosmos node
    - `gaia_block_height` - latest block height of the node.
    - `gaia_block_time_drift_seconds` - time difference between current time and block creation time.
    - `gaia_peers_count` - total peers connected to the node.
    - `gaia_peers_by_version` - connected peers grouped by Cosmos version.

3. Use security best practices - Lynis score > 80

* Note: node and exporter should run via systemd services that survive reboot.

Artifacts:
----------------
1. Shell script:
   - Setup: Gaia testnet node, Prometheus exporter, Nginx reverse proxy and security measures.
```bash
cd ~
git clone https://github.com/dvir1994/p2p_org_solana.git && cd p2p_org_solana

./main.sh <app_user_name>
```

2. Golang:
   - Prometheus exporter to collect and expose node metrics.
   - Can be found at `tools/gaia_node_exporter/main.go`

3. Nginx config:
    - Reverse proxy to allow for HTTPS secure connection to RPC + Websocket endpoints.
    - Uses basic_auth.
    - Can be found at `config/nginx_config.conf`

Security:
------------------------
1. Secure Shell Configuration (SSH):
   - SSH access allowed only to specific IPs (office/VPN).
   - Only SSH allowed for authentication - Password-based login is disabled.
   - SSH connections secured with `fail2ban` to protect against brute-force attacks.

2. Firewall Configuration:
   - A firewall has been configured to allow only necessary traffic (e.g., SSH, Cosmos P2P, Prometheus metrics).
   - All other ports are closed by default.

3. User management:
   - Dedicated app for node and exporter (with a strong password).
   - Root login is disabled.

4. Setup and configure ufw

5. Configure password expiration policies

6. Hardening SSH configurations

7. Installed chkrootkit

8. And more, full script can be found at scripts/06_security_implementations.sh

Suggestions:
------------------------

1. Having that services run with restart policy of always is nice but not enough, a better indication that our node is alive is needed, for example I would add a tool to calculate diff between our node latest block and public RPC latest block, because the service can be alive but it does not always mean the node is working as expected.

2. Deploy on Hetzner to save cost, plus many others peers are on Hetzner DC so that our node can be closer to them.

3. Use LVM to allow future scalability of disk - usually needed in blockchain nodes.

4. Forward node logs to centralized logging platform (e.g. New Relic/ELK) and setup alerts (to Slack/PagerDuty)
   - Currently, only metrics are collected.
   - This will help with both observability and troubleshooting.
   - Most simple would be to use remote_write integration by New Relic

5. Implement SELinux in enforcing mode to provide an additional layer of security.

6. Create a Slack RSS feed notification for new releases for the cosmos/gaia repo - https://github.com/cosmos/gaia/releases
    - From exprience, even though we are using Cosmovisor in this assignment and upgrades should be handled automatically, it is better to know about upgrades in advance, update that in the schedule and see that the upgrade went well.
    - To setup the RSS feed run the following in any Slack channel `/feed subscribe https://github.com/cosmos/gaia/releases.atom`

7. Use IaC tools like Terraform to automate the node provisioning process. This can help for creating additional nodes for testing purposes or DR.

Resources:
-----------

- Tendermint Metrics - https://docs.tendermint.com/v0.34/tendermint-core/metrics.html

- Prometheus resources (exporters and best practices):
    - https://prometheus.io/docs/instrumenting/writing_exporters/
    - https://prometheus.io/docs/practices/naming/

- Joining testnet documentation - https://hub.cosmos.network/main/hub-tutorials/join-testnet.html
