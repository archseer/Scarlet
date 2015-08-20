require 'spec_helper'
require 'data_model/validators/presence'

module Fixtures
  class PresenceModel < Moon::DataModel::Metal
    field :name, type: String, validate: { presence: {} }
  end
end

describe Moon::DataModel::Validators::Presence do
  it 'reports true for a #present? value' do
    expect(subject.valid?('a')).to eq(true)
    expect(subject.valid?(1)).to eq(true)
    expect(subject.valid?([1])).to eq(true)
    expect(subject.valid?(1 => 2)).to eq(true)
  end

  it 'reports false for a blank? value' do
    expect(subject.valid?('      ')).to eq(false)
    expect(subject.valid?(nil)).to eq(false)
    expect(subject.valid?([])).to eq(false)
    expect(subject.valid?({})).to eq(false)
  end

  it 'fails if the value is blank?' do
    expect { subject.validate('    ') }.to raise_error(Moon::DataModel::ValidationFailed)
    expect { subject.validate({}) }.to raise_error(Moon::DataModel::ValidationFailed)
    expect { subject.validate([]) }.to raise_error(Moon::DataModel::ValidationFailed)
    expect { subject.validate(nil) }.to raise_error(Moon::DataModel::ValidationFailed)
  end
end
