# Copyright (c) 2013 ablagoev
# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: MIT

require "fluent/plugin/output"
require "fluent/plugin/http_client"

module Fluent::Plugin
  class LogIntelligenceOutput < Output
    Fluent::Plugin.register_output('vmware_log_intelligence', self)

    config_param :endpoint_url, :string
    config_param :http_retry_statuses, :string, default: ''
    config_param :read_timeout, :integer, default: 60
    config_param :open_timeout, :integer, default: 60
    # config_param :use_ssl, :bool, :default => false
    config_param :verify_ssl, :bool, :default => true
    config_param :rate_limit_msec, :integer, :default => 0

    config_section :buffer do
      config_set_default :@type, "memory"
      config_set_default :chunk_keys, []
      config_set_default :timekey_use_utc, true
    end

    def initialize
      super
      require 'http'
      require 'uri'
    end

    def validate_uri(uri_string)
      unless uri_string =~ /^#{URI.regexp}$/
        fail Fluent::ConfigError, 'endpoint_url invalid'
      end

      begin
        @uri = URI.parse(uri_string)
      rescue URI::InvalidURIError
        raise Fluent::ConfigError, 'endpoint_url invalid'
      end
    end

    def retrieve_headers(conf)
      headers = {}
      conf.elements.each do |element|
        if element.name == 'headers'
          headers = element.to_hash
        end
      end
      headers
    end

    def configure(conf)
      super
      validate_uri(@endpoint_url)
      
      @statuses = @http_retry_statuses.split(',').map { |status| status.to_i }
      @statuses = [] if @statuses.nil?

      @headers = retrieve_headers(conf)

      @http_client = Fluent::Plugin::HttpClient.new(
        @endpoint_url, @verify_ssl, @headers, 
        @open_timeout, @read_timeout, @log)
    end

    def start
      super
    end

    def shutdown
      super
      begin
        @http_client.close if @http_client
      rescue
      end
    end

    def write(chunk)
      @log.info('write(chunk) called')
      is_rate_limited = (@rate_limit_msec != 0 and not @last_request_time.nil?)
      if is_rate_limited and ((Time.now.to_f - @last_request_time) * 1000.0 < @rate_limit_msec)
        @log.info('Dropped request due to rate limiting')
        return
      end

      data = []
      chunk.each do |time, record|
        data << record
      end

      begin
        @last_request_time = Time.now.to_f

        response = @http_client.post(JSON.dump(data))
        puts(response.to_s)  

        if @statuses.include? response.code.to_i
          # Raise an exception so that fluent will retry based on the configurations.
          fail "Server returned bad status: #{response.code}. #{response.to_s}"
        end

      rescue EOFError, SystemCallError, OpenSSL::SSL::SSLError => e
        @log.warn "http post raises exception: #{e.class}, '#{e.message}'"
      end
    end
  end
end
