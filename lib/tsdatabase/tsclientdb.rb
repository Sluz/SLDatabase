#  Tapastreet ltd 
#  All right reserved 
#

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module TSDatabase
  class TSClientdb
    
    class << self
      class RecordIdError < TSDatabaseError; end
      class QueryError < TSDatabaseError; end
    end 
    
    attr_reader :db
    attr_reader :dbconfig
    
    def initialize option={}
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
    def create hash, exception = true
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def update hash, exception = true
      raise NotImplementedError, 'this should be overridden by concrete client'
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def remove record_id, exception = true
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
  end
end
