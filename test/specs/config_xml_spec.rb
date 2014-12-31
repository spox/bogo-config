require 'minitest/autorun'

describe Bogo::Config do

  describe 'XML files' do
    before do
      @config = Bogo::Config.new(File.join(File.dirname(__FILE__), 'xml'))
    end

    let(:config){ @config }

    it 'should provide valid config' do
      config.get(:base, :fubar, :feebar).must_equal true
    end

    it 'should merge files in sorted order' do
      config.get(:base, :bang).must_equal 'boom'
      config.get(:base, :blam).must_equal false
      config.get(:base, :fubar, :complete).must_equal 3.0
      config[:last_file].must_equal true
    end

  end

end
