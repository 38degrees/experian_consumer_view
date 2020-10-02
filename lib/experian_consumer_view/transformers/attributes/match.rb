# frozen_string_literal: true

require_relative 'base'

module ExperianConsumerView
  module Transformers
    module Attributes
      # An Attribute Transformer to tranform the ConsumerView 'Match' field
      class Match
        extend Base

        ATTRIBUTE_NAME = 'Match'

        CODE_MAP = {
          'PC' => { api_code: 'PC', match_level: 'postcode' },
          'H' => { api_code: 'H', match_level: 'household' },
          'P' => { api_code: 'P', match_level: 'person' }
        }.freeze
      end
    end
  end
end
