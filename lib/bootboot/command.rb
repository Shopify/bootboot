# frozen_string_literal: true

require 'fileutils'

module Bootboot
  class Command < Bundler::Plugin::API
    command 'bootboot'

    def exec(_cmd, _args)
      FileUtils.cp("#{GEMFILE}.lock", GEMFILE_NEXT)

      File.open(GEMFILE, 'a+') do |f|
        f.write("Plugin.send(:load_plugin, 'bootboot') if Plugin.installed?('bootboot')\n")
      end
    end
  end
end
