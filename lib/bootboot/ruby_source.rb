# frozen_string_literal: true

module Bootboot
  class RubySource
    include Bundler::Plugin::API::Source

    # The spec name for Ruby changed from "ruby\0" to "Ruby\0" between Bundler
    # 1.17 and 2.0, so we want to use the Ruby spec name from Metadata so
    # Bootboot works across Bundler versions
    def ruby_spec_name
      @ruby_spec_name ||= begin
        metadata = Bundler::Source::Metadata.new
        ruby_spec = metadata.specs.find { |s| s.name[/[R|r]uby\0/] }
        # Default to Bundler > 2 in case the Bundler internals change
        ruby_spec ? ruby_spec.name : "Ruby\0"
      end
    end

    def specs
      Bundler::Index.build do |idx|
        # If the ruby version specified in the Gemfile is different from the
        # Ruby version currently running, we want to build a definition without
        # a lockfile (so that `ruby_version` in the Gemfile isn't overridden by
        # the lockfile) and get its `ruby_version`. This will be used both
        # during dependency resolution so that we can pretend the intended Ruby
        # version is present, as well as when updating the lockfile itself.
        ruby_version = Bundler::Definition.build(Bootboot::GEMFILE, nil, false).ruby_version
        ruby_version ||= Bundler::RubyVersion.system
        ruby_spec = Gem::Specification.new(ruby_spec_name, ruby_version.to_gem_version_with_patchlevel)
        ruby_spec.source = self
        idx << ruby_spec
      end
    end

    def to_s
      "Bootboot plugin Ruby source"
    end
  end
end
