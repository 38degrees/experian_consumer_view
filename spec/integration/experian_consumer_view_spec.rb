require 'spec_helper'

include ExperianConsumerView::Errors

RSpec.describe 'Experian ConsumerView Scenario Tests', integration: true do
  subject do
    ExperianConsumerView::Client.new(
      user_id: user_id,
      password: password,
      client_id: client_id,
      asset_id: asset_id
    )
  end

  let(:login_url) { 'https://neartime.experian.co.uk/overture/login' }
  let(:lookup_url) { 'https://neartime.experian.co.uk/overture/batch' }

  let(:user_id) { 'UserA' }
  let(:password) { 'TopSecret' }
  let(:client_id) { '12345' }
  let(:asset_id) { 'Asset1' }
  let(:auth_token) { '123-456-789' }

  let(:login_query) do
    { 'userid' => user_id, 'password' => password }.to_json
  end

  let(:login_response) do
    { 'token' => auth_token }.to_json
  end

  let(:search_items) do
    {
      'PersonA' => { 'email' => 'person.a@example.com' },
      'Postcode1' => { 'postcode' => 'SW1A 1AA' }
    }
  end

  let(:lookup_query) do
    {
      'ssoId' => user_id,
      'token' => auth_token,
      'clientId' => client_id,
      'assetId' => asset_id,
      'batch' => lookup_batch
    }.to_json
  end

  let(:lookup_batch) do
    [{ 'email' => 'person.a@example.com' }, { 'postcode' => 'SW1A 1AA' }]
  end

  let(:lookup_response) do
    [
      { 'pc_mosaic_uk_6_group' => 'A', 'Match' => 'P' },
      { 'pc_mosaic_uk_6_group' => 'B', 'Match' => 'PC' }
    ].to_json
  end

  context 'Happy path cases' do
    it 'Can login, get an auth token, and lookup data' do
      expected_result = {
        'PersonA' => { 'pc_mosaic_uk_6_group' => 'A', 'Match' => 'P' },
        'Postcode1' => { 'pc_mosaic_uk_6_group' => 'B', 'Match' => 'PC' }
      }

      login_req = stub_request(:post, login_url).
        with { |request| request.body == login_query && content_type_json?(request) }.
        to_return(status: 200, body: login_response)

      lookup_req = stub_request(:post, lookup_url).
        with { |request| request.body == lookup_query && content_type_json?(request) }.
        to_return(status: 200, body: lookup_response)

      expect(subject.lookup(search_items: search_items)).to eq(expected_result)

      expect(login_req).to have_been_requested.once
      expect(lookup_req).to have_been_requested.once
    end

    it 'Caches the auth token across multiple requests' do
      expected_result = {
        'PersonA' => { 'pc_mosaic_uk_6_group' => 'A', 'Match' => 'P' },
        'Postcode1' => { 'pc_mosaic_uk_6_group' => 'B', 'Match' => 'PC' }
      }

      login_req = stub_request(:post, login_url).
        with { |request| request.body == login_query && content_type_json?(request) }.
        to_return(status: 200, body: login_response)

      lookup_req = stub_request(:post, lookup_url).
        with { |request| request.body == lookup_query && content_type_json?(request) }.
        to_return(status: 200, body: lookup_response).
        times(2)

      expect(subject.lookup(search_items: search_items)).to eq(expected_result)
      expect(subject.lookup(search_items: search_items)).to eq(expected_result)

      expect(login_req).to have_been_requested.once
      expect(lookup_req).to have_been_requested.twice
    end
  end

  context 'Error cases' do
    context 'When lookup returns 401 on the first attempt' do
      it 'Retries the lookup, getting a new token on the retry' do
        expected_result = {
          'PersonA' => { 'pc_mosaic_uk_6_group' => 'A', 'Match' => 'P' },
          'Postcode1' => { 'pc_mosaic_uk_6_group' => 'B', 'Match' => 'PC' }
        }

        login_req = stub_request(:post, login_url).
          with { |request| request.body == login_query && content_type_json?(request) }.
          to_return(status: 200, body: login_response).
          times(2)

        lookup_req = stub_request(:post, lookup_url).
          with { |request| request.body == lookup_query && content_type_json?(request) }.
          to_return(status: 401).then.
          to_return(status: 200, body: lookup_response)

        expect(subject.lookup(search_items: search_items)).to eq(expected_result)

        expect(login_req).to have_been_requested.twice
        expect(lookup_req).to have_been_requested.twice
      end
    end

    context 'When lookup returns 401 on multiple attempts' do
      it 'Retries the lookup only once, getting a new token on the retry, then raises an error' do
        expected_result = {
          'PersonA' => { 'pc_mosaic_uk_6_group' => 'A', 'Match' => 'P' },
          'Postcode1' => { 'pc_mosaic_uk_6_group' => 'B', 'Match' => 'PC' }
        }

        login_req = stub_request(:post, login_url).
          with { |request| request.body == login_query && content_type_json?(request) }.
          to_return(status: 200, body: login_response).
          times(2)

        lookup_req = stub_request(:post, lookup_url).
          with { |request| request.body == lookup_query && content_type_json?(request) }.
          to_return(status: 401).
          times(2)

        expect { subject.lookup(search_items: search_items) }.to raise_error(ApiBadCredentialsError)

        expect(login_req).to have_been_requested.twice
        expect(lookup_req).to have_been_requested.twice
      end
    end
  end

  # HELPERS

  def content_type_json?(request)
    request.headers['Content-Type'] =~ /application\/json/
  end
end
