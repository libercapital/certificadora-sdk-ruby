require 'uri'
require 'rest_client'
require 'multi_json'

module Liber
  class SDK
    attr_reader :base_url

    def initialize(apikey, base_url = nil)
      @apikey = apikey

      @base_url = 'https://api.cert.libercapital.com.br/v1'

      @base_url = base_url unless base_url.nil?
    end

    def base_url=(base_url)
      base_url[-1, base_url.length - 1] if base_url[-1, 1] == '/'

      @base_url = base_url
    end

    def pdf_setup(setup)
      response = send_post(
        '/pdf',
        nil,
        setup
      )

      raise(Liber::SDKException, 'Invalid API response format') if !response.is_a?(Hash)

      raise(Liber::SDKException, 'API response does not contain "document_token"') if response['document_token'].to_s.empty?

      response['document_token']
    end

    def pdf_upload(document_token, original_file_path)
      file = open(original_file_path, 'rb')
      response = send_put(
        "/pdf/#{document_token}/file",
        nil,
        file,
        { 'Content-Type': 'application/pdf' }
      )

      raise(Liber::SDKException, 'Invalid API response format') if !response.is_a?(Hash)
    end

    def pdf_create(setup, original_file_path)
      document_token = pdf_setup(setup)
      pdf_upload(document_token, original_file_path)

      document_token
    end

    def pdf_status(document_token)
      response = send_get('/pdf/' + document_token)

      raise(Liber::SDKException, 'Invalid API response format') if !response.is_a?(Hash)

      response
    end

    def pdf_download(document_token, signed_file_path)
      response = send_get("/pdf/#{document_token}/file")

      raise(Liber::SDKException, 'Invalid API response') if response.empty?

      open(signed_file_path, 'w:ASCII-8BIT') do |file|
        file.puts(response)
      end
    end

    private

    def send_get(uri, query = nil, headers = nil)
      uri = '/' + uri if uri[0, 1] != '/'

      send_request(
        'GET',
        uri,
        query,
        nil,
        headers
      )
    end

    def send_post(uri, query = nil, body = nil, headers = nil)
      send_request(
        'POST',
        uri,
        query,
        body,
        headers
      )
    end

    def send_put(uri, query = nil, body = nil, headers = nil)
      send_request(
        'PUT',
        uri,
        query,
        body,
        headers
      )
    end

    def send_request(method, uri, query, body, headers)
      default_headers = {
        'Content-Type': 'application/json; charset=utf-8',
        Authorization: "Bearer #{@apikey}"
      }

      body = MultiJson.dump(body) if !body.nil? && body.is_a?(Hash)

      default_headers.merge!(headers) if !headers.nil? && headers.is_a?(Object)

      begin
        response = RestClient::Request.execute(
          method: method,
          url: @base_url + uri,
          payload: body,
          open_timeout: 30,
          timeout: 90,
          headers: default_headers
        )
      rescue RestClient::Exception => exception
        raise(Liber::SDKError, exception.message)
      end

      if response.headers.key?(:content_type)
        content_type = response.headers[:content_type]

        if content_type[%r{^application\/json}]
          begin
            json = MultiJson.load(response.body)
          rescue MultiJson::DecodeError
            raise(Liber::SDKException, 'Invalid API response format')
          end

          if json['status'].to_s.empty? || json['status'].to_s == 'false'
            raise(Liber::SDKException, json['reason']) if !json['reason'].to_s.empty?

            raise(Liber::SDKException, json['message']) if !json['message'].to_s.empty?

            raise(Liber::SDKException, 'Unknown SDK exception') if json['exception'].to_s.empty?

            raise(Liber::SDKException, json['exception'])
          end

          return json
        end
      end

      response.body
    end
  end
end
