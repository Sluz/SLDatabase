
require "tsdatabase/version"
require "tsdatabase/tsmanager"

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module TSDatabase
  
  class TSDatabaseError < StandardError; end 
  class ConfigurationError < TSDatabaseError; end
  class MissingAdapterError < TSDatabaseError; end
  

  # Module function
  class << self 
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
