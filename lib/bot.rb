# frozen_string_literal: true

require "dotenv/load"
require "humanize"
require "discordrb"
require "discordrb/api"
require "chronic"
require_relative "beckon"

TOKEN = ENV["TOKEN"]
SERVER_ID = 441_743_021_654_933_515
ROLE_ID = 833_522_739_264_225_340
COOLSPOT_ID = 786_446_795_822_858_280
DROOLSPOT_ID = 838_610_850_893_398_016

bot = Discordrb::Bot.new token: TOKEN, intents: %i[server_messages server_message_reactions]

# bot.get_application_commands(server_id: SERVER_ID).each do |application|
#   application.delete
# end

# move this to rake task
# bot.register_application_command(:beckon, 'Send out a beckon', server_id: SERVER_ID) do |command|
#   command.string('start_time', 'When would the game start?')
# end
# bot.register_application_command(:play, 'Start', server_id: SERVER_ID) do |command|
#   command.user('player_1', 'Player 1', required: true)
#   command.user('player_2', 'Player 2', required: true)
#   command.user('player_3', 'Player 3', required: true)
#   command.user('player_4', 'Player 4', required: true)
#   command.user('player_5', 'Player 5', required: true)
#   command.user('player_6', 'Player 6', required: true)
#   command.user('player_7', 'Player 7', required: true)
#   command.user('player_8', 'Player 8', required: true)
#   command.user('player_9', 'Player 9', required: true)
#   command.user('player_10', 'Player 10', required: true)
#   command.boolean('include_reserve_maps', 'Include reserve maps (Default: true)')
#   command.string('best_of', 'How many games in the set? (Default: 1)', choices: { '1': '1', '3': '3', '5': '5', '7': '7' })
# end

# bot.register_application_command(:play, 'Start', server_id: SERVER_ID) do |command|
#   command.user('excluded_player_1', 'Excluded Player 1', required: false)
#   command.user('excluded_player_2', 'Excluded Player 2', required: false)
#   command.user('excluded_player_3', 'Excluded Player 3', required: false)
#   command.user('excluded_player_4', 'Excluded Player 4', required: false)
#   command.user('excluded_player_5', 'Excluded Player 5', required: false)
#   command.boolean('include_reserve_maps', 'Include reserve maps (Default: true)')
#   command.string('best_of', 'How many games in the set? (Default: 1)', choices: { '1': '1', '3': '3', '5': '5', '7': '7' })
# end

bot.application_command(:beckon) do |event|
  start_time = Chronic.parse(event.options["start_time"])

  if !@active_beckon.nil? && !@active_beckon.expired?(start_time)
    event.respond(content: "There is already an active beckon: <#{@active_beckon.beckon_message.link}>")
  end

  if start_time.nil? && !event.options["start_time"].nil?
    event.respond(content: ":x: Uh oh, looks like you didn't specify a valid start time.\n\nTry something like '5pm', 'tonight', 'now'")
    return
  elsif event.options["start_time"].nil?
    start_time = Chronic.parse("tonight at 9")
  end

  event.respond(content: "Submitting a new beckon!", ephemeral: true)
  @active_beckon = Beckon.new(start_time, bot, event)
  #  bot.send_message(
  #   event.channel,
  #   "<@&#{ROLE_ID}> a new beckon has appeared!",
  #   false,
  #   {
  #     color: 13_632_027,
  #     fields: [
  #       {
  #         name: "**:stopwatch: Start Time**: #{start_time.strftime("%F %l:%M %p").strip}",
  #         value: ""
  #       },
  #       {
  #         name: "<:coolspot:#{COOLSPOT_ID}> | 0",
  #         value: ""
  #       }
  #     ]
  #   },
  #   nil,
  #   {
  #     roles: [ROLE_ID]
  #   }
  # )

  # message.react "coolspot:#{COOLSPOT_ID}"
end

