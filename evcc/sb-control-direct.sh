#!/bin/sh

############## GLOBAL VARS ##############
BASEDIR=`dirname $0`
VERSION="--EVCC SBCONTROL--"
#########################################

checkCommands() {
	command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required but it's not installed.  Aborting."; exit 1; }
	command -v curl >/dev/null 2>&1 || { echo >&2 "curl is required but it's not installed.  Aborting."; exit 1; }
}


idleBattery() {

	error_message=""

	# init SB manual/API mode (OperatingMode = "1") 
	set_operatingmode_json=$(curl -sS -X PUT -d EM_OperatingMode=1 --header "Auth-Token: $SONNEN_API_TOKEN" "http://$SONNEN_API_IP/api/v2/configurations" 2>&1)

	if [ $? -ne 0 ]; then
		# capturing cURL execution errors
		# Extract and store the error message
		error_message=$(echo "$set_operatingmode_json" | tail -n 1)
		
		echo "Something went wrong: $error_message"
		echo "                  IP: $SONNEN_API_IP"
		echo "               Token: $SONNEN_API_TOKEN"
		exit 1
	fi
	
	set_om=$(echo $set_operatingmode_json | jq -r .EM_OperatingMode)

	if [ "$set_om" != "1" ]; then
		# catching API Errors, expected output is the new OperatingMode in JSON
		echo "Something went wrong: " $set_operatingmode_json
		echo "                  IP: " $SONNEN_API_IP
		echo "               Token: " $SONNEN_API_TOKEN
		exit 1
	fi 

	# it will remember its last command in manual/API, therefore we explicitly need to set it to
	# charge: 0 watts
	# discharge: 0 watts

	# assuming we caught any cURL process errors above, no need for additional checking
	# forcing charge = 0
	devnull=$(curl -sS -X POST --header "Auth-Token: $SONNEN_API_TOKEN" -d "" "http://$SONNEN_API_IP/api/v2/setpoint/charge/0")
	if [ "$devnull" != "true" ]; then
		# catching API Errors, expected output is "true"
		echo "Something went wrong: " $devnull
		echo "                  IP: " $SONNEN_API_IP
		echo "               Token: " $SONNEN_API_TOKEN
		exit 1
	fi 

	# forcing discharge = 0, so battery is effectively idle (neither charging nor discharging).
	devnull=$(curl -sS -X POST --header "Auth-Token: $SONNEN_API_TOKEN" -d "" "http://$SONNEN_API_IP/api/v2/setpoint/discharge/0")
	if [ "$devnull" != "true" ]; then
		# catching API Errors, expected output is "true"
		echo "Something went wrong: " $devnull
		echo "                  IP: " $SONNEN_API_IP
		echo "               Token: " $SONNEN_API_TOKEN
		exit 1
	fi

}

reactivateBattery() {
	
	error_message=""

	# set to self consumption again (OperatingMode = "2") 
	set_operatingmode_json=$(curl -sS -X PUT -d EM_OperatingMode=2 --header "Auth-Token: $SONNEN_API_TOKEN" "http://$SONNEN_API_IP/api/v2/configurations" 2>&1)

	if [ $? -ne 0 ]; then
		# capturing cURL execution errors
		# Extract and store the error message
		error_message=$(echo "$set_operatingmode_json" | tail -n 1)
		
		echo "Something went wrong: $error_message"
		echo "                  IP: $SONNEN_API_IP"
		echo "               Token: $SONNEN_API_TOKEN"
		exit 1
	fi
	
	set_om=$(echo $set_operatingmode_json | jq -r .EM_OperatingMode)

	if [ "$set_om" != "2" ]; then
		# catching API Errors, expected output is the new OperatingMode in JSON
		echo "Something went wrong: " $set_operatingmode_json
		echo "                  IP: " $SONNEN_API_IP
		echo "               Token: " $SONNEN_API_TOKEN
		exit 1
	fi 



}


############ MAIN ###########


[ ! -f $BASEDIR/settings.env ] && echo "missing settings.env file. Please copy the provided settings.env.example and adjust values." && exit 1
. $BASEDIR/settings.env

checkCommands

case $1 in
	vehicle_connected)
		echo $2
		;;
	vehicle_disconnected)
		echo $2
		;;
	charging_started)
		echo $2
		echo "Stopping battery discharge"
		idleBattery
		;;
	charging_stopped)
		echo $2
		echo "Enabling battery normal mode"
		reactivateBattery
		;;
	soc_changed)
		echo "SoC changed: " $2
		;;
	*)
		echo Unknown event type
		exit 1
		;;
esac