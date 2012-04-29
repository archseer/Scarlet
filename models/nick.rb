class ::IrcBot::Nick
  include MongoMapper::Document
  validates_presence_of :nick
  key :nick,            String
  key :aliases,         Array
  key :privileges,      Integer, :default => 1
  key :win_points,      Integer, :default => 0
  key :settings,        Hash
  timestamps!
  many :memos
end
# 0 - regular
# 1 - registered
# 2 - voice
# 3 - VIP
#...
# 6 - super tester
# 7 - op
# 8 - dev
# 9 - owner