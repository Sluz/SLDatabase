
require 'thread'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module SLDatabase
  module SLDatabasePool
    
    attr_accessor :identity
    attr_accessor :configuration
    
    def initialize option = {}
      self.identity =  (option[:idendity] || option[:database] || self.hash).to_sym
      save_configuration option 
    end
    
    def save_configuration option = {}
      self.configuration = option
    end 

    def acquire 
      connection = Thread.current[identity]
      if connection.nil?
        connection = build_connection
        Thread.current[identity] = connection
      end
      connection
    end

    def close 
      connection = Thread.current[identity]
      unless connection.nil?
        Thread.current[identity] = nil
        destroy_connection connection
      end
    end
    
    def build_connection
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    def destroy_connection connection
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
  end
  
end