bot.reaction_add(emoji: COOLSPOT_ID) do |event|
  @active_beckon.reaction_add(event) if event.message.id == @active_beckon.beckon_message.id
  # spotters = JSON.parse(
  #   Discordrb::API::Channel.get_reactions(
  #     "Bot #{TOKEN}",
  #     event.channel.id,
  #     event.message.id,
  #     "coolspot:#{COOLSPOT_ID}",
  #     nil,
  #     nil
  #   ).body
  # ).filter { |user| user["id"] != bot.bot_app.id.to_s }.sort_by { |user| user["username"] }.map { |user| "<@#{user["id"]}>" }

  # event.message.edit(
  #   event.message.content,
  #   {
  #     color: 13_632_027,
  #     fields: [
  #       {
  #         name: event.message.embeds.first.fields.first.name,
  #         value: event.message.embeds.first.fields.first.value
  #       },
  #       {
  #         name: "<:coolspot:#{COOLSPOT_ID}> | #{spotters.count}",
  #         value: spotters.join("\n")
  #       }
  #     ]
  #   }
  # )

  # event.message.delete_own_reaction("coolspot:#{COOLSPOT_ID}") if spotters.count >= 1

  # case spotters.count
  # when 5
  #   event.message.respond(
  #     "**<@&#{ROLE_ID}> halfway there, we have 5/10 <:coolspot:#{COOLSPOT_ID}>!**",
  #     false,
  #     nil,
  #     nil,
  #     { roles: [ROLE_ID] },
  #     {
  #       message_id: event.message.id,
  #       channel_id: event.channel.id,
  #       guild_id: event.server.id
  #     }
  #   )
  # when 9
  #   event.message.respond(
  #     "**<@&#{ROLE_ID}> just one left, we have 9/10 <:coolspot:#{COOLSPOT_ID}>!**",
  #     false,
  #     nil,
  #     nil,
  #     { roles: [ROLE_ID] },
  #     {
  #       message_id: event.message.id,
  #       channel_id: event.channel.id,
  #       guild_id: event.server.id
  #     }
  #   )
  # when 10
  #   event.message.respond(
  #     "**<@&#{ROLE_ID}> play time!**",
  #     false,
  #     nil,
  #     nil,
  #     { roles: [ROLE_ID] },
  #     {
  #       message_id: event.message.id,
  #       channel_id: event.channel.id,
  #       guild_id: event.server.id
  #     }
  #   )
  # end
end

bot.reaction_remove(emoji: COOLSPOT_ID) do |event|
  @active_beckon.reaction_remove(event) if event.message.id == @active_beckon.beckon_message.id
  # spotters = JSON.parse(
  #   Discordrb::API::Channel.get_reactions(
  #     "Bot #{TOKEN}",
  #     event.channel.id,
  #     event.message.id,
  #     "coolspot:#{COOLSPOT_ID}",
  #     nil,
  #     nil
  #   ).body
  # ).filter { |user| user["id"] != bot.bot_app.id.to_s }.sort_by { |user| user["username"] }.map { |user| "<@#{user["id"]}>" }

  # event.message.edit(
  #   event.message.content,
  #   {
  #     color: 13_632_027,
  #     fields: [
  #       {
  #         name: event.message.embeds.first.fields.first.name,
  #         value: event.message.embeds.first.fields.first.value
  #       },
  #       {
  #         name: "<:coolspot:#{COOLSPOT_ID}> | #{spotters.count}",
  #         value: spotters.join("\n")
  #       }
  #     ]
  #   }
  # )

  # event.message.react("coolspot:#{COOLSPOT_ID}") if spotters.count.zero?

  # event.message.respond(
  #   "#{event.user.mention} is a filthy unspotter... ban him!",
  #   false,
  #   nil,
  #   nil,
  #   { roles: [ROLE_ID] }
  # )
end

