#  Tapastreet ltd 
#  All right reserved 
#
# \author Cyril Bourgès <cyril@tapastreet.com>
#

require "tsdatabase"

#
# TODO 
# - Thinking about dependency destroy like for a user model has_many :user_devices, :dependent => :destroy
#
module TSDatabase
  class InvalidError< TSDatabaseError; end
  
  class TSModel
    class << self
      def hash_validates
        @validates ||={}
      end
      
      def hash_links
        @links ||={}
      end

      def database
        @database ||= TSManager.database_default
      end
      
      def database= name
        @database = name 
      end
      
      def create record_datas
        obj = self.new record_datas
        obj.save
      end
      
      def find_by(attrs, *args, &block)
        # Make an array of attribute names
        attrs = attrs.split('_and_')

        # #transpose will zip the two arrays together like so:
        #   [[:a, :b, :c], [1, 2, 3]].transpose
        #   # => [[:a, 1], [:b, 2], [:c, 3]]
        attrs_with_args = [attrs, args].transpose
         
        # Hash[] will take the passed associative array and turn it
        # into a hash like so:
        #   Hash[[[:a, 2], [:b, 4]]] # => { :a => 2, :b => 4 }
        conditions = Hash[attrs_with_args]
         
        r = find_by_hash conditions
        if r.empty?
          nil
        else
          r[0]
        end
      end
      
      def method_missing(method_name, *args, &block)
        if method_name.to_s =~ /^find_by_(.+)$/
          find_by($1, *args, &block)
        else
          super
        end
      end
    end
    
    attr_accessor :datas 
    attr_accessor :errors
    
    def initialize record_datas
      if (record_datas.is_a? Hash)
        self.datas = record_datas
      else
        nil
      end
    end
    
    def self.find(query, *option)
      query_block do |conn|
        array = conn.find_by_query(query, *option)
        array.each_index  do |i|
          array[i] = self.new(array[i])
        end
        array
      end
    end
    
    def self.find_by_hash(hash)
      query_block do |conn|
        array = conn.find_by_hash(hash, "#{self.name.downcase}")
        array.each_index  do |i|
          array[i] = self.new(array[i])
        end
        array
      end
    end
    
    def self.find_by_id(record_id)
      query_block do |conn|
        array = conn.find_by_id(record_id)
        array.each_index  do |i|
          array[i] = self.new(array[i])
        end
        array
      end
    end
    
    def save 
      error = nil
      self.class.hash_validates.each do |key, value|
        e = value.call(key, datas)
        unless e.nil?
          # checking whether e is a boolean
          if !!e == e 
            unless e
              if (error.nil?); error={};end
              error[key] = e
            end
          else
            if (error.nil?); error={};end
            error[key] = e
          end  
        end
      end
      if (error.nil?)
         self.class.query_block do |conn|
           id = conn.parse_id_from datas
           if (id.nil?)
             conn.create( datas.merge( {"@class"=>self.class.name.downcase} ) )
           else
             conn.update( datas.merge( {"@class"=>self.class.name.downcase} ) )
           end
         end
      else
        self.errors = error
        nil
      end
    end
    
    def [] key, *args
      unless args.empty?
        if args.include? :expand
          return expand key
        end
      end
      datas[key]
    end
    
    def []= key, value
      datas[key] = value
    end
    
    def to_hash option=nil
      if option == :expand
        datas
      elsif option == :pointer
        datas
      else
        datas.to_h
      end
    end
    
    def self.query_block database=self.database, &block
      begin
        is_from_thread = true
        if Thread.current[:tsclientdb].nil?
          conn = nil
        else
          conn = Thread.current[:tsclientdb][database]
        end
        if (conn.nil?)
          is_from_thread = false
          conn = TSManager.db.pop(database)
        end
        yield(conn)
      ensure
        unless is_from_thread
          TSManager.db.push(database)
        end
      end
    end
    
    def self.expand key
      info = hash_links[key]
      unless info.nil?
        db = info[:database]
        if (db.nil?)
          db = self.database
        end
        query_block db do |conn|
          if (info[:table].nil?)
            hash_links[key][:expand] = conn.find_by_id(datas[key])
          else
            hash_links[key][:expand] = conn.find_by_id(datas[key], info[:table])
          end
        end
      else
        datas[key]
      end
    end
    
    def self.has_link key, from, option ={}
      
      if from.is_a? String
        rfrom = {:table => from, :database=>self.database }
      elsif from.is_a? Hash
        rfrom = {}
        
        if (from[:table])
          rfrom[:table] = from[:table]
        else
          raise InvalidError, "Wrong, we need :table => \"myTable\" and you give #{from.inspect}"
        end
        
        if (from[:database])
          rfrom[:database] = from[:database]
        else
          rfrom[:database] = self.database
        end
      else
        raise InvalidError, "It's not a String or Hash"
      end
      
      hash_links[key] = option.merge rfrom
    end
    
    def self.validates key, &block
      hash_validates[key] = block
    end
    
    def method_missing(method_name, *args, &block)
      if (method_name.to_s =~ /^(.+)=\z$/)
        datas[$1] = args[0]
      else
        r = datas[method_name.to_s]
        unless r.nil?
          r
        else
          super
        end
      end
    end
  end
end
