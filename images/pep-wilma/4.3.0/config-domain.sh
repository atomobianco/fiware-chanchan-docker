#!/bin/bash

[ -z "${AUTHZFORCE_HOSTNAME}" ] && echo "AUTHZFORCE_HOSTNAME is undefined.  Using default value of 'authzforce'" && export AUTHZFORCE_HOSTNAME=authzforce
[ -z "${AUTHZFORCE_PORT}" ] && echo "AUTHZFORCE_PORT is undefined.  Using default value of '8080'" && export AUTHZFORCE_PORT=8080
[ -z "${IDM_HOSTNAME}" ] && echo "IDM_HOSTNAME is undefined.  Using default value of 'idm'" && export IDM_HOSTNAME=idm
[ -z "${IDM_PORT}" ] && echo "IDM_PORT is undefined.  Using default value of '5000'" && export IDM_PORT=5000
declare DOMAIN=''

# fix variables when using docker-compose
if [[ ${AUTHZFORCE_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
    export AUTHZFORCE_PORT=${BASH_REMATCH[1]}
fi
if [[ ${IDM_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
    export IDM_PORT=${BASH_REMATCH[1]}
fi

function check_host_port () {

    local _timeout=10
    local _tries=0
    local _is_open=0

    if [ $# -lt 2 ] ; then
    echo "check_host_port: missing parameters."
    echo "Usage: check_host_port <host> <port> [max-tries]"
    exit 1
    fi

    local _host=$1
    local _port=$2
    local _max_tries=${3:-${_timeout}}
    local NC=$( which nc )

    if [ ! -e "${NC}" ] ; then
    echo "Unable to find 'nc' command."
    exit 1
    fi

    echo "Testing if port '${_port}' is open at host '${_host}'."

    while [ ${_tries} -lt ${_max_tries} -a ${_is_open} -eq 0 ] ; do
    echo -n "Checking connection to '${_host}:${_port}' [try $(( ${_tries} + 1 ))] ... "
    if ${NC} -z -w ${_timeout} ${_host} ${_port} ; then
        echo "OK."
        _is_open=1
    else
        echo "Failed."
        sleep 1
        _tries=$(( ${_tries} + 1 ))
    fi
    done

    if [ ${_is_open} -eq 0 ] ; then
    echo "Failed to connect to port '${_port}' on host '${_host}' after ${_tries} tries."
    echo "Port is closed or host is unreachable."
    exit 1
    else
    echo "Port '${_port}' at host '${_host}' is open."
    fi
}


function check_domain () {

    if [ $# -lt 2 ] ; then
    echo "check_host_port: missing parameters."
    echo "Usage: check_host_port <host> <port> [max-tries]"
    exit 1
    fi

    local _host=$1
    local _port=$2

    # Request to Authzforce to retrieve Domain

    DOMAIN="$(curl -s --request GET http://${AUTHZFORCE_HOSTNAME}:${AUTHZFORCE_PORT}/authzforce/domains | awk '/href/{print $NF}' | cut -d '"' -f2)" 

    # Checks if the Domain exists. If not, creates one

    if [ -z "$DOMAIN" ]; then 
        echo "Domain is not created yet!"
        curl -s --request POST --header "Content-Type: application/xml;charset=UTF-8" --data '<?xml version="1.0" encoding="UTF-8"?><taz:properties xmlns:taz="http://thalesgroup.com/authz/model/3.0/resource"><name>MyDomain</name><description>This is my domain.</description></taz:properties>' --header "Accept: application/xml" http://${AUTHZFORCE_HOSTNAME}:${AUTHZFORCE_PORT}/authzforce/domains --output /dev/null
        DOMAIN="$(curl -s --request GET http://${AUTHZFORCE_HOSTNAME}:${AUTHZFORCE_PORT}/authzforce/domains | awk '/href/{print $NF}' | cut -d '"' -f2)"
        echo "Domain has been created: $DOMAIN"
    else
        echo "Domain value is not empty: "
        echo $DOMAIN
    fi

}

# Call checks

check_host_port ${AUTHZFORCE_HOSTNAME} ${AUTHZFORCE_PORT}
check_host_port ${IDM_HOSTNAME} ${IDM_PORT}
check_domain ${AUTHZFORCE_HOSTNAME} ${AUTHZFORCE_PORT}


# Configure PEP Proxy adding authzforce complete URL

sed -e "s@^    path:@    path:'/authzforce/domains/$DOMAIN/pdp'@" -i /opt/fi-ware-pep-proxy/config.js

# Configure Domain permissions to user 'pepproxy' at IdM

FRESHTOKEN="$(curl -s -i   -H "Content-Type: application/json"   -d '{ "auth": {"identity": {"methods": ["password"], "password": { "user": { "name": "idm", "domain": { "id": "default" }, "password": "idm"} } } } }' http://${IDM_HOSTNAME}:${IDM_PORT}/v3/auth/tokens | grep ^X-Subject-Token: | awk '{print $2}')"
MEMBERID="$(curl -s -H "X-Auth-Token:$FRESHTOKEN" -H "Content-type: application/json" http://${IDM_HOSTNAME}:${IDM_PORT}/v3/roles | python -m json.tool | grep -iw id | awk -F'"' '{print $4}' | head -n 1)"
REQUEST="$(curl -s -X PUT -H "X-Auth-Token:$FRESHTOKEN" -H "Content-type: application/json" http://${IDM_HOSTNAME}:${IDM_PORT}/v3/domains/default/users/pepproxy/roles/${MEMBERID})"

echo "User pepproxy has been granted with:"
echo "Role: ${MEMBERID}"
echo "Token:  $FRESHTOKEN"

# Start container back

exec /sbin/init