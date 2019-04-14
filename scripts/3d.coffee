{RtmClient, WebClient} = require "@slack/client"
fs = require('fs')

valueOrDefault = (item, defaultValue) ->
  value = item
  if !item
    value = defaultValue
  value
 
parseDefaultTime = (item, defaultValue="n/a", suffix="") ->
  parsedTime = (item / 60).toFixed(2)
  if parsedTime == 0
    parsedTime = defaultValue
  parsedTime + suffix

uniqueId = (length=8) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length

module.exports = (robot) ->
  web = new WebClient(process.env.HUBOT_SLACK_TOKEN);
  config = JSON.parse(process.env.CONFIG)

  robot.listen(
    # Matcher
    (message) ->
      return unless message.text
      message.match(/^!([a-zA-Z]*)( .*)?$/)
    (response) ->
      command = response.match[1]
      printer = valueOrDefault(response.match[2], "").trim()
      printerConfig = valueOrDefault(config["#{printer}"], config[Object.keys(config)[0]]) 
      apiToken = printerConfig.OCTOPRINT_API_TOKEN

      if command == "snapshot"
        response.send "Getting snapshot"

        downloadFile = (url, fileName) ->

        tmpFileName="/tmp/" + uniqueId() + ".jpg"
        fileName="images/" + uniqueId() + ".jpg"

        url = "#{printerConfig.OCTOPRINT_PROTOCOL}#{printerConfig.OCTOPRINT_URL}:#{printerConfig.MJPG_PORT}/?action=snapshot"
        cmd = "curl #{url} > #{tmpFileName} && convert #{tmpFileName} -rotate 90 #{fileName}"
        @exec = require('child_process').exec
        @exec cmd, (error, stdout, stderr) -> 
          if error
            response.send "Error: " + error
            return
          else
            web.files.upload(
              fileName, {
                message: '',
                channels: '#general',
                filetype: 'jpg',
                mimetype: 'image/jpeg',
                file: fs.readFileSync(fileName)
              },(err, response) ->
                console.log(error);
                console.log(response);
            );
      else if command == "cancel" or command == "stop"
        data = JSON.stringify({
            command: 'cancel'
        })
        robot.http("#{printerConfig.OCTOPRINT_PROTOCOL}#{printerConfig.OCTOPRINT_URL}:#{printerConfig.OCTOPRINT_PORT}/api/job")
          .header('Content-Type', 'application/json')
          .header('X-Api-Key', apiToken)
          .post(data) (err, res, body) ->
            if err
              response.send "Encountered an error :( #{err}"
              return
          response.send "Cancelled print successfully"
          return
      else if command == "status"
        robot.http("#{printerConfig.OCTOPRINT_PROTOCOL}#{printerConfig.OCTOPRINT_URL}:#{printerConfig.OCTOPRINT_PORT}/api/job")
          .header('Content-Type', 'application/json')
          .header('X-Api-Key', apiToken)
          .get() (err, res, body) ->
            if err
              response.send "Encountered an error :( #{err}"
              return
            data = JSON.parse body
            timeRemaining = parseDefaultTime(data.progress.printTimeLeft, "n/a", " minutes")
            timeElapsed = parseDefaultTime(data.progress.printTime, "n/a", " minutes")
            estimatedTime = parseDefaultTime(data.job.estimatedPrintTime, "n/a", " minutes")
            status = valueOrDefault(data.state, "n/a")
            progress = parseDefaultTime(data.progress.completion, "0", "%")

            attachment = {
              title: "#{printer}",
              fields: [
                {
                  title: "File name"
                  value: data.job.file.name
                  short: false
                },
                {
                  title: "Status"
                  value: status
                  short: false
                },
                {
                  title: "Progress"
                  value: progress
                  short: true
                },
                {
                  title: "Time Elapsed"
                  value: timeElapsed
                  short: true
                },
                {
                  title: "Time Left"
                  value: timeRemaining
                  short: true
                }
                {
                  title: "Total Estimated Time"
                  value: estimatedTime
                  short: true
                },
              ],
              color: "#003366"
            }
            response.send 
              attachments: [attachment]
  );
