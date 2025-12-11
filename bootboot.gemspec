# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bootboot/version"

Gem::Specification.new do |spec|
  spec.name          = "bootboot"
  spec.version       = Bootboot::VERSION
  spec.authors       = ["Shopify"]
  spec.email         = ["rails@shopify.com"]

  spec.summary       = "Dualbooting your ruby app made easy."
  spec.description   = <<-EOM.gsub(/\W+/, " ")
    This gem remove the overhead of monkeypatching your Gemfile in order to
    dualboot your app using the Gemfile_next.lock strategy.
    It also ensure that dependencies in the Gemfile.lock and Gemfile_next.lock are
    in sync whenever someone updates a gem.
  EOM
  spec.homepage      = "https://github.com/shopify/bootboot"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/shopify/bootboot"
  spec.metadata["changelog_uri"] = "https://github.com/Shopify/bootboot/blob/master/CHANGELOG.md"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.files = %x(git ls-files -z lib plugins.rb README.md LICENSE.txt).split("\x0")
  spec.extra_rdoc_files = ["LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0"

  spec.add_development_dependency("minitest", "~> 5.0")
  spec.add_development_dependency("rake", "~> 10.0")
end
