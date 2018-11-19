# frozen_string_literal: true

module Bootboot
  class GemfileNextAutoSync < Bundler::Plugin::API
    def setup
      check_bundler_version
      opt_in
    end

    private

    def check_bundler_version
      self.class.hook("before-install-all") do
        next if Bundler::VERSION >= "1.17.0" || !GEMFILE_NEXT.exist?

        Bundler.ui.warn(<<-EOM.gsub(/\s+/, " "))
          Bootboot can't automatically update the Gemfile_next.lock because you are running
          an older version of Bundler.

          Update Bundler to 1.17.0 to discard this warning.
        EOM
      end
    end

    def opt_in
      self.class.hook('before-install-all') do
        @previous_lock = Bundler.default_lockfile.read
      end

      self.class.hook("after-install-all") do
        current_definition = Bundler.definition

        next if !GEMFILE_NEXT.exist? || nothing_changed?(current_definition) || Bundler.default_lockfile == GEMFILE_NEXT
        update!(current_definition)
      end
    end

    def nothing_changed?(current_definition)
      current_definition.to_lock == @previous_lock
    end

    def update!(current_definition)
      Bundler.ui.confirm("Updating the #{GEMFILE_NEXT}")
      ENV[DUALBOOT_ENV] = '1'

      unlock = current_definition.instance_variable_get(:@unlock)
      definition = Bundler::Definition.build(GEMFILE, GEMFILE_NEXT, unlock)
      definition.resolve_remotely!
      definition.lock(GEMFILE_NEXT)
    ensure
      ENV.delete(DUALBOOT_ENV)
    end
  end
end
