require 'scarlet/models/model_base'

module Scarlet
  # Privileges level
  # 0 - regular
  # 1 - registered
  # 2 - voice
  # 3 - VIP
  #...
  # 6 - super tester
  # 7 - op
  # 8 - dev
  # 9 - owner
  class Nick < ModelBase
    field :nick,       type: String,  validate: { presence: {} }
    field :aliases,    type: Array,   default: proc { Array.new }
    field :privileges, type: Integer, default: 1
    field :win_points, type: Integer, default: 0
    field :settings,   type: Hash,    default: proc { Hash.new }

    def self.owner
      first(privileges: 9)
    end
  end
end
