require 'test_helper'

class RelationshipsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @other_user = users(:lana) # Use lana since michael doesn't follow her yet
  end

  test 'should require logged-in user for create' do
    assert_no_difference 'Relationship.count' do
      post relationships_path, params: { followed_id: @other_user.id }
    end
    assert_redirected_to login_url
  end

  test 'should require logged-in user for destroy' do
    log_in_as(@user)
    relationship = @user.active_relationships.create!(followed_id: @other_user.id)
    delete "/logout"
    
    assert_no_difference 'Relationship.count' do
      delete relationship_path(relationship)
    end
    assert_redirected_to login_url
  end

  test 'should follow a user' do
    log_in_as(@user)
    assert_difference 'Relationship.count', 1 do
      post relationships_path, params: { followed_id: @other_user.id }
    end
  end

  test 'should unfollow a user' do
    log_in_as(@user)
    relationship = @user.active_relationships.create!(followed_id: @other_user.id)
    assert_difference 'Relationship.count', -1 do
      delete relationship_path(relationship)
    end
  end

  test 'should follow a user with AJAX' do
    log_in_as(@user)
    assert_difference 'Relationship.count', 1 do
      post relationships_path, params: { followed_id: @other_user.id }, xhr: true
    end
  end

  test 'should unfollow a user with AJAX' do
    log_in_as(@user)
    relationship = @user.active_relationships.create!(followed_id: @other_user.id)
    assert_difference 'Relationship.count', -1 do
      delete relationship_path(relationship), xhr: true
    end
  end

  test 'should return JSON when following' do
    log_in_as(@user)
    post relationships_path, params: { followed_id: @other_user.id }, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert json_response['following']
    assert_includes json_response, 'relationship_id'
    assert_includes json_response, 'followers_count'
    assert_includes json_response, 'following_count'
  end

  test 'should return JSON when unfollowing' do
    log_in_as(@user)
    relationship = @user.active_relationships.create!(followed_id: @other_user.id)
    delete relationship_path(relationship), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_not json_response['following']
    assert_includes json_response, 'followers_count'
    assert_includes json_response, 'following_count'
  end

  test 'should create follow notification' do
    log_in_as(@user)
    assert_difference 'Notification.count', 1 do
      post relationships_path, params: { followed_id: @other_user.id }
    end

    notification = Notification.last
    assert_equal @other_user, notification.recipient
    assert_equal @user, notification.actor
    assert_equal 'followed', notification.action
  end

  test 'should not create duplicate relationships' do
    log_in_as(@user)
    @user.follow(@other_user)

    assert_no_difference 'Relationship.count' do
      post relationships_path, params: { followed_id: @other_user.id }
    end
  end

  test 'should update follower counts' do
    log_in_as(@user)
    initial_followers_count = @other_user.followers.count
    initial_following_count = @user.following.count

    post relationships_path, params: { followed_id: @other_user.id }, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal initial_followers_count + 1, json_response['followers_count']
  end
end
