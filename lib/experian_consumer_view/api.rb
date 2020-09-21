require "jsonclient"

module ExperianConsumerView
  class Api
    BASE_URL = 'https://stg.neartime.experian.co.uk'  # Staging
    #BASE_URL = 'https://neartime.experian.co.uk'      # Prod
    LOGIN_PATH = '/overture/login'
    SINGLE_LOOKUP_PATH = '/overture/lookup'
    BATCH_LOOKUP_PATH = '/overture/batch'

    def initialize
      @jsonclient = JSONClient.new
      @jsonclient.receive_timeout = 60 * 5 # 5 mins
    end

    # Logs in to the Experian ConsumerView API, and gets an authorization token.
    #
    # @param user_id [String] the username / email used to authorize use of the ConsumerView API
    # @param password [String] the password used to authorize use of the ConsumerView API
    def get_auth_token(user_id:, password:)
      query_params = { 'userid' => user_id, 'password' => password }
      result = @jsonclient.post(BASE_URL + LOGIN_PATH, query_params)

      # TODO: delete
      puts "#{result.status}"
      puts result.to_s

      # TODO: Throw error on non-200?
      return nil unless result.status == HTTP::Status::OK

      result.body['token']
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
      # TODO: Delete this method if looking up a single item via the batch method isn't any slower - no point supporting both!

      query_params = {
        'ssoId' => user_id,
        'token' => token,
        'clientId' => client_id,
        'assetId' => asset_id
      }
      query_params.merge!(search_keys)

      result = @jsonclient.post(BASE_URL + SINGLE_LOOKUP_PATH, query_params)

      # TODO: Throw error if unauthorised (eg. token expired)
      return nil unless result.status == HTTP::Status::OK

      result.body
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
      # TODO: Throw error if batched_search_keys has > 5000 elements

      query_params = {
        'ssoId' => user_id,
        'token' => token,
        'clientId' => client_id,
        'assetId' => asset_id,
        'batch' => batched_search_keys
      }

      # TODO: delete
      puts "#{query_params}"

      result = @jsonclient.post(BASE_URL + BATCH_LOOKUP_PATH, query_params)

      # TODO: delete
      puts "#{result.status}"
      puts "#{result.body}"

      # TODO: Throw error if unauthorised (eg. token expired)
      return nil unless result.status == HTTP::Status::OK

      JSON.parse(result.body)
    end
  end
end
