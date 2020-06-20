#! /bin/bash

# in order to write to this folder, need to run as root
APP_DIR="/var/lib/ipmonitor"
API_KEY_FILE="${APP_DIR}/api_key"
LAST_IP_FILE="${APP_DIR}/last_ip"

mkdir -p $APP_DIR
if [[ ! -f $API_KEY_FILE ]]; then
    echo "Need to put sendgrid api key in ${API_KEY_FILE}"
    exit 1
fi
if [[ -z $1 ]]; then
    echo "Give me an email address as an argument"
    exit 2
fi

TO_EMAIL_ADDR=$1

FROM_EMAIL_ADDR="abraham.simpson@oldmanyellsat.cloud"
FROM_EMAIL_NAME="Abraham Simpson"
EMAIL_SUBJECT="IP Address Update: ${HOSTNAME}"
EMAIL_BODY="IP address of machine ${HOSTNAME} has changed: ${OLD_IP} -> ${NEW_IP}"

SENDGRID_API_KEY=`cat $API_KEY_FILE`
[[ -f $LAST_IP_FILE ]] && OLD_IP=`cat $LAST_IP_FILE` || OLD_IP="(none)"
NEW_IP=`dig +short myip.opendns.com @resolver1.opendns.com`
if [[ $OLD_IP != $NEW_IP ]]; then
    echo "IP has changed: ${OLD_IP} -> ${NEW_IP}"
    echo "${NEW_IP}" > $LAST_IP_FILE

    curl --request POST \
      --url https://api.sendgrid.com/v3/mail/send \
      --header "Authorization: Bearer ${SENDGRID_API_KEY}" \
      --header 'Content-Type: application/json' \
      --data "{\"personalizations\": [{\"to\": [{\"email\": \"${TO_EMAIL_ADDR}\"}]}],\"from\": {\"email\": \"${FROM_EMAIL_ADDR}\", \"name\": \"${FROM_EMAIL_NAME}\"},\"subject\": \"${EMAIL_SUBJECT}\",\"content\": [{\"type\": \"text/plain\", \"value\": \"${EMAIL_BODY}\"}]}"
else
    echo "IP still ${NEW_IP}, nothing to do"
fi
