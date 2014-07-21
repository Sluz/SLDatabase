#  Tapastreet ltd 
#  All right reserved 
#

require 'orientdb'
require 'tsdatabase/tsclientdb'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module TSDatabase
  class JTSOrientdb < TSClientdb
    
    def initialize option={}
      @dbconfig = {
        :username => option["username"],
        :password => option["password"],
        :database => option["database"]
      }
      
      if (option["url"].nil?)
        if (option["port"].nil?)
          @dbconfig[:url] = "remote:#{ option["host"] }/#{ option["database"] }"
        else
          @dbconfig[:url] = "remote:#{ option["host"] }:#{ option["port"] }/#{ option["database"] }"
        end
      else 
        @dbconfig[:url] = option["url"]
      end
    end
    
    # \return true if query is a record_id
    def is_by_id? query
      query.is_a? String && query =~ /\A#\d+:\d+\z/
    end
    
    # \return hash of records or nil
    def find_by_id record_id, *option
      begin
        if (option.empty?)
          format_record @db.find_by_rid record_id
        else
          datas = @db.find_by_rids record_id, *option
          if datas.empty?
            nil
          else
            format_results datas
          end
        end
      rescue =>e
        nil
      end
    end
    
    # \return a array whith hash of record
    def find_by_hash record_datas, *option
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
      
      format_results @db.all("select from #{from} where #{where}")
      
    end
    
    # \return a array whith hash of record
    def find_by_query query, *option
      format_results @db.all(query)
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def create hash, exception = true
      begin
        unless class_name = hash["@class"]
          class_name = hash[:class]
        end
        OrientDB::Document.create @db, class_name, hash
      rescue => e
        if (exception)
          raise parse_exception  e
        else
          false
        end
        
      end
      true
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def update hash, exception = true
      create hash, exception
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def remove record_id, exception = true
      unless is_by_id?(record_id); if exception; raise RecordIdError  else false end end
      begin
        @db.delete(OrientDB::RID.new record_id)
      rescue => e
        if (exception)
          raise parse_exception e
        else
          false
        end
      end
    end
    
    def connect
      unless (connected?)
        begin
          @db = OrientDB::DocumentDatabase.connect @dbconfig[:url], @dbconfig[:username], @dbconfig[:password]
        rescue =>e
          raise parse_exception  e
        end
      end
    end
    
    #\return true if connection is alive
    def connected?
      unless @db.nil?
        !@db.isClosed 
      else
        false
      end
    end

    def disconnect
      unless @db.nil?
        @db.close
      end
    end
    
    def format_results datas
      result = []
      for record in datas
        result << format_record(record)
      end
      result
    end
    
    def format_record record
      result = {}
      if record.kind_of?(Java::ComOrientechnologiesOrientCoreRecordImpl::ODocument)
        result["@type"]    = "d"
      end
      result["@rid"]     = record.rid
      result["@version"] = record.getVersion()
      result["@class"]   = record.getClassName()
      result.merge! format_field record 
      result
    end
    
    def format_field hash
      result = {}
      for key_value in hash
        unless key_value.getValue().nil?
          result[key_value.getKey()] = format_value key_value.getValue()
        end
      end
      result
    end
    
    def format_hash hash
      result = {}
      for key, value in hash
        unless value.nil?
          result[key] = format_value value
        end
      end
      result
    end
    
    def format_recordlist otrackedlist
      result = []
      for obj in otrackedlist
        result << format_value(obj)
      end
      result
    end

    def format_value value
      if value.kind_of?(Java::ComOrientechnologiesOrientCoreDbRecord::OTrackedList) || 
          value.kind_of?(Java::ComOrientechnologiesOrientCoreDbRecord::OTrackedSet)
        format_recordlist value
      elsif value.kind_of?(Java::JavaUtil::AbstractMap)
        format_hash value
      else
        value
      end
    end
    
    def parse_exception exception
      except = nil
      #Duplicate record
      if exception.kind_of?(Java::ComOrientechnologiesOrientCoreStorage::ORecordDuplicatedException)
        except = TSDatabase::RecordDuplicateError.new exception.message
        except.set_backtrace(exception.backtrace) 
      
      #IO Database Connection
      elsif exception.kind_of?(Java::ComOrientechnologiesCommonIo::OIOException)
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
