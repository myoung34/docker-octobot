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
      slackChannel = process.env.HUBOT_SLACK_CHANNEL

      if command == "help"
        [
          "`!help` - list commands", 
          "`!list` - list printers as links", 
          "`!stop {printer}` - stop a print", 
          "`!cancel {printer}` - stop a print", 
          "`!snapshot {printer}` - stop a print", 
          "`!status {printer}` - stop a print", 
        ].forEach (_command) ->
          response.send 
            attachments: [{ title: "#{_command}"}]
        return
      if command == "list"
        Object.keys(config).forEach (_name) ->
          url = "#{config[_name].OCTOPRINT_PROTOCOL}#{config[_name].OCTOPRINT_URL}"
          response.send 
            attachments: [{ title: "#{_name}", title_link: "#{url}" }]
        return
      if command == "snapshot"
        if printer == "" 
          response.send "Please give a printer name. `!list` to get printer(s)"
          return
        response.send "Getting snapshot"
        console.log("Getting snapshot for #{printer}")

        downloadFile = (url, fileName) ->

        tmpFileName="/tmp/" + uniqueId() + ".jpg"
        fileName="images/" + uniqueId() + ".jpg"

        url = "#{printerConfig.OCTOPRINT_PROTOCOL}#{printerConfig.OCTOPRINT_URL}:#{printerConfig.MJPG_PORT}/?action=snapshot"
        cmd = "curl #{url} > #{tmpFileName} && convert #{tmpFileName} -rotate #{printerConfig.ROTATE} #{fileName}"
        @exec = require('child_process').exec
        @exec cmd, (error, stdout, stderr) -> 
          if error
            console.log(error)
            return
          else
            web.files.upload(
              fileName, {
                message: '',
                channels: "#{slackChannel}",
                filetype: 'jpg',
                mimetype: 'image/jpeg',
                file: fs.readFileSync(fileName)
              },(err, response) ->
                console.log(error);
                console.log(response);
            );
      else if command == "cancel" or command == "stop"
        if printer == "" 
          response.send "Please give a printer name. `!list` to get printer(s)"
          return
        robot.http("#{printerConfig.OCTOPRINT_PROTOCOL}#{printerConfig.OCTOPRINT_URL}:#{printerConfig.OCTOPRINT_PORT}/api/job")
          .header('Content-Type', 'application/json')
          .header('X-Api-Key', apiToken)
          .get() (err, res, body) ->
            if err
              console.log("Encountered an error :( #{err}")
              return
            data = JSON.parse body
            status = valueOrDefault(data.state, "n/a")
            if status == "Printing from SD"
              response.send "Cannot cancel a job thats being run via SD card."
              console.log("Cannot cancel a job thats being run via SD card.")
              return
            console.log("running cancel (#{command}) for #{printer}")
            data = JSON.stringify({
                command: 'cancel'
            })
            robot.http("#{printerConfig.OCTOPRINT_PROTOCOL}#{printerConfig.OCTOPRINT_URL}:#{printerConfig.OCTOPRINT_PORT}/api/job")
              .header('Content-Type', 'application/json')
              .header('X-Api-Key', apiToken)
              .post(data) (err, res, body) ->
                if err
                  console.log("Encountered an error :( #{err}")
                  return
              response.send "Cancelled print successfully"
              return
      else if command == "status"
        robot.http("#{printerConfig.OCTOPRINT_PROTOCOL}#{printerConfig.OCTOPRINT_URL}:#{printerConfig.OCTOPRINT_PORT}/api/job")
          .header('Content-Type', 'application/json')
          .header('X-Api-Key', apiToken)
          .get() (err, res, body) ->
            if err
              console.log("Encountered an error :( #{err}")
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
