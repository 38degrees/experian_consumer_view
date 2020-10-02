# frozen_string_literal: true

# For convinience, ensure all attribute transformers are included, ready to be used as defaults
Dir[File.join(File.dirname(__FILE__), 'attributes', '*.rb')].sort.each { |file| require file }

module ExperianConsumerView
  module Transformers
    # Default implementation of a class to transform the raw result returned by the ConsumerView API into a richer
    # format. It does this by registering one or more attribute transformers, and iterating over the key/value pairs in
    # the result hash, applying the attribute transformers to the appropriate values.
    #
    # You may provide your own custom implementations which transform the result hash in any way you wish. The only
    # requirement is implementing the +transform+ method.
    class ResultTransformer
      def initialize
        @attribute_transformers = {}
      end

      # Registers an attribute transformer on this +ResultTransformer+.
      #
      # An attribute transformer must implement:
      # - +attribute_name+ - returns the name of an attribute, as returned by the ConsumerView API, which it can
      #     transform.
      # - +transform_attribute+ - accepts a value for the given attribute as returned by the ConsumerView API, and
      #     transforms it in some way - usually into a richer data format.
      #
      # @param transformer
      def register_attribute_transformer(transformer)
        @attribute_transformers[transformer.attribute_name] = transformer
      end

      # Transforms all values in the given +result_hash+ using the registered attribute transformers. If there is no
      # attribute transformer for a particular key in the +result_hash+ then the associated value will not be
      # transformed.
      #
      # @param result_hash [Hash] the raw result hash from the ConsumerView API for a single item which was looked up -
      #   eg. a single individual, household, or postcode.
      #
      # @returns [Hash] the transformed hash of result data
      def transform(result_hash:)
        result_hash.each do |k, v|
          result_hash[k] = @attribute_transformers[k].transform_attribute(v) if @attribute_transformers[k]
        end
      end

      ################################################
      ### Helper code to get a default Transformer ###
      ################################################
      DEFAULT_ATTRIBUTE_TRANSFORMERS = [
        ExperianConsumerView::Transformers::Attributes::Match,
        ExperianConsumerView::Transformers::Attributes::MosaicUk6Group,
        ExperianConsumerView::Transformers::Attributes::MosaicUk6Type
      ].freeze

      # Class instance variable
      @default_transformer = nil

      def self.default
        unless @default_transformer
          @default_transformer = ResultTransformer.new

          DEFAULT_ATTRIBUTE_TRANSFORMERS.each { |t| @default_transformer.register_attribute_transformer(t) }
        end

        @default_transformer
      end
    end
  end
end
