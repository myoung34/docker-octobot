OctoBot
=======

A hubot Slack bot designed to work with [octoprint](http://octoprint.org)


![snapshot](img/snapshot.png) 
![status](img/status.png)
![stop](img/status.png)

## Commands

`!stop {printer}` - stop a print
`!cancel {printer}` - stop a print
`!snapshot {printer}` - stop a print
`!status {printer}` - stop a print

## Configuration

Almost everything is configured with environment variables:

`HUBOT_SLACK_TOKEN` - The slack token to use. Generate one [here](https://slack.dev/hubot-slack/)
`HUBOT_SLACK_CHANNEL` - The slack channel to use.
`HUBOT_NAME` - The bot name to assign in slack
`CONFIG` - The JSON configuration. See below

The configuration is a JSON object that represents one or more printers:

```json
{
  "taz": {
    "OCTOPRINT_URL": "192.168.2.100",
    "OCTOPRINT_PROTOCOL": "http://",
    "OCTOPRINT_PORT": "80",
    "MJPG_PORT": "8080",
    "ROTATE": "0",
    "OCTOPRINT_API_TOKEN": "1111111111111111"
  },
  "prusa": {
    "OCTOPRINT_URL": "192.168.2.110",
    "OCTOPRINT_PROTOCOL": "http://",
    "OCTOPRINT_PORT": "80",
    "MJPG_PORT": "8080",
    "ROTATE": "90",
    "OCTOPRINT_API_TOKEN": "2222222222222222"
  }
}
```

## Example

```bash
cat <<EOF >.env
HUBOT_SLACK_TOKEN=xoxb-...
CONFIG={"taz": {"OCTOPRINT_URL": "192.168.2.100", "OCTOPRINT_PROTOCOL": "http://", "OCTOPRINT_PORT": "80", "MJPG_PORT": "8080", "OCTOPRINT_API_TOKEN": "SOMETOKENVALUE"}}
EOF

make run
```
