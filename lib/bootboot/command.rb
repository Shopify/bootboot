# frozen_string_literal: true

require 'fileutils'

module Bootboot
  class Command < Bundler::Plugin::API
    def setup
      self.class.command('bootboot')
    end

    def exec(_cmd, _args)
      FileUtils.cp(GEMFILE_LOCK, GEMFILE_NEXT_LOCK)

      File.open(GEMFILE, 'a+') do |f|
        f.write(<<-EOM)
Plugin.send(:load_plugin, 'bootboot') if Plugin.installed?('bootboot')

if ENV['#{Bootboot.env_next}']
  enable_dual_booting if Plugin.installed?('bootboot')

  # Add any gem you want here, they will be loaded only when running
  # bundler command prefixed with `#{Bootboot.env_next}=1`.
end
EOM
      end
    end
  end
end
