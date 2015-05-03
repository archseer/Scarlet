require 'spec_helper'
require 'scarlet/models/model_base'

class FixtureModel < Scarlet::ModelBase
  field :name, type: String
end

class TestModel < Scarlet::ModelBase
  field :name, type: String
end

describe Scarlet::ModelBase do
  before :all do
    FileUtils.mkdir_p Scarlet.config.db[:path]
  end

  it 'creates a new model without saving it' do
    TestModel.new(name: 'First')
  end

  it 'creates, updates and destroys a record' do
    record = TestModel.create(name: 'Second')
    expect(record.name).to eq('Second')
    expect(record.exists?).to eq(true)
    record.update(name: 'I made a thing')

    record = TestModel.first(name: 'I made a thing')
    expect(record.exists?).to eq(true)
    record.name = 'ItsJustAModel'
    record.save

    record = TestModel.first(name: 'ItsJustAModel')
    expect(record.exists?).to eq(true)
    record.destroy
    expect(record.exists?).to eq(false)
  end

  it 'retrieves an existing model' do
    id = '5f8dacfc-e585-4f1e-9c2b-376697c2b527'
    record = FixtureModel.get(id)
    expect(record.id).to eq(id)
  end

  it 'nabs the first model that matches a query' do
    id = '5f8dacfc-e585-4f1e-9c2b-376697c2b527'
    record = FixtureModel.first(id: id)
    expect(record.id).to eq(id)
  end
end
