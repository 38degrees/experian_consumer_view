# ExperianConsumerView

ExperianConsumerView is a Ruby Gem client for the [Experian](https://www.experian.co.uk/) ConsumerView API. This is a product licensed by Experian, and as such this client is only useful if you have a license key for the ConsumerView API product.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'experian_consumer_view'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install experian_consumer_view

## Usage

### Basic example

```ruby
# Create the client
# Experian will send your user_id, password, client_id, & asset_id when you purchase a license
client = ExperianConsumerView::Client.new(
  user_id: 'YOUR_USER_ID',
  password: 'YOUR_PASSWORD',
  client_id: 'YOUR_CLIENT_ID',
  asset_id: 'YOUR_ASSET_ID'
)

# Lookup a single item from the API:
result = client.lookup(search_items: { "MyPostcode" => { "postcode" => "SW1A 0AA" } })
# result will be something like:
# {
#   "MyPostcode" => {
#     "pc_mosaic_uk_6_group" => { api_code: 'A', group: 'A', description: 'City Prosperity' },
#     "pc_mosaic_uk_6_type" => { api_code: '03', type: 'A03', description: 'Penthouse Chic' },
#     "Match" => { api_code: 'PC', match_level: 'postcode' }
#   }
# }

# Lookup a batch of items from the API:
batch_result = client.lookup(search_items: {
  "Postcode1" => { "postcode" => "SW1A 0AA" },
  "Address2" => { "addressline" => "10 Downing Street", "postcode" => "SW1A 2AA" },
  "Person3" => { "email" => "example@example.com" }
})
# batch_result will be something like:
# {
#   "Postcode1" => {
#     "pc_mosaic_uk_6_group" => { api_code: 'A', group: 'A', description: 'City Prosperity' },
#     "pc_mosaic_uk_6_type" => { api_code: '03', type: 'A03', description: 'Penthouse Chic' },
#     "Match" => { api_code: 'PC', match_level: 'postcode' }
#   },
#   "Address2" => {
#     "pc_mosaic_uk_6_group" => { api_code: 'A', group: 'A', description: 'City Prosperity' },
#     "pc_mosaic_uk_6_type" => { api_code: '02', type: 'A02', description: 'Uptown Elite' },
#     "Match" => { api_code: 'H', match_level: 'household' }
#   },
#   "Person3" => {
#     "pc_mosaic_uk_6_group" => { api_code: 'O', group: 'O', description: 'Rental Hubs' },
#     "pc_mosaic_uk_6_type" => { api_code: '66', type: 'O66', description: 'Student Scene' },
#     "Match" => { api_code: 'P', match_level: 'person' }
#   }
# }
```

### Understanding what to pass to the lookup method

Calls to `lookup` require the `search_items` named parameter - this is a hash of items to lookup in the API. Eg. as per the example above:

```ruby
client.lookup(search_items: {
  "Postcode1" => { "postcode" => "SW1A 0AA" },
  "Address2" => { "addressline" => "10 Downing Street", "postcode" => "SW1A 2AA" },
  "Person3" => { "email" => "example@example.com" }
})
```

The keys are arbitrary names you assign to each search item for reference. For example they could be the ID of a postcode or person in your application database. The example above uses "Postcode1", "Address2", etc.

The values are the items you wish to search for in the API, in order to get demographic data about them. The ConsumerView API allows searching for demographic data at various levels, such as postcode, household, or an individual person. Each value must itself be a hash, as you can see in the examples above. They must contain a valid combination of search keys which the ConsumerView API supports. Eg:

- Providing just a `postcode` would search for data at the postcode level.
- Providing an `addressline` and a `postcode` would search for data at the household level.
- Providing an `email` would search for data at the person level.

There are other valid combinations of search keys - refer to the ConsumerView API Developer Guide. Note, search keys may change over time as the ConsumerView API changes.

### Understanding what is returned from the lookup method

Each successful call to `lookup` will return a hash containing the same keys as were provided in the `search_items` argument, as well as the results returned by the ConsumerView API for each search item.

For example:

```ruby
client.lookup(search_items: {
  "Postcode1" => { "postcode" => "SW1A 0AA" },
  "Address2" => { "addressline" => "10 Downing Street", "postcode" => "SW1A 2AA" },
  "Person3" => { "email" => "example@example.com" }
})

# Outputs something like:
{
  "Postcode1" => {
    "pc_mosaic_uk_6_group" => { api_code: 'A', group: 'A', description: 'City Prosperity' },
    "pc_mosaic_uk_6_type" => { api_code: '03', type: 'A03', description: 'Penthouse Chic' },
    "Match" => { api_code: 'PC', match_level: 'postcode' }
  },
  "Address2" => {
    "pc_mosaic_uk_6_group" => { api_code: 'A', group: 'A', description: 'City Prosperity' },
    "pc_mosaic_uk_6_type" => { api_code: '02', type: 'A02', description: 'Uptown Elite' },
    "Match" => { api_code: 'H', match_level: 'household' }
  },
  "Person3" => {
    "pc_mosaic_uk_6_group" => { api_code: 'O', group: 'O', description: 'Rental Hubs' },
    "pc_mosaic_uk_6_type" => { api_code: '66', type: 'O66', description: 'Student Scene' },
    "Match" => { api_code: 'P', match_level: 'person' }
  }
}
```

In this example, the keys "Postcode1", "Address2" & "Person3" were provided in the `search_items`, so these are also be used as the keys in the result hash.

Each search item has a hash containing all the data returned by the ConsumerView API for that search item. For example, here we can see each search item has the mosaic group (`pc_mosaic_uk_6_group`) & type (`pc_mosaic_uk_6_type`), as well as the match level (`Match`).

If a search item is not successfully looked up in the Experian API, that search item will have an empty hash.

Note, your license with Experian will determine the exact attributes the ConsumerView API will return. Refer to the ConsumerView API Variables and Propensities Reference Guide for details on what is available, and all possible values.

#### Mapping attributes

By default, some attributes are automatically transformed from single values into richer objects.

In the example above, the ConsumerView API returned `pc_mosaic_uk_6_group`, `pc_mosaic_uk_6_type`, and `Match` attributes. For the "Postcode1" search item, the raw values from the API would have been `A`, `03`, and `PC` respectively - these are not very informative.

Instead, they have been automatically transformed into richer hashes containing more meaningful information - eg. we can see from the richer hashes that the mosaic group `A` means "City Prosperity", and the mosaic type `03` means "Penthouse Chic".

See the [`Transformers::Attributes` classes](lib/experian_consumer_view/transformers/attributes) to see exactly which attributes are transformed, and how.

Attributes without transformers will still be returned, but they will just have the raw value from the API.

_You can also apply custom transformations to the data returned by the ConsumerView API, in order to automatically transform the data into a richer or more useable format for consumption by your application. This is described further in the advanced useage section of this documentation._

#### The Match attribute

Note that `Match` is a special attribute which is always returned if the search was successful, and indicates at what level a match was found.

For example, if searching for a household, it may be that demographic data for the specific household could not be found, but demographic data for the postcode was found, in which case the `Match` attribute would be 'PC' (postcode) rather than 'H' (household).

## Advanced Useage

### Providing a token cache

If you are using this code in a multi-server / cloud-based setup, then it is recommended that you override the default in-memory token cache. A distributed cache, eg. Redis, is recommended.

Using the in-memory token cache in such environments may lead to multiple servers logging into the ConsumerView API with the same credentials, invalidating the others' API tokens.

You may override the default by initializing the `Client` with the `token_cache` option. This must be an `ActiveSupport::Cache` object.

For example, in a Rails app, if the default Rails cache has already been configured to use a distributed cache like Redis, you may use:

```ruby
client = ExperianConsumerView::Client.new(
  user_id: 'YOUR_USER_ID',
  password: 'YOUR_PASSWORD',
  client_id: 'YOUR_CLIENT_ID',
  asset_id: 'YOUR_ASSET_ID',
  options: { token_cache: Rails.cache }
)
```

### Using a non-standard API URL

This can be useful if you need to test your code, eg. against Experians Staging server. Override the default URL by initializing the `Client` with the `api_base_url` option:

```ruby
client = ExperianConsumerView::Client.new(
  user_id: 'YOUR_USER_ID',
  password: 'YOUR_PASSWORD',
  client_id: 'YOUR_CLIENT_ID',
  asset_id: 'YOUR_ASSET_ID',
  options: { api_base_url: ExperianConsumerView::Api::STAGING_URL }
)
```

### Mapping / transforming the returned data

By default, this gem maps _some_ of the raw attributes returned by the ConsumerView API into richer objects for ease of use by other applications.

However, you can provide your own transformer by initializing the `Client` with the `result_transformer` option.

#### Turning off result transforming

Transforming will have some performance impact. If you just want the raw data provided by the API, then use the provided `NoOpTransformer`.

```ruby
client = ExperianConsumerView::Client.new(
  user_id: 'YOUR_USER_ID',
  password: 'YOUR_PASSWORD',
  client_id: 'YOUR_CLIENT_ID',
  asset_id: 'YOUR_ASSET_ID',
  options: { result_transformer: ExperianConsumerView::Transformers::NoOpTransformer.new }
)

result = client.lookup(search_items: { "MyPostcode" => { "postcode" => "SW1A 0AA" } })
# result will be something like:
# { "MyPostcode" => { "pc_mosaic_uk_6_group" => "A", "pc_mosaic_uk_6_type" => "03", "Match" => "PC" } }
```

Note that the results will still be parsed from a JSON String into a Ruby Hash, which will be keyed on the search item keys. If you want the _completely_ raw API results, you may use the `ExperianConsumerView::Api` class directly.

#### Using your own attribute transformers

If you simply want to transform more attributes, or transform them in a slightly different manner, you can use the provided `ResultTransformer` as a base, and register as many custom attribute transformers as you wish on it.

Each attribute transformer must provide an `attribute_name` method, and a `transform_attribute` method, and examples can be seen in the [Transformers::Attributes module](lib/experian_consumer_view/transformers/attributes).

New attribute transformers can be easily created by extending `ExperianConsumerView::Transformers::Attributes::Base`, but this is not required as long as the necessary methods are implemented.

An example of using a custom attribute transformer:

```ruby
class CustomAttributeTransformer
  def attribute_name
    "p_head_of_household"     # Transform attributes returned by the API with this name
  end
  def transform_attribute(value)
    case value
    when '0'
      'Not head of household' # The API Code of 0 means 'Not head of household'
    when '1'
      'Head of household'     # The API Code of 1 means 'Head of household'
    else
      'Unclassified'          # Any other API Code means 'Unclassified'
    end
  end
end

my_result_transformer = ExperianConsumerView::Transformers::ResultTransformer.new
my_result_transformer.register_attribute_transformer(CustomAttributeTransformer.new)

client = ExperianConsumerView::Client.new(
  user_id: 'YOUR_USER_ID',
  password: 'YOUR_PASSWORD',
  client_id: 'YOUR_CLIENT_ID',
  asset_id: 'YOUR_ASSET_ID',
  options: { result_transformer: my_result_transformer }
)

result = client.lookup(search_items: { "PersonA" => { "email" => "example@example.com" } })
# result will be something like this (assuming your license gives access to "p_head_of_household"):
# {
#   "PersonA" => {
#     "p_head_of_household" => 'Head of household',
#     "pc_mosaic_uk_6_group" => 'G',
#     "pc_mosaic_uk_6_type" => '28',
#     "Match" => 'P'
#   }
# }
```

#### Using a completely custom result transformer

If you want _complete_ control of how the result hash is transformed, you may implement your own result transformer.

A result transformer has to provide the `transform` method. This must accept a hash which is the parsed JSON for a _single_ search item, and should return the transformed hash for that search item.

A simple example:

```ruby
class CustomResultTranslator
  # Exact attributes will depend on the Experian license, but input will be something like this...
  # { "pc_mosaic_uk_6_group" => "A", "pc_mosaic_uk_6_type" => "02", "Match" => "PC" }
  def transform(result_hash)
    new_hash = {}
    # Discard the Match attribute, then transform keys from Strings into symbols
    result_hash.select { |k| k != 'Match' }.each { |k,v| new_hash[k.to_sym] = v }
    new_hash
  end
end

client = ExperianConsumerView::Client.new(
  user_id: 'YOUR_USER_ID',
  password: 'YOUR_PASSWORD',
  client_id: 'YOUR_CLIENT_ID',
  asset_id: 'YOUR_ASSET_ID',
  options: { result_transformer: CustomResultTranslator.new }
)

result = client.lookup(search_items: { "MyPostcode" => { "postcode" => "SW1A 0AA" } })
# result will be something like:
# { "MyPostcode" => { pc_mosaic_uk_6_group: "A", pc_mosaic_uk_6_type: "03" } }
```

## License

[MIT License](LICENSE.md)

Copyright (c) 2020, 38 Degrees Ltd

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/38degrees/experian_consumer_view. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).


## Code of Conduct

Everyone interacting in the ExperianConsumerView project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
