require 'scarlet/models/model_base'

class Scarlet
  # Ban.level
  # 0 - No Ban
  # 1 - Suspension
  # 2 - Bot Ban
  # 3 - Ban (from Channel)
  class Ban < ModelBase
    extend RecordRepository

    field :nick,    type: String, validate: { presence: {} }
    field :servers, type: Array,  default: proc { Array.new }
    field :by,      type: String
    field :reason,  type: String
    field :level,   type: Integer, default: 0
  end
end
