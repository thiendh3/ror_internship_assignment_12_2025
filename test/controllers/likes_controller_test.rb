require 'test_helper'

class LikesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @other_user = users(:archer)
    @micropost = microposts(:tau_manifesto) # Use different micropost without existing like
  end

  test 'should require logged in user to create like' do
    assert_no_difference 'Like.count' do
      post micropost_likes_path(@micropost), params: {}, as: :json
    end
  end

  test 'should create like' do
    log_in_as(@user)

    assert_difference 'Like.count', 1 do
      post micropost_likes_path(@micropost), params: {}, as: :json
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_not_nil json_response['like_id']
  end

  test 'should not create duplicate like' do
    log_in_as(@user)

    # Create first like
    post micropost_likes_path(@micropost), params: {}, as: :json

    # Try to create duplicate
    assert_no_difference 'Like.count' do
      post micropost_likes_path(@micropost), params: {}, as: :json
    end

    assert_response :unprocessable_entity
  end

  test 'should destroy like' do
    log_in_as(@user)
    like = @micropost.likes.create!(user: @user)

    assert_difference 'Like.count', -1 do
      delete micropost_like_path(@micropost, like), as: :json
    end

    assert_response :success
  end

  test 'should get likes list' do
    log_in_as(@user)
    @micropost.likes.create!(user: @user)

    get micropost_likes_path(@micropost), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 1, json_response.length
  end
end
