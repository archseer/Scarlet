require 'active_support/core_ext/string'
require 'securerandom'
require 'data_model/load'
require 'data_model/validators/presence'
require 'scarlet/models/file_repository'
require 'scarlet/bot'
require 'scarlet/core_ext/moon-record'
require 'scarlet/core_ext/enumerable'

class Scarlet
  # Base model class for all other models in Scarlet
  module RecordRepository
    include Moon::Record::ClassMethods

    def repository_basename
      name.tableize + '.yml'
    end

      # @return [String]
    def repository_filename
      dirname = File.expand_path(Scarlet.config.db.fetch(:path), Scarlet.root)
      filename = File.join(dirname, repository_basename)
    end

      # @return [Hash<Symbol, Object>]
    def repo_config
      {
        memory: false,
        filename: repository_filename
      }
    end

    def prepare_repository
      FileUtils.mkdir_p(File.dirname(repository_filename))
    end

    def scope(method_name, cb)
      define_singleton_method method_name do |*a|
        cb.call(*a)
      end
    end
  end

  class ModelBase < Moon::DataModel::Metal
    include Moon::Record::InstanceMethods

    field :id,           type: String,  default: proc { SecureRandom.uuid }
    field :created_at,   type: Integer, default: proc { Time.now.to_i }
    field :updated_at,   type: Integer, default: proc { Time.now.to_i }
    field :destroyed_at, type: Integer, default: proc { -1 }

    def pre_update
      self.updated_at = Time.now.to_i
    end

    def pre_save
      self.updated_at = Time.now.to_i
    end

    def pre_destroy
      self.destroyed_at = Time.now.to_i
    end
  end
end
