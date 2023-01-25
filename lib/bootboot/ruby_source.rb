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
        requested_ruby = Bundler::Definition.build(Bootboot::GEMFILE, nil, false).ruby_version
        system_version = Bundler::RubyVersion.system.gem_version
        requirement = Gem::Requirement.new(requested_ruby.versions) if requested_ruby

        # This will be used both during dependency resolution so that we can pretend
        # the intended Ruby version is present, as well as when updating the lock file.
        ruby_spec_version = if requested_ruby.nil?
          # if the Gemfile doesn't request a specific Ruby version, just use system
          system_version
        elsif !requirement.exact? && requirement.satisfied_by?(system_version)
          # if the Gemfile requests a non-exact Ruby version which is satisfied by
          # the currently running Ruby, use that when updating the lock file
          system_version
        else
          # If we're here, there's either an exact requirement for the Ruby version
          # (in which case we should substitue it instead of current Ruby version),
          # else the currently running Ruby doesn't satisfy the non-exact requirement
          # (in which case an error will be thrown by bundler). Not sure how we can
          # improve the error message, which will be vague due to using #gem_version
          # of the unsatisified requirement.
          requested_ruby.gem_version
        end

        ruby_spec = Gem::Specification.new(ruby_spec_name, ruby_spec_version)
        ruby_spec.source = self
        idx << ruby_spec
      end
    end

    def to_s
      "Bootboot plugin Ruby source"
    end
  end
end
