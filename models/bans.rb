class ::IrcBot::Bans
  include MongoMapper::Document
  timestamps!
  many :bans
end
class ::IrcBot::Ban
  include MongoMapper::EmbeddedDocument
  validates_presence_of :nick
  key :nick,        String
  key :by,          String
  key :reason,      String
  key :level,       Integer, :default => 0
  timestamps!
  embedded_in :bans
end
# // Ban.level
# // 0 - Suspension
# // 1 - Bot Ban
# // 2 - Ban (From Channel)