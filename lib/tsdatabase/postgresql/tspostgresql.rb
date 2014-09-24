
require 'tsdatabase' unless defined?( TSDatabase )
require 'pg' unless defined?( PG )
require 'tsdatabase/tsclientdb'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module TSDatabase
  class TSPostgresql < TSClientdb
    
    class << self
      class TableError < QueryError; end
    end 
    
    def initialize option={}
      @dbconfig = {}
      
      unless option["host"].nil?
        @dbconfig[:hostaddr] = option["host"]
      end
      
      unless option["port"].nil?
        @dbconfig[:port] = option["port"]
      end
      
      unless option["username"].nil?
        @dbconfig[:user] = option["username"]
      end
      
      unless option["password"].nil?
        @dbconfig[:password] = option["password"]
      end
      
      unless option["database"].nil?
        @dbconfig[:dbname] = option["database"]
      end
      
      # "postgresql://username:password@host:port/database"
      unless (option["url"].nil?)
        url = option["url"].gsub(/\Apostgresql:\/\//, "")
        url.gsub(/[\w:@\.\-]+/) do |config|
          
          config.gsub(/\A[\w:]+@/) do |user_pass|
            user_pass.gsub(/:[\w\-\.]+/) do |pass|
              @dbconfig[:password] = pass
              pass = ""
            end
            
            user_pass.gsub(/[\w\-\.]+/) do |user|
              @dbconfig[:user] = user
              user = ""
            end
            ""
          end
          
          config.gsub(/\A[\w\.]+/) do |host|
            @dbconfig[:hostaddr] = host
            host = ""
          end
          
          config.gsub(/\d+/) do |port|
            @dbconfig[:port] = port
            port = ""
          end
        end
        
        url.gsub(/\w+/) do |match|
          @dbconfig[:dbname] = match
        end
      end
      #[host port options tty dbname user password]
    end
    
    def parse_id_from hash
      hash["id"]
    end
    
    # \return hash of records or nil
    def find_by_id record_id, *option
      if option.empty() ; raise TSPostgresql::TableError, "No table associate"; end
      
      table = option.pop
      if option.length == 1
        find_by_query("select * from #{ table } where id=#{record_id};")
      else
        query = "select * from #{ table } where id=#{record_id}"
        option.each do |id|
          query += "and id=#{id}"
        end
        query +=";"
        find_by_query(query)
      end
    end
    
    # \return a array whith hash of record
    def find_by_hash record_datas, *option
      if option.empty() ; raise TSPostgresql::TableError, "No table associate"; end
      
      table = option.pop
      query = "select * from #{ table } where "
      record_datas.each do |key, value|
        query += "'#{key}'=#{value}"
      end
      query +=";"
      find_by_query(query)
    end
    
    # \return a array whith hash of record
    def find_by_query query, *option
      if (option.nil?)
        @db.exec_params query, option
      else
        @db.exec query
      end
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def create hash, exception = true
      begin
        #TODO
        raise NotImplementedError, 'NotImplementedError To Do'
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
        #TODO
        raise NotImplementedError, 'NotImplementedError To Do'
      rescue => e
        if (exception)
          raise parse_exception e
        else
          false
        end
      end
    end
    
    #\return boolean exception is false or exception if failed and exception is true
    def remove record_id, exception = true
      unless is_by_id?(record_id); if exception; raise RecordIdError  else false end end
      begin
        #TODO
        raise NotImplementedError, 'NotImplementedError To Do'
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
          @db = PG.connect @dbconfig 
        rescue =>e
          raise parse_exception  e
        end
      end
    end
    
    #\return true if connection is alive
    def connected?
      !@db.finished?
    end

    def disconnect
      unless @db.nil?
        @db.close
      end
    end
    
    def parse_exception exception
      except = nil
      
      #Duplicate record
      if false
        except = RecordDuplicateError.new  e.message
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

  end
end
