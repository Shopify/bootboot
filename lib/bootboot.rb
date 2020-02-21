# frozen_string_literal: true

require "bootboot/version"
require "bootboot/bundler_patch"

module Bootboot
  GEMFILE = Bundler.default_gemfile
  GEMFILE_LOCK = Pathname("#{GEMFILE}.lock")
  GEMFILE_NEXT_LOCK = Pathname("#{GEMFILE}_next.lock")

  autoload :GemfileNextAutoSync, 'bootboot/gemfile_next_auto_sync'
  autoload :Command,             'bootboot/command'

  class << self
    def env_next
      env_prefix + '_NEXT'
    end

    def env_previous
      env_prefix + '_PREVIOUS'
    end

    def load
      return if Bundler::Plugin.instance_variable_get(:@loaded_plugin_names).include?('bootboot')

      GemfileNextAutoSync.new.setup
      Command.new.setup
    end

    private

    def env_prefix
      Bundler.settings['bootboot_env_prefix'] || 'DEPENDENCIES'
    end
  end
end
