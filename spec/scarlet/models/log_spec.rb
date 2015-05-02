require 'spec_helper'
require 'scarlet/models/log'

describe Scarlet::Log do
  it 'should log something' do
    Scarlet::Log.log nick: 'Scarlet', channel: '#rspec', command: 'JOIN',
      target: 'Scarlet', message: 'Scarlet joined #rspec'
  end
end
