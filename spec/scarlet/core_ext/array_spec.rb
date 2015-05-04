require 'spec_helper'
require 'scarlet/core_ext/array'

describe Array do
  context '#subtract_once' do
    it 'removes only 1 occurence of an element' do
      data = [1, 1, 1, 2, 2, 3, 4]
      data.subtract_once 1, 2
      expect(data).to eq([1, 1, 2, 3, 4])
    end
  end
end
