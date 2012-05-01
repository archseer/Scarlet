class Scarlet::Ban
  include MongoMapper::Document
  validates_presence_of :username
  key :username,    String
  key :channel,     Array
  key :by,          String
  key :reason,      String
  key :level,       Integer, :default => 0
  timestamps!
end
# // Ban.level
# // 0 - Suspension
# // 1 - Bot Ban
# // 2 - Ban (From Channel)