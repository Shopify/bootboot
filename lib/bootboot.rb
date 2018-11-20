require "bootboot/version"
require "bootboot/bundler_patch"

module Bootboot
  GEMFILE = Bundler.default_gemfile
  GEMFILE_LOCK = Pathname("#{GEMFILE}.lock")
  GEMFILE_NEXT_LOCK = Pathname("#{GEMFILE}_next.lock")
  DUALBOOT_NEXT = 'DEPENDENCIES_NEXT'
  DUALBOOT_PREVIOUS = 'DEPENDENCIES_PREVIOUS'

  autoload :GemfileNextAutoSync, 'bootboot/gemfile_next_auto_sync'
  autoload :Command,             'bootboot/command'
end

Bootboot::GemfileNextAutoSync.new.setup
Bootboot::Command.new.setup
