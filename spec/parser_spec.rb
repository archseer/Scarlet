require 'scarlet/core_ext/hash'
require 'scarlet/parser'

describe Scarlet::Parser do
  before :all do
    @parser = Scarlet::Parser.new('(qaohv)~&@%+')
  end

  describe '#parse_names_list' do
    it 'correctly parses response with one prefix' do
      @parser.parse_names_list("@Op").should eq ["Op", {:owner=>false, :admin=>false, :op=>true, :hop=>false, :voice=>false}]
    end

    it 'correctly parses response with multiple prefixes' do
      @parser.parse_names_list("~@Speed").should eq ["Speed", {:owner=>true, :admin=>false, :op=>true, :hop=>false, :voice=>false}]
    end

    it 'correctly parses response without prefixes' do
      @parser.parse_names_list("Nick").should eq ["Nick", {:owner=>false, :admin=>false, :op=>false, :hop=>false, :voice=>false}]
    end
  end

  describe '#parse_line' do

    it 'correctly parses a simple 001 response' do
      result = {:prefix=>"server.net", :command=>"001", :params=>["Welcome to the IRC Network Scarlet!~name@host.net"], :target=>"Scarletto"}
      Scarlet::Parser.parse_line(':server.net 001 Scarletto :Welcome to the IRC Network Scarlet!~name@host.net').should eq result
    end

    it 'parses a complex MODE response' do
      result = {:prefix=>"Speed!~Speed@lightspeed.org", :command=>"MODE", :params=>["-mivv", "Speed", "Scarletto"], :target=>"#bugs"}
      Scarlet::Parser.parse_line(':Speed!~Speed@lightspeed.org MODE #bugs -mivv Speed Scarletto').should eq result
    end

  end

  describe '#parse_mode' do

    it 'parses a complex MODE list' do
      test = []
      @parser.parse_mode(["-miv+v", "Speed", "Scarletto"], "#test") do |*args|
        test << args
      end

      test.should eq [[:remove, "m", "#test"], [:remove, "i", "#test"], [:remove, "v", "Speed"], [:add, "v", "Scarletto"]]
    end

    it 'parses a MODE list targetting only the channel' do
      test = []
      @parser.parse_mode(["-mi"], "#test") do |*args|
        test << args
      end

      test.should eq [[:remove, "m", "#test"], [:remove, "i", "#test"]]
    end

  end

end
