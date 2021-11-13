require 'nft/client'

class ActiveStorage::Blob
  validates :key, uniqueness: true
end

module ActiveStorage
  class Service::NftService < Service
    attr_accessor :client

    def initialize(api_key:, gateway_endpoint:)
      @client = Nft::Client.new api_key, gateway_endpoint
    end

    # File is uploaded to NFT.storage and a hash
    # is returned which is used to retrieve the file
    # Change the key of the blob to that of the hash
    def upload(key, io, checksum: nil, **)
      instrument :upload, key: key, checksum: checksum do
        cid_key = @client.add io.path
        Blob.find_by_key(key).update! key: cid_key
      end
    end

    def download(key, &block)
      if block_given?
        instrument :streaming_download, key: key do
          @client.download key, &block
        end
      else
        instrument :download, key: key do
          @client.download key
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        @client.cat key, range.begin, range.size
      end
    end

    def url(key, content_type: nil, filename: nil, expires_in: nil, disposition: nil)
      instrument :url, key: key do
        @client.build_file_url key, filename.to_s
      end
    end

    def exists?(key)
      instrument :exist, key: key do
        @client.file_exists?(key)
      end
    end

    def url_for_direct_upload(key, expires_in: nil, content_type: nil, content_length: nil, checksum: nil)
      instrument :url_for_direct_upload, key: key do
        "#{@client.api_endpoint}/api/v0/add"
      end
    end

  end
end
