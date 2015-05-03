require 'spec_helper'
require 'lorem'
require 'scarlet/fmt'
require 'uri'

describe Scarlet::Fmt do
  context '.uri' do
    it 'formats a uri given a String' do
      uri = 'https://duckduckgo.com'

      expect(described_class.uri(uri)).to eq('( https://duckduckgo.com )')
    end

    it 'formats a uri given a URI' do
      uri = URI('https://duckduckgo.com')

      expect(described_class.uri(uri)).to eq('( https://duckduckgo.com )')
    end
  end

  context '.commit_sha' do
    it 'formats a sha' do
      sha = '52cce9f01638a1387d124976001cafdbb4ef68e8'

      expect(described_class.commit_sha(sha)).to match(/\x03\d{2},\d{2}\s52cce9f0\s\x03/)
    end
  end

  context '.purify_msg' do
    it 'removes new lines from strings' do
      str = "Ho ho ho\nWhat is this\n\rAha!"
      expect(described_class.purify_msg(str)).to eq("Ho ho ho What is this Aha!")
    end
  end

  context '.chop_msg' do
    it 'yields one chunk if there is less than 450 characters' do
      chars = Lorem::Base.new('chars', 400).output
      enum = described_class.chop_msg chars
      expect(enum.to_a).to eq [chars]
    end

    it 'yields multiple chunks if there are more than 450 characters' do
      chars = Lorem::Base.new('chars', 800).output
      enum = described_class.chop_msg chars
      expect(enum.to_a.size).to eq(2)
    end
  end
end

