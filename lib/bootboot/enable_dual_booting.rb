# frozen_string_literal: true

module DefinitionPatch
  def initialize(*)
    lockfile = Pathname.new("#{Bundler::SharedHelpers.default_gemfile}_next.lock")
    super
  end
end

if ENV['SHOPIFY_NEXT']
  Bundler::Definition.prepend(DefinitionPatch)
end
