require 'test_helper'

class UserProfileTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @other_user = users(:lana)
  end

  test 'user profile display' do
    log_in_as(@user)
    get user_path(@user)
    assert_response :success
    assert_select 'h2', text: @user.name
    assert_select '#followers'
    assert_select '#following'
  end

  test 'user profile shows microposts count' do
    log_in_as(@user)
    get user_path(@user)
    assert_response :success
    assert_match(/Microposts/, response.body)
  end

  test 'user profile shows follow button for other users' do
    log_in_as(@user)
    get user_path(@other_user)
    assert_response :success
    assert_select 'input[value=?]', 'Follow'
  end

  test 'user profile shows unfollow button when already following' do
    log_in_as(@user)
    @user.follow(@other_user)
    get user_path(@other_user)
    assert_response :success
    assert_select 'input[value=?]', 'Unfollow'
  end

  test 'user profile shows edit button for own profile' do
    log_in_as(@user)
    get user_path(@user)
    assert_response :success
    assert_select 'a[href=?]', edit_user_path(@user)
  end

  test 'followers page displays followers' do
    log_in_as(@user)
    @other_user.follow(@user)
    get followers_user_path(@user)
    assert_response :success
    assert_match(/Followers/, response.body)
  end

  test 'following page displays following users' do
    log_in_as(@user)
    @user.follow(@other_user)
    get following_user_path(@user)
    assert_response :success
    assert_match(/Following/, response.body)
  end

  test 'following user via AJAX' do
    log_in_as(@user)
    assert_difference '@other_user.followers.count', 1 do
      post relationships_path, params: { followed_id: @other_user.id }, as: :json
    end
    assert_response :success
  end

  test 'unfollowing user via AJAX' do
    log_in_as(@user)
    @user.follow(@other_user)
    relationship = @user.active_relationships.find_by(followed_id: @other_user.id)

    assert_difference '@other_user.followers.count', -1 do
      delete relationship_path(relationship), as: :json
    end
    assert_response :success
  end

  test 'stats update after follow' do
    log_in_as(@user)
    initial_followers = @other_user.followers.count
    @user.following.count

    post relationships_path, params: { followed_id: @other_user.id }, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal initial_followers + 1, json_response['followers_count']
  end
end
