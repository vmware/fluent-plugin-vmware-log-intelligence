# Copyright 2023 VMware, Inc.
# SPDX-License-Identifier: MIT

module Fluent::Plugin
  class HttpClient
    def initialize(endpoint_url, verify_ssl, 
      headers, statuses, open_timeout, read_timeout, log)
      @log = log
      @statuses = statuses
      @options = {}

      if !verify_ssl
        @log.warn('SSL verification of the remote VMware Log Intelligence service is turned off. This is serious security risk. Please turn on SSL verification and restart the Fluentd/td-agent process.')
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
        @options = {:ssl_context => ctx}
      end

      timeout_options = {
        :connect_timeout => open_timeout,
        :read_timeout => read_timeout
      }
      @log.debug "VMware Log Intelligence - Timeout Options: connect timeout #{open_timeout}, read timeout #{read_timeout}"
        
      @conn = HTTP.persistent(endpoint_url)
        .headers(headers)
        .timeout(timeout_options)

      @endpoint_path = HTTP::URI.parse(endpoint_url).path
      @last_429_time = nil
    end

    def quota_reached
      @log.debug "VMware Log Intelligence - Checking Rate Limit Quota"
      if @last_429_time
        if (Time.new - @last_429_time) < 600
          return true
        end

        @last_429_time = nil
      end
      return false
    end

    def post(data)
      if quota_reached
        @log.debug "VMware Log Intelligence - Rate limit quota reached"
        return
      end

      begin
        response = @conn.post(@endpoint_path, @options.merge(:body => data))
        response.body.to_s
        if (response.code == 429)
          @log.warn('1GB quota of free account has been reached. Will stop sending data for 1 hour.')
          @last_429_time = Time.new
        else
          @last_429_time = nil
        end
        @log.debug "VMware Log Intelligence - Response code from VMware Log Intelligence: #{response.code}"
        
        if @statuses.include? response.code.to_i
          # Raise an exception so that fluent will retry based on the configurations.
          fail "Server returned bad status: #{response.code}. #{response.to_s}"
        end

      rescue EOFError, SystemCallError, OpenSSL::SSL::SSLError => e
        @log.warn "http post raises exception: #{e.class}, '#{e.message}'"
      end
    end

    def close
      @conn.close
    end
  end
end
