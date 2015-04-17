
require 'thread'
require 'pqueue'
require 'sldatabase/sldatabasepool'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module SLDatabase
  class SLProcess
    attr_accessor :process
      
    def initialize *params, &block
      self.process = block
    end
      
    def run 
      process.()
    end
  end

  class SLDatabasePoolManager
    include SLDatabasePool
    
    DEFAULT     = :default     # => :DEFAULT : disconnect client on push 
    PRELOADED   = :preload     # => :PRELOADED : don't disconnect client on push and connect on initialisation \see :config_json or :config_yml
    KEEP_LOADED = :keep_loaded # => :KEEP_LOADED : don't disconnect client on push    
   
    attr_accessor :mode
    attr_accessor :queue
    attr_accessor :configuration
    
    def initialize option = {}
      super option
      self.mode  =  (option[:mode] || DEFAULT).to_sym
      
      self.queue = PQueue.new() do |a,b| 
        a.is_a?(SLProcess) && b.is_a?(SLProcess) == false 
      end
      
      max_pool = (configuration.delete(:pool) || 5)
      block = process_block
      if mode == PRELOADED
        (1..max_pool).each do 
          queue.push block.()
        end
      else
        (1..max_pool).each do 
          queue.push(SLProcess.new &block)
        end
      end
    end

    def build_connection
      connection = self.queue.pop
      if connection.is_a?(SLProcess)
        connection = connection.run
      end
      connection
    end
    
    def destroy_connection connection
      if mode == DEFAULT
        connection.disconnect
      end
      queue.push connection
    end
    
    def process_block
      ->{ raise NotImplementedError, 'def process_block this should be overridden by concrete lambda' }
    end
  end
end