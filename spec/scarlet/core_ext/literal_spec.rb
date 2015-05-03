require 'spec_helper'
require 'scarlet/core_ext/literal'

describe String do
  it 'is a Literal' do
    expect('a').to be_kind_of(Literal)
  end
end

describe Symbol do
  it 'is a Literal' do
    expect(:a).to be_kind_of(Literal)
  end
end