PLAYER_RANKINGS = [
  "451190205609934858", # skip
  "164172161290862592", # reggy
  "158322743522099211", # faffy
  "185515699563790336", # joel
  "548738933199077377", # ak
  "506673069860061195", # yung steve
  "617878892795002892", # slimv
  "158321729935114240", # balba
  "158322234509885440", # liam
  "323375425344634881", # schmuckers
  "429757218070593557", # scotty
  "548314290923241472", # rmah
  "374597350485655563", # kullsy
  "352287964740714496", # jackson
  "592590053268652033", # flubby
  "351080463978463233", # jim jam
  "449419256476598273", # wubby
  "171076951451107339", # Jiho
  "346917819121664002", # aidan
  "234443663479013376" # gronz
].freeze

ACTIVE_DUTY_MAPS = %w[
  Inferno
  Mirage
  Nuke
  Overpass
  Vertigo
  Ancient
  Anubis
].freeze

RESERVE_MAPS = [
  "Dust II",
  "Train",
  "Cache"
].freeze

TEAM_NAMES = %w[
  Children
  Youngsters
  Bambinos
].freeze

bot.application_command(:play) do |event|
  if @active_beckon.nil? || @active_beckon.expired?
    event.respond(
      content: ":x: Uh oh. There is no active_beckon",
      ephemeral: true
    )
    return
  end
  # event.defer
  matches = event.options["best_of"]&.to_i || 1

  maps = if event.options["include_reserve_maps"]
           ACTIVE_DUTY_MAPS + RESERVE_MAPS
         else
           ACTIVE_DUTY_MAPS
         end.sample(matches)

  team_one_name, team_two_name = TEAM_NAMES.sample(2)
  team_one = []
  team_two = []
  players = @active_beckon.spotters

  excluded_players = (1..5).map { |i|
    event.options["excluded_player_#{i}"] }.filter { |excluded_player| !excluded_player.nil? }


  players = players.filter { |player| !excluded_players.include?(player.id.to_s) }

  if players.count < 10
    event.respond(
      content: ":x: Uh oh. There isn't enough spotters",
      ephemeral: true
    )
    return
  end

  players_by_ranking = PLAYER_RANKINGS.filter do |player|
    players.map(&:id).include?(player)
  end

  if players_by_ranking.count != 10
    event.respond(
      content: ":x: Uh oh. You might have too many players or have included players which have not been ranked yet. Try again!",
      ephemeral: true
    )
    return
  end

  team_one_captain, team_two_captain = players_by_ranking.shift(2)
  team_one << team_one_captain
  team_two << team_two_captain

  first_pick_choice, first_side_choice = %i[team_one team_two].shuffle

  team = first_pick_choice

  while players_by_ranking.count.positive?
    shift_amount = if players_by_ranking.count == 8 || players_by_ranking.count == 1
                     1
                   else
                     2
                   end

    players_to_add = players_by_ranking.shift(shift_amount)

    if team == :team_one
      team_one.push(*players_to_add)
      team = :team_two
    elsif team == :team_two
      team_two.push(*players_to_add)
      team = :team_one
    end
  end

  event.respond(
    embeds: [
      {
        color: 13_632_027,
        fields: [
          {
            name: "**#{team_one_name}**",
            value: team_one.each_with_index.map do |player, index|
                     index.zero? ? "<@#{player}> :crown:" : "<@#{player}>"
                   end.join("\n"),
            inline: true
          },

          {
            name: "Maps",
            value: maps.each_with_index.map do |map, index|
                     "**:#{(index + 1).humanize}: #{map}** - [*Sides chosen by #{index.odd? ? eval("#{first_side_choice}_name") : eval("#{first_pick_choice}_name")}*]"
                   end.join("\n"),
            inline: true
          },
          {
            name: "**#{team_two_name}**",
            value: team_two.each_with_index.map do |player, index|
                     index.zero? ? "<@#{player}> :crown:" : "<@#{player}>"
                   end.join("\n"),
            inline: true
          }
        ]
      }
    ]
  )
end

bot.run
