# requirements: docker installed and running, vm connectable/ip assigned

# USAGE

# export COUNTRIES="DE NL"
# PASS="<PASSWORD>"
# source process.sh

# AUTH bootstrapping using forked https://github.com/tmcphee/cyberghostvpn
for COUNTRY in $(echo $COUNTRIES|xargs); do
	rm -rf tokens/ # we need to reauthenticate for each concurrent (VPN) connection
	docker run \
		--name='cyberghostvpn' \
		--privileged=true \
		--cap-add=NET_ADMIN  \
		-e 'ACC'='sebibek@gmail.com' \
		-e 'PASS'="$PASS" \
		-e 'COUNTRY'="$COUNTRY" \
		-v './tokens':'/home/root/.cyberghost:rw' \
		-d zebswag/cyberghostvpn-debug
	
	sleep 30 # wait for container to connect
	# bootstrap wireguard config
	mkdir $COUNTRY
	cp ./tokens/wg0.conf ./$COUNTRY/wg0.conf.ini # wg config template
	docker rm -f cyberghostvpn
done

# real wireguard needs addr range and resolved IP to connect
source resolve.sh # wg0.conf.ini -> wg0.conf

# run gluetun instances by mounting wg0.conf(s) since they are more stable and can scale better (req. 300MB/instance)
i=0; for COUNTRY in $(echo $COUNTRIES|xargs); do
	docker run -d -e HTTPPROXY=on -p $((8000+$i)):8888 --cap-add=NET_ADMIN --restart=always \
		-e VPN_SERVICE_PROVIDER=custom -e VPN_TYPE=wireguard \
		-v ./$COUNTRY:/gluetun/wireguard \
		qmcgaw/gluetun # always makes them reconnect on startup

	((i++))
done

# local proxies will be available on localhost: 8000, 8001, 8002, etc.