{RtmClient, WebClient} = require "@slack/client"
fs = require('fs')

module.exports = (robot) ->
  web = new WebClient(process.env.HUBOT_SLACK_TOKEN);
  config = JSON.parse(process.env.CONFIG)

  robot.listen(
    # Matcher
    (message) ->
      return unless message.text
      message.match(/^!snapshot ?(.*)?$/)
    (response) ->
      printer = response.match[1]
      printerConfig = config["#{printer}"]
      if !printerConfig 
       printerConfig = config[Object.keys(config)[0]]; 

      if printer
        response.send "Getting snapshot for #{printer} (#{printerConfig.OCTOPRINT_URL})"
      else
        response.send "Getting snapshot"

      uniqueId = (length=8) ->
        id = ""
        id += Math.random().toString(36).substr(2) while id.length < length
        id.substr 0, length

      downloadFile = (url, fileName) ->

      tmpFileName="/tmp/" + uniqueId() + ".jpg"
      fileName="images/" + uniqueId() + ".jpg"

      url = "#{printerConfig.OCTOPRINT_PROTOCOL}#{printerConfig.OCTOPRINT_URL}:#{printerConfig.OCTOPRINT_PORT}/?action=snapshot"
      cmd = "curl #{url} > #{tmpFileName} && convert #{tmpFileName} -rotate 90 #{fileName}"
      @exec = require('child_process').exec
      @exec cmd, (error, stdout, stderr) -> 
        if error
          response.send error
          response.send stderr
        else
          web.files.upload(fileName, {message: '',channels: '#general', filetype: 'jpg', mimetype: 'image/jpeg', file: fs.readFileSync(fileName)},(err, response) ->
          );
  );
