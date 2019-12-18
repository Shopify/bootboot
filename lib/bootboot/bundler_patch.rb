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

module RubyVersionPatch
  def system
    if ENV['BOOTBOOT_UPDATING_ALTERNATE_LOCKFILE']
      # If we're updating the alternate file and the ruby version specified in
      # the Gemfile is different from the Ruby version currently running, we
      # want to build a definition without a lockfile (so that `ruby_version`
      # in the Gemfile isn't overridden by the lockfile) and get its
      # `ruby_version`. This will be used both during dependency resolution so
      # that we can pretend that intended Ruby version is present, as well as
      # when updating the lockfile itself.
      Bundler::Definition.build(Bootboot::GEMFILE, nil, false).ruby_version || super
    else
      super
    end
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
    Bundler::RubyVersion.singleton_class.prepend(RubyVersionPatch)
    Bundler::SharedHelpers.singleton_class.prepend(SharedHelpersPatch)
  end
end
