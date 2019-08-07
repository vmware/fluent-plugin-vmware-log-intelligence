# Copyright (c) 2013 ablagoev
# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: MIT

$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'fluent-plugin-vmware-log-intelligence'
  s.version     = File.read("VERSION").strip
  s.date        = '2018-08-12'
  s.summary     = "Fluentd buffered output plugin for VMware Log Intelligence"
  s.description = "Send Fluentd buffered logs to VMware Log Intelligence"
  s.authors     = ["Alexander Blagoev", "Chaur Wu"]
  s.email       = 'gwu@vmware.com'
  s.homepage    =
    'http://github.com/vmware/fluent-plugin-vmware-log-intelligence'

  s.files       = [
    "lib/fluent/plugin/out_vmware_log_intelligence.rb",
    "lib/fluent/plugin/http_client.rb",
    "Gemfile",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "fluent-plugin-vmware-log-intelligence.gemspec",
    "test/helper.rb",
    "test/plugin/test_out_vmware_log_intelligence.rb",
    "test/plugin/test_http_client.rb",
  ]

  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.licenses = ["MIT"]

  s.require_paths = ['lib']

  s.add_dependency "fluentd", ">= 0.14.20"
  s.add_dependency "http", ">= 0.9.8"
  s.add_dependency "myslog", "~> 0.0"
  s.add_dependency "fluent-plugin-mysqlslowquery", ">= 0.0.9"
  s.add_development_dependency "rake", ">= 0.9.2"
  s.add_development_dependency "bundler", ">= 1.3.4"
  s.add_development_dependency 'test-unit', '~> 3.1.0'
  s.add_development_dependency 'webmock', '~> 3.4.0'
end