# frozen_string_literal: true

module ExperianConsumerView
  module Transformers
    class ResultTransformer
      def initialize
        @attribute_transformers = {}
      end

      def register_attribute_transformer(transformer)
        @attribute_transformers[transformer.attribute_name] = transformer
      end

      def transform(result_hash:)
        result_hash.each do |k, v|
          result_hash[k[ = @attribute_transformers[k].transform_attribute(v) if @attribute_transformers[k]
        end
      end

      # Helper code to get a default ResultTransformer object
      DEFAULT_ATTRIBUTE_TRANSFORMERS = [
        ExperianConsumerView::AttributeTransformers::MosaicUk6Group,
        ExperianConsumerView::AttributeTransformers::MosaicUk6Type
      ]

      def self.default
        unless @@default_transformer
          @@default_transformer = ResultTransformer.new

          DEFAULT_ATTRIBUTE_TRANSFORMERS.each { |t| @@default_transformer.register_attribute_transformer(t) }
        end

        @@default_transformer
      end
    end
  end
end
