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
      @users.to_a.should_not include(@user)
    end
  end

  describe '#add' do
    it 'adds the user to the collection' do
      user2 = Scarlet::User.new('test2')
      @users.add user2
      @users.get(name: user2.name).should eq user2
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
    @channel.users.to_a.should include @user
    @user.channels.to_a.should include @channel
  end

  it 'should part a channel' do
    @user.join @channel
    @user.part @channel
    @user.channels.to_a.should_not include @channel
    @channel.users.to_a.should_not include @user
    @channel.user_flags.should_not have_key @user
  end

  it 'should part all channels' do
    @user.join @channel
    channel2 = Scarlet::Channel.new('#test2')
    @user.join channel2
    @user.part_all
    @user.channels.to_a.should be_empty
    @channel.users.to_a.should_not include @user
    channel2.users.to_a.should_not include @user
    @channel.user_flags.should_not have_key @user
    channel2.user_flags.should_not have_key @user
  end

  it 'should remove channel from user' do
    @channels.remove @channel

    expect(@channels.exist?(@channel.name)).to eq false
    @user.channels.to_a.should_not include @channel
  end
end
