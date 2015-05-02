require 'thread'
require 'thread_safe'
require 'yaml'

module Scarlet
  class FileStorage
    # @!attribute filename
    #   @return [String]
    attr_accessor :filename
    # @!attribute [r] data
    #   @return [Hash<String, Hash>]
    attr_reader :data

    def initialize(filename)
      @filename = filename
      @transact_m = Mutex.new
      @data = ThreadSafe::Hash.new
      load if File.exist?(@filename)
    end

    def load_unsafe
      @data = Hash[YAML.load_file(@filename).map do |key, value|
        [key, value.symbolize_keys]
      end]
    end

    def load
      @transact_m.synchronize do
        load_unsafe
      end
    end

    def save_unsafe
      File.write @filename, @data.to_yaml
    end

    def save
      @transact_m.synchronize do
        save_unsafe
      end
    end

    def update_unsafe(new_data)
      @data = new_data
      save_unsafe
    end

    def update(new_data)
      @transact_m.synchronize do
        update_unsafe(new_data)
      end
    end

    def map(&block)
      @transact_m.synchronize do
        update_unsafe block.call(@data)
      end
    end

    def modify(&block)
      map do |data|
        block.call data
        data
      end
    end
  end

  class Repository
    class EntryExists < IndexError
    end

    class EntryMissing < IndexError
    end

    def initialize(filename)
      @storage = FileStorage.new(filename)
      @repo_m = Mutex.new
    end

    def filename
      @storage.filename
    end

    private def store(id, data)
      @storage.modify do |stored|
        stored[id] = data
      end
    end

    def exists?(id)
      @storage.data.key?(id)
    end

    private def ensure_no_entry(id)
      raise EntryExists, "entry #{id} exists" if exists?(id)
    end

    private def ensure_entry(id)
      raise EntryMissing, "entry #{id} does not exist" unless exists?(id)
    end

    def create(id, data)
      ensure_no_entry(id)
      store(id, data)
    end

    def touch(id, data = {})
      store(id, data) unless exists?(id)
    end

    def all
      @storage.data
    end

    def get(id)
      @storage.data.fetch(id).dup
    end

    def update(id, data)
      ensure_entry(id)
      store(id, data)
    end

    def save(id, data)
      store(id, data)
    end

    def delete(id)
      ensure_entry(id)
      @storage.modify { |stored| stored.delete(id) }
    end

    def query(&block)
      data = @storage.data.dup
      Enumerator.new do |yielder|
        data.each_value do |entry|
          yielder.yield entry if block.call(entry)
        end
      end
    end
  end
end
