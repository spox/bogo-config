source 'https://rubygems.org'

{
  attribute_struct: "chrisroberts/attribute_struct",
  bogo: "spox/bogo",
}.each do |name, path|
  gem name, path: "~/Projects/#{path}" if File.exist?("~/Projects/#{path}")
end

gemspec
