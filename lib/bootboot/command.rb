# frozen_string_literal: true

require 'fileutils'

module Bootboot
  class Command < Bundler::Plugin::API
    command 'bootboot'

    def exec(_cmd, _args)
      FileUtils.cp("#{GEMFILE}.lock", GEMFILE_NEXT)

      File.open(GEMFILE, 'a+') do |f|
        f.write(<<-EOM)
Plugin.send(:load_plugin, 'bootboot') if Plugin.installed?('bootboot')

if ENV['#{DUALBOOT_ENV}']
  enable_dual_booting

# Add any gem you want here, they will be loaded only when running
# bundler command prefixed with `#{DUALBOOT_ENV}=1`.
end
EOM
      end
    end
  end
end
