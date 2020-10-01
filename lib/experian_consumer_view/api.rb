# frozen_string_literal: true

require_relative 'errors'

require 'faraday'
require 'json'

module ExperianConsumerView
  # Low-level class for accessing the Experian ConsumerView API. It is not recommended to use this class directly.
  # The +ExperianConsumerView::Client+ class is designed to be directly used by applications.
  #
  # This class provides low-level access to make specific HTTP calls to the ConsumerView API, such as logging in to get
  # an authorisation token, and performing lookups of an individual / household / postcode.
  class Api
    include ExperianConsumerView::Errors

    PRODUCTION_URL = 'https://neartime.experian.co.uk'
    STAGING_URL = 'https://stg.neartime.experian.co.uk'

    LOGIN_PATH = '/overture/login'
    SINGLE_LOOKUP_PATH = '/overture/lookup'
    BATCH_LOOKUP_PATH = '/overture/batch'

    def initialize(url: PRODUCTION_URL)
      @httpclient = Faraday.new(
        url: url,
        headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
      )
    end

    # Logs in to the Experian ConsumerView API, and gets an authorization token.
    #
    # @param user_id [String] the username / email used to authorize use of the ConsumerView API
    # @param password [String] the password used to authorize use of the ConsumerView API
    def get_auth_token(user_id:, password:)
      query_params = { 'userid' => user_id, 'password' => password }

      result = @httpclient.post(LOGIN_PATH, query_params.to_json)
      check_http_result_status(result)

      JSON.parse(result.body)['token']
    end

    # Looks up demographic data for a single individual / household / postcode.
    #
    # Note that the demographic / propensity keys returned will only be those which the given client & asset have access
    # to. Refer to the Experian ConsumerView API Documentation for exact details of the keys & possible values.
    #
    # @param user_id [String] the username / email used to authorize use of the ConsumerView API
    # @param token [String] the time-limited authorization token provided when logging into the API
    # @param client_id [String] your 5-digit Experian client ID
    # @param asset_id [String] your 6-character Experian asset ID
    # @param search_keys [Hash] hash containing the keys required to look up an individual / household / postcode.
    #   Refer to the Experian ConsumerView API Documentation for exact details on the required keys.
    #
    # @return [Hash] a hash containing a key/value pair for each demographic / propensity for the individual / household
    #   / postcode which was successfully looked up. Returns an empty hash if the lookup does not find any matches.
    def single_lookup(user_id:, token:, client_id:, asset_id:, search_keys:)
      # TODO: Delete this if looking up a single item via the batch method isn't any slower - no point supporting both!

      query_params = {
        'ssoId' => user_id,
        'token' => token,
        'clientId' => client_id,
        'assetId' => asset_id
      }
      query_params.merge!(search_keys)

      result = @httpclient.post(SINGLE_LOOKUP_PATH, query_params.to_json)
      check_http_result_status(result)

      JSON.parse(result.body)
    end

    # Looks up demographic data for a batch of individuals / households / postcodes.
    #
    # Note that the demographic / propensity keys returned will only be those which the given client & asset have access
    # to. Refer to the Experian ConsumerView API Documentation for exact details of the keys & possible values.
    #
    # @param user_id [String] the username / email used to authorize use of the ConsumerView API
    # @param token [String] the time-limited authorization token provided when logging into the API
    # @param client_id [String] your 5-digit Experian client ID
    # @param asset_id [String] your 6-character Experian asset ID
    # @param search_keys [Array<Hash>] an array of hashes, each hash containing the keys required to look up an
    #   individual / household / postcode. Refer to the Experian ConsumerView API Documentation for exact details on the
    #   required keys.
    #
    # @return [Array<Hash>] an array of hashes, each hash containing a key/value pair for each demographic / propensity
    #   for the individual / household / postcode which was successfully looked up. Returns an empty hash for any items
    #   in the batch where no matches were found. The order of the results array is the same as the order of the
    #   supplied search array - ie. element 0 of the results array contains the hash of demographic data for the
    #   individual / household / postcode supplied in position 0 of the batch of search keys.
    def batch_lookup(user_id:, token:, client_id:, asset_id:, batched_search_keys:)
      raise ApiBatchTooBigError if batched_search_keys.length > ExperianConsumerView::MAX_LOOKUP_BATCH_SIZE

      query_params = {
        'ssoId' => user_id,
        'token' => token,
        'clientId' => client_id,
        'assetId' => asset_id,
        'batch' => batched_search_keys
      }

      result = @httpclient.post(BATCH_LOOKUP_PATH, query_params.to_json)
      check_http_result_status(result)

      JSON.parse(result.body)
    end

    private

    # Helper to check the result, and throw an appropriate error if something went wrong
    def check_http_result_status(result)
      return if result.status == 200

      # An error occurred - attempt to extract the response string from the body if we can
      response = get_response(result)

      case result.status
      when 401
        raise ApiBadCredentialsError.new(result.status, response)
      when 404
        raise ApiEndpointNotFoundError.new(result.status, response)
      when 417
        raise ApiIncorrectJsonError.new(result.status, response)
      when 500
        raise ApiServerError.new(result.status, response)
      when 503
        raise ApiServerRefreshingError(result.status, response) if response == 'Internal refresh in progress'

        raise ApiServerError.new(result.status, response)
      when 515
        raise ApiHttpVersionNotSupportedError.new(result.status, response)
      else
        raise ApiUnhandledHttpError.new(result.status, response)
      end
    end

    def get_response(result)
      # TODO: Temp debugging for convenience
      # puts result.body.class.to_s
      # puts result.body.to_s

      # TODO: Is this complex handling necessary? Check if all types of error are consistent in the body they return...
      if result.body&.is_a?(Hash)
        result.body['response']
      elsif result.body&.is_a?(String)
        JSON.parse(result.body)['response']
      else
        ''
      end
    rescue JSON::ParserError
      ''
    end
  end
end
