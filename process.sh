
for conf in */wg0.conf; do
    cat $conf
	endpoint=$(grep "Endpoint" $conf | cut -d "=" -f2)
	host=$(echo $endpoint | cut -d ":" -f1)
	port=$(echo $endpoint | cut -d ":" -f2)
	resolved=$(host $host | awk '/has address/ {print $4}') # resolves the hostname
	sed "s/Endpoint.*/Endpoint = $resolved:$port/g" $conf > ./tmp.conf
	sed 's/Address.*/&\/24/g' ./tmp.conf > $conf
	cat $conf
done