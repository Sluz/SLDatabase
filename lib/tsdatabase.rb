
require "tsdatabase/version"
require "tsdatabase/tsmanager"

#
# \author Cyril Bourgès <cyril@tapastreet.com>
# 
module TSDatabase
  
  class TSDatabaseError < StandardError 
    def initialize message_or_symbol
        if message_or_symbol.is_a? Symbol
            super message_for(message_or_symbol)
        else
            super message_or_symbol
        end
    end
    
    def message_for symbol
        "Undefined #{symbol} error"
    end
    
  end 
  class MissingAdapterError < TSDatabaseError; end
  
  class ConfigurationError < TSDatabaseError
      def message_for symbol
          case symbol
          when :multiple
              "Multiple configuration"
          when :file
              "Incompatible file is not a File or Path"
          when :format
              "Incompatible format require file extention .json or .yml"
          else
              super symbol
          end
      end
  end
  
  # Module function
  class << self 
    def load_configuration filename_or_hash, mode="production"
        #--- Generate hash of server option
        if filename_or_hash.is_a? Hash
            TSDatabase::TSManager.instance.config_hash filename_or_hash, mode
        else
            if filename_or_hash.is_a? String 
                extname = File.extname(filename_or_hash) 
            elsif filename_or_hash.is_a? File 
                extname = File.extname(filename_or_hash.path) 
            end
            
            unless extname.nil?
                if extname === ".json"
                    TSDatabase::TSManager.instance.config_json filename_or_hash, mode
                elsif extname === ".yml"
                    TSDatabase::TSManager.instance.config_yml filename_or_hash, mode
                else
                    raise ConfigurationError.new :format
                end
            else
                raise ConfigurationError.new :file
            end
        end
    end
    
    def instance;    TSManager.instance;    end
    def default;     TSManager.default;     end
    def preloaded;   TSManager.preloaded;   end
    def keep_loaded; TSManager.keep_loaded; end
    alias_method :db, :instance
    alias_method :DEFAULT, :default
    alias_method :PRELOADED, :preloaded
    alias_method :KEEP_LOADED, :keep_loaded 
  end
end
