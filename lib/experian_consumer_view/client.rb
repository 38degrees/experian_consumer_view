require 'active_support'
require 'active_support/cache'

module ExperianConsumerView
  class Client
    CACHE_KEY = 'ExperianConsumerView::Client::CachedToken'.freeze

    # @param user_id [String] the username / email used to authorize use of the ConsumerView API
    # @param password [String] the password used to authorize use of the ConsumerView API
    # @param client_id [String] your 5-digit Experian client ID (TODO: might this change per request if accessing multiple types of data?)
    # @param asset_id [String] your 6-character Experian asset ID (TODO: might this change per request if accessing multiple types of data?)
    # @param token_cache [ActiveSupport::Cache] optional cache to store login tokens. If no cache
    #   cache is provided, a default in-memory cache is used, however such a cache is not suitable
    #   for distributed or cloud environments, and will likely result in frequently invalidating
    #   the Experian ConsumerView authorization token.
    def initialize(user_id:, password:, client_id:, asset_id:, token_cache: nil)
      @user_id = user_id
      @password = password
      @client_id = client_id
      @asset_id = asset_id
      @token_cache = token_cache || ActiveSupport::Cache::MemoryStore.new
      @api = ExperianConsumerView::Api.new
    end

    # Looks up 1 or more search items in the ConsumerView API.
    #
    # Note that the demographic / propensity keys returned will only be those which the client & asset have access to.
    # Refer to the Experian ConsumerView API Documentation for exact details of the keys & possible values.
    #
    # @param search_items [Hash] a hash of identifiers to search keys for an individual / household / postcode as
    #   required by the ConsumerView API. Eg.
    #   <tt>{ "PersonA" => { "email" => "person.a@example.com" }, "Postcode1" => { "postcode" => "SW1A 1AA" } }</tt>.
    #   Note that the top-level key is not passed to the ConsumerView API, it is just used for convenience when
    #   returning results.
    # @param auto_retries [Integer] optional number of times the lookup should be retried if a transient / potentially
    #   recoverable error occurs. Defaults to 1.
    #
    # @returns [Hash] a hash of identifiers to the results returned by the ConsumerView API. Eg.
    #   <tt><{ "PersonA" => { "pc_mosaic_uk_6_group":"G", "Match":"P" } , "Postcode1" => { "pc_mosaic_uk_6_group":"G", "Match":"PC" }}</tt>.
    def lookup(search_items:, auto_retries: 1)
      item_identifiers = search_items.keys
      search_terms = search_items.values
      attempts = 0

      begin
        ordered_results = @api.batch_lookup(
          user_id: @user_id,
          token: get_or_refresh_auth_token,
          client_id: @client_id,
          asset_id: @asset_id,
          batched_search_keys: search_terms
        )
      rescue ExperianConsumerView::Errors::ApiBadCredentialsError, ExperianConsumerView::Errors::ApiServerRefreshingError => e
        # Bad Credentials can sometimes be caused by race conditions - eg. one thread / server updating the cached
        # token while another is querying with the old token. Retrying once should avoid the client throwing
        # unnecessary errors to the calling code.
        # Experian docs recommend retrying when a server refresh is in progress, and if that fails, retrying again
        # in approximately 10 minutes.
        if attempts < auto_retries
          attempts += 1
          retry
        else
          raise e
        end
      end

      unless ordered_results.size == item_identifiers.size
        raise ExperianConsumerView::Errors::ApiResultSizeMismatchError
      end

      # Construct a hash of { item_identifier => result_hash }
      Hash[item_identifiers.zip(ordered_results)]
    end

    private

    def get_or_refresh_auth_token
      # ConsumerView auth tokens last for 30 minutes before expiring & becoming invalid.
      # After 29 minutes, the cache entry will expire, and the first process to find the expired entry will refresh it,
      # while allowing other processes to use the existing value for another 10s. This should alleviate race conditions,
      # but will not eliminate them entirely. Note that in a distributed / cloud / multi-server environment, a shared
      # cache MUST be used. An in-memory store would mean multiple instances logging to the ConsumerView API, and each
      # login will change the active token, which other servers will not see, leading to frequent authorisation
      # failures.
      @token_cache.fetch(
        CACHE_KEY, expires_in: 29.minutes, race_condition_ttl: 10.seconds
      ) do
        @api.get_auth_token(user_id: @user_id, password: @password)
      end
    end
  end
end
