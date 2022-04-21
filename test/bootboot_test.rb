# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "open3"
require "fileutils"

class BootbootTest < Minitest::Test
  def test_does_not_sync_the_gemfile_next_lock_when_unexisting
    write_gemfile do |file, _dir|
      File.write(file, 'gem "rake"', mode: "a")

      run_bundle_command("install", file.path)

      refute(File.exist?(gemfile_next(file)))
    end
  end

  def test_does_not_sync_the_gemfile_next_lock_when_nothing_changed
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, 'gem "rake"', mode: "a")

      output = run_bundle_command("install", file.path)
      assert_match("Updating the #{file.path}_next.lock", output)

      output = run_bundle_command("install", file.path)
      refute_match("Updating the #{file.path}_next.lock", output)
    end
  end

  def test_sync_the_gemfile_next_after_installation_of_new_gem
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, 'gem "rake"', mode: "a")

      run_bundle_command("install", file.path)

      assert(Bundler::Definition.build(file.path, "#{file.path}.lock", false).locked_deps["rake"])
      assert(Bundler::Definition.build(file.path, gemfile_next(file), false).locked_deps["rake"])
    end
  end

  def test_sync_the_gemfile_next_after_removal_of_gem
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, 'gem "rake"', mode: "a")

      run_bundle_command("install", file.path)

      assert(Bundler::Definition.build(file.path, "#{file.path}.lock", false).locked_deps["rake"])
      assert(Bundler::Definition.build(file.path, gemfile_next(file), false).locked_deps["rake"])

      File.write(file, file.read.gsub('gem "rake"'))

      run_bundle_command("install", file.path)

      refute(Bundler::Definition.build(file.path, "#{file.path}.lock", false).locked_deps["rake"])
      refute(Bundler::Definition.build(file.path, gemfile_next(file), false).locked_deps["rake"])
    end
  end

  def test_sync_the_gemfile_next_after_installation_of_new_gem_with_custom_bootboot_env
    write_gemfile("source 'https://rubygems.org'\n#{plugin}\n") do |file, _dir|
      File.write(file, <<-EOM, mode: "a")
        Bundler.settings.set_local('bootboot_env_prefix', 'SHOPIFY')

        if ENV['SHOPIFY_NEXT']
          gem 'minitest', '5.11.3'
        end
      EOM

      run_bundle_command("bootboot", file.path)

      run_bundle_command("install", file.path, env: { "SHOPIFY_NEXT" => "1" })
      output = run_bundle_command(
        'exec ruby -e "require \'minitest\';puts Minitest::VERSION"',
        file.path,
        env: { "SHOPIFY_NEXT" => "1" }
      )

      assert_equal("5.11.3", output.strip)
    end
  end

  def test_sync_the_gemfile_next_after_update_of_gem
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, 'gem "rake", "10.5.0"', mode: "a")

      run_bundle_command("install", file.path)

      assert_equal(
        "= 10.5.0",
        Bundler::Definition.build(
          file.path, "#{file.path}.lock", false
        ).locked_deps["rake"].requirement.to_s
      )

      assert_equal(
        "= 10.5.0",
        Bundler::Definition.build(
          file.path, gemfile_next(file), false
        ).locked_deps["rake"].requirement.to_s
      )

      File.write(file, file.read.gsub("10.5.0", "11.3.0"))

      run_bundle_command("update rake", file.path)

      assert_equal(
        "= 11.3.0",
        Bundler::Definition.build(
          file.path, "#{file.path}.lock", false
        ).locked_deps["rake"].requirement.to_s
      )

      assert_equal(
        "= 11.3.0",
        Bundler::Definition.build(
          file.path, gemfile_next(file), false
        ).locked_deps["rake"].requirement.to_s
      )
    end
  end

  def test_sync_the_gemfile_next_when_gemfile_contain_if_else_statement
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, <<-EOM, mode: "a")
        if ENV['DEPENDENCIES_NEXT']
          gem 'rake', '11.3.0'
        else
          gem 'rake', '10.5.0'
        end
      EOM

      run_bundle_command("install", file.path)

      assert_equal(
        "= 10.5.0",
        Bundler::Definition.build(
          file.path, "#{file.path}.lock", false
        ).locked_deps["rake"].requirement.to_s
      )

      assert_equal(
        "= 11.3.0",
        Bundler::Definition.build(
          file.path, gemfile_next(file), false
        ).locked_deps["rake"].requirement.to_s
      )
    end
  end

  def test_sync_the_lock_when_the_next_lock_gets_updated_rak
    gemfile_content = <<-EOM
      source "https://rubygems.org"
      #{plugin}
      Plugin.send(:load_plugin, 'bootboot') if Plugin.installed?('bootboot')

      unless ENV['DEPENDENCIES_PREVIOUS']
        enable_dual_booting if Plugin.installed?('bootboot')
      end
    EOM

    write_gemfile(gemfile_content) do |file, _dir|
      FileUtils.cp(gemfile_next(file), "#{file.path}.lock")
      File.write(file, 'gem "rake"', mode: "a")

      run_bundle_command("install", file.path)

      assert(Bundler::Definition.build(file.path, "#{file.path}.lock", false).locked_deps["rake"])
      assert(Bundler::Definition.build(file.path, gemfile_next(file), false).locked_deps["rake"])
    end
  end

  def test_does_not_sync_the_gemfile_next_lock_when_installing_env_is_set
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, 'gem "rake"', mode: "a")

      output = run_bundle_command("install", file.path, env: { "DEPENDENCIES_NEXT" => "1" })
      refute_match("Updating the", output)
    end
  end

  def test_bootboot_command_initialize_the_next_lock_and_update_the_gemfile
    write_gemfile("source 'https://rubygems.org'\n#{plugin}\n") do |file, _dir|
      run_bundle_command("bootboot", file.path)

      assert(File.exist?(gemfile_next(file)))
      assert_equal(File.read(gemfile_next(file)), File.read("#{file.path}.lock"))

      File.write(file, <<-EOM, mode: "a")
        if ENV['DEPENDENCIES_NEXT']
          gem 'minitest', '5.11.3'
        end
      EOM

      run_bundle_command("install", file.path, env: { "DEPENDENCIES_NEXT" => "1" })
      output = run_bundle_command(
        'exec ruby -e "require \'minitest\';puts Minitest::VERSION"',
        file.path,
        env: { "DEPENDENCIES_NEXT" => "1" }
      )

      assert_equal("5.11.3", output.strip)
    end
  end

  def test_bundle_install_with_different_ruby_updating_gemfile_next_lock_succeeds
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, <<-EOM, mode: "a")
        if ENV['DEPENDENCIES_NEXT']
          ruby '9.9.9'
        else
          ruby '#{RUBY_VERSION}'
        end
      EOM

      run_bundle_command("install", file.path)

      assert_equal(
        RUBY_VERSION,
        Bundler::Definition.build(
          file.path, "#{file.path}.lock", false
        ).locked_ruby_version_object.gem_version.to_s
      )

      with_env_next do
        assert_equal(
          "9.9.9",
          Bundler::Definition.build(
            file.path, gemfile_next(file), false
          ).locked_ruby_version_object.gem_version.to_s
        )
      end
    end
  end

  def test_bundle_install_with_different_ruby_for_installing_gemfile_next_lock_fails
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, <<-EOM, mode: "a")
        if ENV['DEPENDENCIES_NEXT']
          ruby '9.9.9'
        else
          ruby '#{RUBY_VERSION}'
        end
      EOM

      error = assert_raises(BundleInstallError) do
        run_bundle_command("install", file.path, env: { Bootboot.env_next => "1" })
      end

      assert_match("Your Ruby version is #{RUBY_VERSION}, but your Gemfile specified 9.9.9", error.message)
    end
  end

  def test_bundle_caching_both_sets_of_gems
    write_gemfile do |file, dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, <<-EOM, mode: "a")
        if ENV['DEPENDENCIES_NEXT']
          gem 'minitest', '5.14.0'
        else
          gem 'minitest', '5.13.0'
        end
      EOM

      run_bundle_command("install", file.path)
      run_bundle_command("install", file.path, env: { Bootboot.env_next => "1" })
      run_bundle_command("pack", file.path)
      run_bundle_command("pack", file.path, env: { Bootboot.env_next => "1" })

      assert(File.exist?(dir + "/vendor/cache/minitest-5.13.0.gem"))
      refute(File.exist?(dir + "/vendor/cache/minitest-5.14.0.gem"))
      assert(File.exist?(dir + "/vendor/cache-next/minitest-5.14.0.gem"))
      refute(File.exist?(dir + "/vendor/cache-next/minitest-5.13.0.gem"))
      assert(run_bundle_command("info minitest", file.path).include?("minitest (5.13.0)"))
      refute(run_bundle_command("info minitest", file.path).include?("minitest (5.14.0)"))
      assert(run_bundle_command(
        "info minitest", file.path, env: { Bootboot.env_next => "1" }
      ).include?("minitest (5.14.0)"))
      refute(run_bundle_command(
        "info minitest", file.path, env: { Bootboot.env_next => "1" }
      ).include?("minitest (5.13.0)"))
    end
  end

  private

  def gemfile_next(gemfile)
    "#{gemfile.path}_next.lock"
  end

  def write_gemfile(content = nil)
    dir = Dir.mktmpdir
    file = Tempfile.new("Gemfile", dir).tap do |f|
      f.write(content || <<-EOM)
        source "https://rubygems.org"

        #{plugin}
        Plugin.send(:load_plugin, 'bootboot') if Plugin.installed?('bootboot')

        if ENV['DEPENDENCIES_NEXT']
          enable_dual_booting if Plugin.installed?('bootboot')
        end
      EOM
      f.rewind
    end

    run_bundle_command("install", file.path)

    yield(file, dir)
  ensure
    FileUtils.remove_dir(dir, true)
  end

  def plugin
    branch = %x(git rev-parse --abbrev-ref HEAD).strip

    "plugin 'bootboot', git: '#{Bundler.root}', branch: '#{branch}'"
  end

  class BundleInstallError < StandardError; end

  def run_bundle_command(subcommand, gemfile_path, env: {})
    output = nil
    bundler_version = ENV.fetch("BOOTBOOT_TEST_BUNDLER_VERSION")
    command = "bundle _#{bundler_version}_ #{subcommand}"
    Bundler.with_unbundled_env do
      output, status = Open3.capture2e({ "BUNDLE_GEMFILE" => gemfile_path }.merge(env), command)

      raise BundleInstallError, "bundle install failed: #{output}" unless status.success?
    end
    output
  end

  def with_env_next
    prev = ENV[Bootboot.env_next]
    ENV[Bootboot.env_next] = "1"
    yield
  ensure
    ENV[Bootboot.env_next] = prev
  end
end
