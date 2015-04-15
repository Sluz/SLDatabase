#  Tapastreet ltd
#  All right reserved
#

require 'jorientdb'
require 'multi_json'
require 'sldatabase/slclientdb'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module SLDatabase
    class SLOrientdb < SLClientdb
        attr_accessor :format

        def initialize option={}
            @dbconfig = {
                :user => option[:"username"],
                :password => option[:"password"],
                :database => option[:"database"],
            }

            @server_config = {
                :host => option[:"host"],
                :port => option[:"port"]
            }

            if (option[:"url"].nil?)
                if (option[:"port"].nil?)
                  @dbconfig[:url] = "remote:#{ option[:"host"] }/#{ option[:"database"] }"
                else
                  @dbconfig[:url] = "remote:#{ option[:"host"] }:#{ option[:"port"] }/#{ option[:"database"] }"
                end
            else
                @dbconfig[:url] = option[:"url"]
            end
#JOrientdb::OPartitionedDatabasePool.new @dbconfig[:url], @dbconfig[:username], @dbconfig[:password], option[:pool]
            @db = JOrientdb::ODatabaseDocumentTx.new @dbconfig[:url]
            self.format = :json_ruby_sym
        end

        # \return true if query is a record_id
        def is_by_id? query
            query.is_a?(String) && (query =~ /\A#\d+:\d+\z/)
        end

        # \return hash of record or nil
        def find_by_id record_id, *option
            raise RecordIdError unless is_by_id?(record_id)
      
            find_by_query("select from #{record_id}").first
        rescue => e
          raise parse_exception e
        end
    
        # \return hash of records or nil
        def find_by_ids record_ids, *option
            raise RecordIdError unless record_ids.is_a?(Array)

            datas = []
            record_ids.each do |current_id|
                datas << find_by_query("select from #{record_id}").first
            end
            datas
        rescue => e
          raise parse_exception e
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
                elsif where.empty?
                    where += "#{key.to_s}=#{ quote(value) }"
                else
                    where += " AND #{key.to_s}=#{ quote(value) }"
                end
            end

            if from.empty?
                unless option.empty?
                    from = option[0]
                else
                    raise TableError
                end
            end
      
            find_by_query("select * from #{from} where #{where}")
        rescue => e
          raise parse_exception e
        end

        # \return a array whith hash of record
        def find_by_query query, *option
            limit = 100
            query.gsub! /(limit|LIMIT)\s+(\d+)/ do 
              limit = $2.to_i
              ''
            end
            
            format_results @db.query(JOrientdb::OSQLSynchQuery.new(query, limit), option)
        rescue => e
            raise parse_exception e
        end

        #\return boolean exception is false or exception if failed and exception is true
        def create hash, *option
            raise HashError unless hash.is_a?(Hash)
            raise HashEmptyError if hash.empty?
            
            document = @db.newInstance()
            hash.each do |key, value|
              document.field key.to_s, value
            end
            format_record document
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
      
            document = @db.newInstance()
            hash.each do |key, value|
              document.field key.to_s, value
            end
            @db.save(document, hashdelete("@class"))
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
            @db.delete(JOrientdb::ORecordId.new(record_id))
        rescue => e
            if (option.empty? || option.last)
                raise parse_exception e
            else
                false
            end
        end

        def connect
            @client = @db.open(@dbconfig[:user], @dbconfig[:password]) unless connected?
        rescue => e 
            raise parse_exception  e
        end

        #\return true if connection is alive
        def connected?
            if @client.nil?
                false
            else
                @client.isClosed()
            end
        end

        def disconnect
            @db.close() unless @db.nil?
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
        
        def format_results datas
            result = []
            for record in datas
                result << format_record(record)
            end
            result
        end
        
        def format_record record
            if format == :ruby
                result = {}
                result["@type"]    = record.field("@type").to_s[0]
                result["@rid"]     = record.getIdentity().to_s
                result["@version"] = record.getVersion()
                result["@class"]   = record.getClassName()
            
                #--- Extract fields
                for key_value in record
                  result[key_value.getKey().to_s] = key_value.getValue().to_ruby_value
                end
                result
            elsif format == :json_ruby
                MultiJson.load(record.toJSON())
            elsif format == :json_ruby_sym
                MultiJson.load(record.toJSON(), :symbolize_keys => true)
            elsif format == :json
                record.toJSON()
            elsif format == :none
                record
            end
        end
    end
end
