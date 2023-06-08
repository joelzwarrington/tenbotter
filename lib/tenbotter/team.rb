# frozen_string_literal: true

class Team
  def initialize(team_name, players)
    @team_name = team_name
    @players = players
    @captain = players[0]
  end

  attr_reader :team_name, :players, :captain
end
