# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: MIT

require 'helper'
require 'yaml'

class LogIntelligenceOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::LogIntelligenceOutput).configure(conf)
  end

  def test_configure
    config = %[
      endpoint_url  http://localhost:9200/li
    ]
  
    instance = create_driver(config).instance
    assert_equal 'http://localhost:9200/li', instance.endpoint_url
    assert_equal '', instance.instance_eval { @http_retry_statuses }
    assert_equal [], instance.instance_eval { @statuses }
    assert_equal 60, instance.instance_eval { @read_timeout }
    assert_equal 60, instance.instance_eval { @open_timeout }
    assert_equal({}, instance.instance_eval { @headers })
  end

  def test_full_configure
    config = %[
      @type http_buffered
      endpoint_url https://local.endpoint:3000/dummy/xyz
      verify_ssl false
      <headers>
        Content-Type application/json
        Authorization Bearer EdaNNN68y
        structure simple
        format syslog
      </headers>
      <buffer>
        chunk_limit_records 3
        flush_interval 12s
        retry_max_times 3
      </buffer>
    ]
  
    instance = create_driver(config).instance
    assert_equal 'https://local.endpoint:3000/dummy/xyz', instance.endpoint_url
    assert_equal '', instance.http_retry_statuses
    assert_equal [], instance.instance_eval { @statuses }
    assert_equal 60, instance.read_timeout
    assert_equal 60, instance.open_timeout
    assert_equal({
      "Authorization"=>"Bearer EdaNNN68y",
      "Content-Type"=>"application/json",
      "structure"=>"simple",
      "format"=>"syslog"}, instance.instance_eval { @headers })
  end

  def test_invalid_endpoint
    assert_raise Fluent::ConfigError do
      create_driver('endpoint_url \\@3')
    end

    assert_raise Fluent::ConfigError do
      create_driver('endpoint_url google.com')
    end
  end

end
