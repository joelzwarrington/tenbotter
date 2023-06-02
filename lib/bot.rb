# frozen_string_literal: true

require 'redis'
require 'securerandom'
require 'discordrb'
require 'discordrb/webhooks'
require 'discordrb/api'

TOKEN = "change_me"
SERVER_ID = 441743021654933515
ROLE_ID = 833522739264225340
COOLSPOT_ID = 786446795822858280
DROOLSPOT_ID = 838610850893398016

bot = Discordrb::Bot.new token: TOKEN, intents: %i[server_messages server_message_reactions]
redis = Redis.new

# move this to rake task
bot.register_application_command(:beckon, 'Send out a beckon', server_id: SERVER_ID)
bot.register_application_command(:play, 'Start the play', server_id: SERVER_ID)

bot.application_command(:beckon) do |event|
  message = bot.send_message(
    event.channel,
    "<@&#{ROLE_ID}> a new beckon has appeared!",
    false,
    {
      color: 13632027,
      fields: [
        {
          name: "<:coolspot:#{COOLSPOT_ID}>",
          value: "",
          inline: true
        },
        {
          name: "",
          value: "",
          inline: true
        },
        {
          "name": "<:droolspot:#{DROOLSPOT_ID}>",
          "value": "",
          "inline": true
        }
      ]
    },
    nil,
    {
      roles: [ROLE_ID]
    }
  )

  redis.set('beckon_channel_id', message.channel.id)
  redis.set('beckon_id', message.id)


  event.respond(content: 'Beckon has been sent!', ephemeral: true)

  message.react "coolspot:#{COOLSPOT_ID}"
  message.react "droolspot:#{DROOLSPOT_ID}"
end

bot.reaction_add do |event|
  return unless [COOLSPOT_ID, DROOLSPOT_ID].include? event.emoji.id

  users_by_emoji_reaction = [['coolspot', COOLSPOT_ID], ['droolspot', DROOLSPOT_ID]].each_with_object({}) do |emoji, object|
    emoji_name, emoji_id = emoji
    reaction_response = Discordrb::API::Channel.get_reactions("Bot #{TOKEN}", event.channel.id, event.message.id, "#{emoji_name}:#{emoji_id}", nil, nil)
    reactions = JSON.parse(reaction_response.body)
    object[emoji_name] = reactions.filter { |r| r['id'] != bot.bot_app.id.to_s }.map { |r| r['id'] }
  end

  message_response = Discordrb::API::Channel.message("Bot #{TOKEN}", event.channel.id, event.message.id)
  message = Discordrb::Message.new(JSON.parse(message_response.body), bot)

  message.edit(
    message.content,
    {
      color: 13632027,
      fields: [
        {
          name: "<:coolspot:#{COOLSPOT_ID}>",
          value: users_by_emoji_reaction['coolspot'].map { |user| "<@#{user}>" }.join('\n'),
          inline: true
        },
        {
          name: "",
          value: "",
          inline: true
        },
        {
          name: "<:droolspot:#{DROOLSPOT_ID}>",
          value: users_by_emoji_reaction['droolspot'].map { |user| "<@#{user}>" }.join('\n'),
          inline: true
        }
      ]
    }
  )
end

bot.reaction_remove do |event|
  return unless [COOLSPOT_ID, DROOLSPOT_ID].include? event.emoji.id 

  users_by_emoji_reaction = [['coolspot', COOLSPOT_ID], ['droolspot', DROOLSPOT_ID]].each_with_object({}) do |emoji, object|
    emoji_name, emoji_id = emoji
    reaction_response = Discordrb::API::Channel.get_reactions("Bot #{TOKEN}", event.channel.id, event.message.id, "#{emoji_name}:#{emoji_id}", nil, nil)
    reactions = JSON.parse(reaction_response.body)
    object[emoji_name] = reactions.filter { |r| r['id'] != bot.bot_app.id.to_s }.map { |r| r['id'] }
  end

  message_response = Discordrb::API::Channel.message("Bot #{TOKEN}", event.channel.id, event.message.id)
  message = Discordrb::Message.new(JSON.parse(message_response.body), bot)

  message.edit(
    message.content,
    {
      color: 13632027,
      fields: [
        {
          name: "<:coolspot:#{COOLSPOT_ID}>",
          value: users_by_emoji_reaction['coolspot'].map { |user| "<@#{user}>" }.join('\n'),
          inline: true
        },
        {
          name: "",
          value: "",
          inline: true
        },
        {
          name: "<:droolspot:#{DROOLSPOT_ID}>",
          value: users_by_emoji_reaction['droolspot'].map { |user| "<@#{user}>" }.join('\n'),
          inline: true
        }
      ]
    }
  )
end

bot.application_command(:play) do |event|
  event.respond(content: "hello world")
end

bot.run