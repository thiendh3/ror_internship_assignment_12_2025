require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @micropost = microposts(:orange)
  end

  test 'should require logged in user to create comment' do
    assert_no_difference 'Comment.count' do
      post micropost_comments_path(@micropost), params: { comment: { content: 'Test' } }, as: :json
    end
  end

  test 'should create comment' do
    log_in_as(@user)

    assert_difference 'Comment.count', 1 do
      post micropost_comments_path(@micropost),
           params: { comment: { content: 'Great post!' } },
           as: :json
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_equal 'Great post!', json_response['comment']['content']
  end

  test 'should not create comment with empty content' do
    log_in_as(@user)

    assert_no_difference 'Comment.count' do
      post micropost_comments_path(@micropost),
           params: { comment: { content: '' } },
           as: :json
    end

    assert_response :unprocessable_entity
  end

  test 'should get comments list' do
    log_in_as(@user)
    @micropost.comments.create!(user: @user, content: 'Test comment')

    get micropost_comments_path(@micropost), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    # @micropost (orange) has 1 comment from fixture + 1 just created
    assert_equal 2, json_response.length
  end

  test 'should delete own comment' do
    log_in_as(@user)
    comment = @micropost.comments.create!(user: @user, content: 'Test')

    assert_difference 'Comment.count', -1 do
      delete micropost_comment_path(@micropost, comment), as: :json
    end

    assert_response :success
  end

  test 'micropost owner should delete any comment' do
    log_in_as(@micropost.user)
    commenter = users(:archer)
    comment = @micropost.comments.create!(user: commenter, content: 'Test')

    assert_difference 'Comment.count', -1 do
      delete micropost_comment_path(@micropost, comment), as: :json
    end

    assert_response :success
  end
end
