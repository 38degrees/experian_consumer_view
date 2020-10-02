# frozen_string_literal: true

module ExperianConsumerView
  module Transformers
    module Attributes
      # Base mpdule for Attribute Transformers.
      # Mixin to Attribute Transformer classes with +extend ExperianConsumerView::Transformers::Attributes::Base+.
      #
      # Expects the class to provide two constants:
      # - +ATTRIBUTE_NAME+ - the name of the attribute, as returned by the ConsumerView API, which the class can
      #     transform.
      # - +CODE_MAP+ - a hash whose keys are all the String codes which the ConsumerView API may return for the
      #     attribute in question, and whose values are the what the attribute should be mapped to when the matching
      #     code is returned.
      #
      # This module will then provide two class-level methods:
      # - +attribute_name+ - simply returns the value of the +ATTRIBUTE_NAME+ constant.
      # - +transform_attribute+ - transforms the given +value+ based on the +CODE_MAP+, or raises a
      #     +AttributeValueUnrecognisedError+ if the value is not foung in the +CODE_MAP+.
      module Base
        def attribute_name
          self::ATTRIBUTE_NAME
        end

        def transform_attribute(value)
          return self::CODE_MAP[value] if self::CODE_MAP[value]

          raise ExperianConsumerView::Errors::AttributeValueUnrecognisedError
        end
      end
    end
  end
end
