require 'spec_helper'
require 'scarlet/models/file_repository'

describe Moon::Storage::YAMLStorage do
  after :all do
    FileUtils.rm_rf fixture_pathname('db_tmp.yml')
  end

  it 'loads an existing store' do
    store = described_class.new(fixture_pathname('db.yml'))
    expect(store.data).to eq({ '1' => { id: '1', name: 'First!' }})
  end

  it 'saves a new store' do
    store = described_class.new(fixture_pathname('db_tmp.yml'))
    store.save
  end

  it 'updates an existing store' do
    store = described_class.new(fixture_pathname('db_tmp.yml'))
    store.update({ '1' => { id: '1', epic: 'Yeah' }})
    store2 = described_class.new(fixture_pathname('db_tmp.yml'))
    expect(store2.data).to eq({ '1' => { id: '1', epic: 'Yeah' }})
  end
end
