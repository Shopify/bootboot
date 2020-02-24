# frozen_string_literal: true

require "test_helper"
require 'tempfile'
require 'open3'
require 'fileutils'

class BootbootTest < Minitest::Test
  def test_does_not_sync_the_gemfile_next_lock_when_unexisting
    write_gemfile do |file, _dir|
      File.write(file, 'gem "warning"', mode: 'a')

      run_bundler_command('bundle install', file.path)

      refute File.exist?(gemfile_next(file))
    end
  end

  def test_does_not_sync_the_gemfile_next_lock_when_nothing_changed
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, 'gem "warning"', mode: 'a')

      output = run_bundler_command('bundle install', file.path)
      assert_match("Updating the #{file.path}_next.lock", output)

      output = run_bundler_command('bundle install', file.path)
      refute_match("Updating the #{file.path}_next.lock", output)
    end
  end

  def test_sync_the_gemfile_next_after_installation_of_new_gem
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, 'gem "warning"', mode: 'a')

      run_bundler_command('bundle install', file.path)

      assert Bundler::Definition.build(file.path, "#{file.path}.lock", false).locked_deps['warning']
      assert Bundler::Definition.build(file.path, gemfile_next(file), false).locked_deps['warning']
    end
  end

  def test_sync_the_gemfile_next_after_removal_of_gem
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, 'gem "warning"', mode: 'a')

      run_bundler_command('bundle install', file.path)

      assert Bundler::Definition.build(file.path, "#{file.path}.lock", false).locked_deps['warning']
      assert Bundler::Definition.build(file.path, gemfile_next(file), false).locked_deps['warning']

      File.write(file, file.read.gsub('gem "warning"'))

      run_bundler_command('bundle install', file.path)

      refute Bundler::Definition.build(file.path, "#{file.path}.lock", false).locked_deps['warning']
      refute Bundler::Definition.build(file.path, gemfile_next(file), false).locked_deps['warning']
    end
  end

  def test_sync_the_gemfile_next_after_installation_of_new_gem_with_custom_bootboot_env
    write_gemfile("source 'https://rubygems.org'\n#{plugin}\n") do |file, _dir|
      File.write(file, <<-EOM, mode: 'a')
        Bundler.settings.set_local('bootboot_env_prefix', 'SHOPIFY')

        if ENV['SHOPIFY_NEXT']
          gem 'minitest', '5.11.3'
        end
      EOM

      run_bundler_command('bundle bootboot', file.path)

      run_bundler_command('bundle install', file.path, env: { 'SHOPIFY_NEXT' => '1' })
      output = run_bundler_command(
        'bundle exec ruby -e "require \'minitest\';puts Minitest::VERSION"',
        file.path,
        env: { 'SHOPIFY_NEXT' => '1' }
      )

      assert_equal '5.11.3', output.strip
    end
  end

  def test_sync_the_gemfile_next_after_update_of_gem
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, 'gem "warning", "0.10.1"', mode: 'a')

      run_bundler_command('bundle install', file.path)

      assert_equal(
        "= 0.10.1",
        Bundler::Definition.build(
          file.path, "#{file.path}.lock", false
        ).locked_deps['warning'].requirement.to_s
      )

      assert_equal(
        "= 0.10.1",
        Bundler::Definition.build(
          file.path, gemfile_next(file), false
        ).locked_deps['warning'].requirement.to_s
      )

      File.write(file, file.read.gsub('0.10.1', '0.10.0'))

      run_bundler_command('bundle update warning', file.path)

      assert_equal(
        "= 0.10.0",
        Bundler::Definition.build(
          file.path, "#{file.path}.lock", false
        ).locked_deps['warning'].requirement.to_s
      )

      assert_equal(
        "= 0.10.0",
        Bundler::Definition.build(
          file.path, gemfile_next(file), false
        ).locked_deps['warning'].requirement.to_s
      )
    end
  end

  def test_sync_the_gemfile_next_when_gemfile_contain_if_else_statement
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, <<-EOM, mode: 'a')
        if ENV['DEPENDENCIES_NEXT']
          gem 'warning', '0.10.1'
        else
          gem 'warning', '0.10.0'
        end
      EOM

      run_bundler_command('bundle install', file.path)

      assert_equal(
        "= 0.10.0",
        Bundler::Definition.build(
          file.path, "#{file.path}.lock", false
        ).locked_deps['warning'].requirement.to_s
      )

      assert_equal(
        "= 0.10.1",
        Bundler::Definition.build(
          file.path, gemfile_next(file), false
        ).locked_deps['warning'].requirement.to_s
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
      File.write(file, 'gem "warning"', mode: 'a')

      run_bundler_command('bundle install', file.path)

      assert Bundler::Definition.build(file.path, "#{file.path}.lock", false).locked_deps['warning']
      assert Bundler::Definition.build(file.path, gemfile_next(file), false).locked_deps['warning']
    end
  end

  def test_does_not_sync_the_gemfile_next_lock_when_installing_env_is_set
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, 'gem "warning"', mode: 'a')

      output = run_bundler_command('bundle install', file.path, env: { 'DEPENDENCIES_NEXT' => '1' })
      refute_match("Updating the", output)
    end
  end

  def test_bootboot_command_initialize_the_next_lock_and_update_the_gemfile
    write_gemfile("source 'https://rubygems.org'\n#{plugin}\n") do |file, _dir|
      run_bundler_command('bundle bootboot', file.path)

      assert File.exist?(gemfile_next(file))
      assert_equal File.read(gemfile_next(file)), File.read("#{file.path}.lock")

      File.write(file, <<-EOM, mode: 'a')
        if ENV['DEPENDENCIES_NEXT']
          gem 'minitest', '5.11.3'
        end
      EOM

      run_bundler_command('bundle install', file.path, env: { 'DEPENDENCIES_NEXT' => '1' })
      output = run_bundler_command(
        'bundle exec ruby -e "require \'minitest\';puts Minitest::VERSION"',
        file.path,
        env: { 'DEPENDENCIES_NEXT' => '1' }
      )

      assert_equal '5.11.3', output.strip
    end
  end

  def test_bundle_install_with_different_ruby_updating_gemfile_next_lock_succeeds
    write_gemfile do |file, _dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      File.write(file, <<-EOM, mode: 'a')
        if ENV['DEPENDENCIES_NEXT']
          ruby '9.9.9'
        else
          ruby '#{RUBY_VERSION}'
        end
      EOM

      run_bundler_command('bundle install', file.path)

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
      File.write(file, <<-EOM, mode: 'a')
        if ENV['DEPENDENCIES_NEXT']
          ruby '9.9.9'
        else
          ruby '#{RUBY_VERSION}'
        end
      EOM

      error = assert_raises BundleInstallError do
        run_bundler_command('bundle install', file.path, env: { Bootboot.env_next => '1' })
      end

      assert_match("Your Ruby version is #{RUBY_VERSION}, but your Gemfile specified 9.9.9", error.message)
    end
  end

  # If a developer downloads an app using bootboot (maybe they just joined the
  # team) and they update the Gemfile without first running "bundle install",
  # bootboot should properly sync Gemfile_next.lock
  def test_syncs_the_gemfile_when_first_installed
    write_gemfile do |file, dir|
      FileUtils.cp("#{file.path}.lock", gemfile_next(file))
      # emulate cloning a new app
      FileUtils.rm_rf("#{dir}/.bundle")
      File.write(file, "gem 'warning'", mode: "a")
      run_bundler_command("bundle install", file.path)

      assert Bundler::Definition.build(file.path, "#{file.path}.lock", false).locked_deps['warning']
      assert Bundler::Definition.build(file.path, gemfile_next(file), false).locked_deps['warning']
    end
  end

  private

  def gemfile_next(gemfile)
    "#{gemfile.path}_next.lock"
  end

  def write_gemfile(content = nil)
    dir = Dir.mktmpdir
    file = Tempfile.new('Gemfile', dir).tap do |f|
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

    run_bundler_command('bundle install', file.path)

    yield(file, dir)
  ensure
    FileUtils.remove_dir(dir, true)
  end

  def plugin
    branch = %x(git rev-parse --abbrev-ref HEAD).strip

    "plugin 'bootboot', git: '#{Bundler.root}', branch: '#{branch}'"
  end

  class BundleInstallError < StandardError; end

  def run_bundler_command(command, gemfile_path, env: {})
    output = nil
    Bundler.with_unbundled_env do
      output, status = Open3.capture2e({ 'BUNDLE_GEMFILE' => gemfile_path }.merge(env), command)

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
