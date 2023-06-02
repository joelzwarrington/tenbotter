# frozen_string_literal: true

require 'discordrb'
require 'discordrb/api'
require 'chronic'

TOKEN = "change_me"
SERVER_ID = 441743021654933515
ROLE_ID = 833522739264225340
COOLSPOT_ID = 786446795822858280
DROOLSPOT_ID = 838610850893398016

bot = Discordrb::Bot.new token: TOKEN, intents: %i[server_messages server_message_reactions]

# bot.get_application_commands(server_id: SERVER_ID).each do |application|
#   application.delete
# end

# move this to rake task
# bot.register_application_command(:beckon, 'Send out a beckon', server_id: SERVER_ID) do |command|
#   command.string('start_time', 'When would the game start?')
# end
# bot.register_application_command(:play, 'Start', server_id: SERVER_ID) do |command|
#   command.string('best_of', 'How many games in the set?', choices: { 'BO1': '1', 'BO3': '3', 'BO5': '5', 'BO7': '7' })
# end

bot.application_command(:beckon) do |event|
  start_time = Chronic.parse(event.options['start_time'])

  if start_time.nil? && !event.options['start_time'].nil?
    revent.respond(content: ":x: Uh oh, looks like you didn't specify a valid start time.\n\nTry something like '5pm', 'tonight', 'now'")
    return
  elsif event.options['start_time'].nil?
    start_time = Chronic.parse('tonight at 9')
  end

  event.respond(content: "Submitting a new beckon!", ephemeral: true)
  message = bot.send_message(
    event.channel,
    "<@&#{ROLE_ID}> a new beckon has appeared!",
    false,
    {
      color: 13632027,
      fields: [
        {
          name: "**:stopwatch: Start Time**: #{start_time.strftime("%l:%M %p").strip}",
          value: ""
        },
        {
          name: "<:coolspot:#{COOLSPOT_ID}> | 0",
          value: "",
        },
      ]
    },
    nil,
    {
      roles: [ROLE_ID]
    }
  )


  message.react "coolspot:#{COOLSPOT_ID}"
end

bot.reaction_add(emoji: COOLSPOT_ID) do |event|
  spotters = JSON.parse(
    Discordrb::API::Channel.get_reactions(
      "Bot #{TOKEN}",
      event.channel.id,
      event.message.id,
      "coolspot:#{COOLSPOT_ID}",
      nil,
      nil
    ).body
  ).filter {|user| user['id'] != bot.bot_app.id.to_s }.sort_by { |user| user['username'] }.map { |user| "<@#{user['id']}>" }

  event.message.edit(
    event.message.content,
    {
      color: 13632027,
      fields: [
        {
          name: event.message.embeds.first.fields.first.name,
          value: event.message.embeds.first.fields.first.value,
        },
        {
          name: "<:coolspot:#{COOLSPOT_ID}> | #{spotters.count}",
          value: spotters.join("\n"),
        },
      ]
    }
  )

  event.message.delete_own_reaction("coolspot:#{COOLSPOT_ID}") if spotters.count >= 1

  if spotters.count >= 2
    event.message.respond(
      "**<@&#{ROLE_ID}> play time!**",
      false,
      nil,
      nil,
      { roles: [ROLE_ID] },
      {
        message_id: event.message.id,
        channel_id: event.channel.id,
        guild_id: event.server.id,
      }
    )
  end
end

bot.reaction_remove(emoji: COOLSPOT_ID) do |event|
  spotters = JSON.parse(
    Discordrb::API::Channel.get_reactions(
      "Bot #{TOKEN}",
      event.channel.id,
      event.message.id,
      "coolspot:#{COOLSPOT_ID}",
      nil,
      nil
    ).body
  ).filter {|user| user['id'] == bot.bot_app.id.to_s }.sort_by { |user| user['username'] }.map { |user| "<@#{user['id']}>" }

  event.message.edit(
    event.message.content,
    {
      color: 13632027,
      fields: [
        {
          name: event.message.embeds.first.fields.first.name,
          value: event.message.embeds.first.fields.first.value,
        },
        {
          name: "<:coolspot:#{COOLSPOT_ID}> | #{spotters.count}",
          value: spotters.join("\n"),
        },
      ]
    }
  )

  event.message.react("coolspot:#{COOLSPOT_ID}") if spotters.count == 0

  event.message.respond(
    "#{event.user.mention} is a filthy unspotter... ban him!",
    false,
    nil,
    nil,
    { roles: [ROLE_ID] }
  )
end

bot.application_command(:play) do |event|
  event.respond(content: "hello world")
end

bot.run