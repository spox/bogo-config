require_relative '../spec'

describe Bogo::Config do
  def with_env(k,v)
    old, ENV[k] = ENV[k], v
    yield
  ensure
    ENV[k] = old
  end

  let(:config_dir){ File.join(File.dirname(__FILE__), 'fail') }

  it 'should refuse to eval ruby code when BOGO_CONFIG_DISABLE_EVAL is set' do
    expect {
      Bogo::Config.new(File.join(config_dir, 'config-ruby'))
    }.to raise_error(Bogo::Config::FileLoadError)
  end

  describe 'File load failure' do
    let(:config_path){ File.join(config_dir, 'config.json') }

    it 'should generate a custom exception on load failure' do
      expect {
        Bogo::Config.new(config_path)
      }.to raise_error(Bogo::Config::FileLoadError)
    end

    it 'should provide original exception on load failure' do
      error = nil
      begin
        Bogo::Config.new(config_path)
      rescue Bogo::Config::FileLoadError => error
      end
      expect(error).to be_a(Bogo::Config::FileLoadError)
      expect(error.original).to be_a(Exception)
    end

    it 'should provide customer errors for ruby' do
      expect {
        Bogo::Config.new(File.join(config_dir, 'config.rb'))
      }.to raise_error(SyntaxError)
    end
  end

  describe 'Extensionless load error' do
    it 'should provide ruby exception on ruby file' do
      error = nil
      begin
        Bogo::Config.new(File.join(config_dir, 'config-ruby'))
      rescue Bogo::Config::FileLoadError => error
      end
      expect(error.original).to be_a(SyntaxError)
    end

    it 'should provide json exception on json file' do
      error = nil
      begin
        Bogo::Config.new(File.join(config_dir, 'config-json'))
      rescue Bogo::Config::FileLoadError => error
      end
      expect(error.original).to be_a(MultiJson::ParseError)
    end

    it 'should provide yaml exception on yaml file' do
      error = nil
      begin
        Bogo::Config.new(File.join(config_dir, 'config-yaml'))
      rescue Bogo::Config::FileLoadError => error
      end
      expect(error.original).to be_a(Psych::SyntaxError)
    end

    it 'should provide xml exception on xml file' do
      error = nil
      begin
        Bogo::Config.new(File.join(config_dir, 'config-xml'))
      rescue Bogo::Config::FileLoadError => error
      end
      expect(error.original).to be_a(MultiXml::ParseError)
    end
  end
end
