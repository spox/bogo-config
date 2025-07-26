# Bogo Config

Hash based application configuration helpers, because
snowflake configurations are evil.

## Usage

### Direct

Use the `Bogo::Config` directly to store configuration values:

```ruby
require 'bogo-config'

config = Bogo::Config.new(
  :bind => {
    :address => '0.0.0.0',
    :port => 8080
  },
  :run_as => 'www-data'
)

puts config.get(:bind, :address)
puts config[:run_as]
```

### Configuration files

A path to a configuration file can also be provided. Lets
define the file:

```json
# /tmp/bogo-config.json
{
  "bind": {
    "address": "0.0.0.0",
    "port": 8080
  },
  "run_as": "www-data"
}
```

and now we can load it:

```ruby
require 'bogo-config'

config = Bogo::Config.new('/tmp/bogo-config.json')

puts config.get(:bind, :address)
puts config[:run_as]
```

### Subclassing

Subclassing `Bogo::Config` allows adding some structure
to the configuration file. The `Bogo::Lazy` module is
used to provide the `#attribute` method to describe
the configuration:

```ruby
require 'bogo-config'

class MyConfig < Bogo::Config
  attribute :bind, Smash, :coerce => proc{|v| v.to_smash}
  attribute :run_as, String, :default => 'www-data'
end

config = MyConfig.new('/tmp/bogo-config.json')
puts config.get(:bind, :address)
puts config[:run_as]
```

### `Configuration` file

Support for `AttributeStruct` configuration files is builtin.
A helper class is provided as a visual nicety. The above
JSON example could also be written as:

```ruby
# /tmp/bogo-config.rb
Configuration.new do
  bind do
    address '0.0.0.0'
    port 8080
  end
  run_as 'www-data'
end
```

#### Kernel methods

By default the configuration is loaded within a mostly
empty context and does not include commonly expected
methods as defined by the `Kernel` module. There are 
two ways access these methods:

##### Use root namespace

Accessing methods on the `Kernel` module can be accomplished
by forcing the root namespace:

``` ruby
Configuration.new do
  random_value ::Kernel.rand
end
```

##### Load within kernelified struct

Methods from the `Kernel` module can be made available within
the struct when loading the configuration:

``` ruby
config = MyConfig.new('/tmp/bogo-config.rb', :kernelify)
```

This will allow using the `Kernel` module methods directly:

``` ruby
Configuration.new do
  random_value rand
end
```

__NOTE__: Use caution when using `:kernelify`. Because it 
makes all methods defined on the `Kernel` module available,
it may conflict with desired attribute names._

### Configuration file support

Currently the following serialization types are supported:

* JSON
* YAML
* XML
* AttributeStruct

Note on XML configuration files: The configuration must
be contained within a `<configuration>` tag. The above
example would then look like this:

```xml
<configuration>
  <bind>
    <address>
      0.0.0.0
    </address>
    <port>
      8080
    </port>
  </bind>
  <run_as>
    www-data
  </run_as>
</configuration>
```

### Configuration directory

The path provided on initialization can also be a directory.
The contents of the directory will be read in string sorted
order and deep merged. Files can be a mix of supported types.

### Ruby evaluation

Ruby evaluation is super awesome, except when you don't want
it and then it's not super awesome. If a running process needs
to disable Ruby based evaluation (a service perhaps), this
can be done with an environment variable:

```
export BOGO_CONFIG_DISABLE_EVAL=true
```

## Info
* Repository: https://github.com/spox/bogo-config
