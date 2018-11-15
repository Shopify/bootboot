require "bootboot/version"

module Bootboot
  GEMFILE = Bundler.root.join('Gemfile')
  GEMFILE_NEXT = Bundler.root.join('Gemfile_next.lock')

  autoload :GemfileNextAutoSync, 'bootboot/gemfile_next_auto_sync'
end

Bootboot::GemfileNextAutoSync.new.setup
