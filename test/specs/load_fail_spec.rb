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
    e = with_env 'BOGO_CONFIG_DISABLE_EVAL', 'true' do
      assert_raises Bogo::Config::FileLoadError do
        Bogo::Config.new(File.join(config_dir, 'config-ruby'))
      end
    end
    _(e.original.message).must_equal "Ruby based configuration evaluation is currently disabled!"
  end

  describe 'File load failure' do
    let(:config_path){ File.join(config_dir, 'config.json') }

    it 'should generate a custom exception on load failure' do
      _{
        Bogo::Config.new(config_path)
      }.must_raise Bogo::Config::FileLoadError
    end

    it 'should provide original exception on load failure' do
      error = nil
      begin
        Bogo::Config.new(config_path)
      rescue Bogo::Config::FileLoadError => error
      end
      _(error).must_be_kind_of Bogo::Config::FileLoadError
      _(error.original).must_be_kind_of Exception
    end

    it 'should provide customer errors for ruby' do
      assert_raises SyntaxError do
        Bogo::Config.new(File.join(config_dir, 'config.rb'))
      end
    end
  end

  describe 'Extensionless load error' do
    it 'should provide ruby exception on ruby file' do
      error = nil
      begin
        Bogo::Config.new(File.join(config_dir, 'config-ruby'))
      rescue Bogo::Config::FileLoadError => error
      end
      _(error.original).must_be_kind_of SyntaxError
    end

    it 'should provide json exception on json file' do
      error = nil
      begin
        Bogo::Config.new(File.join(config_dir, 'config-json'))
      rescue Bogo::Config::FileLoadError => error
      end
      _(error.original).must_be_kind_of MultiJson::ParseError
    end

    it 'should provide yaml exception on yaml file' do
      error = nil
      begin
        Bogo::Config.new(File.join(config_dir, 'config-yaml'))
      rescue Bogo::Config::FileLoadError => error
      end
      _(error.original).must_be_kind_of Psych::SyntaxError
    end

    it 'should provide xml exception on xml file' do
      error = nil
      begin
        Bogo::Config.new(File.join(config_dir, 'config-xml'))
      rescue Bogo::Config::FileLoadError => error
      end
      _(error.original).must_be_kind_of MultiXml::ParseError
    end
  end
end
