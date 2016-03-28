# v0.2.0
* Stop configuration detection after successful load
* Use custom exception type for config load failures

# v0.1.14
* Update debug environment variable name

# v0.1.12
* Allow Ruby config disable via environment variable
* Remove exclusive use during init

# v0.1.10
* Gracefully handle failures of ruby files (rescue parse errors)

# v0.1.8
* Support JSON serialization of configurations

# v0.1.6
* Remove dirty functionality to retain consistent data access
* Allow setting configuration as immutable

# v0.1.4
* Delegate more methods from config instance to underlying data instance
* Add initial support for auto reloading configuration

# v0.1.2
* Update `Bogo::Config` to behave more like `Smash`
* Make XML usage more consistent and apply type formats
* Add `Configuration` class for cleaner struct usage
* Add test coverage

# v0.1.0
* Initial release
