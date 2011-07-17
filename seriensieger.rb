require "net/http"
require "json"
require "time"
require "./config"

# load JSON data of season

LEAGUE_SHORTCUT = "bl1"

class Seriensieger
  attr_reader :match_data

  def generate_guess (match_id)
    id_team1 = by_match_id[match_id][:id_team1]
    id_team2 = by_match_id[match_id][:id_team2]

    last_result_team1 = last_result_team2 = nil
    (0...match_id).reverse_each do |m_id|
      the_match = by_match_id[m_id] or next
      the_match[:match_is_finished] or next
      last_result_team1 ||=
          [the_match[:points_team1], the_match[:points_team2]] if the_match[:id_team1] == id_team1
      last_result_team1 ||=
          [the_match[:points_team2], the_match[:points_team1]] if the_match[:id_team2] == id_team1
      last_result_team2 ||=
          [the_match[:points_team1], the_match[:points_team2]] if the_match[:id_team1] == id_team2
      last_result_team2 ||=
          [the_match[:points_team2], the_match[:points_team1]] if the_match[:id_team2] == id_team2
      break if last_result_team1 and last_result_team2
    end
    last_result_team1 ||= [0, 0]
    last_result_team2 ||= [0, 0]

    goal_quantity = (last_result_team1.first + last_result_team1.last +
                     last_result_team2.first + last_result_team2.last) / 2.0
    goal_difference = last_result_team1.first - last_result_team1.last - 
        (last_result_team2.first - last_result_team2.last)

    [
      [0, (goal_quantity / 2.0 + goal_difference / 2.0).round].max,
      [0, (goal_quantity / 2.0 - goal_difference / 2.0).round].max
    ]
  end

  def matches_to_guess
    match_data.select {|match| !match[:match_is_finished] and
          match[:match_date_time] > Time.now and
          match[:match_date_time] < Time.now + 60*60*24}.
      map {|match| match[:match_id]}
  end

  def match_data= (new_data)
    @match_data = new_data.map do |match|
      [:match_id, :points_team1, :points_team2].each do |key|
        match[key] = match[key].to_i if match[key].is_a?(String)
      end
      match[:match_date_time] = Time.parse(match[:match_date_time]) if match[:match_date_time].is_a?(String)
      match
    end
  end

  def load (season, loader = nil)
    @match_data_by_match_id = nil
    self.match_data = (loader || SeasonDataLoader.new).get(season)
  end

  def guess_all (submitter = nil)
    submitter ||= GuessSubmitter.new
    match_data.each {|match| submitter.submit(match[:match_id], generate_guess(match[:match_id])) }
  end

  def guess_next (submitter = nil)
    submitter ||= GuessSubmitter.new
    matches_to_guess.each {|match_id| submitter.submit(match_id, generate_guess(match_id))}
  end

  private
  def by_match_id
    @match_data_by_match_id ||= match_data.each_with_object({}) {|match, memo| memo[match[:match_id]] = match}
  end
end

class SeasonDataLoader
  URL_FORMAT = "http://openligadb-json.heroku.com/api/matchdata_by_league_saison?league_saison=%{season}&league_shortcut=bl1"
  def get (season)
    puts "Loading data for #{season}..."
    response = Net::HTTP.get_response URI.parse(url_for_season(season))
    if response.is_a?(Net::HTTPSuccess)
      json_data = JSON.parse(response.body)
      raise "Unexpected result body.  Missing data['matchdata']." unless json_data.is_a?(Hash) and json_data['matchdata']
      puts "Received data on #{json_data['matchdata'].length} matches."
      json_data['matchdata'].map do |raw_data|
        raw_data.each_with_object({}) {|(key,val),hash| hash[key.to_sym] = val}
      end
    else
      raise "Could not retrieve current data for season %{season}: %{msg}" % {season: season, msg: response}
    end
  end

  def url_for_season (season)
    URL_FORMAT % {season: season}
  end
end

class GuessSubmitter
  def initialize
    @http = Net::HTTP.new('botliga.de',80)
  end

  def submit (match_id, result)
    puts "Submitting for #{match_id}: #{result[0]}:#{result[1]}"
    response, data = @http.post('/api/guess',"match_id=#{match_id}&result=#{result[0]}:#{result[1]}&token=#{BOT_TOKEN}")
    raise "Error submitting guess: #{response.code} #{data}" unless response.is_a?(Net::HTTPSuccess)
  end
end

# vim: ai sw=2 expandtab smarttab ts=2
