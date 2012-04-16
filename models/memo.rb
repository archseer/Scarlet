class Memo
  include MongoMapper::EmbeddedDocument
  validates_presence_of :message
  key :sender,    String
  key :message,   String
  timestamps!
  def to_short_s()
    "FROM: #{sender} at #{created_at.to_s}"
  end
  embedded_in :nick
end