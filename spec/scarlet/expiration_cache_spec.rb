require 'spec_helper'
require 'scarlet/expiration_cache'
require 'scarlet/logger'

module Fixtures
  class BasicScheduler
    attr_reader :entries

    def initialize
      @entries = []
    end

    def clear
      @entries.clear
    end

    def add_timer(t, &block)
      @entries << [t, block]
    end

    def self.instance
      @instance ||= new
    end
  end
end

describe Scarlet::ExpirationCache do
  let(:cache) { @cache ||= described_class.new(scheduler: Fixtures::BasicScheduler.instance, logger: Scarlet::NullLogger) }

  context '#initialize' do
    it 'initializes without parameters' do
      cache = described_class.new
      # offers sane defaults
      expect(cache.scheduler).to eq(EM)
      expect(cache.lifespan).to eq(30.minutes)
      expect(cache.schedule_time).to eq(10.minutes)
    end

    it 'initializes with parameters' do
      cache = described_class.new(scheduler: Fixtures::BasicScheduler.instance, lifespan: 1.hour, schedule_time: 30.minutes)
      expect(cache.scheduler).to eq(Fixtures::BasicScheduler.instance)
      expect(cache.lifespan).to eq(1.hour)
      expect(cache.schedule_time).to eq(30.minutes)
    end
  end

  context 'caching' do
    before(:each) { cache.clear }

    it 'adds an entry' do
      expect(cache.set(:egg, 12)).to eq(12)
      cache[:egg] = 14
      expect(cache.get(:egg)).to eq(14)
    end

    it 'initializes a value via fetch' do
      expect(cache.fetch(:egg, 12)).to eq(12)
      expect(cache.fetch(:egg, 14)).to eq(12)
    end
  end

  context 'expiration' do
    before(:each) { cache.clear }

    it 'expires entries' do
      cache.set(:egg, 12, lifespan: 1.second)
      sleep 2.0
      cache.run_expiration
      expect(cache).to be_empty
    end
  end

  context 'scheduling' do
    it 'schedules a expiration' do
      scheduler = cache.scheduler.clear
      cache.schedule_expiration
      # ensure that it set the time correctly
      expect(scheduler.entries.first.first).to eq(600)

      # now simulate the execution
      scheduler.entries.first.last.call

      # it should reschedule itself
      expect(scheduler.entries.size).to eq(2)

      expect(scheduler.entries.last.first).to eq(600)
    end
  end
end
