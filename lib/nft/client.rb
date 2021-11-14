# frozen_string_literal: true

require 'http'
require 'json'

module Nft
  class Error < StandardError; end
  class NotFoundError < Error; end

  class Client
    attr_reader :api_key, :gateway_endpoint, :http_client

    def initialize(api_key, gateway_endpoint)
      @api_key = api_key
      @gateway_endpoint = gateway_endpoint
      @http_client = HTTP
    end

    # Uploads a file to NFT.storage and returns the IPFS CID
    def add(path)
      res = @http_client.auth("Bearer #{@api_key}").post(
        "https://api.nft.storage/upload", body: File.open(path)
      )

      if res.code >= 200 && res.code <= 299
        JSON.parse(res.body)['value']['cid']
      else
        raise Error, res.body
      end
    end

    def download(hash, &block)
      url = build_file_url(hash)
      res = @http_client.get(url)

      if block_given?
        res.body.each(&block)
      else
        res.body
      end
    end

    def delete(key)
      # haha, no.
    end

    def file_exists?(cid)
      res = @http_client.auth("Bearer #{@api_key}").get(
        "https://api.nft.storage/check/#{cid}"
      )
      if res.code >= 200 && res.code <= 299
        true
      else
        false
      end
    end

    def build_file_url(hash, filename = '')
      query = filename.empty? ? '' : "?filename=#{filename}"
      "#{@gateway_endpoint}/ipfs/#{hash}#{query}"
    end
  end
end
