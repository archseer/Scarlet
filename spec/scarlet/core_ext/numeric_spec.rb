require 'spec_helper'
require 'scarlet/core_ext/numeric'

describe Numeric do
  context '#minmax' do
    it 'will clamp a value between a given minimum and maximum' do
      expect(23.minmax(24, 26)).to eq(24)
      expect(25.minmax(24, 26)).to eq(25)
      expect(27.minmax(24, 26)).to eq(26)
    end
  end
end
