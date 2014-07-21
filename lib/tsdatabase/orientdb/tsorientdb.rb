#  Tapastreet ltd 
#  All right reserved 
#

require 'orientdb4r'
require 'tsdatabase/tsclientdb'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module TSDatabase
  class TSOrientdb < TSClientdb
     
    def initialize option={}
      @dbconfig = {
        :user => option["username"],
        :password => option["password"],
        :database => option["database"],
      }
      
      @server_config = {
        :host => option["host"], 
        :port => option["port"],
        :ssl  => option["ssl"]
      }
      
      #if (option["url"].nil?)
      #  if (option["port"].nil?)
      #    @dbconfig[:url] = "remote:#{ option["host"] }/#{ option["database"] }"
      #  else
      #    @dbconfig[:url] = "remote:#{ option["host"] }:#{ option["port"] }/#{ option["database"] }"
      #  end
      #else 
      #  @dbconfig[:url] = option["url"]
      #end
      
      @db = Orientdb4r.client @server_config
    end
    
    # \return true if query is a record_id
    def is_by_id? query
      query.is_a?(String) && (query =~ /\A#\d+:\d+\z/)
    end
    
    # \return hash of records or nil
    def find_by_id record_id, *option
      begin
        connect
        if (option.empty?)
          @db.get_document record_id
        else
          datas = []
          datas <<  @db.get_document(record_id)
          option.each do |current_id|
            datas <<  @db.get_document(current_id)
          end
          datas
        end
      rescue =>e
        nil
      end
    end
    
    # \return a array whith hash of record
    def find_by_hash record_datas, *option
      connect
      where = ""
      from = ""
      record_datas.each do |key, value|
        if key === "@class"
          from = value
        else
          where += key.to_s+"=#{ @db.quote(value) }"
        end
      end
      
      if from.empty?
        unless option.empty?
          from = option[0]
        end
      end
      
      @db.query("select from #{from} where #{where}")
      
    end
    
    # \return a array whith hash of record
    def find_by_query query, *option
      connect
      if (option.empty?)
        @db.query(query)
      else
        @db.query(query, option[0])
      end
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def create hash, exception = true
      begin
        connect
        @db.create_document(hash)
      rescue => e
        if (exception)
          raise parse_exception e
        else
          false
        end
      end
      true
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def update hash, exception = true
      begin
        connect
        hash.extend Orientdb4r::DocumentMetadata
        @db.update_document(hash)
      rescue => e
        if (exception)
          raise parse_exception e
        else
          false
        end
      end
      true
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def remove record_id, exception = true
      unless is_by_id?(record_id); if exception; raise RecordIdError  else false end end
      
      begin
        connect
        @db.delete_document(record_id)
      rescue => e
        if (exception)
          raise parse_exception e
        else
          false
        end
      end
      true
    end
    
    def connect
      unless connected?
        begin
          @db.connect(@dbconfig)
        rescue =>e
          raise parse_exception  e
        end
      end
    end
    
    #\return true if connection is alive
    def connected?
      @db.connected?
    end

    def disconnect
      unless @db.nil?
        @db.disconnect
      end
    end
    
    def parse_exception exception
      except = nil
      
      #Duplicate record
      if exception.message["com.orientechnologies.orient.core.storage.ORecordDuplicatedException"].nil? == false
        except = TSDatabase::RecordDuplicateError.new  e.message
        except.set_backtrace(exception.backtrace)
        
      #IO Database Connection
      elsif exception.message["com.orientechnologies.common.io.OIOException"].nil? == false
        except = TSDatabase::ConnectionError.new exception.message
        except.set_backtrace(exception.backtrace)
        
      #default
      else 
        except = super exception
      end
      
      except
    end
  end
end
