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
      self.class.hook("after-install-all") do
        current_definition = Bundler.definition

        update!(current_definition) unless current_definition.nothing_changed? && GEMFILE_NEXT.exist?
      end
    end

    def update!(current_definition)
      Bundler.ui.confirm("Updating the #{GEMFILE_NEXT}")

      unlock = current_definition.instance_variable_get(:@unlock)
      definition = Bundler::Definition.build(GEMFILE, GEMFILE_NEXT, unlock)
      definition.resolve_remotely!
      definition.lock(GEMFILE_NEXT)
    end
  end
end
