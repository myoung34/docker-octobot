{RtmClient, WebClient} = require "@slack/client"
fs = require('fs')

module.exports = (robot) ->
  web = new WebClient(process.env.HUBOT_SLACK_TOKEN);

  robot.hear /^!snapshot$/i, (res) ->
    res.send "Getting snapshot"
    child = require 'child_process'

    uniqueId = (length=8) ->
      id = ""
      id += Math.random().toString(36).substr(2) while id.length < length
      id.substr 0, length

    downloadFile = (url, fileName) ->

    tmpFileName="/tmp/" + uniqueId() + ".jpg"
    fileName="images/" + uniqueId() + ".jpg"

    url = "#{process.env.OCTOPRINT_PROTOCOL}#{process.env.OCTOPRINT_URL}:#{process.env.OCTOPRINT_PORT}/?action=snapshot"
    child.exec "curl #{url} > #{tmpFileName} && convert #{tmpFileName} -rotate 90 #{fileName}", (err, stdout, stderr) ->
      throw err if err
      web.files.upload(fileName, {message: '',channels: '#general', filetype: 'jpg', mimetype: 'image/jpeg', file: fs.readFileSync(fileName)},(err, response) -> 
      );
