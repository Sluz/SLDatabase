
require 'pg' unless defined?( PG ) && RUBY_PLATFORM =~ /java/
require 'sldatabase/slclientdb'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module SLDatabase
  class SLPostgresql
    include SLClientdb

    def is_table? *option
      if option.empty? || option.first.is_a?(String) == false
        false
      else
        true
      end
    end
    
    def parse_id_from hash
      hash["id"]
    end
    
    # \return hash of records or nil
    def find_by_id record_id, *option
      raise RecordIdError unless is_by_id?(record_id)
      raise TableError unless is_table?(*option)

      find_by_query("SELECT * FROM #{ option.first } WHERE id=#{record_id};")
    end
    
    def find_by_ids record_ids, *option
      raise RecordIdError unless record_ids.is_a?(Array)
      raise TableError unless is_table?(*option)

      query = "SELECT * FROM #{ option.first } WHERE "
      record_ids.each do |record_id|
        query << "id=#{record_id} OR"
      end
      query.gsub!(/OR\z/, ";")
      
      find_by_query(query)
    end
    
    # \return a array whith hash of record
    def find_by_hash hash, *option
      raise HashError unless hash.is_a?(Hash)
      raise HashEmptyError if hash.empty?
      raise TableError unless is_table?(*option)
      
      query = "SELECT * FROM #{ option.first } WHERE "
      hash.each do |key, value|
        query << " #{key} = #{quote value} AND"
      end
      query.gsub!(/AND\z/, ";")
      
      find_by_query(query)
    end
    
    # \return a array whith hash of record
    def find_by_query query, *option
      if (option.empty?)
        db.exec query
      elsif option[0].is_a?(Array)
        db.exec_params query, *option
      else
        db.exec_params query, *option
      end
    rescue => e
      raise parse_exception e
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def create hash, *option  
      raise HashError unless hash.is_a?(Hash)
      raise HashEmptyError if hash.empty?
      raise TableError unless is_table?(*option)
    
      query = "INSERT INTO #{option.first} "
      keys = "("
      values = " VALUES ("
   
      hash.each do |key, value|
        keys << "#{key.to_s},"
        values << "#{quote value},"
      end
      
      keys.gsub!(/,\z/, ")")
      values.gsub!(/,\z/, ")")
      query += keys+values+";"
      
      find_by_query query
    rescue => e
      if (option.empty? || option.last)
        raise parse_exception e
      else
        false
      end
    end
    
    def update hash, *option
      raise HashError unless hash.is_a?(Hash)
      raise HashEmptyError if hash.empty?
      raise TableError unless is_table?(*option)
      
      query = "UPDATE #{option.first} SET"
      hash.each do |key, value|
        query << " #{key} = #{quote value},"
      end
      query.gsub!(/,\z/, ";")
      
      find_by_query query
    rescue => e
      if (option.empty? || option.last)
        raise parse_exception e
      else
        false
      end
    end
    
    def remove record_id, *option
      raise RecordIdError unless is_by_id?(record_id)
      raise TableError unless is_table?(*option)
      
      find_by_query "DELETE FROM #{option.first} WHERE id = #{ record_id };"
      
    rescue => e
      if (option.empty? || option.last)
        raise parse_exception e
      else
        false
      end
    end
    
    #\return true if connection is alive
    def connected?
      if db.nil?
        false
      else
        !db.finished?
      end
    end
    
    def disconnect
      db.close unless db.nil? || db.finished?
    end
    
    def parse_exception exception
      except = nil
      
      #Duplicate record
      if false
        except = RecordDuplicateError.new exception.message
        except.set_backtrace(exception.backtrace)
        
        #IO Database Connection
      elsif  false
        except = ConnectionError.new exception.message
        except.set_backtrace(exception.backtrace)
        
        #default
      else 
        except = super exception
      end
      
      except
    end
    
    def quote value
      case value
      when Numeric, Symbol
        value.to_s
      when String
        "'#{value}'"
      when Array
        "[" + value.map { |x| quote(x) }.join(", ") + "]"
      when Regexp
        raise NotImplementedError, 'Regexp quote tspostgresql'
      else
        value.to_s
      end
    end

  end
end
