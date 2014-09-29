#  Tapastreet ltd
#  All right reserved
#

require 'orient_db_client'
require 'tsdatabase/orientdb'
require 'tsdatabase/tsclientdb'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module TSDatabase
    class TSOrientdbBinary < TSClientdb

        def initialize option={}
            
            @database = option["database"]
            @credential = {
                :user => option["username"],
                :password => option["password"]
            }
            @host = option["host"]
              
            @server_config = {}
            @server_config[:port] = option["port"] unless option["port"].nil?
            @server_config[:port] = 2424 if @server_config[:port].nil?
            
            mode= option["mode"] unless option["mode"].nil?
            mode= OrientDB::Type::DOCUMENT if mode.nil?
        end
        
        def mode
            @mode
        end
        
        def mode= mode
           @mode
        end

        # \return true if query is a record_id
        def is_by_id? query
            query.is_a?(OrientDbClient::Rid) || query.is_a?(String) && (query =~ /\A#\d+:\d+\z/)
        end

        # \return hash of record or nil
        def find_by_id record_id, *option
            format_results @db.query("select * from #{format_id_string record_id}")
        rescue =>e
            nil
        end
    
        # \return hash of records or nil
        def find_by_ids record_ids, *option
            raise RecordIdError unless record_ids.is_a?(Array)

            query = "select * from ["
            record_ids.each do |record_id|
              query << " #{format_id_string record_id},"
            end
            query.gsub!(/,\z/, "];")
            
            format_results @db.query(query)
        rescue =>e
            nil
        end

        # \return a array whith hash of record
        def find_by_hash hash, *option
            raise HashError unless hash.is_a?(Hash)
            raise HashEmptyError if hash.empty?
            
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
      
            format_results @db.query("select * from #{from} where #{where}")
        end

        # \return a array whith hash of record
        def find_by_query query, *option
            if (option.empty?)
                format_results @db.query(query)
            else
                raise HashError unless option.first.is_a?(Hash)
                raise HashEmptyError if option.first.empty?
                format_results @db.query(query, option.first)
            end
        end

        #\return boolean exception is false or exception if failed and exception is true
        def create hash, *option
            raise HashError unless hash.is_a?(Hash)
            raise HashEmptyError if hash.empty?
            
            @db.create_record get_cluster_id(hash), hash
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
            
            @db.update_record hash, format_id(hash), format_version(hash)
        rescue => e
            if (option.empty? || option.last)
                raise parse_exception e
            else
                false
            end
        end

        #\return boolean exception is false or exception if failed and exception is true
        def remove record_id, *option
            @db.delete_record format_id(record_id), -1
        rescue => e
            if (option.empty? || option.last)
                raise parse_exception e
            else
                false
            end
        end

        def connect
            unless connected?
                @connect = OrientDbClient.connect @host, @server_config
                @db = @connect.open_database @database, @credential unless @connect.nil?
            end
        rescue =>e
            raise parse_exception  e
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
            @db.close unless @db.nil?
        end
        
        def format_results datas
            result = []
            for record in datas
                result << format_record(record)
            end
            result
        end
    
        def format_record record
            result = record[:document]       
            result["@rid"]     = "##{record[:cluster_id]}:#{record[:cluster_position]}"
            result["@type"]    = record[:record_type].chr
            result["@version"] = record[:record_version]
            result["@class"]   = get_cluster_string record[:cluster_position]
            result
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
        
        def format_id record_or_id
            record_id = record_or_id
            
            unless record_id.is_a? OrientDbClient::Rid
                if record_id.is_a? Hash
                    record_id = record_id[:"@rid"]||record_id["@rid"]
                end
                
                if record_id.is_a? String &&  record_id =~ /\A#\d+:\d+\z/
                    record_id = OrientDbClient::Rid.new record_id
                else
                    raise RecordIdError
                end
            end
            
            record_id
        end
        
        def format_id_string record_or_id
            record_id = record_or_id
            
            if record_id.is_a? Hash
                record_id = record_id[:"@rid"]||record_id["@rid"]
            end
                
            if record_id.is_a? String &&  record_id =~ /\A#\d+:\d+\z/
                record_id
            else
                raise RecordIdError
            end
        end
        
        def format_version record_or_version
            record_version = record_or_version
            
            if record_version.is_a? Hash
                record_version = record_id[:"@version"]||record_id["@version"]
            end
            
            if record_version.is_a? String
                record_version = record_version.to_i
            end
            
            if record_version.is_a? Fixnum
                record_version
            else  
                raise TableError
            end
        end
        
        def get_cluster_id record_or_cluster_id
            cluster_id = record_or_cluster_id
            
            if cluster_id.is_a? Hash
                cluster_id = record_id[:"@class"]||record_id["@class"]
            end
            
            if cluster_id.is_a? String
                tmp = @db.get_cluster cluster_id
                unless (tmp.nil?) 
                    cluster_id = tmp[:id].to_i
                end
            end
            
            if cluster_id.is_a? Numeric
                cluster_id
            else  
                raise TableError
            end
        end
        
        def get_cluster_string record_or_cluster_id
             cluster_name = record_or_cluster_id
            
            if cluster_name.is_a? Hash
                cluster_name = record_id[:"@class"]||record_id["@class"]
            end
            
            if cluster_name.is_a? Numeric
                tmp = @db.get_cluster cluster_name
                unless (tmp.nil?) 
                    cluster_name = tmp[:name]
                end
            end
            puts "cluster_name => #{cluster_name}"
            if cluster_name.is_a? String
                cluster_name
            else  
                raise TableError
            end
        end
    end
end