require_relative '../spec'

describe Bogo::Config do

  let(:config_dir){ File.join(File.dirname(__FILE__), 'fail') }

  describe 'File load failure' do

    before do
      @config_path = File.join(config_dir, 'config.json')
    end

    let(:config_path){ @config_path }

    it 'should generate a custom exception on load failure' do
      ->{
        Bogo::Config.new(config_path)
      }.must_raise Bogo::Config::FileLoadError
    end

    it 'should provide original exception on load failure' do
      error = nil
      begin
        Bogo::Config.new(config_path)
      rescue Bogo::Config::FileLoadError => error
      end
      error.must_be_kind_of Bogo::Config::FileLoadError
      error.original.must_be_kind_of Exception
    end

  end

  describe 'Extensionless load error' do

    it 'should provide ruby exception on ruby file' do
      error = nil
      begin
        Bogo::Config.new(File.join(config_dir, 'config-ruby'))
      rescue Bogo::Config::FileLoadError => error
      end
      error.original.must_be_kind_of SyntaxError
    end

    it 'should provide json exception on json file' do
      error = nil
      begin
        Bogo::Config.new(File.join(config_dir, 'config-json'))
      rescue Bogo::Config::FileLoadError => error
      end
      error.original.must_be_kind_of MultiJson::ParseError
    end

    it 'should provide yaml exception on yaml file' do
      error = nil
      begin
        Bogo::Config.new(File.join(config_dir, 'config-yaml'))
      rescue Bogo::Config::FileLoadError => error
      end
      error.original.must_be_kind_of Psych::SyntaxError
    end

    it 'should provide xml exception on xml file' do
      error = nil
      begin
        Bogo::Config.new(File.join(config_dir, 'config-xml'))
      rescue Bogo::Config::FileLoadError => error
      end
      error.original.must_be_kind_of MultiXml::ParseError
    end

  end

end
