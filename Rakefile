#!/usr/bin/env rake

# Copyright (c) 2013 ablagoev
# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: MIT

require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test