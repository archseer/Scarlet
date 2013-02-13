# basically stores the entire Event inside the DB.
# port of Defusal's system
class Scarlet::Log
  include MongoMapper::Document
  key :nick,     String
  key :channel,  String
  key :command,  String
  key :target,   String
  key :message,  String
  timestamps!

  # Create a new log entry from an event.
  # @param [Event] event The event we want to log.
  def self.write event
    return if !event.sender.nick || (event.sender.nick == "Global" or event.sender.nick =~ /Serv$/)
    log = self.new(
      :nick => event.sender.nick,
      :message => event.params.join(" "),
      :channel => event.channel,
      :command => event.command.upcase,
      :target => event.target
    )
    log.save!
  end

  scope :in_channel, lambda { where(:channel.ne => "") } # ne -> not equals
  scope :nick, lambda {|nick| where(:nick => nick) }
  scope :channel, lambda {|channel| where(:channel => channel) }
  scope :join, lambda { where(:command => 'JOIN') }
  scope :privmsg, lambda { where(:command => 'PRIVMSG') }
  scope :created_at, lambda {|created_at| where(:created_at => created_at) }
  scope :message, lambda {|msg| where(:message => msg) }
end
