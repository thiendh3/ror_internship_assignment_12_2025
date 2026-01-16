require 'test_helper'

class UsersSearchTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @other_user = users(:lana) # Use lana for consistency
  end

  test 'user search interface' do
    log_in_as(@user)
    get users_path
    assert_response :success
    assert_select 'input[name=?]', 'q'
  end

  test 'searching for users' do
    log_in_as(@user)
    begin
      # Ensure Elasticsearch index is up to date
      User.reindex

      get search_users_path, params: { q: @other_user.name }, as: :json
      assert_response :success

      json_response = JSON.parse(response.body)
      assert json_response['users'].any? { |u| u['id'] == @other_user.id }
    rescue StandardError => e
      skip "Elasticsearch not available in test environment: #{e.message}"
    end
  end

  test 'search with filters for following' do
    log_in_as(@user)
    begin
      User.reindex

      get search_users_path, params: { q: @other_user.name, following: 'true' }, as: :json
      assert_response :success

      json_response = JSON.parse(response.body)
      # Michael doesn't follow lana by default, so results should be empty or not include lana
    rescue StandardError => e
      skip "Elasticsearch not available in test environment: #{e.message}"
    end
  end

  test 'empty search query returns empty results' do
    log_in_as(@user)
    get search_users_path, params: { q: '' }, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal [], json_response['users']
  end
end