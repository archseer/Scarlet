require 'spec_helper'
require 'scarlet/user'
require 'scarlet/channel'

describe Scarlet::Collection do
  before :each do
    @users = Scarlet::Collection.new
    @user = Scarlet::User.new('test')
    @users.add @user
  end

  describe '#where' do
    it 'gets an user array by an attribute' do
      expect(@users.where(name: @user.name)).to eq [@user]
    end

    it 'gets an user array by name string' do
      expect(@users.where(@user.name)).to eq [@user]
    end
  end

  describe '#get' do
    it 'gets the first user with the value' do
      expect(@users.get(@user.name)).to eq @user
    end
  end

  describe '#remove' do
    it 'removes the user from the collection' do
      @users.remove @user
      expect(@users.to_a).not_to include(@user)
    end
  end

  describe '#add' do
    it 'adds the user to the collection' do
      user2 = Scarlet::User.new('test2')
      @users.add user2
      expect(@users.get(name: user2.name)).to eq user2
    end
  end

  describe '#exist?' do
    it 'checks the existence of the user' do
      expect(@users.exist?(@user.name)).to eq true
    end
  end
end

describe Scarlet::Users do
  it 'should ensure a user' do
    @users = Scarlet::Users.new
    expect(@users.get_ensured('test')).to be_an_instance_of Scarlet::User
  end
end

describe 'Users and Channels' do
  before :each do
    @users = Scarlet::Users.new
    @user = Scarlet::User.new('bot')
    @channels = Scarlet::ServerChannels.new
    @channel = Scarlet::Channel.new('#test')

    @users.add @user
    @channels.add @channel
  end

  it 'should join a channel' do
    @user.join @channel
    expect(@channel.users.to_a).to include @user
    expect(@user.channels.to_a).to include @channel
  end

  it 'should part a channel' do
    @user.join @channel
    @user.part @channel
    expect(@user.channels.to_a).not_to include @channel
    expect(@channel.users.to_a).not_to include @user
    expect(@channel.user_flags).not_to have_key @user
  end

  it 'should part all channels' do
    @user.join @channel
    channel2 = Scarlet::Channel.new('#test2')
    @user.join channel2
    @user.part_all
    expect(@user.channels.to_a).to be_empty
    expect(@channel.users.to_a).not_to include @user
    expect(channel2.users.to_a).not_to include @user
    expect(@channel.user_flags).not_to have_key @user
    expect(channel2.user_flags).not_to have_key @user
  end

  it 'should remove channel from user' do
    @channels.remove @channel

    expect(@channels.exist?(@channel.name)).to eq false
    expect(@user.channels.to_a).not_to include @channel
  end
end
