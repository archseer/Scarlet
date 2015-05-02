require 'data_model/validators/base'

module Moon
  module DataModel
    module Validators
      class Presence < Base
        # Tests value if it is #present?
        #
        # @param [#present?] value
        # @return [Array[Boolean, String]] result, message
        def test_valid(value)
          return true, nil if value.present?
          return false, 'value is not present'
        end

        register :presence
      end
    end
  end
end
