require_relative '../spec'

describe Bogo::Config do

  describe 'XML files' do
    before do
      @config = Bogo::Config.new(File.join(File.dirname(__FILE__), 'xml'))
    end

    let(:config){ @config }

    it 'should provide valid config' do
      expect(config.get(:base, :fubar, :feebar)).to be_truthy
    end

    it 'should merge files in sorted order' do
      expect(config.get(:base, :bang)).to eq('boom')
      expect(config.get(:base, :blam)).to be_falsey
      expect(config.get(:base, :fubar, :complete)).to eq(3.0)
      expect(config[:last_file]).to be_truthy
    end

  end
end
