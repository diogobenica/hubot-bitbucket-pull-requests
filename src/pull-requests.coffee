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
  pullrequests = () -> robot.brain.data.remember ?= {}

  robot.router.post '/bitbucket-pullrequests', (req, res) ->
    payload = req.body

    if payload.pullrequest_created
      payload = payload.pullrequest_created

      robot
        .http("https://api-ssl.bitly.com/v3/shorten")
        .query
          access_token: process.env.HUBOT_BITLY_ACCESS_TOKEN
          longUrl: payload.links.self
          format: "json"
        .get() (err, res, body) ->
          response = JSON.parse body
          if response.status_code is 200
            link = response.data.url
          else
            link = payload.links.self
          msg = "PR ##{payload.id}: #{payload.title} (#{payload.destination.repository.full_name}) by @#{payload.author.username} (#{link})"
          robot.messageRoom req.query.room, msg
          res.end 'OK'
