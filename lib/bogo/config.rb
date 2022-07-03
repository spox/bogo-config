require 'bogo'
require 'yaml'
require 'multi_xml'
require 'multi_json'
require 'attribute_struct'
require 'forwardable'
require 'bogo/config/version'

autoload :Configuration, 'bogo/config/configuration'

module Bogo

  class Config

    # Exception wrapper class used for configuration file load failure
    class FileLoadError < LoadError

      # @return [Exception]
      attr_reader :original

      def initialize(message, original_exception = nil)
        super(message)
        @original = original_exception
      end

      # @return [Fixnum]
      def exit_code
        222
      end

    end

    class << self

      include Bogo::Memoization

      # Reload any registered `Bogo::Config` instances
      #
      # @return [TrueClass]
      def reload!
        obj_ids = memoize(:bogo_reloadable_configs, :global)
        objects = Thread.exclusive do
          ObjectSpace.each_object.find_all do |obj|
            obj_ids.include?(obj.object_id)
          end
        end
        objects.map(&:init!)
        memoize(:bogo_reloadable_configs, :global).delete_if do |oid|
          !obj_ids.include?(oid)
        end
        true
      end

      # Register config instance to auto reload on HUP
      #
      # @param config [Bogo::Config]
      # @return [TrueClass]
      def reloadable(config)
        if(config.is_a?(Bogo::Config))
          reloader
          memoize(:bogo_reloadable_configs, :global){ [] }.push(config.object_id).uniq!
        else
          raise TypeError.new "Expecting type `Bogo::Config`. Received: `#{config.class}`"
        end
        true
      end

      # Internal reloader
      #
      # @return [Thread]
      def reloader
        memoize(:bogo_config_reloader, :global) do
          Thread.new do
            begin
              loop do
                begin
                  sleep
                rescue SignalException => e
                  if(e.signm == 'SIGHUP')
                    if(ENV['BOGO_DEBUG'])
                      $stdout.puts 'SIGHUP encountered. Reloading `Bogo::Config` instances.'
                    end
                    Bogo::Config.reload!
                  else
                    raise
                  end
                end
              end
            rescue => e
              if(ENV['BOGO_DEBUG'])
                $stderr.puts "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
              end
              retry
            end
          end
        end
      end

    end

    include Bogo::Lazy
    extend Forwardable

    # @return [String] configuration path
    attr_reader :path
    # @return [String, Hash]
    attr_reader :initial

    # Create new instance
    #
    # @param path_or_hash [String, Hash] file/directory path or base Hash
    # @return [self]
    def initialize(path_or_hash=nil)
      @initial = path_or_hash
      @data = Smash.new
      init!
    end

    # Enables automatic reloading on SIGHUP
    #
    # @return [TrueClass]
    def reloadable!
      Bogo::Config.reloadable(self)
      true
    end

    # Freeze underlying configuration data
    #
    # @return [self]
    def immutable!
      @data = data.to_smash(:freeze)
    end

    # Intialize the configuration
    #
    # @return [self]
    def init!
      if(initial.is_a?(String))
        @path = initial.dup
        hash = load!
      else
        hash = initial
      end
      if(hash)
        is_immutable = data.frozen?
        # TODO: synchronize here
        load_data(hash)
        @data = hash.to_smash.deep_merge(data.to_smash)
        @data.to_smash(:freeze) if is_immutable
      end
      self
    end

    # Allow Smash like behavior
    def_delegators *([:data, :[]] + (Smash.public_instance_methods - Object.public_instance_methods))

    # Override to force consistent data access (removes dirty
    # functionality)
    #
    # @return [Smash]
    def dirty
      data
    end

    # @return [String]
    def to_json(*args)
      MultiJson.dump(data, *args)
    end

    # Load configuration from file(s)
    #
    # @return [self]
    def load!
      if(path)
        if(File.directory?(path))
          conf = Dir.glob(File.join(path, '*')).sort.inject(Smash.new) do |memo, file_path|
            memo.deep_merge(load_file(file_path))
          end
        elsif(File.file?(path))
          conf = load_file(path)
        else
          raise Errno::ENOENT.new path
        end
        conf
      end
    end

    # Load configuration file
    #
    # @param file_path [String] path to file
    # @return [Smash]
    def load_file(file_path)
      result = nil
      errors = Smash.new
      error = nil
      begin
        result = case File.extname(file_path)
                 when '.yaml', '.yml'
                   yaml_load(file_path)
                 when '.json'
                   json_load(file_path)
                 when '.xml'
                   xml_load(file_path)
                 when '.rb'
                   struct_load(file_path)
                 else
                   [:struct_load, :json_load, :yaml_load, :xml_load].each do |loader|
                     begin
                       result = send(loader, file_path)
                       break
                     rescue StandardError, ScriptError => e
                       errors[loader] = e
                       if(ENV['BOGO_DEBUG'])
                         $stderr.puts "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
                       end
                     end
                   end
                   result
                 end
      rescue => error
      end
      unless(result)
        raise FileLoadError.new(
          "Failed to load configuration from file (#{file_path})",
          error || extract_error_for(file_path, errors)
        )
      end
      result
    end

    # Read and parse YAML file
    #
    # @param file_path
    # @return [Smash]
    def yaml_load(file_path)
      YAML.load(File.read(file_path)).to_smash
    end

    # Read and parse JSON file
    #
    # @param file_path
    # @return [Smash]
    def json_load(file_path)
      MultiJson.load(File.read(file_path)).to_smash
    end

    # Read and parse XML file
    #
    # @param file_path
    # @return [Smash]
    # @note supar ENTERPRISE
    def xml_load(file_path)
      result = MultiXml.parse(File.read(file_path)).to_smash[:configuration]
      xml_format(result)
    end

    # Format XML types
    #
    # @param result [Smash]
    # @return [Smash]
    def xml_format(result)
      Smash[result.map{|k,v| [k, xml_format_value(v)]}]
    end

    # Format XML value types
    #
    # @param value [Object]
    # @return [Object]
    def xml_format_value(value)
      case value
      when Hash
        xml_format(value)
      when Array
        value.map{|v| xml_format_value(v)}
      else
        value.strip!
        if(value == 'true')
          true
        elsif(value == 'false')
          false
        elsif(value.to_i.to_s == value)
          value.to_i
        elsif(value.to_f.to_s == value)
          value.to_f
        else
          value
        end
      end
    end

    # Read and parse AttributeStruct file
    #
    # @param file_path
    # @return [Smash]
    def struct_load(file_path)
      if(eval_disabled?)
        raise 'Ruby based configuration evaluation is currently disabled!'
      else
        result = Module.new.instance_eval(
          IO.read(file_path), file_path, 1
        )
        result._dump.to_smash
      end
    end

    # @return [TrueClass, FalseClass]
    def eval_enabled?
      ENV['BOGO_CONFIG_DISABLE_EVAL'].to_s.downcase != 'true'
    end

    # @return [TrueClass, FalseClass]
    def eval_disabled?
      !eval_enabled?
    end

    # Extract appropriate execption based on path
    #
    # @param path [String]
    # @param errors [Hash]
    # @return [Exception, NilClass]
    def extract_error_for(path, errors)
      content = File.read(path).strip
      if(content.start_with?('{'))
        errors[:json_load]
      elsif(content.start_with?('<'))
        errors[:xml_load]
      elsif(content.match(/\.new\s*(do|\{)/))
        errors[:struct_load]
      else
        errors[:yaml_load]
      end
    end

  end
end
