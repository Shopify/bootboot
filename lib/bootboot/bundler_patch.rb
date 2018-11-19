# frozen_string_literal: true

module DefinitionPatch
  def initialize(wrong_lock, *args)
    lockfile = Pathname.new("#{Bundler::SharedHelpers.default_gemfile}_next.lock")

    super(lockfile, *args)
  end
end

module SharedHelpersPatch
  def default_lockfile
    Pathname.new("#{default_gemfile}_next.lock")
  end
end

Bundler::Dsl.class_eval do
  def enable_dual_booting
    Bundler::Definition.prepend(DefinitionPatch)
    Bundler::SharedHelpers.singleton_class.prepend(SharedHelpersPatch)
  end
end
