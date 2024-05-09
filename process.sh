# requirements: docker installed and running, vm connectable/ip assigned
# COUNTRIES="DE NL"
# PASS="<PASSWORD>"
# ./process.sh

# AUTH bootstrapping
for COUNTRY in $COUNTRIES; do
	rm -rf tokens/ # we need to reauthenticate for each concurrent connection
	docker run \
		--name='cyberghostvpn' \
		--privileged=true \
		--cap-add=NET_ADMIN  \
		-e 'ACC'='sebibek@gmail.com' \
		-e 'PASS'="$PASS" \
		-e 'COUNTRY'="$COUNTRY" \
		-v './tokens':'/home/root/.cyberghost:rw' \
		-d $(echo $(docker image ls --format json|head -n1|jq -r .ID))
	
	sleep 30 # wait for container to connect
	# bootstrap wireguard config
	mkdir $COUNTRY
	cp ./tokens/wg0.conf ./$COUNTRY/wg0.conf.ini # wg config template
	docker rm -f cyberghostvpn
done

source resolve.sh

# run gluetun instances since they are more stable and can scale better
i=0; for COUNTRY in $COUNTRIES; do
	docker run -d -e HTTPPROXY=on -p $((8000+$i)):8888 --cap-add=NET_ADMIN \
		-e VPN_SERVICE_PROVIDER=custom -e VPN_TYPE=wireguard \
		-v ./$COUNTRY:/gluetun/wireguard \
		qmcgaw/gluetun
	((i++))
done

# proxies will be available on localhost: 8000, 8001, 8002, etc.