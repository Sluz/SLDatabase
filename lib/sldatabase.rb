
require "sldatabase/version"
require "sldatabase/slmanager"

#
# \author Cyril Bourgès <cyril@tapastreet.com>
# 
# Ruby:
# :postgresql => gem 'pg', platform: :ruby
# :orientdb   => gem 'jorientdb', platform: :ruby
# 
# JRuby:
# :postgresql => gem 'jruby_pg', platform: :jruby  
# :orientdb   => gem 'jorientdb', platform: :jruby
#
module SLDatabase
  class SLDatabaseError < StandardError 
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
  class MissingAdapterError < SLDatabaseError; end
  
  class ConfigurationError < SLDatabaseError
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
  
  class << self 
    def db 
      SLDatabase::SLManager.instance
    end
    
    def load_configuration filename_or_hash, mode=:production
      db.load_configuration filename_or_hash, mode
    end
    
    def open database = db.database_default
      db.pop_connection database
    end 

    def free database = db.database_default
      db.push_connection database
    end 
            
    alias_method :get,  :open
    alias_method :pop,  :open
    alias_method :push,  :free
    alias_method :close, :free
  end
end
