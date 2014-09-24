
require 'tsdatabase' unless defined?( TSDatabase )

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module TSDatabase
  
  class RecordIdError < TSDatabaseError; end
  class RecordDuplicateError < TSDatabaseError; end
  class QueryError < TSDatabaseError; end
  class ConnectionError < TSDatabaseError; end
  
  class TableError < QueryError; end
  class HashError < QueryError; end
  class HashEmptyError < QueryError; end

  class TSClientdb
    
    attr_reader :db
    attr_reader :dbconfig
    
    def initialize option={}
      raise NotImplementedError, 'this should be overridden by concrete client'
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
    
    def connect
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    #\return true if connection is alive
    def connected?
      raise NotImplementedError, 'this should be overridden by concrete client'
    end

    def disconnect
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    def parse_exception exception
      except = TSDatabaseError.new exception.message
      except.set_backtrace exception.backtrace
      except
    end
  end
end
