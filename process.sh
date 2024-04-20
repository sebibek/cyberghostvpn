# requirements: docker installed and running, vm connectable/ip assigned

COUNTRIES="NL DE"
# AUTH bootstrapping
for COUNTRY in $COUNTRIES; do
	rm -rf tokens/ # we need to reauthenticate for each concurrent connection
	docker run \
	--name='cyberghostvpn' \
	--privileged=true \
	--cap-add=NET_ADMIN  \
	-e 'ACC'='sebibek@gmail.com' \
	-e 'PASS'='pass' \
	-e 'COUNTRY'="$COUNTRY" \
	-v './tokens':'/home/root/.cyberghost:rw' \
	-d $(echo $(docker image ls --format json|head -n1|jq -r .ID))
	
	sleep 30 # wait for container to connect
	# bootstrap wireguard config
	mkdir $COUNTRY
	cp ./tokens/wg0.conf ./$COUNTRY/wg0.conf
	docker rm -f cyberghostvpn
done

# wg0.conf post-processing
for conf in */wg0.conf; do
    echo INPUT && cat $conf
	cp $conf $conf.ini # backup

	endpoint=$(grep "Endpoint" $conf | cut -d "=" -f2)
	host=$(echo $endpoint | cut -d ":" -f1)
	port=$(echo $endpoint | cut -d ":" -f2)
	resolved=$(host $host | awk '/has address/ {print $4}') # resolves the hostname
	sed "s/Endpoint.*/Endpoint = $resolved:$port/g" $conf > ./tmp.conf
	sed 's/Address.*/&\/24/g' ./tmp.conf > $conf
	echo OUTPUT && cat $conf
done

# run gluetun instances since they are more stable and can scale better
i=0; for COUNTRY in $COUNTRIES; do
	docker run -d -e HTTPPROXY=on -p $((8000+$i)):8888 --cap-add=NET_ADMIN \
	-e VPN_SERVICE_PROVIDER=custom -e VPN_TYPE=wireguard \
	-v ./$COUNTRY:/gluetun/wireguard \
	qmcgaw/gluetun
	((i++))
done

# proxies will be available on localhost: 8000, 8001, 8002, etc.