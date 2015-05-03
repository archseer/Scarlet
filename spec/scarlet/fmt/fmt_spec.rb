require 'spec_helper'
require 'lorem'
require 'scarlet/fmt'
require 'uri'

describe Scarlet::Fmt do
  context '.uri' do
    it 'formats a uri given a String' do

    end

    it 'formats a uri given a URI' do

    end
  end

  context '.chop_msg' do
    it 'yields one chunk if there is less than 450 characters' do
      chars = Lorem::Base.new('chars', 400).output
      enum = Scarlet::Fmt.chop_msg chars
      expect(enum.to_a).to eq [chars]
    end

    it 'yields multiple chunks if there are more than 450 characters' do
      chars = Lorem::Base.new('chars', 800).output
      enum = Scarlet::Fmt.chop_msg chars
      expect(enum.to_a.size).to eq(2)
    end
  end
end

