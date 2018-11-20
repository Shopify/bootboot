require "bootboot/version"
require "bootboot/bundler_patch"

module Bootboot
  GEMFILE = Bundler.default_gemfile
  GEMFILE_NEXT = "#{GEMFILE}_next.lock"
  DUALBOOT_ENV = 'DEPENDENCIES_NEXT'

  autoload :GemfileNextAutoSync, 'bootboot/gemfile_next_auto_sync'
  autoload :Command, 'bootboot/command'
end

Bootboot::GemfileNextAutoSync.new.setup
Bootboot::Command.new.setup
