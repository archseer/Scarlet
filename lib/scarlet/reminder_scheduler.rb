require 'scarlet/models/model_base'
require 'chronic'

class Scarlet
  class ReminderScheduler
    class TaskRepository
      include Scarlet::RecordRepository
      undef_method :repository_basename
      undef_method :scope

      attr_reader :filename

      def initialize(filename)
        @filename = filename
      end

      # @return [String]
      def repository_filename
        filename
      end

      def model
        Task
      end

      def create(*args, &block)
        record = super(*args, &block)
        record.repository = repository
        record
      end
    end

    class Task < Scarlet::ModelBase
      field :requested_at, type: DateTime, default: proc { DateTime.now }
      field :execute_at,   type: DateTime, default: proc { DateTime.now }
      field :sender,       type: String
      field :receiver,     type: String
      field :message,      type: String

      attr_accessor :repository
    end

    class MessageTarget
      include MessageHelper

      attr_reader :server

      def initialize(server)
        @server = server
      end
    end

    attr_reader :server
    attr_reader :repository

    def initialize(server)
      @server = server
      basename = @server.config.address + ".yml"
      dirname = Scarlet.config.scheduler.fetch('path')
      pathname = File.join(dirname, basename)
      @repository = TaskRepository.new pathname
      @target = MessageTarget.new @server
    end

    def update
      now = DateTime.now
      dead = []
      @repository.repository.all.each do |_, data|
        begin
          if now >= data[:execute_at]
            dead << data[:id]
            @target.msg data[:receiver], data[:message]
          end
        rescue => ex
          Scarlet.logger.error ex.inspect
          ex.backtrace.each do |line|
            Scarlet.logger.error line
          end
        end
      end
      dead.each do |id|
        @repository.repository.delete(id)
      end
    end

    private def create_job(execute_at, data)
      repository.create({ execute_at: execute_at }.merge(data))
    end

    # Parses a duration string
    #
    # @param [String] t
    # @param [Hash] data
    # @return [Boolean] true the job was added, false something went wrong
    def add(t, data)
      if execute_at = Chronic.parse(t)
        create_job(execute_at.to_datetime, data)
        true
      else
        false
      end
    end
  end
end
