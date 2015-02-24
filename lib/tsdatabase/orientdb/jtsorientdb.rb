#  Tapastreet ltd 
#  All right reserved 
#

require 'orientdb'
require 'tsdatabase/orientdb'
require 'tsdatabase/tsclientdb'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module TSDatabase
    class JTSOrientdb < TSClientdb
        attr_accessor :enable_hash_record
        attr_reader :db
        
        def initialize option={}
            @dbconfig = {
                :username => option[:"username"],
                :password => option[:"password"],
                :database => option[:"database"]
            }
      
            if (option["url"].nil?)
                if (option["port"].nil?)
                    @dbconfig[:url] = "remote:#{ option[:"host"] }/#{ option[:"database"] }"
                else
                    @dbconfig[:url] = "remote:#{ option[:"host"] }:#{ option[:"port"] }/#{ option[:"database"] }"
                end
            else 
                @dbconfig[:url] = option["url"]
            end
      
            @mode = option[:"mode"] if option[:"mode"]
            @mode = OrientDB::Type::DOCUMENT if @mode.nil?
        end
    
        # \return true if query is a record_id
        def is_by_id? query
            query.is_a? String && query =~ /\A#\d+:\d+\z/
        end
    
        # \return hash of records or nil
        def find_by_id record_id, *option
            raise RecordIdError unless is_by_id?(record_id)
      
            format_record @db.find_by_rid record_id
        rescue =>e
            nil
        end
    
        def find_by_ids record_ids, *option
            raise RecordIdError unless record_ids.is_a?(Array)
      
            datas = @db.find_by_rids record_ids, *option
            if datas.empty?
                nil
            else
                format_results datas
            end
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
      
            format_results @db.all("select from #{from} where #{where}")
        end
    
        # \return a array whith hash of record
        def find_by_query query, *option
            format_results @db.all(query)
        end
    
        #\return boolean exception is false or exception if failed and exception is true
        def create hash, *option
            raise HashError unless hash.is_a?(Hash)
            raise HashEmptyError if hash.empty?
     
            class_name = hash["@class"]
            if class_name.nil?
                class_name = hash[:class]
                if class_name.nil?
                    if option.empty? == false && option[0].is_a?(String)
                        class_name = option[0]
                    else
                        raise TableError
                    end
                end
            end
      
            format_record( OrientDB::Document.create(@db, class_name, hash) )
        rescue => e
            if (option.empty? || option.last)
                raise parse_exception  e
            else
                false
            end
        end
    
        #\return boolean exception is false or exception if failed and exception is true
        def update hash, *option
            format_record(create hash, *option)
        end
    
        #\return boolean exception is false or exception if failed and exception is true
        def remove record_id, *option
            raise RecordIdError unless is_by_id?(record_id)
      
            format_record(@db.delete(OrientDB::RID.new record_id))
        rescue => e
            if (option.empty? || option.last)
                raise parse_exception e
            else
                false
            end
        end
    
        def connect 
            unless (connected?)
                if @mode == OrientDB::Type::DOCUMENT
                    @db = OrientDB::DocumentDatabase.connect @dbconfig[:url], @dbconfig[:username], @dbconfig[:password]
                elsif @mode == OrientDB::Type::GRAPH
                    raise NotImplementedError, 'Graph is not support yet'
                end
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
    
        def parse_id_from hash
            hash["@rid"]
        end
    
        def format_results datas
            result = []
            for record in datas
                result << format_record(record)
            end
            result
        end
    
        def format_record record
            if enable_hash_record
                result = {}
                if record.kind_of?(Java::ComOrientechnologiesOrientCoreRecordImpl::ODocument)
                    result["@type"]    = "d"
                end
                result["@rid"]     = record.rid
                result["@version"] = record.getVersion()
                result["@class"]   = record.getClassName()
                result.merge! format_field record 
                result
            else
                record
            end
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
                except = RecordDuplicateError.new exception.message
                except.set_backtrace(exception.backtrace) 
      
                #IO Database Connection
            elsif exception.kind_of?(Java::ComOrientechnologiesCommonIo::OIOException)
                except = ConnectionError.new exception.message
                except.set_backtrace(exception.backtrace)
        
                #default
            else
                except = super exception
            end
       
            except
        end
        
        def quote value
            @db.quote value
        end
    end
end
