#!/bin/bash
curl --location 'https://id.twitch.tv/oauth2/device'\
    --form 'client_id="p4o11tboz7cctfmpymrlw3u5wmj0ao"'\
    --form 'scopes="chat:read chat:edit"'