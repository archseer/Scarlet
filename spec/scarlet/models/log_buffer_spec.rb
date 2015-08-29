require 'spec_helper'
require 'scarlet/models/log'

describe Scarlet::LogBuffer do
  it 'logs something' do
    subject.log nick: 'Scarlet', channel: '#rspec', command: 'JOIN',
      target: 'Scarlet', message: 'Scarlet joined #rspec'
  end

  it 'it scopes' do
    gen = Lorem::Base.new('words', 16)
    subject.log nick: 'ThatGuy', channel: '#rspec', command: 'PRIVMSG',
      target: 'Scarlet', message: gen.output
    subject.log nick: 'SomeGuy', channel: '#other', command: 'PRIVMSG',
      target: 'Scarlet', message: gen.output
    subject.log nick: 'OtherGuy', channel: '#someplace', command: 'PRIVMSG',
      target: 'Scarlet', message: gen.output
    subject.log nick: 'Scarlet', channel: '', command: 'QUIT',
      target: '', message: ''

    subject.in_channel.each do |l|
      expect(l.channel).to be_present
    end

    subject.nick('ThatGuy').each do |l|
      expect(l.nick).to eq('ThatGuy')
    end

    subject.privmsg.each do |l|
      expect(l.command).to eq('PRIVMSG')
    end
  end
end
