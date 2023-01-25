# frozen_string_literal: true

require "bootboot/ruby_source"

module DefinitionPatch
  def initialize(wrong_lock, *args)
    lockfile = if ENV["BOOTBOOT_UPDATING_ALTERNATE_LOCKFILE"]
      wrong_lock
    else
      Bootboot::GEMFILE_NEXT_LOCK
    end

    super(lockfile, *args)
  end
end

module RubyVersionPatch
  def system
    # Only monkey-patch if we're updating the alternate file
    return super unless ENV["BOOTBOOT_UPDATING_ALTERNATE_LOCKFILE"]

    # Bail out if the Gemfile doesn't specify a Ruby requirement
    requested_ruby = Bundler::Definition.build(Bootboot::GEMFILE, nil, false).ruby_version
    return super unless requested_ruby

    # If the requirement is for an exact Ruby version, we should substitute the
    # system version with the requirement so that it gets written to the lock file
    requirement = Gem::Requirement.new(requested_ruby.versions)
    requirement.exact? ? requested_ruby : super
  end
end

module DefinitionSourceRequirementsPatch
  def source_requirements
    super.tap do |source_requirements|
      # Bundler has a hard requirement that Ruby should be in the Metadata
      # source, so this replaces Ruby's Metadata source with our custom source
      source = Bootboot::RubySource.new({})
      source_requirements[source.ruby_spec_name] = source
    end
  end
end

module SharedHelpersPatch
  def default_lockfile
    Bootboot::GEMFILE_NEXT_LOCK
  end
end

Bundler::Definition.prepend(DefinitionSourceRequirementsPatch)
Bundler::RubyVersion.singleton_class.prepend(RubyVersionPatch)

Bundler::Dsl.class_eval do
  def enable_dual_booting
    Bundler::Definition.prepend(DefinitionPatch)
    Bundler::SharedHelpers.singleton_class.prepend(SharedHelpersPatch)
    Bundler::Settings.prepend(Module.new do
      def app_cache_path
        "vendor/cache-next"
      end
    end)
  end
end
