# frozen_string_literal: true

ENV["BOOTBOOT_TEST_BUNDLER_VERSION"] ||= Bundler::VERSION
puts "Running tests using Bundler #{ENV["BOOTBOOT_TEST_BUNDLER_VERSION"]}"

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "bootboot"

require "minitest/autorun"
