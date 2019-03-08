# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: MIT

require 'helper'

class HttpClientTest < Test::Unit::TestCase
  DEFAULT_URL = "https://local.endpoint:3000/dummy/xyz"

  def stub_server_out_of_quota(url=DEFAULT_URL)
    stub_request(:post, url).to_return(:status => [429, "User out of ingestion quota."])
  end

  def test_check_quota
    http_client = create_http_client()
    assert_equal http_client.check_quota, true

    stub_server_out_of_quota
    http_client.post(JSON.dump(sample_record()))
    assert_equal http_client.check_quota, false
  end

  def stub_server_unavailable(url=DEFAULT_URL)
    stub_request(:post, url).to_return(:status => [503, "Service Unavailable"])
  end

  def stub_server_returns_500(url=DEFAULT_URL)
    stub_request(:post, url).to_return(:status => [500, "Internal service error"])
  end

  def stub_server_raise_error(url=DEFAULT_URL)
    stub_request(:post, url).with do |req|
      raise IOError
    end
  end

  def stub_post_logs(url=DEFAULT_URL)
    stub_request(:post, url)
      .with(
        body: "[{\"field1\":26,\"field2\":\"value26\"},{\"field1\":27,\"field2\":\"value27\"},{\"field1\":28,\"field2\":\"value28\"}]",
        headers: {
          'Authorization'=>'Bearer EdaNNN68y',
  	      'Connection'=>'Keep-Alive',
          'Content-Type'=>'application/json',
          'Format'=>'syslog',
          'Structure'=>'simple'
        })
      .to_return(:status => 200, :body => "ok")
  end

  def sample_record()
    [
      {'field1' => 26, 'field2' => 'value26'},
      {'field1' => 27, 'field2' => 'value27'},
      {'field1' => 28, 'field2' => 'value28'}
    ]
  end

  def create_http_client
    Fluent::Plugin::HttpClient.new(
      DEFAULT_URL, true, 
        {
            'Authorization'=>'Bearer EdaNNN68y',
            'Connection'=>'Keep-Alive',
            'Content-Type'=>'application/json',
            'Format'=>'syslog',
            'Host'=>'local.endpoint:3000',
            'Structure'=>'simple'
        }, [500, 510], 60, 60, Logger.new(STDOUT))
  end

  def test_retry_on_response_status_code
    http_client = create_http_client()
    stub_server_returns_500
    assert_raise RuntimeError do
      http_client.post(JSON.dump(sample_record()))
    end
  end

  def test_server_raise_error
    http_client = create_http_client()
    stub_server_raise_error
    assert_raise IOError do
      http_client.post(JSON.dump(sample_record()))
    end
  end

  def test_post_logs
    stub_post_logs
    http_client = create_http_client()
    http_client.post(JSON.dump(sample_record()))

    stub_post_logs
    http_client.post(JSON.dump(sample_record()))
  end
end
