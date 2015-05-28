module Moon
  module Record
    module ClassMethods
      # Creates a query Enumerator which yields all records which match
      # the given query, the query is a key value pair compared using `==`
      #
      # @param [Hash<Symbol, Object>] query
      # @return [Enumerator]
      def where_with_block(&block)
        Enumerator.new do |yielder|
          repository.query(&block).each do |data|
            yielder.yield model.new(data)
          end
        end
      end
    end
  end
end
