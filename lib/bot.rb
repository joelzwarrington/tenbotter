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
#   command.user('excluded_player_1', 'Excluded Player 1', required: false)
#   command.user('excluded_player_2', 'Excluded Player 2', required: false)
#   command.user('excluded_player_3', 'Excluded Player 3', required: false)
#   command.user('excluded_player_4', 'Excluded Player 4', required: false)
#   command.user('excluded_player_5', 'Excluded Player 5', required: false)
#   command.boolean('include_reserve_maps', 'Include reserve maps (Default: true)')
#   command.string('best_of', 'How many games in the set? (Default: 1)', choices: { '1': '1', '3': '3', '5': '5', '7': '7' })
# end
# bot.register_application_command(:dire, "Cancel the current active beckon", server_id: SERVER_ID)

bot.application_command(:beckon) do |event|
  start_time = Chronic.parse(event.options["start_time"])

  if start_time.nil? && !event.options["start_time"].nil?
    event.respond(content: ":x: Uh oh, looks like you didn't specify a valid start time.\n\nTry something like '5pm', 'tonight', 'now'")
    return
  elsif event.options["start_time"].nil?
    start_time = Chronic.parse("tonight at 9")
  end

  if !@active_beckon.nil? && !@active_beckon.expired?(start_time)
    event.respond(content: "There is already an [active beckon](#{@active_beckon.beckon_message.link})!")
  end

  event.respond(content: "Submitting a new beckon!", ephemeral: true)
  @active_beckon = Beckon.new(start_time, bot, event)
  @active_beckon.create_beckon_message(bot, event)
  @active_beckon.add_bot_reaction
end

bot.application_command(:dire) do |event|
  if @active_beckon.nil?
    event.respond(content: "There is no active beckon to cancel!", ephemeral: true)
  else
    event.respond(content: "[The beckon](#{@active_beckon.beckon_message.link}) has been canceled")
    @active_beckon = nil
  end
end

bot.reaction_add(emoji: COOLSPOT_ID) do |event|
  @active_beckon.reaction_add(event) if event.message.id == @active_beckon.beckon_message.id
end

bot.reaction_remove(emoji: COOLSPOT_ID) do |event|
  @active_beckon.reaction_remove(event) if event.message.id == @active_beckon.beckon_message.id
end

PLAYER_RANKINGS = [
  "214151105813282816", # shimmy
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

def validate_players(players, event)
  excluded_players = (1..5).map do |i|
    event.options["excluded_player_#{i}"]
  end.filter { |excluded_player| !excluded_player.nil? }

  players = players.filter { |player| !excluded_players.include?(player.id.to_s) }

  if players.count < 10
    event.respond(
      content: ":x: Uh oh. There isn't enough spotters",
      ephemeral: true
    )
    return nil
  end

  players_by_ranking = PLAYER_RANKINGS.filter do |player|
    players.map(&:id).include?(player)
  end

  return nil unless players_by_ranking.count != 10

  event.respond(
    content: ":x: Uh oh. You might have too many players or have included players which have not been ranked yet. Try again!",
    ephemeral: true
  )
  players
end

def validate_active_beckon(event)
  if @active_beckon.nil? || @active_beckon.expired?
    event.respond(
      content: ":x: Uh oh. There is no active_beckon",
      ephemeral: true
    )
    return false
  end
  true
end

bot.application_command(:play) do |event|
  return unless validate_active_beckon(event)

  num_matches = event.options["best_of"]&.to_i || 1
  include_reserve_maps = event.options["include_reserve_maps"]
  players = validate_players(@active_beckon.spotters, event)
  return if players.nil?

  game = new Game(players, num_matches, include_reserve_maps)

  event.respond(
    embeds: [
      {
        color: 13_632_027,
        fields: [
          {
            name: "**#{game.team_one.team_name}**",
            value: game.team_one.players.each_with_index.map do |player, index|
                     index.zero? ? "<@#{player}> :crown:" : "<@#{player}>"
                   end.join("\n"),
            inline: true
          },

          {
            name: "Maps",
            value: game.maps.each_with_index.map do |map, index|
                     "**:#{(index + 1).humanize}: #{map}** - [*Sides chosen by #{index.odd? ? eval("#{first_side_choice}_name") : eval("#{first_pick_choice}_name")}*]"
                   end.join("\n"),
            inline: true
          },
          {
            name: "**#{game.team_two.team_name}**",
            value: game.team_two.players.each_with_index.map do |player, index|
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
