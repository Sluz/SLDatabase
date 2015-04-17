
require 'sldatabase' unless defined?( SLDatabase )

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module SLDatabase
  
  class RecordIdError < SLDatabaseError; end
  class RecordVersionError < SLDatabaseError; end
  class RecordDuplicateError < SLDatabaseError; 
    attr_accessor :rid
    def initialize message, rid
      super message
      self.rid = rid
    end
  end
  class QueryError < SLDatabaseError; end
  class ConnectionError < SLDatabaseError; end
  
  class TableError < QueryError; end
  class HashError < QueryError; end
  class HashEmptyError < QueryError; end

  class SLConfiguration
    include Singleton
    attr_accessor :configuration
    
    def initialize
      self.configuration = {}
    end
    
    def self.configuration
      self.instance.configuration
    end
    
  end
  
  module SLClientdb
    attr_accessor :db
    attr_accessor :format # => [:ruby, :json_ruby, :json_ruby_sym, :json, :none]
    
    def initialize db, format
      self.db     = db
      self.format = (format || :ruby)
    end
    
    def available_format
      [:ruby, :json_ruby, :json_ruby_sym, :json, :none]
    end
    
    def format= new_format
      unless new_format.is_a?(Symbol) && available_format.include?(new_format)
        raise StandardError.new "format should be #{available_format}"
      end
      @format = new_format
    end
    
    def parse_id_from hash
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    def find query, *option
      if is_by_hash? query
        find_by_hash query, *option
      elsif is_by_id? query
        find_by_id query, *option
      elsif is_by_query? query
        find_by_query query, *option
      else
        find_by_extended query, *option
      end
    end
    
    # \return true if query is a record_id
    def is_by_id? query
      query.is_a? Numeric
    end
    
    # \return hash of record or nil
    def find_by_id record_id, *option
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    # \return array of hash of record or nil
    def find_by_ids record_ids, *option
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    # \return true if query is a Hash
    def is_by_hash? query
      query.is_a? Hash
    end
    
    # \return a array whith hash of record
    def find_by_hash record_datas, *option
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    # \return true if query is a SQL query (doesn't check if the sql is right)
    def is_by_query? query
      query.is_a? String
    end
    
    # \return a array whith hash of record
    def find_by_query query, *option
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    # default find if other doesn't match
    def find_by_extended query, *option
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def create hash, *option
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def update hash, *option
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def remove record_id, *option
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    #\return true if connection is alive
    def connected?
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    def connect
      unless connected?  
        self.db = SLConfiguration.configuration[configuration_key].acquire
      end
    rescue => e 
      raise parse_exception  e
    end
    
    def disconnect
      SLConfiguration.configuration[configuration_key].close() if connected?
    rescue => e 
      raise parse_exception  e
    end
    
    def parse_exception exception
      except = SLDatabaseError.new exception.message
      except.set_backtrace exception.backtrace
      except
    end
  end
end
