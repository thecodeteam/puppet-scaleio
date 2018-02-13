require "net/https"
require "rest-client"
require "cgi"
require "json"

require "puppet"

module Puppet
  module ScaleIO
    class Transport
      attr_accessor :host, :port, :user, :password, :scaleio_cookie

      def initialize(opts)
        self.user = opts[:username]
        self.host = opts[:server]
        self.password = opts[:password]
        self.port = opts[:port] || 443
      end

      def cgi_escape(value)
        CGI.escape(value)
      end

      def get_scaleio_cookie
        return @scaleio_cookie unless @scaleio_cookie.nil?

        response = ""
        url = "https://%s:%s@%s:%s/api/login" % [cgi_escape(self.user),
                                                 cgi_escape(self.password),
                                                 self.host,
                                                 self.port]

        begin
          response = RestClient::Request.execute(
              :url => url,
              :method => :get,
              :verify_ssl => false ,
              :payload => '{}',
              :headers => {:content_type => :json,
                           :accept => :json })
        rescue => ex
          Puppet.error "Failed to get cookie from ScaleIO Gateway with error %s" % [ex.message]
        end
        @scaleio_cookie = response.strip.tr('""', '')
      end

      def get_url(end_point)
        return "https://%s:%s@%s:%s/%s" % [self.user, self.get_scaleio_cookie, self.host, self.port, end_point]
      end

      def post_request(url, payload, method)
        response = RestClient::Request.execute(:url => url,
                                               :method => method.to_sym,
                                               :verify_ssl => false,
                                               :payload => payload,
                                               :headers => headers
        )
        JSON.parse(response)
      end

      def headers
        {
            :content_type => :json,
            :accept => :json,
            'Cookie' => self.scaleio_cookie || get_scaleio_cookie
        }
      end
    end
  end
end
