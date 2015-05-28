require 'spec_helper'
require 'lorem'
require 'scarlet/models/log'

describe Scarlet::Log do
  it 'logs something' do
    described_class.log nick: 'Scarlet', channel: '#rspec', command: 'JOIN',
      target: 'Scarlet', message: 'Scarlet joined #rspec'
  end

  it 'it scopes' do
    gen = Lorem::Base.new('words', 16)
    described_class.log nick: 'ThatGuy', channel: '#rspec', command: 'PRIVMSG',
      target: 'Scarlet', message: gen.output
    described_class.log nick: 'SomeGuy', channel: '#other', command: 'PRIVMSG',
      target: 'Scarlet', message: gen.output
    described_class.log nick: 'OtherGuy', channel: '#someplace', command: 'PRIVMSG',
      target: 'Scarlet', message: gen.output
    described_class.log nick: 'Scarlet', channel: '', command: 'QUIT',
      target: '', message: ''

    described_class.in_channel.each do |l|
      expect(l.channel).to be_present
    end

    described_class.nick('ThatGuy').each do |l|
      expect(l.nick).to eq('ThatGuy')
    end

    described_class.privmsg.each do |l|
      expect(l.command).to eq('PRIVMSG')
    end
  end
end
