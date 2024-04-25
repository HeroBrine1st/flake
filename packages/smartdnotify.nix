{ config, lib, pkgs, ... }: pkgs.writeShellApplication {
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.coreutils ];
    name = "smartdnotify";
    text = ''
#!/bin/bash

set -e

body=$(cat <<-END
{
  "content": $(jq --null-input --arg text "$SMARTD_MESSAGE" '$text'),
  "embeds": [
    {
      "title": "$SMARTD_FAILTYPE",
      "description": $(jq --null-input --arg text "$SMARTD_FULLMESSAGE" '$text'),
      "color": 16711680,
      "fields": [
        {
          "name": "Device",
          "value": "$SMARTD_DEVICE ($SMARTD_DEVICETYPE)"
        },
        {
          "name": "First encounter",
          "value": "<t:$SMARTD_TFIRSTEPOCH:d>"
        },
        {
          "name": "Message number",
          "value": "$((SMARTD_PREVCNT + 1))",
          "inline": true
        },
        {
          "name": "Next message in",
          "value": "$SMARTD_PREVCNT days",
          "inline": true
        }
      ]
    }
  ],
  "username": "Fusion",
  "avatar_url": "https://cdn.discordapp.com/avatars/564403404688850973/5255509ed9be331c5b37aa873c279e6b.png",
  "attachments": []
}
END
)

curl --header "Content-Type: application/json"  --request POST --data "$body" --silent --show-error https://discord.com/api/webhooks/658390924052660246/1nSDsGIsGvyT3EsMKoaWCyAcGyZxQ0T37nNBN29chel-4EtWgWhgpY1c8gfTqRqsNsfV
    '';
}