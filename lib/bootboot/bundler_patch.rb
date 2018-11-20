# frozen_string_literal: true

module DefinitionPatch
  def initialize(wrong_lock, *args)
    lockfile = if ENV['SKIP_BUNDLER_PATCH']
      wrong_lock
    else
      Bootboot::GEMFILE_NEXT_LOCK
    end

    super(lockfile, *args)
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
    Bundler::SharedHelpers.singleton_class.prepend(SharedHelpersPatch)
  end
end
