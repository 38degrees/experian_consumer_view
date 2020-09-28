# frozen_string_literal: true

module ExperianConsumerView
  module Errors
    # Base helper class for errors caused due to unexpected HTTP responses
    class ApiHttpError < StandardError
      attr_reader :code, :response

      def initialize(code, response)
        super()
        @code = code
        @response = response
      end

      def message
        "HTTP code [#{@code}], response text [#{@response}]"
      end
    end

    # Thrown for HTTP 401 codes. This means there is a problem with some of the supplied credentials. Race conditions
    # may lead to out-of-date or invalid API tokens occasionally. These errors may be auto-retried.
    class ApiBadCredentialsError < ApiHttpError; end

    # Thrown for HTTP 404 codes. These imply the API endpoints may have changed, likely requiring a code change to
    # this code library.
    class ApiEndpointNotFoundError < ApiHttpError; end

    # Thrown for HTTP 417 codes. These imply the API format may have changed, likely requiring a code change to this
    # code library.
    class ApiIncorrectJsonError < ApiHttpError; end

    # Thrown for HTTP 500 codes, and HTTP 503 codes where the text response is "Server error". This means a serious
    # server error has occurred. This can only be resolved on the server side by Experian - inform them if it persists.
    class ApiServerError < ApiHttpError; end

    # Thrown for HTTP 503 codes where the text response is "Internal refresh in progress". This means the server is
    # temporarily down while data is being refreshed, but the request should complete successfully once the refresh
    # operation is complete. These errors may be auto-retried.
    class ApiServerRefreshingError < ApiHttpError; end

    # Thrown for HTTP 505 codes. These imply an error which likely requires a code change to this code library.
    class ApiHttpVersionNotSupportedError < ApiHttpError; end

    # Thrown for unhandled HTTP codes.
    class ApiUnhandledHttpError < ApiHttpError; end

    # Thrown when the API is passed a batch which is too big to be given to the API
    class ApiBatchTooBigError < StandardError; end

    # Thrown when the API returns data successfully, but the size of the data returned does not match the size of the
    # query data provided, meaning there is no way to know for sure which result relates to which query string. Such
    # an error either implies a serious issue with the Experian API, or with this code library (or a change to the API
    # contract).
    class ApiResultSizeMismatchError < StandardError; end
  end
end
