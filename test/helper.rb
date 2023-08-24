# Copyright (c) 2013 ablagoev
# Copyright 2023 VMware, Inc.
# SPDX-License-Identifier: MIT

require 'coveralls'
Coveralls.wear!

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'test-unit'
require 'fluent/test'
require "fluent/test/driver/output"
require "fluent/test/helpers"
Test::Unit::TestCase.include(Fluent::Test::Helpers)
Test::Unit::TestCase.extend(Fluent::Test::Helpers)

require 'fluent/plugin/out_vmware_log_intelligence'
require 'webmock/test_unit'
WebMock.disable_net_connect!
