class Scarlet::Ban
  include MongoMapper::Document
  validates_presence_of :nick
  key :nick,        String
  key :servers,     Array
  key :by,          String
  key :reason,      String
  key :level,       Integer, :default => 0
  timestamps!
end
# // Ban.level
# // 0 - No Ban
# // 1 - Suspension
# // 2 - Bot Ban
# // 3 - Ban (from Channel)