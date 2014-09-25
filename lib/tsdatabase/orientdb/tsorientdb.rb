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

    # \return hash of record or nil
    def find_by_id record_id, *option
      raise RecordIdError unless is_by_id?(record_id)
      
      connect
      @db.get_document record_id
    rescue =>e
      nil
    end
    
     # \return hash of records or nil
    def find_by_ids record_ids, *option
      raise RecordIdError unless record_ids.is_a?(Array)

      datas = []
      record_ids.each do |current_id|
        datas << @db.get_document(current_id)
      end
      datas
    rescue =>e
      nil
    end

    # \return a array whith hash of record
    def find_by_hash hash, *option
      raise HashError unless hash.is_a?(Hash)
      raise HashEmptyError if hash.empty?
      
      connect
      where = ""
      from = ""
      hash.each do |key, value|
        if key === "@class"
          from = value
        else
          where += key.to_s+"=#{ quote(value) }"
        end
      end

      if from.empty?
        unless option.empty?
          from = option[0]
        else
          raise TableError
        end
      end
      
      @db.query("select * from #{from} where #{where}")
    end

    # \return a array whith hash of record
    def find_by_query query, *option
      connect
      if (option.empty?)
        @db.query(query)
      else
        @db.query(query, option.first)
      end
    end

    #\return boolean exception is false or exception if failed and exception is true
    def create hash, *option
      raise HashError unless hash.is_a?(Hash)
      raise HashEmptyError if hash.empty?
      
      connect
      @db.create_document(hash)
    rescue => e
      if (option.empty? || option.last)
        raise parse_exception e
      else
        false
      end
    end

    #\return boolean exception is false or exception if failed and exception is true
    def update hash, *option
      raise HashError unless hash.is_a?(Hash)
      raise HashEmptyError if hash.empty?
      
      connect
      hash.extend Orientdb4r::DocumentMetadata
      @db.update_document(hash)
    rescue => e
      if (option.empty? || option.last)
        raise parse_exception e
      else
        false
      end
    end

    #\return boolean exception is false or exception if failed and exception is true
    def remove record_id, *option
      raise RecordIdError unless is_by_id?(record_id)

      connect
      @db.delete_document(record_id)
    rescue => e
      if (option.empty? || option.last)
        raise parse_exception e
      else
        false
      end
    end

    def connect
      @db.connect(@dbconfig) unless connected?
    rescue =>e
      raise parse_exception  e
    end

    #\return true if connection is alive
    def connected?
      @db.connected?
    end

    def disconnect
      @db.disconnect unless @db.nil?
    end

    def quote value
      case value
      when Numeric, Symbol
        value.to_s
      when String
        quote_string(value)
      when Array
        "[" + value.map { |x| quote(x) }.join(", ") + "]"
      when Regexp
        quote_regexp(value)
      else
        quote_string value.to_s
      end
    end

    def quote_string string
      if(string[0, 1] == "'" && string[-1, 1] == "'")
        string
      else
        string.gsub!("'", "\'")
        "'#{ string }'"
      end
    end

    def quote_regexp regexp
      "'#{ regexp.source }'"
    end

    def parse_id_from hash
      hash["@rid"]
    end

    def parse_exception exception
      except = nil

      #Duplicate record (Java)
      if exception.message["com.orientechnologies.orient.core.storage.ORecordDuplicatedException"].nil? == false
        except = RecordDuplicateError.new  exception.message
        except.set_backtrace(exception.backtrace)

        #IO Database Connection (Java)
      elsif exception.message["com.orientechnologies.common.io.OIOException"].nil? == false
        except = ConnectionError.new exception.message
        except.set_backtrace(exception.backtrace)

        #IO Database Connection (Ruby)
      elsif exception.message["all nodes failed to communicate with server!"].nil? == false
        except = ConnectionError.new exception.message
        except.set_backtrace(exception.backtrace)

        #default
      else
        except = super exception
      end

      except
    end
  end
end
