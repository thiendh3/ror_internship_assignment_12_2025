require 'test_helper'

class UserSearchServiceTest < ActiveSupport::TestCase
  test 'initializes with params' do
    params = { q: 'test', filter: 'following', min_followers: '5', page: '2' }
    service = UserSearchService.new(params, nil)

    assert_equal 'test', service.query
    assert_equal 'following', service.filter
    assert_equal 5, service.min_followers
    assert_equal '2', service.page
  end

  test 'strips whitespace from query' do
    params = { q: '  test query  ' }
    service = UserSearchService.new(params, nil)

    assert_equal 'test query', service.query
  end

  test 'handles empty params' do
    params = {}
    service = UserSearchService.new(params, nil)

    assert_equal '', service.query
    assert_nil service.filter
    assert_nil service.min_followers
    assert_nil service.min_following
  end

  test 'converts min_followers to integer' do
    params = { min_followers: '10' }
    service = UserSearchService.new(params, nil)

    assert_equal 10, service.min_followers
    assert service.min_followers.is_a?(Integer)
  end
end
