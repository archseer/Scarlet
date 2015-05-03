require 'active_support/core_ext/string'
require 'securerandom'
require 'data_model/load'
require 'data_model/validators/presence'
require 'scarlet/models/file_repository'
require 'scarlet/bot'

class Scarlet
  # Base model class for all other models in Scarlet
  class ModelBase < Moon::DataModel::Metal
    field :id,           type: String,  default: proc { SecureRandom.uuid }
    field :created_at,   type: Integer, default: proc { Time.now.to_i }
    field :updated_at,   type: Integer, default: proc { Time.now.to_i }
    field :destroyed_at, type: Integer, default: proc { -1 }

    def self.repo_config
      {}
    end

    def self.repo
      @repo ||= begin
        if repo_config[:memory]
          Repository.new(repo_config)
        else
          bsn = name.tableize
          dirname = File.expand_path(Scarlet.config.db.fetch(:path), Scarlet.root)
          filename = File.join(dirname, bsn + '.yml')
          FileUtils.mkdir_p(File.dirname(filename))
          Repository.new(repo_config.merge(filename: filename))
        end
      end
    end

    def repo
      self.class.repo
    end

    def exists?
      repo.exists?(id)
    end

    def pre_update
      self.updated_at = Time.now.to_i
    end

    def on_update
    end

    def pre_save
      self.updated_at = Time.now.to_i
    end

    def on_save
    end

    def pre_destroy
      self.destroyed_at = Time.now.to_i
    end

    def on_destroy
    end

    def update(opts)
      update_fields opts
      pre_update
      repo.update(id, to_h)
      on_update
      self
    end

    def save
      pre_save
      repo.save(id, to_h)
      on_save
      self
    end

    def destroy
      pre_destroy
      repo.delete(id)
      on_destroy
      self
    end

    def self.create(data = {})
      record = new(data)
      repo.create record.id, record.to_h
      record
    end

    def self.get(id)
      new(repo.get(id))
    end

    def self.where(query)
      Enumerator.new do |yielder|
        repo.query do |data|
          query.all? do |key, value|
            data[key] == value
          end
        end.each do |data|
          yielder.yield new(data)
        end
      end
    end

    def self.first(query)
      where(query).first
    end
  end
end
