require 'spec_helper'
require 'scarlet/models/file_repository'

describe Scarlet::Repository do
  before :all do
    @tmp = Dir.mktmpdir
    @db_path = File.join(@tmp, "db.yml")
    @db = described_class.new(filename: @db_path)
  end

  after :all do
    FileUtils.remove_entry_secure @tmp
  end

  let(:repo) { @db }

  it 'initializes a repository' do
    repo
  end

  it 'creates an entry' do
    repo.create('1', { id: '1', name: 'First!' })
  end

  it 'should fail to create an entry with the same id' do
    expect { repo.create('1', { id: '1', name: 'Second!' }) }.to raise_error(Scarlet::Repository::EntryExists)
  end

  it 'creates an entry if it doesn\'t exist' do
    repo.touch('2', { id: '2', name: 'Second!' })
    repo.touch('1', { id: '1', name: 'Third!' })
    repo.touch('3', { id: '3', name: 'Third!' })
  end

  it 'gets an existing entry' do
    expect(repo.get('1')).to eq(id: '1', name: 'First!')
  end

  it 'fails to get an non-existant entry' do
    expect { repo.get('super') }.to raise_error(IndexError)
  end

  it 'queries for entries' do
    actual = repo.query { |d| d[:name].include?('ird') }.to_a
    expect(actual).to eq([{id: '3', name: 'Third!'}])
  end

  it 'updates an existing entry' do
    repo.update('3', id: '3', name: 'Third!', extra: 'data!')
  end

  it 'fails to update an non-existant entry' do
    expect { repo.update('4', name: 'Forth, yes the language') }.to raise_error(Scarlet::Repository::EntryMissing)
  end

  it 'deletes an entry' do
    repo.delete('3')
  end

  it 'saves an entry regardless' do
    repo.save('4', id: '4', name: 'pew')
    repo.delete('4')
  end

  it 'returns all entries' do
    expect(repo.all).to eq({
      '1' => { id: '1', name: 'First!' },
      '2' => { id: '2', name: 'Second!' }
    })
  end
end
