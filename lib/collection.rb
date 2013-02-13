module Scarlet
  # Represents a collection of objects that can be querried.
  class Collection
    include Enumerable

    def initialize
      @collection = []
    end

    # Enumerate trough all items on the list.
    # @yield [Object] Gives the object to the block.
    def each &block
      @collection.each(&block)
    end

    # Gets the queried objects from the collection.
    # @param [Hash] query The parameters we want to match on our objects.
    # @return [Array] An array of matching objects.
    def where query
      query = {name: query} if query.is_a? String
      @collection.select do |object|
        query.each_pair {|attribute, value|
          break false unless object.instance_variable_get("@#{attribute}") == value
        }
      end
    end

    # Gets the first object that matches our where query.
    # @return [Object, nil] The object, or nil if no such object exists.
    def get query
      where(query).first
    end

    # Adds a object to the collection.
    # @param [Object] object The object we want to add to the collection.
    # @return [Object] The object we've just added.
    def add object
      @collection << object
      return object
    end

    # Removes a object from the list.
    # @param [Object] object The object we want to delete.
    # @return [Object] The object we've just deleted.
    def remove object
      @collection.delete object
    end

    # Clear the collection.
    def clear
      @collection.clear
    end

    # Checks if object with such query exists.
    # @param [Hash] query The parameters we want to match on our objects.
    # @return [Boolean] True if any objects match, false if not.
    def exist? query
      !where(query).empty?
    end

    # Returns the collection of objects as an array.
    # @return [Array] An array of objects.
    def to_a
      @collection
    end
  end
end
