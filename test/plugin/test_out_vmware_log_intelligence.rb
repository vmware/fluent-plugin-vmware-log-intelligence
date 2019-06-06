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

  def test_json_with_log
    input = {"host" => "192.168.0.1", "log" => "machine reboot"}
    output = [{"host" => "192.168.0.1", "text" => "machine reboot"}]
    verify_write(input, output)
  end

  def test_json_with_msg
    input = {"host" => "192.168.0.1", "msg" => "machine reboot"}
    output = [{"host" => "192.168.0.1", "text" => "machine reboot"}]
    verify_write(input, output)
  end

  def test_nested_json
    input = {"host" => "192.168.0.1", "properties" => {"type" => "windows"}, "msg" => "machine reboot"}
    output = [{"host" => "192.168.0.1", "properties_type" => "windows", "text" => "machine reboot"}]
    verify_write(input, output)
  end

  def test_nested_json_with_log
    input = {"host" => "192.168.0.1", "properties" => {"type" => "windows"}, "message" => "machine reboot"}
    output = [{"host" => "192.168.0.1", "properties_type" => "windows", "text" => "machine reboot"}]
    verify_write(input, output)
  end

  def test_json_with_new_line
    input = {"host" => "192.168.0.1", "log" => "\\n"}
    output = [{}]
    verify_write(input, output)
  end

  def test_json_with_multiple_log_formats
    input = {"host" => "192.168.0.1", "log" => "custom log:1", "message" => "custom message:2", "msg" => "custom msg:3"}
    output = [{"host" => "192.168.0.1", "text" => "custom log:1 custom message:2 custom msg:3"}]
    verify_write(input, output)
  end

  # For any null values, its key and values are not being populated to output.
  def test_json_with_null_value
    input = {"host" => "192.168.0.1", "source" => nil, "log" => "abc"}
    output = [{"host" => "192.168.0.1", "text" => "abc"}]
    verify_write(input, output)
  end

  # like '/', '-', '\', '.', etc. replace with '_'
  def test_json_with_sperators
    input = {"host" => "192.168.0.1", "/properties" => {"type-" => "windows"}, "msg" => "123"}
    output = [{"host" => "192.168.0.1", "_properties_type_" => "windows", "text" => "123"}]
    verify_write(input, output)
  end

  def test_json_with_empty_message
    input = {"host" => "192.168.0.1", "properties" => {"type" => "windows"}, "log" => ""}
    output = [{}]
    verify_write(input, output)
  end

  def verify_write(input, output)
    config = %[
     endpoint_url  http://localhost:9200/li
   ]
    stub = stub_request(:post, "http://localhost:9200/li").with(body: output.to_json).
        to_return(status: 200, body: "", headers: {})

    driver = create_driver(config)
    driver.run(default_tag: 'test') do
      driver.feed(input)
    end
    assert_requested(stub)
  end
end