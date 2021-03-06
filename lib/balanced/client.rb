require 'logger'
require "uri"
require "faraday"
require "faraday_middleware"

module Balanced
  class Client

    DEFAULTS = {
      :scheme => 'http',
      :host => 'localhost',
      :port => 5000,
      :version => '1',
      :logging_level => 'WARN',
    }

    attr :api_key, true
    attr_reader :conn
    attr_accessor :config

    def initialize(api_key, options={})
      @api_key = api_key.nil? ? api_key : api_key.strip
      @config = DEFAULTS.merge! options
      build_conn
    end


    def build_conn
      logger = Logger.new(STDOUT)
      logger.level = Logger.const_get(DEFAULTS[:logging_level].to_s)

      @conn = Faraday.new url do |cxn|
        cxn.request  :json

        cxn.response :logger, logger
        cxn.response :json
        cxn.response :raise_error  # raise exceptions on 40x, 50x responses
        cxn.adapter  Faraday.default_adapter
      end
      @conn.path_prefix = '/'
      @conn.headers['User-Agent'] = "balanced-ruby/#{Balanced::VERSION}"
    end

    def inspect  # :nodoc:
      "<Balanced::Client @api_key=#@api_key, @url=#{url}>"
    end

    def url
      _url = URI::HTTP.build(
        :host => @config[:host],
        :port => @config[:port],
      )
      # wow. yes, this is what you actually have to do.
      _url.scheme = @config[:scheme]
      _url
    end

    # wtf..
    def get *args
      op(:get, *args)
    end

    def post *args
      op(:post, *args)
    end

    def put *args
      op(:put, *args)
    end

    def delete *args
      op(:delete, *args)
    end

    private

    def op (method, *args)
      unless @api_key.nil?
        @conn.basic_auth(@api_key, '')
      end
      @conn.send(method, *args)
    end

  end

end