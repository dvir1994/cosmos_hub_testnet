# check the sync status of the node

total_waited=0
eta=420 # 7 minutes in seconds

echo "##############################################"
echo "Checking sync status of the node"
echo "##############################################"

while true; do
    catching_up=$(curl -s http://localhost:26657/status | jq -r '.result.sync_info.catching_up')
    if [ "$catching_up" == "false" ]; then
        echo "Node is synced"
        break
    else
        echo "Node is catching up"
        echo "Latest block height: $(curl -s http://localhost:26657/status | jq -r '.result.sync_info.latest_block_height')"

        total_waited=$((total_waited + 10))
        remaining_time=$((eta - total_waited))
        echo "Elapsed: $total_waited seconds"
        echo "ETA: $remaining_time seconds"

        echo "Sleeping for 10 seconds"
        sleep 10
        echo "---------------------------------"
    fi
done
