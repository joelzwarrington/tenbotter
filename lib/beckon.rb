# frozen_string_literal: true

class Beckon
  def initialize(start_time, _bot, _event)
    @start_time = start_time
    @spotters = []
    @beckon_message = nil
  end

  def create_beckon_message(bot, event)
    @beckon_message = bot.send_message(
      event.channel,
      "<@&#{ROLE_ID}> a new beckon has appeared!",
      false,
      {
        color: 13_632_027,
        fields: [
          {
            name: "**:stopwatch: Start Time**: #{@start_time.strftime("%F %l:%M %p").strip}",
            value: ""
          },
          {
            name: "<:coolspot:#{COOLSPOT_ID}> | 0",
            value: ""
          }
        ]
      },
      nil,
      {
        roles: [ROLE_ID]
      }
    )
  end

  def add_bot_reaction
    @beckon_message&.react("coolspot:#{COOLSPOT_ID}")
  end

  def remove_bot_reaction
    @beckon_message&.delete_own_reaction("coolspot:#{COOLSPOT_ID}")
  end

  attr_reader :beckon_message, :spotters

  def expired?(new_start_time = Time.now)
    !new_start_time.between?(@start_time - (3 * 60 * 60), @start_time + (3 * 60 * 60))
  end

  def reaction_add(event)
    @spotters.push(event.user)

    event.message.edit(
      event.message.content,
      {
        color: 13_632_027,
        fields: [
          {
            name: event.message.embeds.first.fields.first.name,
            value: event.message.embeds.first.fields.first.value
          },
          {
            name: "<:coolspot:#{COOLSPOT_ID}> | #{@spotters.count}",
            value: @spotters.map { |user| "<@#{user.id}>" }.join("\n")
          }
        ]
      }
    )

    remove_bot_reaction if @spotters.count >= 1

    handle_spotter_count(event)
  end

  def handle_spotter_count(event)
    case @spotters.count
    when 5
      event.message.respond(
        "**<@&#{ROLE_ID}> halfway there, we have 5/10 <:coolspot:#{COOLSPOT_ID}>!**",
        false,
        nil,
        nil,
        { roles: [ROLE_ID] },
        {
          message_id: event.message.id,
          channel_id: event.channel.id,
          guild_id: event.server.id
        }
      )
    when 9
      event.message.respond(
        "**<@&#{ROLE_ID}> just one left, we have 9/10 <:coolspot:#{COOLSPOT_ID}>!**",
        false,
        nil,
        nil,
        { roles: [ROLE_ID] },
        {
          message_id: event.message.id,
          channel_id: event.channel.id,
          guild_id: event.server.id
        }
      )
    when 10
      event.message.respond(
        "**<@&#{ROLE_ID}> play time!**",
        false,
        nil,
        nil,
        { roles: [ROLE_ID] },
        {
          message_id: event.message.id,
          channel_id: event.channel.id,
          guild_id: event.server.id
        }
      )
    end
  end

  def reaction_remove(event)
    @spotters = @spotters.reject { |user| user.id == event.user.id }
    event.message.edit(
      event.message.content,
      {
        color: 13_632_027,
        fields: [
          {
            name: event.message.embeds.first.fields.first.name,
            value: event.message.embeds.first.fields.first.value
          },
          {
            name: "<:coolspot:#{COOLSPOT_ID}> | #{@spotters.count}",
            value: @spotters.map { |user| "<@#{user.id}>" }.join("\n")
          }
        ]
      }
    )

    add_bot_reaction if @spotters.count.zero?

    event.message.respond(
      "#{event.user.mention} is a filthy unspotter... ban him!",
      false,
      nil,
      nil,
      { roles: [ROLE_ID] }
    )
  end

  def play
    puts play
  end
end
