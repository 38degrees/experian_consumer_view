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
result = client.lookup( search_items: { "Item" => { "postcode" => "SW1A 0AA" } } )
# result will be something like: { "Item" => { "pc_mosaic_uk_6_group" => "A", "Match" => "PC" }

# Lookup a batch of items from the API:
batch_result = client.lookup( search_items: {
  "Item1" => { "postcode" => "SW1A 0AA" },
  "Item2" => { "addressline" => "10 Downing Street", "postcode" => "SW1A 2AA" },
  "Item3" => { "email" => "example@example.com" }
} )
# batch_result will be something like:
# {
#   "Item1" => { "pc_mosaic_uk_6_group" => "A", "Match" => "PC" },
#   "Item2" => { "pc_mosaic_uk_6_group" => "B", "Match" => "H" },
#   "Item3" => { "pc_mosaic_uk_6_group" => "C", "Match" => "P" },
# }
```

### Understanding what to pass to the lookup method

Calls to `lookup` require the `search_items` named parameter - this is a hash of items to lookup in the API.

The keys to this hash are arbitrary names you assign to the items, for example they could be the ID of a postcode or person in your application database. These are simply used to key the results which are returned to you.

The values of this hash are the items to search for. The ConsumerView API allows searching for demographic data at various levels, such as postcode, household, or individual. Each value in the `search_tems` hash must itself be a hash, as you can see in the examples above, and the keys in these hashes must be a valid combination of search keys the ConsumerView API supports. Eg:

- Providing just a `postcode` key would search for data at the postcode level.
- Providing an `addressline` and a `postcode` key would search for data at the household level.
- Providing an `email` key would search for data at the person level.

Refer to the ConsumerView API Developer Guide for all valid combinations of search keys. Note that these may change over time as the ConsumerView API changes.  

### Understanding what is returned from the lookup method

Each successful call to `lookup` will return a hash containing the keys provided in the `search_items` hash input parameter, as well as the results returned by the ConsumerView API for that item.

For example, if you provided the keys "Item1" & "Item2" in the `search_items` hash, then these keys would be the keys in the returned hash.

The values in the returned hash are simply what was returned by the ConsumerView API for that search item, parsed into a ruby hash from the JSON returned by the API.

A successful match will always contain a `Match` key, detailing the level at which the lookup matched:

- `PC` = Postcode
- `H` = Household
- `P` = Person

The other fields in the result hash will depend upon which ConsumerView variables are covered by your license with Experian. You should refer to the ConsumerView API Variables and Propensities Reference Guide for details on all available variables and the values the ConsumerView API will return for each variable.

### Mapping / translating the returned data

The ConsumerView API returns a String code for _most_ variables (although in some cases it returns a percentile or percentage propensity). These String codes are generally not especially meaningful unless interpreted against the ConsumerView API Variables and Propensities Reference Guide.

This gem provides a number of mapping classes to make it easy to translate from the String code into other useful information.

For example, you can use this to translate the "pc_mosaic_uk_6_group" variable from the code "01" which is returned by the API, into the actual Mosaic Code of "A01", and the description of this Mosaic Code, "World-Class Wealth".

TODO: Provide example of doing this.

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
