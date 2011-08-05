require "./seriensieger"
require "time"

def a_match (options = {})
  {
    match_is_finished: false,
    group_id: 1,
    id_team1: 1,
    id_team2: 2,
    league_id: 1,
    match_date_time:"2012-01-30T17:30:00+00:00",
  }.merge(options)
end

def finished_match (options = {})
  a_match({
    match_is_finished: true,
    points_team1: 1,
    points_team2: 0,
    match_date_time: "2011-01-30T17:30:00+00:00",
  }.merge(options))
end

def match_data (data)
  cnt = 0
  data.map do |match|
    cnt += 1
    {match_id: cnt}.merge(match)
  end
end

RSpec.configure do |config|
  config.mock_framework = :rspec
end

describe Seriensieger do
  describe "#generate_guess" do
    it "returns 2:1 on first game" do
      sieger = Seriensieger.new
      sieger.match_data = match_data([a_match])
      sieger.generate_guess(sieger.match_data.first[:match_id]).should == [2, 1]
    end

    it "returns 2:0 on previous 1:0, 0:1" do
      sieger = Seriensieger.new
      sieger.match_data = match_data([
        finished_match(id_team1: 1, id_team2: 3),
        finished_match(id_team1: 3, id_team2: 2),
        a_match
      ])
      sieger.generate_guess(sieger.match_data.last[:match_id]).should == [2, 0]
    end

    it "returns 1:0 on previous 1:0, 0:0" do
      sieger = Seriensieger.new
      sieger.match_data = match_data([
        finished_match(id_team1: 1, id_team2: 3),
        finished_match(id_team1: 3, id_team2: 2, points_team1: 0),
        a_match
      ])
      sieger.generate_guess(sieger.match_data.last[:match_id]).should == [1, 0]
    end

    it "returns 2:1 on previous 2:0, 2:1" do
      sieger = Seriensieger.new
      sieger.match_data = match_data([
        finished_match(id_team1: 1, id_team2: 3, points_team1: 2),
        finished_match(id_team1: 3, id_team2: 2, points_team2: 2),
        a_match
      ])
      sieger.generate_guess(sieger.match_data.last[:match_id]).should == [2, 1]
    end

    it "returns 3:0 on previous 2:0, 0:2" do
      sieger = Seriensieger.new
      sieger.match_data = match_data([
        finished_match(id_team1: 1, id_team2: 3, points_team1: 2),
        finished_match(id_team1: 3, id_team2: 2, points_team1: 2, points_team2: 0),
        a_match
      ])
      sieger.generate_guess(sieger.match_data.last[:match_id]).should == [3, 0]
    end

    it "returns 3:0 on previous 4:0, 0:0" do
      sieger = Seriensieger.new
      sieger.match_data = match_data([
        finished_match(id_team1: 1, id_team2: 3, points_team1: 4),
        finished_match(id_team1: 3, id_team2: 2, points_team2: 0),
        a_match
      ])
      sieger.generate_guess(sieger.match_data.last[:match_id]).should == [3, 0]
    end

    it "returns 2:1 on previous 4:2, 1:0" do
      sieger = Seriensieger.new
      sieger.match_data = match_data([
        finished_match(id_team1: 1, id_team2: 3, points_team1: 4, points_team2: 2),
        finished_match(id_team1: 3, id_team2: 2, points_team1: 0, points_team2: 1),
        a_match
      ])
      sieger.generate_guess(sieger.match_data.last[:match_id]).should == [2, 1]
    end
  end

  describe "#matches_to_guess" do
    it "returns the match in the next 24 hours" do
      sieger = Seriensieger.new
      sieger.match_data = match_data([
        finished_match,
        a_match(match_date_time: Time.at(Time.now + 60*60*2).iso8601),
        a_match(match_date_time: Time.at(Time.now + 60*60*24*5).iso8601)
      ])
      sieger.matches_to_guess.length.should == 1
      sieger.matches_to_guess.should == [sieger.match_data[1][:match_id]]
    end
  end

  describe "#guess_next" do
    it "sends one guess for each next match" do
      sieger = Seriensieger.new
      sieger.match_data = match_data([
        a_match(match_date_time: Time.at(Time.now + 60*60*2).iso8601)
      ])
      mock_submitter = double('submitter')
      mock_submitter.should_receive(:submit)
      sieger.guess_next(mock_submitter)
    end
  end

  describe "#guess_all" do
    it "sends one guess for each match" do
      sieger = Seriensieger.new
      sieger.match_data = match_data([
        a_match
      ])
      mock_submitter = double('submitter')
      mock_submitter.should_receive(:submit)
      sieger.guess_all(mock_submitter)
    end
  end

  describe "#load" do
    it "sends a load request and updates match_data" do
      sieger = Seriensieger.new
      mock_loader = double('loader')
      mock_loader.should_receive(:get).with(2010).and_return([{match_id: 1}])
      sieger.load(2010, mock_loader)
      sieger.match_data.length.should == 1
    end
  end
end

# vim: ai sw=2 expandtab smarttab ts=2
