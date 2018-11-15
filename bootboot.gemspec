lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bootboot/version"

Gem::Specification.new do |spec|
  spec.name          = "bootboot"
  spec.version       = Bootboot::VERSION
  spec.authors       = ["Shopify"]
  spec.email         = ["rails@shopify.com"]

  spec.summary       = "Dualbooting your ruby app made easy."
  spec.description   = <<-EOM.gsub(/\W+/, ' ')
    This gems removes you the overhead of monkeypatching your Gemfile in order to
    dualboot your app using the Gemfile_next.lock strategy.
    It also ensure that dependencies in the Gemfile.lock and Gemfile_next.lock are
    in sync whenever someone updates a gem.
  EOM
  spec.homepage      = "https://github.com/shopify/bootboot"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/shopify/bootboot"
  spec.metadata["changelog_uri"] = "https://github.com/Shopify/bootboot/blob/master/CHANGELOG.md"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
