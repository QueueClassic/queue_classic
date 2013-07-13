require 'uri'

module QC
  module Conf

    def self.env(k); ENV[k]; end
    def self.env!(k); env(k) || raise("Must set #{k}."); end

    def self.debug?
      !env('DEBUG').nil?
    end

    def self.db_url
      url = env("QC_DATABASE_URL") ||
            env("DATABASE_URL")    ||
            raise(ArgumentError, "Must set QC_DATABASE_URL or DATABASE_URL.")
      URI.parse(url)
    end

    def self.normalized_db_url(url=nil)
      url ||= db_url
      host = url.host
      host = host.gsub(/%2F/i, '/') if host
      [host, # host or percent-encoded socket path
       url.port || 5432,
       nil, '', #opts, tty
       url.path.gsub("/",""), # database name
       url.user,
       url.password]
    end

  end
end
