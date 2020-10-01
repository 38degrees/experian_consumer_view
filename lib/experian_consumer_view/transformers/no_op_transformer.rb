# frozen_string_literal: true

module ExperianConsumerView
  module Transformers
    # Trivial implementation of a result transformer for when the calling code just wants the raw results as returned
    # by the API.
    class NoOpTransformer
      def transform(result_hash:)
        result_hash
      end
    end
  end
end
