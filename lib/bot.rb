# frozen_string_literal: true

require 'redis'
require 'securerandom'
require 'discordrb'
require 'discordrb/webhooks'
require 'discordrb/api'
require 'chronic'

TOKEN = "change_me"
SERVER_ID = 441743021654933515
ROLE_ID = 833522739264225340
COOLSPOT_ID = 786446795822858280
DROOLSPOT_ID = 838610850893398016

bot = Discordrb::Bot.new token: TOKEN, intents: %i[server_messages server_message_reactions]
redis = Redis.new

# bot.get_application_commands(server_id: SERVER_ID).each do |application|
#   application.delete
# end

# move this to rake task
bot.register_application_command(:beckon, 'Send out a beckon', server_id: SERVER_ID) do |command|
  command.string('start_time', 'When would the game start?')
end
bot.register_application_command(:play, 'Start', server_id: SERVER_ID) do |command|
  command.string('best_of', 'How many games in the set?', choices: { 'BO1': '1', 'BO3': '3', 'BO5': '5', 'BO7': '7' })
end

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
          inline: true
        },
        {
          name: "",
          value: "",
          inline: true
        },
        {
          "name": "<:droolspot:#{DROOLSPOT_ID}> | 0",
          "value": "",
          "inline": true
        },
        {
          name: "",
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
          name: "<:coolspot:#{COOLSPOT_ID}> | #{users_by_emoji_reaction['coolspot'].count}",
          value: users_by_emoji_reaction['coolspot'].map { |user| "<@#{user}>" }.join("\n"),
          inline: true,
        },
        {
          name: "",
          value: "",
          inline: true,
        },
        {
          name: "<:droolspot:#{DROOLSPOT_ID}> | #{users_by_emoji_reaction['droolspot'].count}",
          value: users_by_emoji_reaction['droolspot'].map { |user| "<@#{user}>" }.join("\n"),
          inline: true,
        }
      ]
    }
  )

  users_by_emoji

  if users_by_emoji_reaction['coolspot'].count >= 2
    bot.send_message(
      event.channel,
      "**<@&#{ROLE_ID}> play time!**",
      false,
      nil,
      nil,
      {
        roles: [ROLE_ID]
      },
      {
        message_id: event.message.id,
        channel_id: event.channel.id,
        guild_id: event.server.id
      }
    )
  end
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
          name: event.message.embeds.first.fields.first.name,
          value: event.message.embeds.first.fields.first.value,
        },
        {
          name: "<:coolspot:#{COOLSPOT_ID}> | #{users_by_emoji_reaction['coolspot'].count}",
          value: users_by_emoji_reaction['coolspot'].map { |user| "<@#{user}>" }.join("\n"),
          inline: true
        },
        {
          name: "",
          value: "",
          inline: true
        },
        {
          name: "<:droolspot:#{DROOLSPOT_ID}> | #{users_by_emoji_reaction['droolspot'].count}",
          value: users_by_emoji_reaction['droolspot'].map { |user| "<@#{user}>" }.join("\n"),
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