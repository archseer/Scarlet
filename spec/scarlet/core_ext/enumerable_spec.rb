require 'spec_helper'
require 'scarlet/core_ext/enumerable'

describe Enumerable do
  context '#limit' do
    it 'limits an enumerable stream to the first X elements' do
      result = [1, 2, 3, 4, 5, 6, 7, 8].limit(4).to_a
      expect(result).to eq([1, 2, 3, 4])
    end
  end
end
