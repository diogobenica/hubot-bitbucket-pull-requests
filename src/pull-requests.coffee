# Description
#   A hubot script that notifies pull requests and keep track of unmerged ones
#
# Configuration:
#   HUBOT_BITLY_ACCESS_TOKEN
#
# Commands:
#   hubot prs - Show open pull requests
#
# Author:
#   Diogo Benicá (@diogobenica)

module.exports = (robot) ->
  pullrequests = () -> robot.brain.data.bitbucket_pull_requests ?= {}

  robot.respond /prs/i, (hubot) ->
    values = []
    values.push value for key, value of pullrequests()
    hubot.send "PRs abertos:\n#{values.join('\n')}"

  robot.router.post '/bitbucket-pullrequests', (req, res) ->
    payload = req.body

    if payload.pullrequest_created
      payload = payload.pullrequest_created
      pr_uid = payload.destination.repository.name+"_"+payload.id

      robot
        .http("https://api-ssl.bitly.com/v3/shorten")
        .query
          access_token: process.env.HUBOT_BITLY_ACCESS_TOKEN
          longUrl: payload.links.self.href
          format: "json"
        .get() (err, res, body) ->
          response = JSON.parse body
          if response.status_code is 200
            link = response.data.url
          else
            link = payload.links.self.href
          msg = "[#{payload.destination.repository.name}] PR ##{payload.id}: #{payload.title} by @#{payload.author.username} (#{link})"
          robot.messageRoom req.query.room, msg
          pullrequests()[pr_uid] = msg
    else if payload.pullrequest_merged
      payload = payload.pullrequest_merged
      pr_uid = payload.destination.repository.name+"_"+payload.id
      delete pullrequests()[pr_uid]
    else if payload.pullrequest_declined
      payload = payload.pullrequest_declined
      pr_uid = payload.destination.repository.name+"_"+payload.id
      delete pullrequests()[pr_uid]

    res.end 'OK'
