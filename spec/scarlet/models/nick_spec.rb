require 'spec_helper'
require 'scarlet/models/nick'

describe Scarlet::Nick do
  context '.owner' do
    it 'returns the owner Nick' do
      obj = described_class.owner
      expect(obj).to be_kind_of(Scarlet::Nick)
      expect(obj.nick).to eq('RspecGuy')
    end
  end
end
