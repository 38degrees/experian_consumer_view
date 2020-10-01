# frozen_string_literal: true

module ExperianConsumerView
  module Transformers
    module Attributes
      module Base
        def attribute_name
          ATTRIBUTE_NAME
        end

        def transform_attribute(value)
          raise AttributeValueUnrecognisedError unless CODE_MAP[value]

          CODE_MAP[value]
        end
      end
    end
  end
end
