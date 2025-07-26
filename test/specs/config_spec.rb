require_relative '../spec'

class MyConfig < Bogo::Config
  attribute :name, String, :default => 'the config'
  attribute :location, Smash, :coerce => proc{|v| v.to_smash}
  attribute :count, Integer, :required => true
end

describe Bogo::Config do
  before do
    @config = MyConfig.new(
      :name => 'custom config',
      :location => {
        :address => '127.0.0.1',
        :port => 8080
      },
      :count => 1
    )
  end

  let(:config){ @config }

  it 'should allow unconfigured config' do
    expect(Bogo::Config.new.path).to be_nil
  end

  it 'should have customized name' do
    expect(config.name).to eq('custom config')
  end

  it 'should have a count of 1' do
    expect(config.count).to eq(1)
  end

  it 'should have a location of type Smash' do
    expect(config.location).to be_a(Smash)
  end

  it 'should error if no count is provided' do
    expect {
      MyConfig.new(:name => 'custom config')
    }.to raise_error(ArgumentError)
  end

  it 'should allow updating defined attributes' do
    config.name = 'fubar'
    expect(config.name).to eq('fubar')
  end

  it 'should allow free form access' do
    my_conf = Bogo::Config.new(:a => 1, :b => 2, :c => {:d => {:e => 3}})
    expect(my_conf[:a]).to eq(1)
    expect(my_conf.get(:b)).to eq(2)
    expect(my_conf.get(:c, :d, :e)).to eq(3)
    expect(my_conf.fetch(:z, :c, :x, 4)).to eq(4)
  end

  it 'should allow option immutable' do
    my_conf = Bogo::Config.new(:a => 1, :b => 2, :c => {:d => {:e => 3}})
    my_conf.immutable!
    expect(my_conf[:a]).to be_frozen
    expect(my_conf[:c][:d]).to be_frozen
  end
end
