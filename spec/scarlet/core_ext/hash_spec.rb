require 'spec_helper'
require 'scarlet/core_ext/hash'

describe Hash do
  subject(:data) { { 1 => 'Hello World', 2 => 'How are you', :egg => 'Yuppers' } }

  context '#remap' do
    it 'maps with the evaluated value from the block' do
      actual = data.remap do |key, value|
        [key.to_s, value]
      end
      expect(actual).to eq('1' => 'Hello World', '2' => 'How are you',
                         'egg' => 'Yuppers')
    end
  end

  context '#remap!' do
    it 'replaces the hash with the mapped values' do
      actual = data.dup
      actual.remap! do |key, value|
        [key.to_s, value]
      end
      expect(actual).to eq('1' => 'Hello World', '2' => 'How are you',
                           'egg' => 'Yuppers')
    end
  end
end
