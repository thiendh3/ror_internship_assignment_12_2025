require 'test_helper'

class UsersSearchTest < ActionDispatch::IntegrationTest
  test 'should return empty array for blank autocomplete query' do
    get autocomplete_users_path, params: { q: '' }, as: :json
    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test 'search routes are defined' do
    assert_routing({ path: '/users/search', method: :get }, { controller: 'users', action: 'search' })
    assert_routing({ path: '/users/autocomplete', method: :get }, { controller: 'users', action: 'autocomplete' })
  end
end
