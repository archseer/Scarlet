require 'time-lord'
require 'thread'
require 'scarlet/logger'

class Scarlet
  class ExpirationCache
    include Scarlet::Loggable

    def initialize
      @mutex = Mutex.new
      @entries = {}
      schedule_expiration
    end

    def new_expiration
      5.minutes.from_now.to_i
    end

    def schedule_time
      10.minutes
    end

    def modify
      @mutex.synchronize do
        yield
      end
    end

    private def reset_expiration(entry)
      entry[:expiration] = new_expiration
    end

    def schedule_expiration
      EM.add_timer schedule_time do
        logger.info 'Expiring old cache entries'
        modify do
          @entries.reject! do |key, data|
            Time.now.to_i >= data[:expiration]
          end
        end
        schedule_expiration
      end
    end

    def [](key)
      logger.info "Accessing cache: key=#{key}"
      data = nil
      modify do
        data = @entries[key]
        reset_expiration(data) if data
      end
      return data && data[:value]
    end

    def []=(key, value)
      logger.info "Modifying cache: key=#{key}"
      modify do
        data = @entries[key] ||= {}
        data[:value] = value
        reset_expiration(data)
      end
    end

    def self.instance
      @instance ||= new
    end
  end
end
