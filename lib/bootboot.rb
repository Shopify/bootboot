require "bootboot/version"
require "bootboot/bundler_patch"

module Bootboot
  GEMFILE = Bundler.root.join('Gemfile')
  GEMFILE_NEXT = Bundler.root.join('Gemfile_next.lock')
  DUALBOOT_ENV = 'DEPENDENCIES_NEXT'

  autoload :GemfileNextAutoSync, 'bootboot/gemfile_next_auto_sync'
end

Bootboot::GemfileNextAutoSync.new.setup
