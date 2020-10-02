# frozen_string_literal: true

require 'spec_helper'

LOGIN_URL = 'https://neartime.experian.co.uk/overture/login'
LOOKUP_URL = 'https://neartime.experian.co.uk/overture/batch'

ERRORS = ExperianConsumerView::Errors

RSpec.describe 'Experian ConsumerView Scenario Tests', integration: true do
  subject do
    ExperianConsumerView::Client.new(
      user_id: user_id,
      password: password,
      client_id: client_id,
      asset_id: asset_id
    )
  end

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
      { 'pc_mosaic_uk_6_type' => '66', 'Match' => 'PC' }
    ].to_json
  end

  let(:expected_result) do
    {
      'PersonA' => {
        'pc_mosaic_uk_6_group' => { api_code: 'A', group: 'A', description: 'City Prosperity' },
        'Match' => { api_code: 'P', match_level: 'person' }
      },
      'Postcode1' => {
        'pc_mosaic_uk_6_type' => { api_code: '66', type: 'O66', description: 'Student Scene' },
        'Match' => { api_code: 'PC', match_level: 'postcode' }
      }
    }
  end

  context 'Happy path cases' do
    context 'when API finds matches for all looked up data' do
      it 'can login, get an auth token, and lookup data' do
        login_req = stub_login_request(request_body: login_query)
                    .to_return(status: 200, body: login_response)

        lookup_req = stub_lookup_request(request_body: lookup_query)
                     .to_return(status: 200, body: lookup_response)

        expect(subject.lookup(search_items: search_items)).to eq(expected_result)

        expect(login_req).to have_been_requested.once
        expect(lookup_req).to have_been_requested.once
      end

      it 'caches the auth token across multiple requests' do
        login_req = stub_login_request(request_body: login_query)
                    .to_return(status: 200, body: login_response)

        lookup_req = stub_lookup_request(request_body: lookup_query)
                     .to_return(status: 200, body: lookup_response).times(2)

        expect(subject.lookup(search_items: search_items)).to eq(expected_result)
        expect(subject.lookup(search_items: search_items)).to eq(expected_result)

        expect(login_req).to have_been_requested.once
        expect(lookup_req).to have_been_requested.twice
      end
    end

    context "when API doesn't match some looked up data" do
      let(:lookup_response) do
        [
          { 'pc_mosaic_uk_6_group' => 'A', 'Match' => 'P' },
          {}
        ].to_json
      end

      let(:expected_result) do
        {
          'PersonA' => {
            'pc_mosaic_uk_6_group' => { api_code: 'A', group: 'A', description: 'City Prosperity' },
            'Match' => { api_code: 'P', match_level: 'person' }
          },
          'Postcode1' => {}
        }
      end

      it 'returns an empty hash for the unmatched data' do
        login_req = stub_login_request(request_body: login_query)
                    .to_return(status: 200, body: login_response)

        lookup_req = stub_lookup_request(request_body: lookup_query)
                     .to_return(status: 200, body: lookup_response)

        expect(subject.lookup(search_items: search_items)).to eq(expected_result)

        expect(login_req).to have_been_requested.once
        expect(lookup_req).to have_been_requested.once
      end
    end

    context "when API doesn't match any looked up data" do
      let(:lookup_response) do
        [{}, {}].to_json
      end

      let(:expected_result) do
        { 'PersonA' => {}, 'Postcode1' => {} }
      end

      it 'returns an empty hash for the unmatched data' do
        login_req = stub_login_request(request_body: login_query)
                    .to_return(status: 200, body: login_response)

        lookup_req = stub_lookup_request(request_body: lookup_query)
                     .to_return(status: 200, body: lookup_response)

        expect(subject.lookup(search_items: search_items)).to eq(expected_result)

        expect(login_req).to have_been_requested.once
        expect(lookup_req).to have_been_requested.once
      end
    end
  end

  context 'Error cases' do
    context 'when lookup returns 401 on the first attempt' do
      it 'retries the lookup, getting a new token on the retry' do
        login_req = stub_login_request(request_body: login_query)
                    .to_return(status: 200, body: login_response).times(2)

        lookup_req = stub_lookup_request(request_body: lookup_query)
                     .to_return(status: 401).then
                     .to_return(status: 200, body: lookup_response)

        expect(subject.lookup(search_items: search_items)).to eq(expected_result)

        expect(login_req).to have_been_requested.twice
        expect(lookup_req).to have_been_requested.twice
      end
    end

    context 'when lookup returns 401 on multiple attempts' do
      it 'retries the lookup only once, getting a new token on the retry, then raises an error' do
        login_req = stub_login_request(request_body: login_query)
                    .to_return(status: 200, body: login_response).times(2)

        lookup_req = stub_lookup_request(request_body: lookup_query)
                     .to_return(status: 401).times(2)

        expect { subject.lookup(search_items: search_items) }.to raise_error(ERRORS::ApiBadCredentialsError)

        expect(login_req).to have_been_requested.twice
        expect(lookup_req).to have_been_requested.twice
      end
    end

    context 'when lookup returns 500' do
      it 'does not retry lookup, and raises an error' do
        login_req = stub_login_request(request_body: login_query)
                    .to_return(status: 200, body: login_response)

        lookup_req = stub_lookup_request(request_body: lookup_query)
                     .to_return(status: 500)

        expect { subject.lookup(search_items: search_items) }.to raise_error(ERRORS::ApiServerError)

        expect(login_req).to have_been_requested.once
        expect(lookup_req).to have_been_requested.once
      end
    end

    context 'when lookup returns an unhandled HTTP code' do
      it 'does not retry lookup, and raises an error' do
        login_req = stub_login_request(request_body: login_query)
                    .to_return(status: 200, body: login_response)

        lookup_req = stub_lookup_request(request_body: lookup_query)
                     .to_return(status: 501)

        expect { subject.lookup(search_items: search_items) }.to raise_error(ERRORS::ApiUnhandledHttpError)

        expect(login_req).to have_been_requested.once
        expect(lookup_req).to have_been_requested.once
      end
    end

    context 'when lookup is passed too many records' do
      let(:search_items) do
        search_items = {}
        5001.times { |i| search_items["item#{i}"] = { 'postcode' => SecureRandom.hex(2) } }
        search_items
      end

      it 'raises an ApiBatchTooBigError' do
        login_req = stub_login_request(request_body: login_query)
                    .to_return(status: 200, body: login_response)

        expect { subject.lookup(search_items: search_items) }.to raise_error(ERRORS::ApiBatchTooBigError)

        expect(login_req).to have_been_requested.once
      end
    end

    context 'when lookup returns the wrong number of records' do
      context 'when lookup returns too few records' do
        let(:lookup_response) do
          [{ 'pc_mosaic_uk_6_group' => 'A', 'Match' => 'P' }].to_json
        end

        it 'raises an ApiResultSizeMismatchError' do
          login_req = stub_login_request(request_body: login_query)
                      .to_return(status: 200, body: login_response)

          lookup_req = stub_lookup_request(request_body: lookup_query)
                       .to_return(status: 200, body: lookup_response)

          expect { subject.lookup(search_items: search_items) }.to raise_error(ERRORS::ApiResultSizeMismatchError)

          expect(login_req).to have_been_requested.once
          expect(lookup_req).to have_been_requested.once
        end
      end

      context 'when lookup returns too many records' do
        let(:lookup_response) do
          [
            { 'pc_mosaic_uk_6_group' => 'A', 'Match' => 'P' },
            { 'pc_mosaic_uk_6_group' => 'B', 'Match' => 'PC' },
            {}
          ].to_json
        end

        it 'raises an ApiResultSizeMismatchError' do
          login_req = stub_login_request(request_body: login_query)
                      .to_return(status: 200, body: login_response)

          lookup_req = stub_lookup_request(request_body: lookup_query)
                       .to_return(status: 200, body: lookup_response)

          expect { subject.lookup(search_items: search_items) }.to raise_error(ERRORS::ApiResultSizeMismatchError)

          expect(login_req).to have_been_requested.once
          expect(lookup_req).to have_been_requested.once
        end
      end
    end
  end

  context 'when using the no-op transformer' do
    subject do
      ExperianConsumerView::Client.new(
        user_id: user_id,
        password: password,
        client_id: client_id,
        asset_id: asset_id,
        options: { result_transformer: ExperianConsumerView::Transformers::NoOpTransformer.new }
      )
    end

    context 'when API finds matches for all looked up data' do
      let(:expected_result) do
        {
          'PersonA' => { 'pc_mosaic_uk_6_group' => 'A', 'Match' => 'P' },
          'Postcode1' => { 'pc_mosaic_uk_6_type' => '66', 'Match' => 'PC' }
        }
      end

      it 'can login, get an auth token, and lookup data' do
        login_req = stub_login_request(request_body: login_query)
                    .to_return(status: 200, body: login_response)

        lookup_req = stub_lookup_request(request_body: lookup_query)
                     .to_return(status: 200, body: lookup_response)

        expect(subject.lookup(search_items: search_items)).to eq(expected_result)

        expect(login_req).to have_been_requested.once
        expect(lookup_req).to have_been_requested.once
      end
    end

    context "when API doesn't match some looked up data" do
      let(:lookup_response) do
        [
          { 'pc_mosaic_uk_6_group' => 'A', 'Match' => 'P' },
          {}
        ].to_json
      end

      let(:expected_result) do
        {
          'PersonA' => { 'pc_mosaic_uk_6_group' => 'A', 'Match' => 'P' },
          'Postcode1' => {}
        }
      end

      it 'returns an empty hash for the unmatched data' do
        login_req = stub_login_request(request_body: login_query)
                    .to_return(status: 200, body: login_response)

        lookup_req = stub_lookup_request(request_body: lookup_query)
                     .to_return(status: 200, body: lookup_response)

        expect(subject.lookup(search_items: search_items)).to eq(expected_result)

        expect(login_req).to have_been_requested.once
        expect(lookup_req).to have_been_requested.once
      end
    end

    context "when API doesn't match any looked up data" do
      let(:lookup_response) do
        [{}, {}].to_json
      end

      let(:expected_result) do
        { 'PersonA' => {}, 'Postcode1' => {} }
      end

      it 'returns an empty hash for the unmatched data' do
        login_req = stub_login_request(request_body: login_query)
                    .to_return(status: 200, body: login_response)

        lookup_req = stub_lookup_request(request_body: lookup_query)
                     .to_return(status: 200, body: lookup_response)

        expect(subject.lookup(search_items: search_items)).to eq(expected_result)

        expect(login_req).to have_been_requested.once
        expect(lookup_req).to have_been_requested.once
      end
    end
  end

  # HELPERS

  def stub_login_request(request_body:)
    stub_request(:post, LOGIN_URL)
      .with { |request| request.body == request_body && content_type_json?(request) }
  end

  def stub_lookup_request(request_body:)
    stub_request(:post, LOOKUP_URL)
      .with { |request| request.body == request_body && content_type_json?(request) }
  end

  def content_type_json?(request)
    request.headers['Content-Type'] =~ %r{application/json}
  end
end
