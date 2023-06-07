# frozen_string_literal: true

class Game
  def initialize(players, num_matches, include_reserve_maps)
    team_one_name, team_two_name = TEAM_NAMES.sample(2)
    team_one_players, team_two_players = create_teams(players)
    @team_one = new Team(team_one_name, team_one_players)
    @team_two = new Team(team_two_name, team_two_players)

    @maps = pick_maps(num_matches, include_reserve_maps)
  end

  def create_teams(players)
    team_one = []
    team_two = []
    team_one_captain, team_two_captain = players.shift(2)
    team_one << team_one_captain
    team_two << team_two_captain
    first_pick_choice, = %i[team_one team_two].shuffle
    current_team_picking = first_pick_choice

    while players_by_ranking.count.positive?
      shift_amount = if players_by_ranking.count == 8 || players_by_ranking.count == 1
                       1
                     else
                       2
                     end

      players_to_add = players_by_ranking.shift(shift_amount)

      if current_team_picking == :team_one
        team_one.push(*players_to_add)
        current_team_picking = :team_two
      elsif current_team_picking == :team_two
        team_two.push(*players_to_add)
        current_team_picking = :team_one
      end
    end

    [team_one, team_two]
  end

  def pick_maps(num_matches, include_reserve_maps)
    if include_reserve_maps
      ACTIVE_DUTY_MAPS + RESERVE_MAPS
    else
      ACTIVE_DUTY_MAPS
    end.sample(num_matches)
  end

  attr_reader :maps, :team_one, :team_two
end