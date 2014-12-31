require 'yaml'
require 'multi_xml'
require 'multi_json'
require 'attribute_struct'
require 'forwardable'

require 'bogo-config'

module Bogo

  class Config

    include Bogo::Lazy
    extend Forwardable

    # @return [String] configuration path
    attr_reader :path

    # Create new instance
    #
    # @param path_or_hash [String, Hash] file/directory path or base Hash
    # @return [self]
    def initialize(path_or_hash=nil)
      if(path_or_hash.is_a?(String))
        @path = path
        hash = load!
      else
        hash = path_or_hash
      end
      load_data(hash)
      data.replace(hash.to_smash.deep_merge(data))
    end

    # Allow Smash like behavior
    def_delegators *([:data, :[]] + Smash.public_instance_methods(false))

    # Load configuration from file(s)
    #
    # @return [self]
    def load!
      if(path)
        if(File.directory?(path))
          conf = Dir.glob(File.join(path, '*')).inject(Smash.new) do |memo, file_path|
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
      case File.extname(file_path)
      when '.yaml', '.yml'
        yaml_load(file_path)
      when '.json'
        json_load(file_path)
      when '.xml'
        xml_load(file_path)
      else
        result = [:struct_load, :json_load, :yaml_load, :xml_load].detect do |loader|
          begin
            send(loader, file_path)
          rescue => e
            nil
          end
        end
        unless(result)
          raise "Failed to load configuration from file (#{file_path})"
        end
        result
      end
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
      MultiXml.parse(File.read(file_path)).to_smash
    end

    # Read and parse AttributeStruct file
    #
    # @param file_path
    # @return [Smash]
    def struct_load(file_path)
      result = BasicObject.new.instance_eval(
        IO.read(file_path), file_path, 1
      )
      result._dump.to_smash
    end

  end
end
