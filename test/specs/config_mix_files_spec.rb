require_relative '../spec'

describe Bogo::Config do
  describe 'Mixed files' do
    before do
      @config = Bogo::Config.new(File.join(File.dirname(__FILE__), 'mixed'))
    end

    let(:config){ @config }

    it 'should provide valid config' do
      _(config.get(:base, :fubar, :feebar)).must_equal true
    end

    it 'should merge files in sorted order' do
      _(config.get(:base, :bang)).must_equal 'boom'
      _(config.get(:base, :blam)).must_equal false
      _(config.get(:base, :fubar, :complete)).must_equal 3.0
      _(config[:last_file]).must_equal true
    end
  end
end
