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
    _(Bogo::Config.new.path).must_be_nil
  end

  it 'should have customized name' do
    _(config.name).must_equal 'custom config'
  end

  it 'should have a count of 1' do
    _(config.count).must_equal 1
  end

  it 'should have a location of type Smash' do
    _(config.location.class).must_equal Smash
  end

  it 'should error if no count is provided' do
    _{ MyConfig.new(:name => 'custom config') }.must_raise(ArgumentError)
  end

  it 'should allow updating defined attributes' do
    config.name = 'fubar'
    _(config.name).must_equal 'fubar'
  end

  it 'should allow free form access' do
    my_conf = Bogo::Config.new(:a => 1, :b => 2, :c => {:d => {:e => 3}})
    _(my_conf[:a]).must_equal 1
    _(my_conf.get(:b)).must_equal 2
    _(my_conf.get(:c, :d, :e)).must_equal 3
    _(my_conf.fetch(:z, :c, :x, 4)).must_equal 4
  end

  it 'should allow option immutable' do
    my_conf = Bogo::Config.new(:a => 1, :b => 2, :c => {:d => {:e => 3}})
    my_conf.immutable!
    _(my_conf[:a]).must_be :frozen?
    _(my_conf[:c][:d]).must_be :frozen?
  end
end
