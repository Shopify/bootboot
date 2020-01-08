# frozen_string_literal: true

module DefinitionPatch
  def initialize(wrong_lock, *args)
    lockfile = if ENV['BOOTBOOT_UPDATING_ALTERNATE_LOCKFILE']
      wrong_lock
    else
      Bootboot::GEMFILE_NEXT_LOCK
    end

    super(lockfile, *args)
  end
end

module MetadataPatch
  def specs
    metadata_specs = super

    # The spec name for Ruby changed between Bundler 1.17 and 2.0, so we
    # want to get the Ruby spec name that the definition is depending on
    ruby_spec = metadata_specs.find { |d| d.name[/[R|r]uby\0/] }
    alternate_ruby_version = Bundler::Definition.build(Bootboot::GEMFILE, nil, false).ruby_version

    if ruby_spec && alternate_ruby_version && alternate_ruby_version != Bundler::RubyVersion.system
      specs_with_ruby = metadata_specs.dup
      ruby_spec = Gem::Specification.new(ruby_spec.name, alternate_ruby_version.to_gem_version_with_patchlevel)
      ruby_spec.source = self
      specs_with_ruby << ruby_spec
      return specs_with_ruby
    end

    metadata_specs
  end
end

module SharedHelpersPatch
  def default_lockfile
    Bootboot::GEMFILE_NEXT_LOCK
  end
end

Bundler::Dsl.class_eval do
  def enable_dual_booting
    Bundler::Definition.prepend(DefinitionPatch)
    Bundler::Source::Metadata.prepend(MetadataPatch)
    Bundler::SharedHelpers.singleton_class.prepend(SharedHelpersPatch)
  end
end
