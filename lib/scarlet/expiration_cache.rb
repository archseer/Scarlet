require 'scarlet/async'
require 'scarlet/time'
require 'scarlet/logger'

class Scarlet
  class ExpirationCache
    class Entry
      attr_accessor :value
      attr_accessor :expiration
      attr_accessor :lifespan
      attr_accessor :settings

      def initialize(**options)
        @value = options[:value]
        @lifespan = options[:lifespan]
        @settings = options.fetch(:settings) do
          { reset_on_change: true, reset_on_access: true }
        end
        reset_expiration
      end

      private def reset_expiration
        @expiration = @lifespan && @lifespan.from_now.to_i || nil
      end

      def on_access
        reset_expiration if @settings[:reset_on_access]
      end

      def on_change
        reset_expiration if @settings[:reset_on_change]
      end
    end

    attr_accessor :logger

    # by default, how long does an entry live?
    attr_accessor :lifespan

    # How often should we check for expired entries?
    attr_accessor :schedule_time

    # What object is in charge of scheduling, defaults to EM
    attr_accessor :scheduler

    def initialize(**options)
      @mutex = Mutex.new
      @entries = {}
      @scheduler = options.fetch(:scheduler, EM)
      @lifespan = options.fetch(:lifespan, 30.minutes)
      @schedule_time = options.fetch(:schedule_time, 10.minutes)
      @logger = options.fetch(:logger, Scarlet.logger)
      schedule_expiration if options.fetch(:autostart, false)
    end

    private def synchronize
      @mutex.synchronize { yield }
    end

    def empty?
      synchronize { @entries.empty? }
    end

    def clear
      logger.debug 'Clearing'
      synchronize { @entries.clear }
    end

    def run_expiration
      logger.debug 'Expiring old cache entries'
      synchronize do
        @entries.reject! do |key, data|
          # can the entry expire ? test if its expired : never expire
          data.expiration ? Time.now.to_i >= data.expiration : false
        end
      end
    end

    def schedule_expiration
      @scheduler.add_timer(schedule_time) do
        run_expiration
        schedule_expiration
      end
    end

    def modify(key)
      synchronize { @entries[key].tap { |entry| yield entry } }
    end

    def key?(key)
      synchronize do
        @entries.key?(key)
      end
    end

    def get(key)
      logger.debug "Accessing cache: key=#{key}"
      data = modify(key) do |entry|
        entry.on_access if entry
      end
      return data && data.value
    end
    alias :[] :get

    def set(key, value, **options)
      logger.info "Modifying cache: key=#{key}"
      synchronize do
        entry = @entries[key] ||= Entry.new({ lifespan: @lifespan }.merge(options))
        entry.value = value
        entry.on_change
        entry.value
      end
    end

    def []=(key, value)
      set(key, value)
    end

    def fetch(key, default_value = nil)
      key?(key) && self[key] || set(key, block_given? && yield || default_value)
    end

    # ExpirationCache has a Singleton instance available, this may
    # be removed in the future.
    #
    # @return [ExpirationCache]
    def self.instance
      @instance ||= new(autostart: true)
    end
  end
end
