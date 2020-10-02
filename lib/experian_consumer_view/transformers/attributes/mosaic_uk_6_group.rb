# frozen_string_literal: true

# Generated by grabbing all values from the table in the Experian docs, and running this search/replace:
# ([A-Z0-9]+) ([A-Z0-9]+) (.*)$
# '$1' => { api_code: '$1', group: '$2', description: '$3' },

require_relative 'base'

module ExperianConsumerView
  module Transformers
    module Attributes
      # An Attribute Transformer to tranform the ConsumerView 'pc_mosaic_uk_6_group' field
      class MosaicUk6Group
        extend Base

        ATTRIBUTE_NAME = 'pc_mosaic_uk_6_group'

        CODE_MAP = {
          'A' => { api_code: 'A', group: 'A', description: 'City Prosperity' },
          'B' => { api_code: 'B', group: 'B', description: 'Prestige Positions' },
          'C' => { api_code: 'C', group: 'C', description: 'Country Living' },
          'D' => { api_code: 'D', group: 'D', description: 'Rural Reality' },
          'E' => { api_code: 'E', group: 'E', description: 'Senior Security' },
          'F' => { api_code: 'F', group: 'F', description: 'Suburban Stability' },
          'G' => { api_code: 'G', group: 'G', description: 'Domestic Success' },
          'H' => { api_code: 'H', group: 'H', description: 'Aspiring Homemakers' },
          'I' => { api_code: 'I', group: 'I', description: 'Family Basics' },
          'J' => { api_code: 'J', group: 'J', description: 'Transient Renters' },
          'K' => { api_code: 'K', group: 'K', description: 'Municipal Tenants' },
          'L' => { api_code: 'L', group: 'L', description: 'Vintage Value' },
          'M' => { api_code: 'M', group: 'M', description: 'Modest Traditions' },
          'N' => { api_code: 'N', group: 'N', description: 'Urban Cohesion' },
          'O' => { api_code: 'O', group: 'O', description: 'Rental Hubs' },
          'U' => { api_code: 'U', group: 'U', description: 'Unclassified' }
        }.freeze
      end
    end
  end
end
