
require 'jorientdb'
require 'sldatabase/sldatabasepool'
require 'sldatabase/orientdb/slorientdb'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module SLDatabase
  class SLOrientdblPool
    include SLDatabasePool
    
    attr_accessor :pool_manager
  
    def save_configuration option = {}
      config = { }
      config[:url]      = option[:url]      unless option[:url].nil?
      config[:mode]     = option[:mode]     unless option[:mode].nil?
      config[:pool]     = option[:pool]     unless option[:pool].nil?
      config[:host]     = option[:host]     unless option[:host].nil?
      config[:port]     = option[:port]     unless option[:port].nil?
      config[:username] = option[:username] unless option[:username].nil?
      config[:password] = option[:password] unless option[:password].nil?
      config[:database] = option[:database] unless option[:database].nil?
      
      if (config[:url].nil?)
        if (config[:port].nil?)
          config[:url] = "remote:#{ config[:host] }/#{ config[:database] }"
        else
          config[:url] = "remote:#{ config[:host] }:#{ config[:port] }/#{ config[:database] }"
        end
      end
      self.configuration = config
      puts configuration.inspect
      self.pool_manager = JOrientdb::OPartitionedDatabasePool.new(configuration[:url],
        configuration[:username],
        configuration[:password],
        configuration[:pool])
    end
    
    def build_connection
      SLOrientdb.new(pool_manager.acquire(), configuration[:mode])
    end
    
    def destroy_connection connection
      connection.disconnect
    end
  end
end