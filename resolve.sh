# wg0.conf post-processing
for conf in */wg0.conf.ini; do
	echo INPUT && cat $conf

	endpoint=$(grep "Endpoint" $conf | cut -d "=" -f2)
	host=$(echo $endpoint | cut -d ":" -f1)
	host=$(echo $host | xargs) # trim whitespace
	port=$(echo $endpoint | cut -d ":" -f2)
	resolved=$(host $host | awk '/has address/ {print $4}') # resolves the hostname
	sed "s/Endpoint.*/Endpoint = $resolved:$port/g" $conf > ./tmp.conf
	sed 's/Address.*/&\/24/g' ./tmp.conf > $(dirname $conf)/wg0.conf
	echo OUTPUT && cat $(dirname $conf)/wg0.conf
done
