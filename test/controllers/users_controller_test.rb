require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @other_user = users(:archer)
  end

  test 'should get new' do
    get signup_url
    assert_response :success
  end

  test 'should redirect index when not logged in' do
    get users_url
    assert_redirected_to login_url
  end

  test 'should show user index when logged in' do
    log_in_as(@user)
    get users_url
    assert_response :success
  end

  test 'should show user profile' do
    log_in_as(@user)
    get user_url(@user)
    assert_response :success
    assert_select 'h2', text: @user.name
  end

  test 'should return JSON for user profile' do
    get user_url(@user), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal @user.id, json_response['user']['id']
    assert_equal @user.name, json_response['user']['name']
    assert_equal @user.email, json_response['user']['email']
    assert_includes json_response['user'], 'microposts_count'
    assert_includes json_response['user'], 'followers_count'
    assert_includes json_response['user'], 'following_count'
  end

  test 'should redirect show when user not activated' do
    @user.update_column(:activated, false)
    get user_url(@user)
    assert_redirected_to root_url
  end

  test 'should search users' do
    log_in_as(@user)
    # Ensure Elasticsearch is reindexed (skip if not available in test env)
    begin
      User.reindex
      get search_users_url, params: { q: 'michael' }, as: :json
      assert_response :success

      json_response = JSON.parse(response.body)
      assert_includes json_response, 'users'
      assert_includes json_response, 'total'
    rescue StandardError => e
      skip "Elasticsearch not available in test environment: #{e.message}"
    end
  end

  test 'should return empty results for blank search' do
    log_in_as(@user)
    get search_users_url, params: { q: '' }, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal [], json_response['users']
    assert_equal 0, json_response['total']
  end

  test 'should filter search by following' do
    log_in_as(@user)
    # Michael already follows archer in fixtures, so no need to follow again

    begin
      User.reindex
      get search_users_url, params: { q: 'archer', following: 'true' }, as: :json
      assert_response :success
    rescue StandardError => e
      skip "Elasticsearch not available in test environment: #{e.message}"
    end
  end

  test 'should update user profile' do
    log_in_as(@user)
    patch user_url(@user), params: {
      user: {
        name: 'Updated Name',
        email: @user.email,
        password: '',
        password_confirmation: ''
      }
    }
    assert_redirected_to @user
    @user.reload
    assert_equal 'Updated Name', @user.name
  end

  test 'should return JSON for successful update' do
    log_in_as(@user)
    patch user_url(@user), params: {
      user: {
        name: 'Updated Name',
        email: @user.email,
        password: '',
        password_confirmation: ''
      }
    }, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_equal 'Updated Name', json_response['user']['name']
  end

  test 'should return JSON errors for failed update' do
    log_in_as(@user)
    patch user_url(@user), params: {
      user: {
        name: '',
        email: @user.email,
        password: '',
        password_confirmation: ''
      }
    }, as: :json
    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_not json_response['success']
    assert_includes json_response, 'errors'
  end

  test 'should get followers' do
    log_in_as(@user)
    @other_user.follow(@user)
    get followers_user_url(@user)
    assert_response :success
  end

  test 'should return JSON for followers' do
    log_in_as(@user)
    @other_user.follow(@user)
    get followers_user_url(@user), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 'Followers', json_response['title']
    assert_includes json_response, 'users'
    assert_includes json_response, 'pagination'
  end

  test 'should get following' do
    log_in_as(@user)
    # Michael already follows archer in fixtures
    get following_user_url(@user)
    assert_response :success
  end

  test 'should return JSON for following' do
    log_in_as(@user)
    # Michael already follows archer in fixtures
    get following_user_url(@user), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 'Following', json_response['title']
    assert_includes json_response, 'users'
    assert_includes json_response, 'pagination'
  end

  test 'should redirect edit when not logged in' do
    get edit_user_url(@user)
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test 'should redirect update when not logged in' do
    patch user_url(@user), params: {
      user: {
        name: @user.name,
        email: @user.email
      }
    }
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test 'should redirect edit when logged in as wrong user' do
    log_in_as(@other_user)
    get edit_user_url(@user)
    assert_redirected_to root_url
  end

  test 'should redirect update when logged in as wrong user' do
    log_in_as(@other_user)
    patch user_url(@user), params: {
      user: {
        name: @user.name,
        email: @user.email
      }
    }
    assert_redirected_to root_url
  end
end
