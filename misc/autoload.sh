#!/bin/bash

# set the IP and API token here or via the
# SONNEN_API_IP
# SONNEN_API_TOKEN
# environment variables or via -i (IP) and -t (token) parameters.
# Command line take precedence over environment variables. 
sonnen_api_ip=$SONNEN_API_IP
sonnen_api_token=$SONNEN_API_TOKEN 



usage() { echo "Usage: $0 -w watts -p percentage [-i IP address] [-t sonnen API token]" 1>&2; exit 1; }

while getopts ":w:p:i:t:" o; do
    case "${o}" in
        w)
            watts=${OPTARG}
            ;;
        p)
            percent=${OPTARG}
            ;;
        i) 
            sonnen_api_ip=${OPTARG}
            ;;
        t)  
            sonnen_api_token=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND-1))

if [ -z "${watts}" ] || [ -z "${percent}" ]; then
    usage
fi

if [ -z "${sonnen_api_ip}" ] || [ -z "${sonnen_api_token}" ]; then
    echo "API key and IP for the Sonnenbatterie need to be set in your environment "
    echo "using"
    echo "export SONNEN_API_IP="
    echo "export SONNEN_API_TOKEN=" 
    echo "prior to running this script"
    echo "-- Alternatively, you can pass them via the -i (IP) and -t (token) "
    echo "command line parameters when calling the script"
    exit 1
fi

# Check if the argument is a valid number
if ! [[ $watts =~ ^[0-9]+$ ]]; then
  echo "Error: Watts must be a numerical value."
  exit 1
fi

if ! [[ $percent =~ ^[0-9]+$ ]]; then
  echo "Error: Percent must be a numerical value (<= 100)."
  exit 1
fi

if [ $percent -gt 100 ]; then
    echo "Charge to more than 100% - you gotta be kidding. Exiting."
    exit 1
elif [ $percent -lt 1 ]; then
    echo "Charge to less than 1% - you gotta be kidding. Exiting."
    exit 1
fi

if [ $watts -gt 4600 ]; then
    echo "4600 Watts is the Sonnenbatterie's maximum charge power, limiting to 4600"
    watts=4600
elif [ $watts -lt 1 ]; then
    echo "Less than 1 Watt? You don't want to charge. Exiting."
    exit 1
fi

error_log="curl_error.log"

# init SB manual charging state and start charging
set_om_json=$(curl -sS -X PUT -d EM_OperatingMode=1 --header "Auth-Token: $sonnen_api_token" "http://$sonnen_api_ip/api/v2/configurations" 2>"$error_log")

if [ $? -ne 0 ]; then
    
    # Extract and display the error message
    error_message=$(cat "$error_log")
    
    echo "Something went wrong: " $error_message
    echo "                  IP: " $sonnen_api_ip
    echo "               Token: " $sonnen_api_token
    exit 1

fi

set_om=$(echo $set_om_json | jq -r .EM_OperatingMode)

if [ "$set_om" != "1" ]; then
    echo "Something went wrong: " $set_om_json
    echo "                  IP: " $sonnen_api_ip
    echo "               Token: " $sonnen_api_token
    exit 1
fi

devnull=$(curl -sS -X POST --header "Auth-Token: $sonnen_api_token" -d "" "http://$sonnen_api_ip/api/v2/setpoint/charge/$watts")

# get the current SoC 

battery_json=$(curl -sS -X GET --header "Auth-Token: $sonnen_api_token" "http://$sonnen_api_ip/api/v2/latestdata")

soc=$(echo $battery_json | jq .USOC)
current_charge=$(echo $battery_json | jq .Pac_total_W)
echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1 Current SoC: $soc% - Starting to charge with" $watts "Watts up to" $percent "%"


spinner=( '/' '-' '\' '|' )


while [ $soc -lt $percent ]; do
    counter=0
    while [ $counter -lt 60 ]; do
        echo -n -e "[${spinner[counter % ${#spinner[@]}]}] Desired SoC: " $percent "%, current SoC" $soc "% -- current charge power" $current_charge "Watts\r"
        counter=$((counter + 1))
        sleep 0.5
    done 
    # takes 30 seconds, we don't want a DoS attack on the battery ;-)
    # also, using the spinner, you can see the script is still running, even with longer
    # periods between curl'ing the battery.
    battery_json=$(curl -sS -X GET --header "Auth-Token: $sonnen_api_token" "http://$sonnen_api_ip/api/v2/latestdata")

    soc=$(echo $battery_json | jq .USOC)
    current_charge=$(echo $battery_json | jq .Pac_total_W)
done

echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1 Charging done, SoC is "$soc"%, resetting Battery to normal state (self consumption)"

curl -sS -X PUT -d EM_OperatingMode=2 --header "Auth-Token: $sonnen_api_token" "http://$sonnen_api_ip/api/v2/configurations"
echo
echo "--Finished--"
