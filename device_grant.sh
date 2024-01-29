#!/bin/bash
read -p "device code: " DEVICE_CODE
curl --location 'https://id.twitch.tv/oauth2/token'\
    --form 'client_id="p4o11tboz7cctfmpymrlw3u5wmj0ao"'\
    --form 'scope="chat:read chat:edit"'\
    --form 'device_code="'$DEVICE_CODE'"'\
    --form 'grant_type="urn:ietf:params:oauth:grant-type:device_code"'
