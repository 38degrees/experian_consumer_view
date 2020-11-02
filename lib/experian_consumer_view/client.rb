# frozen_string_literal: true

require_relative 'errors'
require_relative 'transformers/result_transformer'

require 'active_support'
require 'active_support/cache'

module ExperianConsumerView
  # Top-level wrapper for accessing the ExperianConsumerView API. Once an instance is created with the appropriate
  # credentials, the +lookup+ method provides the ability to lookup individuals, households, or postcodes in the
  # ConsumerView API and return all the data your account has access to.
  #
  # This class automatically handles logging in to the ConsumerView API, obtaining an authorisation token (which is
  # valid for approximately 30 minutes), and then looking up the data. The authorisation token is cached so that it's
  # not necessary to login again for every single lookup request.
  #
  # Note that by default the authorisation is cached in-memory using +ActiveSupport::Cache::MemoryStore+. This is
  # suitable for single-server applications, but is unlikely to be suitable for distributed applications, or those
  # hosted on cloud infrastructure. A distributed cache, such as +ActiveSupport::Cache::RedisCacheStore+ or
  # +ActiveSupport::Cache::MemCacheStore+ is recommended for distributed or cloud-hosted applications.
  #
  # If an in-memory data-store were used in distributed or cloud-hosted applications, then the multiple servers will be
  # unaware of each others tokens, and therefore each server would login to the ConsumerView API independently, even if
  # another server already had a valid token. Logging in to the ConsumerView API multiple times with the same
  # credentials will revoke prior tokens, meaning other servers will find their cached tokens are invalid the next time
  # they try a lookup. This will likely lead to a situation where many lookup attempts fail the first time due to the
  # server in question not having the most up-to-date token.
  class Client
    include ExperianConsumerView::Errors

    CACHE_KEY = 'ExperianConsumerView::Client::CachedToken'

    attr_writer :result_transformer

    # @param user_id [String] the username / email used to authorize use of the ConsumerView API
    # @param password [String] the password used to authorize use of the ConsumerView API
    # @param client_id [String] your 5-digit Experian client ID
    # @param asset_id [String] your 6-character Experian asset ID
    # @param options [Hash] a hash of advanced options for configuring the client
    #
    # @option options [ActiveSupport::Cache] :token_cache optional cache to store login tokens. If no cache is provided,
    #   a default in-memory cache is used, however such a cache is not suitable for distributed or cloud environments,
    #   and will likely result in frequently invalidating the Experian ConsumerView authorization token.
    # @option options [#transform] :result_transformer optional object whose +transform+ method accepts a hash
    #   containing the results returned by the ConsumerView API for a single individual, household or postcode, and
    #   transforms this hash into the desired output. By default, an instance of +ResultTransformer+ is used, which will
    #   transform some common attributes returned by the ConsumerView API into hashes with richer details than returned
    #   by the raw API.
    # @option options [String] :api_base_url optional base URL to make ConsumerView API calls against. By default, uses
    #   the Experian production ConsumerView server.
    def initialize(user_id:, password:, client_id:, asset_id:, options: {})
      @user_id = user_id
      @password = password
      @client_id = client_id
      @asset_id = asset_id

      @token_cache = options[:token_cache] || default_token_cache
      @result_transformer = options[:result_transformer] || default_result_transformer
      @api = ExperianConsumerView::Api.new(url: options[:api_base_url])
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
    #   <tt>
    #   {
    #      "PersonA" => { "pc_mosaic_uk_7_group":"G", "Match":"P" } ,
    #      "Postcode1" => { "pc_mosaic_uk_7_group":"G", "Match":"PC" }
    #   }
    #   </tt>
    def lookup(search_items:, auto_retries: 1)
      ordered_identifiers = search_items.keys
      ordered_terms = search_items.values

      token = auth_token
      attempts = 0
      begin
        ordered_results = @api.batch_lookup(
          user_id: @user_id,
          token: token,
          client_id: @client_id,
          asset_id: @asset_id,
          batched_search_keys: ordered_terms
        )
      rescue ApiBadCredentialsError, ApiServerRefreshingError => e
        # Bad Credentials can sometimes be caused by race conditions - eg. one thread / server updating the cached
        # token while another is querying with the old token. Retrying once should avoid the client throwing
        # unnecessary errors to the calling code.
        # Experian docs also recommend retrying when a server refresh is in progress, and if that fails, retrying again
        # in approximately 10 minutes.
        raise e unless attempts < auto_retries

        token = auth_token(force_lookup: true)
        attempts += 1
        retry
      end

      results_hash(identifiers: ordered_identifiers, results: ordered_results)
    end

    private

    def auth_token(force_lookup: false)
      # ConsumerView auth tokens last for 30 minutes before expiring & becoming invalid.
      # After 29 minutes, the cache entry will expire, and the first process to find the expired entry will refresh it,
      # while allowing other processes to use the existing value for another 10s. This should alleviate race conditions,
      # but will not eliminate them entirely. Note that in a distributed / cloud / multi-server environment, a shared
      # cache MUST be used. An in-memory store would mean multiple instances logging to the ConsumerView API, and each
      # login will change the active token, which other servers will not see, leading to frequent authorisation
      # failures.
      @token_cache.fetch(
        CACHE_KEY, expires_in: 29.minutes, race_condition_ttl: 10.seconds, force: force_lookup
      ) do
        @api.get_auth_token(user_id: @user_id, password: @password)
      end
    end

    def results_hash(identifiers:, results:)
      raise ApiResultSizeMismatchError unless results.size == identifiers.size

      # Construct a hash of { identifier => result_hash }
      # Hash[identifiers.zip(results)]

      results_hash = {}
      results.each_with_index do |single_result, i|
        results_hash[identifiers[i]] = @result_transformer.transform(single_result)
      end

      results_hash
    end

    def default_token_cache
      ActiveSupport::Cache::MemoryStore.new
    end

    def default_result_transformer
      ExperianConsumerView::Transformers::ResultTransformer.default
    end
  end
end
