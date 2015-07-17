module Moon
  class Repository
    # Query's call their given block when #== is called
    class Query
      def initialize(&func)
        @func = func
      end

      def ==(other)
        @func.call(other)
      end

      def self.includes?(*ary)
        new { |other| other & ary == ary }
      end
    end
  end
end
